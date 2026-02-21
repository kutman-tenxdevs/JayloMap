import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../widgets/health_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/data_card.dart';

class DetailScreen extends StatelessWidget {
  final Zone zone;
  const DetailScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final statusColor = JailooColors.statusColor(zone.status);

    return Scaffold(
      backgroundColor: JailooColors.bg,
      appBar: AppBar(
        backgroundColor: JailooColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: JailooColors.textMuted, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          zone.nameEn,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: JailooColors.textPrimary,
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
            const Divider(height: 1, color: JailooColors.border),

            _ZoneMap(zone: zone),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: JailooColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${zone.healthScore}/100 health',
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  HealthBar(score: zone.healthScore),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: DataCard(
                          label: 'Health',
                          value: '${zone.healthScore}',
                          unit: '/100',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DataCard(
                          label: 'Max herd',
                          value: '${zone.maxHerd}',
                          unit: 'sheep',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DataCard(
                          label: 'Last grazed',
                          value: '${zone.lastGrazedDaysAgo}',
                          unit: 'days ago',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DataCard(
                          label: 'Safe days',
                          value: '${zone.safeDays}',
                          unit: 'days',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: zone.status == 'banned'
                            ? JailooColors.surface2
                            : JailooColors.accent,
                        foregroundColor: zone.status == 'banned'
                            ? JailooColors.textMuted
                            : JailooColors.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: zone.status == 'banned'
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Reported: grazing at ${zone.nameEn}'),
                                  backgroundColor: JailooColors.surface,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      child: Text(
                        zone.status == 'banned' ? 'Zone banned' : 'Report: I\'m grazing here',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
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

class _ZoneMap extends StatelessWidget {
  final Zone zone;
  const _ZoneMap({required this.zone});

  @override
  Widget build(BuildContext context) {
    final color = JailooColors.statusColor(zone.status);

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
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.jailoo.app',
          ),
          PolygonLayer(
            polygons: [
              Polygon(
                points: zone.boundary,
                color: color.withValues(alpha: 0.2),
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
                width: 10,
                height: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
