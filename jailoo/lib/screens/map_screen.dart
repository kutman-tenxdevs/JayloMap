import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../data/zones.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../theme/theme_provider.dart';
import '../widgets/health_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/data_card.dart';
import '../services/app_controller.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const _overviewCenter = LatLng(41.42, 75.88);
  static const _overviewZoom = 9.6;

  final _mapController = MapController();

  // Fly animation
  AnimationController? _flyController;

  // Route animation — draws the line progressively from user to destination
  AnimationController? _routeAnimController;
  CurvedAnimation? _routeCurve;

  // Pulsing ring on user location dot
  late AnimationController _pulseController;

  // Route state
  List<LatLng> _routePoints = [];
  Zone? _activeRouteZone;
  String _routeDuration = '';
  String _routeDistance = '';
  bool _fetchingRoute = false;

  bool _reportPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    // Listen to cross-screen navigation requests from AppController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppController>().addListener(_onAppController);
    });
  }

  void _onAppController() {
    final ctrl = context.read<AppController>();
    final zone = ctrl.pendingRouteZone;
    if (zone != null) {
      ctrl.clearPendingRoute();
      _startRoute(zone);
    }
  }

  @override
  void dispose() {
    // ignore: use_build_context_synchronously — context still valid at this point
    context.read<AppController>().removeListener(_onAppController);
    _flyController?.dispose();
    _routeAnimController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Camera fly animation
  // ---------------------------------------------------------------------------

  void _animateCamera(LatLng target, double zoom) {
    _flyController?.dispose();

    final cam = _mapController.camera;
    final latTween = Tween(begin: cam.center.latitude, end: target.latitude);
    final lngTween = Tween(begin: cam.center.longitude, end: target.longitude);
    final zoomTween = Tween(begin: cam.zoom, end: zoom);

    _flyController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    final curved = CurvedAnimation(
      parent: _flyController!,
      curve: Curves.easeInOutCubic,
    );

    _flyController!.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(curved), lngTween.evaluate(curved)),
        zoomTween.evaluate(curved),
      );
    });

    _flyController!.forward();
  }

  // ---------------------------------------------------------------------------
  // Zone selection
  // ---------------------------------------------------------------------------

  void _selectZone(Zone zone) {
    _animateCamera(zone.center, 12.5);
    _reportPressed = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ZoneSheet(
        zone: zone,
        onReport: () {
          _reportPressed = true;
          _startRoute(zone);
        },
      ),
    ).then((_) {
      if (mounted && !_reportPressed) {
        _animateCamera(_overviewCenter, _overviewZoom);
      }
    });
  }

  void _onMapTap(TapPosition _, LatLng point) {
    for (final zone in kZonesByTapOrder) {
      if (_isPointInPolygon(point, zone.boundary)) {
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

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  Future<void> _startRoute(Zone zone) async {
    setState(() {
      _fetchingRoute = true;
      _routePoints = [];
      _activeRouteZone = null;
    });

    // Fly to frame both user and destination
    final midLat = (kUserLocation.latitude + zone.center.latitude) / 2;
    final midLng = (kUserLocation.longitude + zone.center.longitude) / 2;
    // Offset center slightly south so bottom sheet doesn't cover the route
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
            _setRoute(
              zone: zone,
              points: coords
                  .map((c) => LatLng(
                        (c[1] as num).toDouble(),
                        (c[0] as num).toDouble(),
                      ))
                  .toList(),
              duration: _fmt(duration),
              distance: _fmtM(distance),
            );
          }
          return;
        }
      }
    } catch (_) {}

    // Fallback: straight line from user dot to zone center
    if (mounted) {
      final dist = _haversineM(kUserLocation, zone.center);
      // Generate intermediate points along a straight line for smoother animation
      const steps = 30;
      final pts = List.generate(steps + 1, (i) {
        final t = i / steps;
        return LatLng(
          kUserLocation.latitude +
              t * (zone.center.latitude - kUserLocation.latitude),
          kUserLocation.longitude +
              t * (zone.center.longitude - kUserLocation.longitude),
        );
      });
      _setRoute(
        zone: zone,
        points: pts,
        duration: '~${_fmt((dist / 5000 * 3600).round())}',
        distance: _fmtM(dist.round()),
      );
    }
  }

  void _setRoute({
    required Zone zone,
    required List<LatLng> points,
    required String duration,
    required String distance,
  }) {
    _routeAnimController?.dispose();
    _routeAnimController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _routeCurve = CurvedAnimation(
      parent: _routeAnimController!,
      curve: Curves.easeInOut,
    );

    setState(() {
      _routePoints = points;
      _activeRouteZone = zone;
      _routeDuration = duration;
      _routeDistance = distance;
      _fetchingRoute = false;
    });

    _routeAnimController!.forward();
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _activeRouteZone = null;
      _routeDuration = '';
      _routeDistance = '';
      _fetchingRoute = false;
    });
    _routeAnimController?.dispose();
    _routeAnimController = null;
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
  // Tile URL
  // ---------------------------------------------------------------------------

  String _tileUrl(bool isDark) {
    if (isDark) {
      return 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png';
    }
    // OSM standard tile — same data source as OpenFreeMap "bright" style
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _overviewCenter,
              initialZoom: _overviewZoom,
              minZoom: 8.5,
              maxZoom: 15,
              onTap: _onMapTap,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: LatLngBounds(
                  const LatLng(41.05, 75.25),
                  const LatLng(41.80, 76.55),
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl(isDark),
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.jailoo.app',
                maxZoom: 17,
              ),

              // Route polyline — animated draw from user dot to destination
              if (hasRoute && _routeAnimController != null)
                AnimatedBuilder(
                  animation: _routeAnimController!,
                  builder: (_, __) {
                    final progress = _routeCurve?.value ?? 1.0;
                    final count =
                        max(2, (_routePoints.length * progress).round());
                    final pts = _routePoints.sublist(0, count);
                    return PolylineLayer(
                      polylines: [
                        Polyline(
                          points: pts,
                          color: Colors.white.withValues(alpha: 0.55),
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                        Polyline(
                          points: pts,
                          color: c.accent,
                          strokeWidth: 4.5,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                      ],
                    );
                  },
                ),

              // Zone fills: healthy → recovering → banned (z-order)
              PolygonLayer(
                polygons: kZonesByRenderOrder.map((zone) {
                  final color = JailooColors.statusColor(zone.status);
                  final isActive = zone.id == _activeRouteZone?.id;
                  return Polygon(
                    points: zone.boundary,
                    color: color.withValues(
                      alpha: isActive
                          ? (isDark ? 0.30 : 0.24)
                          : (isDark ? 0.16 : 0.12),
                    ),
                    borderColor: color.withValues(alpha: isDark ? 0.60 : 0.70),
                    borderStrokeWidth: isActive ? 2.5 : 1.5,
                    isFilled: true,
                  );
                }).toList(),
              ),

              MarkerLayer(
                markers: [
                  // Zone label markers
                  ...kZones.map((zone) {
                    final color = JailooColors.statusColor(zone.status);
                    return Marker(
                      point: zone.center,
                      width: 110,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _selectZone(zone),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: c.bg.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                zone.nameEn,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: color,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Destination marker — animates in with elastic scale
                  if (hasRoute && _activeRouteZone != null)
                    Marker(
                      point: _activeRouteZone!.center,
                      width: 32,
                      height: 32,
                      child: AnimatedBuilder(
                        animation: _routeAnimController!,
                        builder: (_, __) {
                          final scale = Curves.elasticOut.transform(
                              (_routeCurve?.value ?? 1.0).clamp(0.0, 1.0));
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: c.accent,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.accent.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.flag,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // User location dot with pulsing ring
                  Marker(
                    point: kUserLocation,
                    width: 40,
                    height: 40,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) {
                        final pulse =
                            Curves.easeInOut.transform(_pulseController.value);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
                            Container(
                              width: 28 + pulse * 10,
                              height: 28 + pulse * 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.accent
                                    .withValues(alpha: 0.12 - pulse * 0.09),
                                border: Border.all(
                                  color: c.accent
                                      .withValues(alpha: 0.3 - pulse * 0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            // Core dot
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.accent, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.accent.withValues(alpha: 0.45),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: c.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _HeaderPill(c: c),
                  const Spacer(),
                  _MapButton(
                    colors: c,
                    onTap: () => context.read<ThemeProvider>().toggle(),
                    child: Icon(
                      context.watch<ThemeProvider>().isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 15,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom overlay with smooth transitions between legend / loading / route
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
                  ).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(
                  _fetchingRoute
                      ? 'loading'
                      : hasRoute
                          ? 'route'
                          : 'legend',
                ),
                child: _fetchingRoute
                    ? _buildRouteLoading(c)
                    : hasRoute
                        ? _buildRouteCard(c)
                        : _buildLegend(c),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom cards
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
          _LegendItem(
              color: JailooColors.healthy,
              label: 'Safe',
              textColor: c.textMuted),
          _LegendItem(
              color: JailooColors.recovering,
              label: 'Recovering',
              textColor: c.textMuted),
          _LegendItem(
              color: JailooColors.banned,
              label: 'Banned',
              textColor: c.textMuted),
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
          Text(
            'Building route…',
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
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
  final VoidCallback onReport;
  const _ZoneSheet({required this.zone, required this.onReport});

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final statusColor = JailooColors.statusColor(zone.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
              const SizedBox(height: 16),
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
                        Text(zone.nameEn,
                            style: TextStyle(fontSize: 13, color: c.textMuted)),
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
                  Expanded(
                      child: DataCard(
                          label: 'Health',
                          value: '${zone.healthScore}',
                          unit: '/100')),
                  const SizedBox(width: 8),
                  Expanded(
                      child: DataCard(
                          label: 'Max herd',
                          value: '${zone.maxHerd}',
                          unit: 'sheep')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: DataCard(
                          label: 'Last grazed',
                          value: '${zone.lastGrazedDaysAgo}',
                          unit: 'days ago')),
                  const SizedBox(width: 8),
                  Expanded(
                      child: DataCard(
                          label: 'Safe days',
                          value: '${zone.safeDays}',
                          unit: 'days')),
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
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                        label: 'Area',
                        value: '${zone.areaKm2.toStringAsFixed(0)} km²',
                        colors: c),
                    _InfoRow(
                        label: 'Elevation', value: zone.elevation, colors: c),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: statusColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            zone.seasonNote,
                            style: TextStyle(
                                fontSize: 12, color: c.textMuted, height: 1.4),
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
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        zone.status == 'banned' ? c.surface2 : c.accent,
                    foregroundColor:
                        zone.status == 'banned' ? c.textMuted : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: zone.status == 'banned'
                      ? null
                      : () {
                          Navigator.pop(context);
                          onReport();
                        },
                  icon: Icon(
                      zone.status == 'banned' ? Icons.block : Icons.route,
                      size: 16),
                  label: Text(
                    zone.status == 'banned'
                        ? 'Zone banned'
                        : 'Report: I\'m grazing here',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final JailooColors colors;
  const _InfoRow(
      {required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.textMuted)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable toolbar button
// ---------------------------------------------------------------------------

class _MapButton extends StatelessWidget {
  final JailooColors colors;
  final VoidCallback onTap;
  final Widget child;
  final bool active;
  const _MapButton({
    required this.colors,
    required this.onTap,
    required this.child,
    this.active = false,
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
          color: active
              ? colors.accent.withValues(alpha: 0.12)
              : colors.bg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                active ? colors.accent.withValues(alpha: 0.45) : colors.border,
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
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
  const _LegendItem(
      {required this.color, required this.label, required this.textColor});

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
