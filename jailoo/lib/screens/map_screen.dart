import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../data/zones.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../theme/theme_provider.dart';
import '../widgets/health_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/data_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const _overviewCenter = LatLng(41.44, 75.85);
  static const _overviewZoom = 7.8;

  MapLibreMapController? _mapController;

  // Selected zone panel state
  Zone? _selectedZone;
  bool _sheetVisible = false;

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

      // Center point feature for labels/markers
      features.add({
        'type': 'Feature',
        'id': '${zone.id}-center',
        'properties': {
          ...props,
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
      'healthy': '#10B981', // Emerald
      'recovering': '#F59E0B', // Amber
      'banned': '#EF4444', // Crimson
    }.entries) {
      final polyFilter = ['all', ['==', 'status', entry.key], ['!=', 'isCenter', true]];
      final pointFilter = ['all', ['==', 'status', entry.key], ['==', 'isCenter', true]];

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
      await ctrl.addCircleLayer(
        'zones',
        'zones-centers-${entry.key}',
        CircleLayerProperties(
          circleColor: entry.value,
          circleRadius: 6.0,
          circleStrokeColor: '#ffffff',
          circleStrokeWidth: 2.0,
        ),
        filter: pointFilter,
      );
    }

    // Highlight layer: initially matches nothing (id -1 never exists).
    await ctrl.addFillLayer(
      'zones',
      'zones-highlight',
      const FillLayerProperties(fillColor: '#0f172a', fillOpacity: 0.1),
      filter: ['==', 'id', -1],
    );

    // Zone name labels — static color avoids expression-font interaction issues.
    await ctrl.addSymbolLayer(
      'zones',
      'zones-labels',
      const SymbolLayerProperties(
        textField: ['get', 'nameEn'],
        textSize: 13.0,
        textColor: '#0f172a',
        textHaloColor: '#ffffff',
        textHaloWidth: 2.0,
        textAllowOverlap: false,
        textIgnorePlacement: false,
        textAnchor: 'top',
        textOffset: [0.0, 0.8],
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
      circleColor: '#22C55E',
      circleOpacity: 0.12,
      circleStrokeWidth: 0,
    ));
    await ctrl.addCircle(const CircleOptions(
      geometry: kUserLocation,
      circleRadius: 7,
      circleColor: '#FFFFFF',
      circleStrokeColor: '#22C55E',
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
        lineColor: '#22C55E',
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
      circleColor: '#22C55E',
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
      final lati = poly[i].latitude, latj = poly[j].latitude;
      final lngi = poly[i].longitude, lngj = poly[j].longitude;
      if (((lngi > pt.longitude) != (lngj > pt.longitude)) &&
          (pt.latitude < (latj - lati) * (pt.longitude - lngi) / (lngj - lngi) + lati)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  void _selectZone(Zone zone) {
    _animateCamera(zone.center, 9.5);
    _reportPressed = false;
    setState(() {
      _selectedZone = zone;
      _sheetVisible = true;
    });
    final ctrl = _mapController;
    if (ctrl != null) _updateHighlight(ctrl, zone);
  }

  void _closeSheet() {
    setState(() { _sheetVisible = false; });
    if (!_reportPressed) {
      _animateCamera(_overviewCenter, _overviewZoom);
      final ctrl = _mapController;
      if (ctrl != null) _updateHighlight(ctrl, null);
    }
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
    _animateCamera(LatLng(midLat - 0.08, midLng), 8.5);

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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final hasRoute = _routePoints.isNotEmpty;

    return Stack(
      children: [
          MapLibreMap(
            styleString: _styleUrl(isDark),
            initialCameraPosition: const CameraPosition(
              target: _overviewCenter,
              zoom: _overviewZoom,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(7.0, 14.0),
            cameraTargetBounds: CameraTargetBounds(
              LatLngBounds(
                southwest: const LatLng(40.20, 73.00),
                northeast: const LatLng(42.60, 78.20),
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

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _HeaderPill(c: c),
                  const Spacer(),
                  // Reset camera
                  _MapButton(
                    colors: c,
                    onTap: _resetCamera,
                    child: Icon(
                      Icons.explore_outlined,
                      size: 15,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Theme toggle
                  _MapButton(
                    colors: c,
                    onTap: () => context.read<ThemeProvider>().toggle(),
                    child: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 15,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom overlay
          Positioned(
            bottom: 12,
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
                key: ValueKey(_fetchingRoute ? 'loading' : hasRoute ? 'route' : 'legend'),
                child: _fetchingRoute
                    ? _buildRouteLoading(c)
                    : hasRoute
                        ? _buildRouteCard(c)
                        : _buildLegend(c),
              ),
            ),
          ),
        // ── Zone detail sheet (slides up from bottom) ──────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          left: 0, right: 0,
          bottom: _sheetVisible ? 0 : -600,
          child: _selectedZone == null
              ? const SizedBox.shrink()
              : SafeArea(
                  top: false,
                  child: _ZoneSheet(
                    zone: _selectedZone!,
                    onClose: _closeSheet,
                    onReport: () {
                      _reportPressed = true;
                      _closeSheet();
                      _startRoute(_selectedZone!);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom panels
  // ---------------------------------------------------------------------------

  Widget _buildLegend(JailooColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.bg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: JailooColors.healthy, label: 'Safe', textColor: c.textMuted),
          _LegendItem(color: JailooColors.recovering, label: 'Recovering', textColor: c.textMuted),
          _LegendItem(color: JailooColors.banned, label: 'Banned', textColor: c.textMuted),
        ],
      ),
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
// Bottom sheet
// ---------------------------------------------------------------------------

class _ZoneSheet extends StatelessWidget {
  final Zone zone;
  final VoidCallback onClose;
  final VoidCallback onReport;
  const _ZoneSheet({required this.zone, required this.onClose, required this.onReport});

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final statusColor = JailooColors.statusColor(zone.status);

    return Container(
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + close row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.close, size: 14, color: c.textMuted),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zone.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(zone.nameEn, style: TextStyle(fontSize: 13, color: c.textMuted)),
                          ],
                        ),
                      ),
                      StatusBadge(status: zone.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HealthBar(score: zone.healthScore),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: DataCard(label: 'Health', value: '${zone.healthScore}', unit: '/100')),
                      const SizedBox(width: 8),
                      Expanded(child: DataCard(label: 'Max herd', value: '${zone.maxHerd}', unit: 'sheep')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: DataCard(label: 'Last grazed', value: '${zone.lastGrazedDaysAgo}', unit: 'days ago')),
                      const SizedBox(width: 8),
                      Expanded(child: DataCard(label: 'Safe days', value: '${zone.safeDays}', unit: 'days')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(label: 'Area', value: '${zone.areaKm2.toStringAsFixed(0)} km²', colors: c),
                        _InfoRow(label: 'Elevation', value: zone.elevation, colors: c),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 14, color: statusColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                zone.seasonNote,
                                style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: zone.status == 'banned' ? c.surface2 : c.accent,
                        foregroundColor: zone.status == 'banned' ? c.textMuted : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: zone.status == 'banned' ? null : onReport,
                      icon: Icon(zone.status == 'banned' ? Icons.block : Icons.route, size: 16),
                      label: Text(
                        zone.status == 'banned' ? 'Zone banned' : "Report: I'm grazing here",
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final JailooColors colors;
  const _InfoRow({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.textMuted)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar widgets
// ---------------------------------------------------------------------------

class _MapButton extends StatelessWidget {
  final JailooColors colors;
  final VoidCallback onTap;
  final Widget child;
  const _MapButton({
    required this.colors,
    required this.onTap,
    required this.child,
  });

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
          border: Border.all(
            color: colors.border,
            width: 0.5,
          ),
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
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Naryn Oblast',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
              ),
              Text(
                '${kZones.length} pasture zones',
                style: TextStyle(fontSize: 10, color: c.textMuted),
              ),
            ],
          ),
        ],
      ),
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
