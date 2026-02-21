import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../theme/theme_provider.dart';
import '../widgets/health_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/data_card.dart';

class DetailScreen extends StatelessWidget {
  final Zone zone;
  const DetailScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final statusColor = JailooColors.statusColor(zone.status);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMuted, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          zone.nameEn,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusBadge(status: zone.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, color: c.border),
            _ZoneMap(zone: zone),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${zone.healthScore}/100 health',
                    style: TextStyle(fontSize: 13, color: statusColor),
                  ),
                  const SizedBox(height: 16),
                  HealthBar(score: zone.healthScore),
                  const SizedBox(height: 20),
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
                    width: double.infinity,
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
                        _DetailRow(label: 'Area', value: '${zone.areaKm2.toStringAsFixed(0)} km²', c: c),
                        _DetailRow(label: 'Elevation', value: zone.elevation, c: c),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final JailooColors c;
  const _DetailRow({required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.textMuted)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.textPrimary)),
        ],
      ),
    );
  }
}

class _ZoneMap extends StatelessWidget {
  final Zone zone;
  const _ZoneMap({required this.zone});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final color = JailooColors.statusColor(zone.status);

    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png';

    return SizedBox(
      height: 180,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: zone.center,
          initialZoom: 9,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
            urlTemplate: tileUrl,
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.jailoo.app',
          ),
          PolygonLayer(
            polygons: [
              Polygon(
                points: zone.boundary,
                color: color.withValues(alpha: isDark ? 0.18 : 0.15),
                borderColor: color.withValues(alpha: 0.7),
                borderStrokeWidth: 2,
                isFilled: true,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: zone.center,
                width: 8,
                height: 8,
                child: Container(
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
