import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
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

  @override
  void dispose() {
    _flyController?.dispose();
    super.dispose();
  }

  void _animateCamera(LatLng target, double zoom) {
    _flyController?.dispose();

    final cam = _mapController.camera;
    final latTween = Tween(begin: cam.center.latitude, end: target.latitude);
    final lngTween = Tween(begin: cam.center.longitude, end: target.longitude);
    final zoomTween = Tween(begin: cam.zoom, end: zoom);

    _flyController = AnimationController(
      duration: const Duration(milliseconds: 500),
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

  void _selectZone(Zone zone) {
    _animateCamera(zone.center, 12.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ZoneSheet(zone: zone),
    ).then((_) {
      if (mounted) _animateCamera(_overviewCenter, _overviewZoom);
    });
  }

  void _onMapTap(TapPosition _, LatLng point) {
    // Check banned first, then recovering, then healthy (top-most wins)
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

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;

    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png';

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
                urlTemplate: tileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.jailoo.app',
              ),
              // Render in z-order: healthy (bottom) → recovering → banned (top)
              PolygonLayer(
                polygons: kZonesByRenderOrder.map((zone) {
                  final color = JailooColors.statusColor(zone.status);
                  return Polygon(
                    points: zone.boundary,
                    color: color.withValues(alpha: isDark ? 0.16 : 0.12),
                    borderColor: color.withValues(alpha: isDark ? 0.6 : 0.7),
                    borderStrokeWidth: 1.5,
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
                  Marker(
                    point: kUserLocation,
                    width: 16,
                    height: 16,
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
                    ),
                  ),
                ],
              ),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                          ),
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
                              style: TextStyle(
                                fontSize: 10,
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _ThemeToggle(colors: c),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: _buildLegend(c),
          ),
        ],
      ),
    );
  }

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
}

// ---------------------------------------------------------------------------
// Bottom sheet
// ---------------------------------------------------------------------------

class _ZoneSheet extends StatelessWidget {
  final Zone zone;
  const _ZoneSheet({required this.zone});

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
                    Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
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
                child: FilledButton(
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reported: grazing at ${zone.nameEn}'),
                              backgroundColor: c.surface,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  child: Text(
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
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small widgets
// ---------------------------------------------------------------------------

class _ThemeToggle extends StatelessWidget {
  final JailooColors colors;
  const _ThemeToggle({required this.colors});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return GestureDetector(
      onTap: () => context.read<ThemeProvider>().toggle(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.bg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 16,
          color: colors.textMuted,
        ),
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
