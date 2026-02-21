import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/zone.dart';
import '../widgets/health_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/data_card.dart';

class DetailScreen extends StatelessWidget {
  final Zone zone;
  const DetailScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111811),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111811),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2ECC71), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          zone.nameEn.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 18,
            color: Color(0xFF7A9A7A),
            letterSpacing: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini map
            _MiniMap(zone: zone),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zone name
                  Text(
                    zone.name,
                    style: const TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 36,
                      color: Color(0xFFE8F5E8),
                      letterSpacing: 2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  StatusBadge(status: zone.status),
                  const SizedBox(height: 20),

                  // Data cards grid
                  Row(
                    children: [
                      Expanded(child: DataCard(label: 'ЗДОРОВЬЕ', value: '${zone.healthScore}', unit: '/100')),
                      const SizedBox(width: 10),
                      Expanded(child: DataCard(label: 'МАКС СТАДО', value: '${zone.maxHerd}', unit: 'овец')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: DataCard(label: 'ПОСЛ. ВЫПАС', value: '${zone.lastGrazedDaysAgo}', unit: 'дней назад')),
                      const SizedBox(width: 10),
                      Expanded(child: DataCard(label: 'БЕЗОП. ДНЕЙ', value: '${zone.safeDays}', unit: 'дней')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Health bar
                  const Text(
                    'СОСТОЯНИЕ ПАСТБИЩА',
                    style: TextStyle(
                      fontFamily: 'DMMono',
                      fontSize: 10,
                      color: Color(0xFF7A9A7A),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  HealthBar(score: zone.healthScore),
                  const SizedBox(height: 28),

                  // Report button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: const Color(0xFF0A0F0A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: zone.status == 'banned'
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Зарегистрировано: ${zone.name}'),
                                  backgroundColor: const Color(0xFF1a2a1a),
                                ),
                              );
                            },
                      child: const Text(
                        '✓  Сообщить: я здесь пасу',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.5,
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

class _MiniMap extends StatelessWidget {
  final Zone zone;
  const _MiniMap({required this.zone});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(zone.lat, zone.lng),
          initialZoom: 10,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.jailoo.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(zone.lat, zone.lng),
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor(zone.status),
                    boxShadow: [BoxShadow(color: _statusColor(zone.status).withValues(alpha: 0.7), blurRadius: 12)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'healthy':    return const Color(0xFF2ECC71);
      case 'recovering': return const Color(0xFFF4D03F);
      case 'banned':     return const Color(0xFFE74C3C);
      default:           return Colors.grey;
    }
  }
}
