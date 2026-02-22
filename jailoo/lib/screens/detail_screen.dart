import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../theme/theme_provider.dart';
import '../widgets/health_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/data_card.dart';

class DetailScreen extends StatelessWidget {
  final Zone zone;
  final VoidCallback? onReport;
  const DetailScreen({super.key, required this.zone, this.onReport});

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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.textPrimary),
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
                              if (onReport != null) {
                                onReport!();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Reported: grazing at ${zone.nameEn}'),
                                    backgroundColor: c.surface,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      child: Text(
                        zone.status == 'banned' ? 'Zone banned' : "Report: I'm grazing here",
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

// ---------------------------------------------------------------------------
// Mini-map using MaplibreMap
// ---------------------------------------------------------------------------

class _ZoneMap extends StatefulWidget {
  final Zone zone;
  const _ZoneMap({required this.zone});

  @override
  State<_ZoneMap> createState() => _ZoneMapState();
}

class _ZoneMapState extends State<_ZoneMap> {
  MapLibreMapController? _ctrl;

  void _onMapCreated(MapLibreMapController controller) {
    _ctrl = controller;
  }

  Future<void> _onStyleLoaded() async {
    final ctrl = _ctrl;
    if (ctrl == null) return;

    final zone = widget.zone;
    final colorHex = JailooColors.statusColorHex(zone.status);

    final ring = [
      ...zone.boundary.map((p) => [p.longitude, p.latitude]),
      [zone.boundary.first.longitude, zone.boundary.first.latitude],
    ];
    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {'type': 'Polygon', 'coordinates': [ring]},
        }
      ],
    });

    await ctrl.addSource('zone', GeojsonSourceProperties(data: geojson));
    await ctrl.addFillLayer(
      'zone', 'zone-fill',
      FillLayerProperties(fillColor: colorHex, fillOpacity: 0.15),
    );
    await ctrl.addLineLayer(
      'zone', 'zone-border',
      LineLayerProperties(lineColor: colorHex, lineWidth: 2.0, lineCap: 'round', lineJoin: 'round'),
    );

    await ctrl.addCircle(CircleOptions(
      geometry: LatLng(zone.lat, zone.lng),
      circleRadius: 5,
      circleColor: colorHex,
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 1.5,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final styleUrl = isDark
        ? 'https://tiles.openfreemap.org/styles/liberty'
        : 'https://tiles.openfreemap.org/styles/bright';

    return SizedBox(
      height: 180,
      child: MapLibreMap(
        styleString: styleUrl,
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.zone.lat, widget.zone.lng),
          zoom: 9.0,
        ),
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        myLocationEnabled: false,
        compassEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
      ),
    );
  }
}
