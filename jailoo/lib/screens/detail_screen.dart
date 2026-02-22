import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../theme/theme_provider.dart';
import '../widgets/health_bar.dart';

class DetailScreen extends StatefulWidget {
  final Zone zone;
  final VoidCallback? onReport;
  const DetailScreen({super.key, required this.zone, this.onReport});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _tab = 0;

  static const _tabs = [
    (Icons.map_outlined, 'Overview'),
    (Icons.favorite_border, 'Health'),
    (Icons.pets_outlined, 'Livestock'),
    (Icons.near_me_outlined, 'Navigate'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final zone = widget.zone;
    final statusColor = JailooColors.statusColor(zone.status);
    final statusLabel = zone.status[0].toUpperCase() + zone.status.substring(1);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.nameEn,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                            height: 1.1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$statusLabel · ${zone.healthScore}/100 · ${zone.areaKm2.round()} km²',
                              style: TextStyle(fontSize: 13, color: c.textMuted),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.edit_outlined, size: 13, color: c.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20, color: c.textMuted),
                    style: IconButton.styleFrom(
                      backgroundColor: c.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(38, 38),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab icon bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final (icon, label) = _tabs[i];
                  final active = i == _tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _tab = i);
                        if (i == 3 && widget.onReport != null) {
                          widget.onReport!();
                        } else if (i == 3) {
                          Navigator.pop(context);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? c.accent.withValues(alpha: 0.10) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active ? c.accent.withValues(alpha: 0.35) : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 20, color: active ? c.accent : c.textMuted),
                            const SizedBox(height: 3),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                color: active ? c.accent : c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Divider(height: 1, color: c.border),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _OverviewTab(zone: zone, c: c, statusColor: statusColor),
                  _HealthTab(zone: zone, c: c, statusColor: statusColor),
                  _LivestockTab(zone: zone, c: c),
                  _NavigateTab(zone: zone, c: c, onNavigate: widget.onReport),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 — Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Zone zone;
  final JailooColors c;
  final Color statusColor;
  const _OverviewTab({required this.zone, required this.c, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ZoneMap(zone: zone),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _StatChip(label: 'Last grazed', value: '${zone.lastGrazedDaysAgo}d ago', c: c),
                const SizedBox(width: 8),
                _StatChip(label: 'Safe days', value: '${zone.safeDays} days', c: c),
                const SizedBox(width: 8),
                _StatChip(label: 'Elevation', value: zone.elevation, c: c, flex: 2),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zone details',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  _Row('Area', '${zone.areaKm2.toStringAsFixed(0)} km²', c),
                  _Row('Elevation', zone.elevation, c),
                  _Row('Max herd', '${zone.maxHerd} sheep equiv.', c),
                  Container(height: 1, color: c.border),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: statusColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(zone.seasonNote,
                            style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _Row(String label, String value, JailooColors c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: c.textMuted)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textPrimary)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Health
// ─────────────────────────────────────────────────────────────────────────────

class _HealthTab extends StatelessWidget {
  final Zone zone;
  final JailooColors c;
  final Color statusColor;
  const _HealthTab({required this.zone, required this.c, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        children: [
          // Score circle
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.09),
              border: Border.all(color: statusColor.withValues(alpha: 0.40), width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${zone.healthScore}',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: statusColor, height: 1),
                ),
                Text('/100', style: TextStyle(fontSize: 11, color: c.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Pasture Health Score',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 4),
          Text(
            zone.status == 'healthy'
                ? 'Zone is in good condition'
                : zone.status == 'recovering'
                    ? 'Zone is recovering — limited grazing'
                    : 'Zone is banned — no grazing allowed',
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
          const SizedBox(height: 24),
          HealthBar(score: zone.healthScore),
          const SizedBox(height: 20),
          _MetricRow('Last grazed', '${zone.lastGrazedDaysAgo} days ago', Icons.schedule, statusColor, c),
          const SizedBox(height: 10),
          _MetricRow('Safe grazing days', '${zone.safeDays} days remaining', Icons.check_circle_outline, statusColor, c),
          const SizedBox(height: 10),
          _MetricRow('Seasonal note', zone.seasonNote, Icons.eco_outlined, statusColor, c),
        ],
      ),
    );
  }

  Widget _MetricRow(String label, String value, IconData icon, Color color, JailooColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: c.textMuted)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Livestock
// ─────────────────────────────────────────────────────────────────────────────

class _LivestockTab extends StatelessWidget {
  final Zone zone;
  final JailooColors c;
  const _LivestockTab({required this.zone, required this.c});

  @override
  Widget build(BuildContext context) {
    final sc = JailooColors.statusColor(zone.status);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sc.withValues(alpha: 0.20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stocking Capacity',
                    style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${zone.maxHerd}',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: sc, height: 1)),
                    const SizedBox(width: 6),
                    Text('sheep equiv.', style: TextStyle(fontSize: 13, color: c.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _AnimalRow('Sheep', '${zone.maxHerd}', 'head', Icons.water_outlined, c),
          const SizedBox(height: 8),
          _AnimalRow('Horses', '${(zone.maxHerd / 6).round()}', 'head (×6 equiv)', Icons.directions_walk, c),
          const SizedBox(height: 8),
          _AnimalRow('Cattle', '${(zone.maxHerd / 7).round()}', 'head (×7 equiv)', Icons.adjust, c),
          const SizedBox(height: 8),
          _AnimalRow('Goats', '${(zone.maxHerd / 0.8).round()}', 'head (×0.8)', Icons.grass_outlined, c),
        ],
      ),
    );
  }

  Widget _AnimalRow(String animal, String value, String unit, IconData icon, JailooColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.textMuted),
          const SizedBox(width: 12),
          Text(animal, style: TextStyle(fontSize: 13, color: c.textPrimary)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(width: 4),
          Text(unit, style: TextStyle(fontSize: 11, color: c.textMuted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Navigate
// ─────────────────────────────────────────────────────────────────────────────

class _NavigateTab extends StatelessWidget {
  final Zone zone;
  final JailooColors c;
  final VoidCallback? onNavigate;
  const _NavigateTab({required this.zone, required this.c, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final statusColor = JailooColors.statusColor(zone.status);
    final banned = zone.status == 'banned';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 28, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (banned ? c.surface2 : c.accent).withValues(alpha: 0.10),
                border: Border.all(
                  color: (banned ? c.surface2 : c.accent).withValues(alpha: 0.30), width: 2,
                ),
              ),
              child: Icon(Icons.near_me_outlined, size: 44, color: banned ? c.textMuted : c.accent),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            banned ? 'Navigation disabled' : 'Navigate to ${zone.nameEn}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: banned ? c.textMuted : c.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            banned
                ? 'This zone is banned. No grazing or navigation allowed.'
                : 'Get directions from your current location to this pasture.',
            style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.grass_outlined, size: 20, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone.nameEn,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
                      Text('${zone.areaKm2.round()} km² · ${zone.elevation}',
                          style: TextStyle(fontSize: 11, color: c.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: banned ? c.surface2 : c.accent,
                foregroundColor: banned ? c.textMuted : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: banned
                  ? null
                  : () {
                      if (onNavigate != null) {
                        onNavigate!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
              icon: Icon(banned ? Icons.block : Icons.near_me_outlined, size: 18),
              label: Text(
                banned ? 'Zone banned — no access' : 'Start route',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final JailooColors c;
  final int flex;
  const _StatChip({required this.label, required this.value, required this.c, this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: c.textMuted, letterSpacing: 0.3)),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini-map
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneMap extends StatefulWidget {
  final Zone zone;
  const _ZoneMap({required this.zone});

  @override
  State<_ZoneMap> createState() => _ZoneMapState();
}

class _ZoneMapState extends State<_ZoneMap> {
  MapLibreMapController? _ctrl;

  void _onMapCreated(MapLibreMapController controller) => _ctrl = controller;

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
      'features': [{
        'type': 'Feature',
        'properties': {},
        'geometry': {'type': 'Polygon', 'coordinates': [ring]},
      }],
    });

    await ctrl.addSource('zone', GeojsonSourceProperties(data: geojson));
    await ctrl.addFillLayer('zone', 'zone-fill',
        FillLayerProperties(fillColor: colorHex, fillOpacity: 0.20));
    await ctrl.addLineLayer('zone', 'zone-border',
        LineLayerProperties(lineColor: colorHex, lineWidth: 2.5, lineCap: 'round', lineJoin: 'round'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final styleUrl = isDark
        ? 'https://tiles.openfreemap.org/styles/liberty'
        : 'https://tiles.openfreemap.org/styles/bright';

    return SizedBox(
      height: 200,
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
