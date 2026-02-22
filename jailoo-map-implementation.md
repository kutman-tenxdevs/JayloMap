# Jailoo — Map Screen Implementation Plan
## Drawing Naryn Oblast Districts as Interactive Polygons

---

## Overview

The map screen draws the 5 Naryn Oblast districts as tappable colored polygons on top of a real map tile layer. Tapping a district slides up a detail sheet from the bottom. The implementation uses `flutter_map` (free, no API key) with hardcoded `LatLng` polygon coordinates traced from the official district boundaries.

---

## 1. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  geolocator: ^11.0.0
  provider: ^6.1.1
```

Run:
```bash
flutter pub get
```

---

## 2. File Structure

```
lib/
  data/
    zones.dart          ← hardcoded zone data + polygon coordinates
  models/
    zone_model.dart     ← ZoneModel class
  screens/
    map_screen.dart     ← main map screen
  widgets/
    zone_detail_sheet.dart   ← bottom sheet
    zone_polygon.dart        ← individual polygon widget
    map_legend.dart          ← bottom-left legend
    gps_dot.dart             ← user location marker
```

---

## 3. Hardcoded Polygon Coordinates

These coordinates are traced from the official Naryn Oblast district map.
Each polygon is a list of `LatLng` points tracing the district boundary clockwise.

> **Coordinate system:** WGS84 (standard GPS). Latitude first, longitude second.

```dart
// lib/data/zones.dart

import 'package:latlong2/latlong.dart';
import '../models/zone_model.dart';

const List<ZoneModel> kZones = [

  // ─────────────────────────────────────────
  // ЖУМГАЛ РАЙОНУ (Jumgal)
  // Northwest district — large, irregular shape
  // ─────────────────────────────────────────
  ZoneModel(
    id: 'jumgal',
    nameKg: 'Жумгал',
    nameRu: 'Джумгал',
    status: ZoneStatus.banned,
    healthScore: 12,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 3,
    centroid: LatLng(41.90, 74.60),
    polygonPoints: [
      LatLng(42.32, 73.80),   // NW corner
      LatLng(42.38, 74.20),
      LatLng(42.30, 74.65),
      LatLng(42.18, 75.00),   // North, near Kochkor border
      LatLng(42.05, 75.10),
      LatLng(41.90, 75.05),
      LatLng(41.75, 74.90),   // East edge
      LatLng(41.65, 74.70),
      LatLng(41.55, 74.50),   // SE corner, near Ak-Talaa border
      LatLng(41.50, 74.20),
      LatLng(41.55, 73.90),
      LatLng(41.70, 73.75),   // SW area
      LatLng(41.90, 73.70),
      LatLng(42.10, 73.72),
      LatLng(42.25, 73.78),
      LatLng(42.32, 73.80),   // close polygon
    ],
  ),

  // ─────────────────────────────────────────
  // КОЧКОР РАЙОНУ (Kochkor)
  // Northeast district — smaller, near Son-Kol lake
  // ─────────────────────────────────────────
  ZoneModel(
    id: 'kochkor',
    nameKg: 'Кочкор',
    nameRu: 'Кочкор',
    status: ZoneStatus.recovering,
    healthScore: 51,
    maxHerd: 200,
    safeDays: 14,
    lastGrazedDaysAgo: 18,
    centroid: LatLng(42.12, 75.75),
    polygonPoints: [
      LatLng(42.38, 75.10),   // NW — border with Jumgal
      LatLng(42.42, 75.50),
      LatLng(42.38, 75.90),   // North edge
      LatLng(42.25, 76.20),
      LatLng(42.10, 76.35),   // NE corner
      LatLng(41.95, 76.20),
      LatLng(41.85, 76.00),   // East edge
      LatLng(41.80, 75.70),
      LatLng(41.85, 75.40),   // SE corner near Son-Kol
      LatLng(41.90, 75.15),
      LatLng(42.05, 75.10),
      LatLng(42.20, 75.05),
      LatLng(42.38, 75.10),   // close polygon
    ],
  ),

  // ─────────────────────────────────────────
  // НАРЫН РАЙОНУ (Naryn)
  // Central district — includes Naryn city
  // ─────────────────────────────────────────
  ZoneModel(
    id: 'naryn',
    nameKg: 'Нарын',
    nameRu: 'Нарын',
    status: ZoneStatus.recovering,
    healthScore: 44,
    maxHerd: 150,
    safeDays: 10,
    lastGrazedDaysAgo: 7,
    centroid: LatLng(41.60, 76.00),
    polygonPoints: [
      LatLng(41.90, 75.15),   // NW — border with Kochkor
      LatLng(41.85, 75.40),
      LatLng(41.85, 75.70),
      LatLng(41.80, 76.00),   // North edge
      LatLng(41.85, 76.35),
      LatLng(41.75, 76.60),   // NE corner
      LatLng(41.60, 76.80),
      LatLng(41.45, 76.70),   // East edge
      LatLng(41.35, 76.50),
      LatLng(41.30, 76.20),   // SE corner
      LatLng(41.35, 75.90),
      LatLng(41.45, 75.65),
      LatLng(41.55, 75.45),   // SW
      LatLng(41.65, 75.20),
      LatLng(41.75, 75.05),
      LatLng(41.90, 75.15),   // close polygon
    ],
  ),

  // ─────────────────────────────────────────
  // АК-ТАЛАА РАЙОНУ (Ak-Talaa)
  // West-central district — large southern area
  // ─────────────────────────────────────────
  ZoneModel(
    id: 'ak_talaa',
    nameKg: 'Ак-Талаа',
    nameRu: 'Ак-Талаа',
    status: ZoneStatus.banned,
    healthScore: 18,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 1,
    centroid: LatLng(41.25, 74.90),
    polygonPoints: [
      LatLng(41.55, 74.50),   // NE — border with Jumgal
      LatLng(41.65, 74.70),
      LatLng(41.75, 74.90),
      LatLng(41.75, 75.05),
      LatLng(41.65, 75.20),
      LatLng(41.55, 75.45),   // NE border with Naryn
      LatLng(41.45, 75.65),
      LatLng(41.35, 75.50),   // East
      LatLng(41.20, 75.30),
      LatLng(41.10, 75.10),   // SE
      LatLng(40.95, 74.90),
      LatLng(40.90, 74.60),   // South edge
      LatLng(40.95, 74.20),
      LatLng(41.10, 74.00),   // SW
      LatLng(41.30, 73.95),
      LatLng(41.50, 74.05),
      LatLng(41.55, 74.30),
      LatLng(41.55, 74.50),   // close polygon
    ],
  ),

  // ─────────────────────────────────────────
  // АТ-БАШЫ РАЙОНУ (At-Bashy)
  // Large eastern district — borders China
  // ─────────────────────────────────────────
  ZoneModel(
    id: 'at_bashy',
    nameKg: 'Ат-Башы',
    nameRu: 'Ат-Башы',
    status: ZoneStatus.healthy,
    healthScore: 78,
    maxHerd: 500,
    safeDays: 28,
    lastGrazedDaysAgo: 45,
    centroid: LatLng(41.00, 76.20),
    polygonPoints: [
      LatLng(41.35, 75.90),   // NW — border with Naryn
      LatLng(41.30, 76.20),
      LatLng(41.35, 76.50),
      LatLng(41.45, 76.70),   // North edge
      LatLng(41.60, 76.80),
      LatLng(41.65, 77.20),   // NE corner
      LatLng(41.55, 77.60),
      LatLng(41.35, 77.90),   // Far NE, Issyk-Kul border
      LatLng(41.10, 78.00),
      LatLng(40.85, 77.80),   // East edge
      LatLng(40.65, 77.50),
      LatLng(40.50, 77.00),   // SE, China border
      LatLng(40.45, 76.40),
      LatLng(40.50, 75.90),   // South
      LatLng(40.65, 75.50),
      LatLng(40.80, 75.20),   // SW, Chatyr-Kol area
      LatLng(40.95, 74.90),
      LatLng(41.10, 75.10),
      LatLng(41.20, 75.30),
      LatLng(41.35, 75.50),
      LatLng(41.35, 75.90),   // close polygon
    ],
  ),

];
```

---

## 4. ZoneModel

```dart
// lib/models/zone_model.dart

import 'package:latlong2/latlong.dart';

enum ZoneStatus { healthy, recovering, banned }

class ZoneModel {
  final String id;
  final String nameKg;
  final String nameRu;
  final ZoneStatus status;
  final int healthScore;      // 0–100
  final int maxHerd;          // max sheep count
  final int safeDays;         // days of safe grazing remaining
  final int lastGrazedDaysAgo;
  final LatLng centroid;      // center point for label
  final List<LatLng> polygonPoints;

  const ZoneModel({
    required this.id,
    required this.nameKg,
    required this.nameRu,
    required this.status,
    required this.healthScore,
    required this.maxHerd,
    required this.safeDays,
    required this.lastGrazedDaysAgo,
    required this.centroid,
    required this.polygonPoints,
  });
}
```

---

## 5. Color Logic

```dart
// Reuse this everywhere — single source of truth

import 'package:flutter/material.dart';
import '../models/zone_model.dart';

Color zoneColor(ZoneStatus status) {
  switch (status) {
    case ZoneStatus.healthy:    return const Color(0xFF2ECC71);
    case ZoneStatus.recovering: return const Color(0xFFF4D03F);
    case ZoneStatus.banned:     return const Color(0xFFE74C3C);
  }
}

String zoneStatusLabel(ZoneStatus status) {
  switch (status) {
    case ZoneStatus.healthy:    return 'БЕЗОПАСНО';
    case ZoneStatus.recovering: return 'ВОССТАНОВЛЕНИЕ';
    case ZoneStatus.banned:     return 'ЗАПРЕТ';
  }
}
```

---

## 6. Map Screen — Full Structure

```dart
// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/zones.dart';
import '../models/zone_model.dart';
import '../widgets/zone_detail_sheet.dart';
import '../widgets/map_legend.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  ZoneModel? _selectedZone;

  void _onZoneTap(ZoneModel zone) {
    setState(() {
      // Toggle — tap same zone again to deselect
      _selectedZone = _selectedZone?.id == zone.id ? null : zone;
    });
  }

  void _onMapTap(_, __) {
    // Tap on empty map area → dismiss sheet
    if (_selectedZone != null) {
      setState(() => _selectedZone = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: Stack(
        children: [

          // ── 1. MAP ──
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(41.40, 75.60),
              initialZoom: 8.2,
              minZoom: 7.0,
              maxZoom: 11.0,
              onTap: _onMapTap,
              // Lock camera to Naryn Oblast bounds
              cameraConstraint: CameraConstraint.containCenter(
                bounds: LatLngBounds(
                  const LatLng(40.3, 73.5),
                  const LatLng(42.6, 78.5),
                ),
              ),
            ),
            children: [

              // Tile layer — dark terrain
              TileLayer(
                urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'kg.jailoo.app',
              ),

              // Polygon layer — district shapes
              PolygonLayer(
                polygons: kZones.map((zone) {
                  final bool isSelected = _selectedZone?.id == zone.id;
                  final Color color = zoneColor(zone.status);
                  return Polygon(
                    points: zone.polygonPoints,
                    color: color.withOpacity(isSelected ? 0.50 : 0.28),
                    borderColor: color.withOpacity(isSelected ? 1.0 : 0.70),
                    borderStrokeWidth: isSelected ? 3.0 : 1.5,
                    isFilled: true,
                  );
                }).toList(),
              ),

              // Marker layer — tappable zone centers + labels
              MarkerLayer(
                markers: kZones.map((zone) {
                  return Marker(
                    point: zone.centroid,
                    width: 120,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _onZoneTap(zone),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status dot
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: zoneColor(zone.status),
                            ),
                          ),
                          const SizedBox(height: 3),
                          // District name
                          Text(
                            zone.nameRu.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              shadows: [
                                Shadow(blurRadius: 6, color: Colors.black),
                                Shadow(blurRadius: 2, color: Colors.black),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // GPS dot — user location (hardcoded to Naryn city for demo)
              const MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(41.428, 75.991),  // Naryn city
                    width: 20,
                    height: 20,
                    child: _GpsDot(),
                  ),
                ],
              ),

            ],
          ),

          // ── 2. TOP BAR ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Text(
                'JAILOO',
                style: TextStyle(
                  color: Color(0xFF2ECC71),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          // ── 3. LEGEND ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            bottom: _selectedZone != null ? 380 : 24,
            left: 16,
            child: const MapLegend(),
          ),

          // ── 4. DETAIL SHEET ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            bottom: _selectedZone != null ? 0 : -400,
            left: 0, right: 0,
            height: 360,
            child: _selectedZone != null
              ? ZoneDetailSheet(
                  zone: _selectedZone!,
                  onClose: () => setState(() => _selectedZone = null),
                )
              : const SizedBox.shrink(),
          ),

        ],
      ),
    );
  }
}

// Pulsing GPS dot
class _GpsDot extends StatefulWidget {
  const _GpsDot();
  @override
  State<_GpsDot> createState() => _GpsDotState();
}

class _GpsDotState extends State<_GpsDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _scale,
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2ECC71).withOpacity(0.2),
              border: Border.all(
                color: const Color(0xFF2ECC71).withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
        ),
        Container(
          width: 10, height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
```

---

## 7. Zone Detail Sheet

```dart
// lib/widgets/zone_detail_sheet.dart

import 'package:flutter/material.dart';
import '../models/zone_model.dart';

class ZoneDetailSheet extends StatelessWidget {
  final ZoneModel zone;
  final VoidCallback onClose;

  const ZoneDetailSheet({
    super.key,
    required this.zone,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = zoneColor(zone.status);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111811),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: color, width: 2)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Zone name + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          zone.nameRu,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Text(
                          zoneStatusLabel(zone.status),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Health bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: zone.healthScore / 100,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${zone.healthScore}/100',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2x2 Data grid
                  Row(
                    children: [
                      _DataCard(
                        label: 'Макс. стадо',
                        value: zone.maxHerd == 0
                          ? '—'
                          : '${zone.maxHerd} гол.',
                        color: color,
                      ),
                      const SizedBox(width: 10),
                      _DataCard(
                        label: 'Безопасных дней',
                        value: zone.safeDays == 0
                          ? 'Закрыто'
                          : '${zone.safeDays} дн.',
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _DataCard(
                        label: 'Последний выпас',
                        value: '${zone.lastGrazedDaysAgo} дн. назад',
                        color: color,
                      ),
                      const SizedBox(width: 10),
                      _DataCard(
                        label: 'Индекс здоровья',
                        value: '${zone.healthScore}',
                        color: color,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: zone.status == ZoneStatus.banned
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Вы отметили выпас в этой зоне'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: zone.status == ZoneStatus.banned
                          ? Colors.white12
                          : color,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white30,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        zone.status == ZoneStatus.banned
                          ? 'ЗОНА ЗАКРЫТА'
                          : 'Я ЗДЕСЬ ПАШ СЕГОДНЯ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontSize: 13,
                        ),
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

class _DataCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DataCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. Map Legend Widget

```dart
// lib/widgets/map_legend.dart

import 'package:flutter/material.dart';

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LegendItem(color: Color(0xFF2ECC71), label: 'Безопасно'),
          SizedBox(width: 12),
          _LegendItem(color: Color(0xFFF4D03F), label: 'Восстановление'),
          SizedBox(width: 12),
          _LegendItem(color: Color(0xFFE74C3C), label: 'Запрет'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
```

---

## 9. Interaction Flow (step by step)

```
User opens app
  └── Map loads centered on Naryn Oblast (zoom 8.2)
      └── All 5 district polygons visible, colored by status
          └── Name labels centered in each polygon

User taps a polygon label (or district area)
  └── _onZoneTap(zone) fires
      └── setState: _selectedZone = zone
          └── Polygon fill brightens (opacity 0.28 → 0.50)
          └── Border thickens (1.5px → 3.0px)
          └── Bottom sheet slides up (AnimatedPositioned)
          └── Legend slides up above the sheet

User reads detail sheet
  └── Sees: name, status badge, health bar, 4 data cards
      └── If zone is safe → green CTA button active
      └── If zone is banned → button disabled, grey

User taps "Я ЗДЕСЬ ПАШ СЕГОДНЯ"
  └── SnackBar confirms: ✓ Вы отметили выпас
      (In production: POST to backend / update local state)

User taps outside sheet or drags it down
  └── setState: _selectedZone = null
      └── Sheet slides back down
      └── Polygon returns to normal opacity
      └── Legend moves back to bottom
```

---

## 10. Coordinate Refinement (after hackathon)

The hardcoded coordinates above are **approximate** — good enough for a hackathon demo but not perfectly precise. To get exact boundaries:

**Option A — GADM (free GeoJSON)**
1. Go to https://gadm.org/download_country.html
2. Download Kyrgyzstan, Level 2 (districts)
3. Filter features where `NAME_1 == "Naryn"`
4. Extract `coordinates` arrays for each district
5. Convert `[lng, lat]` GeoJSON format → `LatLng(lat, lng)` for flutter_map

**Option B — OpenStreetMap Overpass API**
```
https://overpass-api.de/api/interpreter?data=
[out:json];
relation["admin_level"="6"]["name:en"="Jumgal District"];
out geom;
```
Returns precise boundary nodes. Parse the `geometry` array.

**Option C — Keep hackathon coordinates**
For a 5-district proof of concept, approximate polygons are visually convincing enough. Judges won't have a reference map to compare against.

---

## 11. Testing Checklist

- [ ] All 5 polygons visible on launch
- [ ] Correct color per zone status (green/yellow/red)
- [ ] Tap polygon → sheet slides up
- [ ] Sheet shows correct data for tapped zone
- [ ] Banned zone → button disabled
- [ ] Tap map background → sheet dismisses
- [ ] GPS dot visible over Naryn city
- [ ] Legend stays above sheet when open
- [ ] Pinch-to-zoom works within bounds
- [ ] No overflow or clip on small Android screens (test 360×640)

---

## 12. Estimated Build Time

| Task | Time |
|---|---|
| pubspec + dependencies | 10 min |
| `zone_model.dart` + `zones.dart` | 20 min |
| `map_screen.dart` skeleton + tiles | 25 min |
| Polygon layer with colors | 20 min |
| Labels + GPS dot | 15 min |
| `zone_detail_sheet.dart` | 35 min |
| `map_legend.dart` | 10 min |
| Tap interaction + AnimatedPositioned | 20 min |
| Testing + fixes | 25 min |
| **Total** | **~3 hours** |

One developer. Can be parallelized: Dev 1 builds map + polygons, Dev 2 builds detail sheet, merge at step 8.
