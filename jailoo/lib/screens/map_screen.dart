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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const _overviewCenter = LatLng(41.46, 75.72);
  static const _overviewZoom = 10.5;

  final _mapController = MapController();
  AnimationController? _flyController;

  // Route state
  List<LatLng> _routePoints = [];
  Zone? _activeRouteZone;
  String _routeDuration = '';
  String _routeDistance = '';
  bool _fetchingRoute = false;

  // 3D terrain toggle
  bool _is3D = false;

  // Flag to prevent zooming back to overview after report tap
  bool _reportPressed = false;

  @override
  void dispose() {
    _flyController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Camera
  // ---------------------------------------------------------------------------

  void _animateCamera(LatLng target, double zoom) {
    _flyController?.dispose();

    final cam = _mapController.camera;
    final latTween = Tween(begin: cam.center.latitude, end: target.latitude);
    final lngTween = Tween(begin: cam.center.longitude, end: target.longitude);
    final zoomTween = Tween(begin: cam.zoom, end: zoom);

    _flyController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final curved = CurvedAnimation(
      parent: _flyController!,
      curve: Curves.easeInOut,
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
    _animateCamera(zone.center, 12.0);
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

    // Zoom to show both user location and destination
    final midLat = (kUserLocation.latitude + zone.center.latitude) / 2;
    final midLng = (kUserLocation.longitude + zone.center.longitude) / 2;
    _animateCamera(LatLng(midLat, midLng), 10.5);

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
            setState(() {
              _routePoints = coords
                  .map((c) => LatLng(
                        (c[1] as num).toDouble(),
                        (c[0] as num).toDouble(),
                      ))
                  .toList();
              _routeDuration = _formatDuration(duration);
              _routeDistance = _formatDistance(distance);
              _activeRouteZone = zone;
              _fetchingRoute = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    // Fallback: straight line with haversine distance
    if (mounted) {
      setState(() {
        _routePoints = [kUserLocation, zone.center];
        _routeDuration = '~${_formatDuration((_haversineM(kUserLocation, zone.center) / 4).round())}';
        _routeDistance = _formatDistance(_haversineM(kUserLocation, zone.center).round());
        _activeRouteZone = zone;
        _fetchingRoute = false;
      });
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _activeRouteZone = null;
      _routeDuration = '';
      _routeDistance = '';
    });
    _animateCamera(_overviewCenter, _overviewZoom);
  }

  String _formatDuration(int seconds) {
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins min';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  String _formatDistance(int meters) {
    if (meters < 1000) return '$meters m';
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
  // Tile URL logic
  // ---------------------------------------------------------------------------

  String _tileUrl(bool isDark, bool is3D) {
    if (is3D) {
      // OpenTopoMap: topographic terrain, contours, elevation — great for herders
      return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }
    if (isDark) {
      return 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png';
    }
    // Standard OSM — colorful, shows roads, rivers, peaks
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
              minZoom: 9.5,
              maxZoom: 15,
              onTap: _onMapTap,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: LatLngBounds(
                  const LatLng(41.15, 75.10),
                  const LatLng(41.75, 76.25),
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl(isDark, _is3D),
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.jailoo.app',
                maxZoom: 17,
              ),

              // Route polyline (below polygons so zones render on top)
              if (hasRoute)
                PolylineLayer(
                  polylines: [
                    // Outline for contrast
                    Polyline(
                      points: _routePoints,
                      color: Colors.white.withValues(alpha: 0.6),
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    Polyline(
                      points: _routePoints,
                      color: c.accent,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
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
                          ? (isDark ? 0.30 : 0.22)
                          : (isDark ? 0.16 : 0.12),
                    ),
                    borderColor: color.withValues(alpha: isDark ? 0.6 : 0.7),
                    borderStrokeWidth: isActive ? 2.5 : 1.5,
                    isFilled: true,
                  );
                }).toList(),
              ),

              MarkerLayer(
                markers: [
                  ...kZones.map((zone) {
                    final color = JailooColors.statusColor(zone.status);
                    return Marker(
                      point: zone.center,
                      width: 100,
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

                  // Destination marker when routing
                  if (hasRoute && _activeRouteZone != null)
                    Marker(
                      point: _activeRouteZone!.center,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: c.accent.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // User location dot
                  Marker(
                    point: kUserLocation,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.accent, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: c.accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
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
                    active: _is3D,
                    onTap: () => setState(() => _is3D = !_is3D),
                    child: Text(
                      '3D',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _is3D ? c.accent : c.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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

          // Bottom overlay: route card OR legend
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_fetchingRoute) _buildRouteLoading(c),
                if (hasRoute && !_fetchingRoute) _buildRouteCard(c),
                if (!hasRoute && !_fetchingRoute) _buildLegend(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom widgets
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: c.accent,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Building route...',
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
        color: c.bg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.route, color: c.accent, size: 16),
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
                        Text(
                          zone.nameEn,
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                        ),
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textMuted,
                              height: 1.4,
                            ),
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
                    backgroundColor: zone.status == 'banned' ? c.surface2 : c.accent,
                    foregroundColor: zone.status == 'banned' ? c.textMuted : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    size: 16,
                  ),
                  label: Text(
                    zone.status == 'banned' ? 'Zone banned' : 'Report: I\'m grazing here',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
  const _InfoRow({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable map toolbar button
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
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? colors.accent.withValues(alpha: 0.12)
              : colors.bg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? colors.accent.withValues(alpha: 0.4) : colors.border,
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
  const _LegendItem({
    required this.color,
    required this.label,
    required this.textColor,
  });

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
