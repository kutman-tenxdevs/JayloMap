import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../data/zones.dart';
import '../models/herder_profile.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../theme/theme_provider.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const _overviewCenter = LatLng(41.42, 75.88);
  static const _overviewZoom = 9.6;

  MapLibreMapController? _mapController;

  // Route state
  List<LatLng> _routePoints = [];
  Zone? _activeRouteZone;
  String _routeDuration = '';
  String _routeDistance = '';
  bool _fetchingRoute = false;
  bool _reportPressed = false;

  // Route draw animation (progressively adds points to the GeoJSON source)
  Timer? _routeDrawTimer;
  int _routeDrawProgress = 0;

  // Annotation handles (needed to remove/replace them)
  Circle? _userRingCircle;
  Circle? _destCircle;

  // Pulse animation drives the user-location outer ring radius/opacity
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    // Update the outer pulse ring annotation every ~50 ms
    _pulseController.addListener(_updatePulseRing);
  }

  @override
  void dispose() {
    _pulseController.removeListener(_updatePulseRing);
    _pulseController.dispose();
    _routeDrawTimer?.cancel();
    _highlightPulseTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Map lifecycle
  // ---------------------------------------------------------------------------

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    final ctrl = _mapController;
    if (ctrl == null) return;

    // Clear previous annotations (style reload wipes style layers but not
    // always annotations — clear explicitly to avoid duplicates).
    await ctrl.clearCircles();
    await ctrl.clearSymbols();

    await _addZoneLayers(ctrl);
    await _addUserLocationMarker(ctrl);

    if (_routePoints.isNotEmpty) await _addRouteToMap(ctrl, _routePoints);
    if (_activeRouteZone != null) await _addDestinationMarker(ctrl, _activeRouteZone!);

  }

  // ---------------------------------------------------------------------------
  // GeoJSON zone layers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _buildZonesGeojson() {
    final features = <Map<String, dynamic>>[];
    
    for (final zone in kZones) {
      final ring = [
        ...zone.boundary.map((p) => [p.longitude, p.latitude]),
        [zone.boundary.first.longitude, zone.boundary.first.latitude],
      ];
      final props = {
        'id': zone.id,
        'status': zone.status,
        'nameEn': zone.nameEn,
        'healthScore': zone.healthScore,
      };

      // Polygon feature
      features.add({
        'type': 'Feature',
        'id': zone.id.toString(),
        'properties': props,
        'geometry': {
          'type': 'Polygon',
          'coordinates': [ring],
        },
      });

      // Center point feature for labels
      features.add({
        'type': 'Feature',
        'id': '${zone.id}-center',
        'properties': {
          ...props,
          'name': zone.nameEn,
          'isCenter': true,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [zone.lng, zone.lat],
        },
      });
    }

    return {'type': 'FeatureCollection', 'features': features};
  }

  Future<void> _addZoneLayers(MapLibreMapController ctrl) async {
    final geojson = _buildZonesGeojson();
    await ctrl.addSource('zones', GeojsonSourceProperties(data: geojson));

    // Use richer, more vibrant colors
    for (final entry in {
      'healthy': '#00C795',   // Teal
      'recovering': '#F5A623', // Amber
      'banned': '#EF4444',    // Crimson
    }.entries) {
      final polyFilter = ['all', ['==', 'status', entry.key], ['!=', 'isCenter', true]];

      await ctrl.addFillLayer(
        'zones',
        'zones-fill-${entry.key}',
        FillLayerProperties(fillColor: entry.value, fillOpacity: 0.15),
        filter: polyFilter,
      );
      await ctrl.addLineLayer(
        'zones',
        'zones-border-${entry.key}',
        LineLayerProperties(
          lineColor: entry.value,
          lineWidth: 2.5,
          lineOpacity: 0.8,
          lineCap: 'round',
          lineJoin: 'round',
        ),
        filter: polyFilter,
      );
      // Circle dots removed — replaced by text labels only
    }

    // Highlight layer: initially matches nothing (id -1 never exists).
    await ctrl.addFillLayer(
      'zones',
      'zones-highlight',
      const FillLayerProperties(fillColor: '#0f172a', fillOpacity: 0.1),
      filter: ['==', 'id', -1],
    );

    // Zone name labels
    await ctrl.addSymbolLayer(
      'zones',
      'zones-labels',
      const SymbolLayerProperties(
        textField: ['get', 'name'],
        textSize: 13.0,
        textColor: '#0f172a',
        textHaloColor: '#ffffff',
        textHaloWidth: 2.5,
        textAllowOverlap: false,
        textIgnorePlacement: false,
        textAnchor: 'center',
        textOffset: [0.0, 0.0],
        textLetterSpacing: 0.05,
      ),
      filter: ['==', 'isCenter', true],
    );
  }

  // Pulse animation for the selected zone highlight
  Timer? _highlightPulseTimer;
  bool _highlightPulseUp = true;

  Future<void> _updateHighlight(MapLibreMapController ctrl, Zone? zone) async {
    _highlightPulseTimer?.cancel();
    _highlightPulseTimer = null;

    if (zone == null) {
      try {
        await ctrl.setFilter('zones-highlight', ['==', 'id', -1]);
      } catch (_) {}
      return;
    }

    final color = JailooColors.statusColorHex(zone.status);
    try {
      // Legacy filter syntax — more reliable on Android maplibre_gl 0.21
      await ctrl.setFilter('zones-highlight', ['==', 'id', zone.id]);
      await ctrl.setLayerProperties(
        'zones-highlight',
        FillLayerProperties(fillColor: color, fillOpacity: 0.30),
      );
    } catch (_) { return; }

    // Gentle opacity pulse
    double opacity = 0.30;
    _highlightPulseUp = true;
    _highlightPulseTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      opacity += _highlightPulseUp ? 0.007 : -0.007;
      if (opacity >= 0.42) _highlightPulseUp = false;
      if (opacity <= 0.18) _highlightPulseUp = true;
      try {
        await ctrl.setLayerProperties(
          'zones-highlight',
          FillLayerProperties(fillColor: color, fillOpacity: opacity),
        );
      } catch (_) {}
    });
  }

  // ---------------------------------------------------------------------------
  // User location marker (circle + pulsing outer ring)
  // ---------------------------------------------------------------------------

  Future<void> _addUserLocationMarker(MapLibreMapController ctrl) async {
    _userRingCircle = await ctrl.addCircle(const CircleOptions(
      geometry: kUserLocation,
      circleRadius: 16,
      circleColor: '#00C795',
      circleOpacity: 0.12,
      circleStrokeWidth: 0,
    ));
    await ctrl.addCircle(const CircleOptions(
      geometry: kUserLocation,
      circleRadius: 7,
      circleColor: '#FFFFFF',
      circleStrokeColor: '#00C795',
      circleStrokeWidth: 2.5,
    ));
  }

  void _updatePulseRing() {
    final ctrl = _mapController;
    final ring = _userRingCircle;
    if (ctrl == null || ring == null) return;

    final t = Curves.easeInOut.transform(_pulseController.value);
    ctrl.updateCircle(
      ring,
      CircleOptions(
        circleRadius: 14 + t * 8,
        circleOpacity: 0.12 - t * 0.08,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Zone label symbols
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Route
  // ---------------------------------------------------------------------------

  // Builds a LineString GeoJSON Map from the first [count] points.
  // setGeoJsonSource expects Map<String, dynamic>, NOT a JSON string.
  Map<String, dynamic> _routeGeojsonMap(List<LatLng> pts, int count) {
    final coords = pts.take(count).map((p) => [p.longitude, p.latitude]).toList();
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
          'geometry': {'type': 'LineString', 'coordinates': coords},
        }
      ],
    };
  }

  // Creates the route source/layers then progressively draws the line using
  // setGeoJsonSource — the same technique as MapLibre GL's animated-route demos.
  Future<void> _addRouteToMap(MapLibreMapController ctrl, List<LatLng> pts) async {
    _routeDrawTimer?.cancel();
    _routeDrawProgress = 0;

    // Seed the source with just the first two points so layers can be created
    final seedJson = jsonEncode(_routeGeojsonMap(pts, 2));

    for (final id in ['route-line', 'route-outline']) {
      try { await ctrl.removeLayer(id); } catch (_) {}
    }
    try { await ctrl.removeSource('route'); } catch (_) {}

    await ctrl.addSource('route', GeojsonSourceProperties(data: seedJson));
    await ctrl.addLineLayer(
      'route', 'route-outline',
      const LineLayerProperties(
        lineColor: '#FFFFFF',
        lineWidth: 7.5,
        lineOpacity: 0.6,
        lineCap: 'round',
        lineJoin: 'round',
      ),
    );
    await ctrl.addLineLayer(
      'route', 'route-line',
      const LineLayerProperties(
        lineColor: '#00C795',
        lineWidth: 4.5,
        lineCap: 'round',
        lineJoin: 'round',
      ),
    );

    // Progressively extend the line — ~60 frames over the full route length
    final step = max(1, (pts.length / 60).ceil());
    _routeDrawTimer = Timer.periodic(const Duration(milliseconds: 16), (t) async {
      _routeDrawProgress = min(_routeDrawProgress + step, pts.length);
      try {
        await ctrl.setGeoJsonSource('route', _routeGeojsonMap(pts, _routeDrawProgress));
      } catch (_) {}
      if (_routeDrawProgress >= pts.length) t.cancel();
    });
  }

  Future<void> _removeRouteFromMap(MapLibreMapController ctrl) async {
    _routeDrawTimer?.cancel();
    for (final id in ['route-line', 'route-outline']) {
      try { await ctrl.removeLayer(id); } catch (_) {}
    }
    try { await ctrl.removeSource('route'); } catch (_) {}
  }

  Future<void> _addDestinationMarker(MapLibreMapController ctrl, Zone zone) async {
    if (_destCircle != null) {
      try { await ctrl.removeCircle(_destCircle!); } catch (_) {}
      _destCircle = null;
    }
    _destCircle = await ctrl.addCircle(CircleOptions(
      geometry: LatLng(zone.lat, zone.lng),
      circleRadius: 11,
      circleColor: '#00C795',
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 2.5,
    ));
  }

  // ---------------------------------------------------------------------------
  // Camera animation
  // ---------------------------------------------------------------------------

  Future<void> _animateCamera(
    LatLng target,
    double zoom, {
    double? tilt,
    double? bearing,
  }) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
        ),
      ),
      duration: const Duration(milliseconds: 700),
    );
  }

  void _onCameraIdle() {}

  void _resetCamera() {
    _animateCamera(_overviewCenter, _overviewZoom, tilt: 0, bearing: 0);
  }

  // ---------------------------------------------------------------------------
  // Zone tap & selection
  // ---------------------------------------------------------------------------

  void _onMapTap(Point<double> _, LatLng coords) {
    for (final zone in kZonesByTapOrder) {
      if (_isPointInPolygon(coords, zone.boundary)) {
        _selectZone(zone);
        return;
      }
    }
  }

  bool _isPointInPolygon(LatLng pt, List<LatLng> poly) {
    bool inside = false;
    int j = poly.length - 1;
    for (int i = 0; i < poly.length; i++) {
      final yi = poly[i].longitude, yj = poly[j].longitude;
      final xi = poly[i].latitude, xj = poly[j].latitude;
      if (((yi > pt.longitude) != (yj > pt.longitude)) &&
          (pt.latitude < (xj - xi) * (pt.longitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  void _selectZone(Zone zone) {
    _animateCamera(zone.center, 12.5);
    _reportPressed = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          zone: zone,
          onReport: () {
            Navigator.pop(context);
            _reportPressed = true;
            _startRoute(zone);
          },
        ),
      ),
    ).then((_) {
      if (mounted && !_reportPressed) {
        _animateCamera(_overviewCenter, _overviewZoom);
        final ctrl = _mapController;
        if (ctrl != null) _updateHighlight(ctrl, null);
      }
    });

    final ctrl = _mapController;
    if (ctrl != null) _updateHighlight(ctrl, zone);
  }

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  Future<void> _startRoute(Zone zone) async {
    setState(() {
      _fetchingRoute = true;
      _routePoints = [];
      _activeRouteZone = null;
    });

    final midLat = (kUserLocation.latitude + zone.center.latitude) / 2;
    final midLng = (kUserLocation.longitude + zone.center.longitude) / 2;
    _animateCamera(LatLng(midLat - 0.04, midLng), 10.2);

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${kUserLocation.longitude},${kUserLocation.latitude};'
        '${zone.center.longitude},${zone.center.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final coords = routes[0]['geometry']['coordinates'] as List;
          final duration = (routes[0]['duration'] as num).toInt();
          final distance = (routes[0]['distance'] as num).toInt();
          if (mounted) {
            await _applyRoute(
              zone: zone,
              points: coords
                  .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                  .toList(),
              duration: _fmt(duration),
              distance: _fmtM(distance),
            );
          }
          return;
        }
      }
    } catch (_) {}

    // Fallback: straight line
    if (mounted) {
      final dist = _haversineM(kUserLocation, zone.center);
      const steps = 30;
      final pts = List.generate(steps + 1, (i) {
        final t = i / steps;
        return LatLng(
          kUserLocation.latitude + t * (zone.center.latitude - kUserLocation.latitude),
          kUserLocation.longitude + t * (zone.center.longitude - kUserLocation.longitude),
        );
      });
      await _applyRoute(
        zone: zone,
        points: pts,
        duration: '~${_fmt((dist / 5000 * 3600).round())}',
        distance: _fmtM(dist.round()),
      );
    }
  }

  Future<void> _applyRoute({
    required Zone zone,
    required List<LatLng> points,
    required String duration,
    required String distance,
  }) async {
    setState(() {
      _routePoints = points;
      _activeRouteZone = zone;
      _routeDuration = duration;
      _routeDistance = distance;
      _fetchingRoute = false;
    });

    final ctrl = _mapController;
    if (ctrl != null) {
      await _addRouteToMap(ctrl, points);
      await _addDestinationMarker(ctrl, zone);
    }
  }

  Future<void> _clearRoute() async {
    final ctrl = _mapController;
    if (ctrl != null) {
      await _removeRouteFromMap(ctrl);
      if (_destCircle != null) {
        try { await ctrl.removeCircle(_destCircle!); } catch (_) {}
        _destCircle = null;
      }
      await _updateHighlight(ctrl, null);
    }
    setState(() {
      _routePoints = [];
      _activeRouteZone = null;
      _routeDuration = '';
      _routeDistance = '';
      _fetchingRoute = false;
    });
    _animateCamera(_overviewCenter, _overviewZoom);
  }

  String _fmt(int seconds) {
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins min';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  String _fmtM(int meters) {
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  double _haversineM(LatLng a, LatLng b) {
    const R = 6371000.0;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final sa = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * R * atan2(sqrt(sa), sqrt(1 - sa));
  }

  // ---------------------------------------------------------------------------
  // Style URL
  // ---------------------------------------------------------------------------

  String _styleUrl(bool isDark) {
    return isDark
        ? 'https://tiles.openfreemap.org/styles/liberty'
        : 'https://tiles.openfreemap.org/styles/bright';
  }

  void _showZoneList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ZoneListSheet(
        onSelectZone: (zone) {
          Navigator.pop(context);
          _selectZone(zone);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final hasRoute = _routePoints.isNotEmpty;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          MapLibreMap(
            styleString: _styleUrl(isDark),
            initialCameraPosition: const CameraPosition(
              target: _overviewCenter,
              zoom: _overviewZoom,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(9.5, 15.0),
            cameraTargetBounds: CameraTargetBounds(
              LatLngBounds(
                southwest: const LatLng(41.05, 75.25),
                northeast: const LatLng(41.80, 76.55),
              ),
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapTap,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),

          // ── Left sidebar toolbar ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SidebarBtn(
                    colors: c,
                    onTap: _resetCamera,
                    child: Icon(Icons.my_location, size: 17, color: c.textMuted),
                  ),
                  const SizedBox(height: 8),
                  _SidebarBtn(
                    colors: c,
                    onTap: () => context.read<ThemeProvider>().toggle(),
                    child: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 17,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom overlay ────────────────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.35),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_fetchingRoute ? 'loading' : hasRoute ? 'route' : 'idle'),
                child: _fetchingRoute
                    ? _buildRouteLoading(c)
                    : hasRoute
                        ? _buildRouteCard(c)
                        : _buildBottomIdle(c),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom panels
  // ---------------------------------------------------------------------------

  Widget _buildBottomIdle(JailooColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Legend chip
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: c.bg.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendDot(color: JailooColors.healthy, label: 'Safe', c: c),
                _LegendDot(color: JailooColors.recovering, label: 'Recovering', c: c),
                _LegendDot(color: JailooColors.banned, label: 'Banned', c: c),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Zone list FAB
        GestureDetector(
          onTap: _showZoneList,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.list, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteLoading(JailooColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: c.bg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
          ),
          const SizedBox(width: 10),
          Text('Building route…', style: TextStyle(fontSize: 13, color: c.textMuted)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(JailooColors c) {
    final zone = _activeRouteZone;
    if (zone == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: c.bg.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.route, color: c.accent, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route to ${zone.nameEn}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_routeDuration · $_routeDistance',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearRoute,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.close, size: 14, color: c.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zone list bottom sheet
// ---------------------------------------------------------------------------

class _ZoneListSheet extends StatefulWidget {
  final void Function(Zone zone) onSelectZone;
  const _ZoneListSheet({required this.onSelectZone});

  @override
  State<_ZoneListSheet> createState() => _ZoneListSheetState();
}

class _ZoneListSheetState extends State<_ZoneListSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final profile = context.watch<HerderProfile>();
    final avatarLetter = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'A';
    final filtered = kZones.where((z) {
      if (_query.isEmpty) return true;
      return z.nameEn.toLowerCase().contains(_query.toLowerCase()) ||
          z.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.accent.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Text(
                      avatarLetter,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zone list',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
                      Text('${kZones.length} pasture zones · Naryn Oblast',
                          style: TextStyle(fontSize: 11, color: c.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: c.textMuted, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: c.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 14, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search zones…',
                  hintStyle: TextStyle(fontSize: 14, color: c.textMuted),
                  prefixIcon: Icon(Icons.search, size: 18, color: c.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Zone list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
              itemBuilder: (_, i) {
                final zone = filtered[i];
                final statusColor = JailooColors.statusColor(zone.status);
                return _ZoneListItem(
                  zone: zone,
                  statusColor: statusColor,
                  c: c,
                  onTap: () => widget.onSelectZone(zone),
                );
              },
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _ZoneListItem extends StatelessWidget {
  final Zone zone;
  final Color statusColor;
  final JailooColors c;
  final VoidCallback onTap;
  const _ZoneListItem({required this.zone, required this.statusColor, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = zone.status[0].toUpperCase() + zone.status.substring(1);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            // Status coloured thumbnail
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Icon(Icons.grass_outlined, size: 20, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.nameEn,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    '$status · ${zone.healthScore}/100 · ${zone.maxHerd} sheep cap',
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ],
              ),
            ),
            // Status dot + three-dot menu
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(height: 6),
                PopupMenuButton<String>(
                  iconSize: 16,
                  icon: Icon(Icons.more_vert, size: 16, color: c.textMuted),
                  color: c.bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: c.border)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(children: [
                        Icon(Icons.open_in_new, size: 16, color: c.textMuted),
                        const SizedBox(width: 8),
                        Text('View details', style: TextStyle(fontSize: 13, color: c.textPrimary)),
                      ]),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'view') onTap();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar widgets
// ---------------------------------------------------------------------------

class _SidebarBtn extends StatelessWidget {
  final JailooColors colors;
  final VoidCallback onTap;
  final Widget child;
  const _SidebarBtn({required this.colors, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.bg.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          border: Border.all(color: colors.border, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// Kept for legacy route card usage
class _MapButton extends StatelessWidget {
  final JailooColors colors;
  final VoidCallback onTap;
  final Widget child;
  const _MapButton({required this.colors, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.bg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final JailooColors c;
  const _HeaderPill({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.bg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Naryn Oblast', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
              Text('${kZones.length} pasture zones', style: TextStyle(fontSize: 10, color: c.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final JailooColors c;
  const _LegendDot({required this.color, required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: c.textMuted)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;
  const _LegendItem({required this.color, required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: textColor)),
      ],
    );
  }
}
