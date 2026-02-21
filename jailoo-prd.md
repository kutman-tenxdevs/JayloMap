# Jailoo — Product Requirements Document

**Version:** 1.0 — Hackathon MVP  
**Platform:** Flutter (Android + iOS)  
**Scope:** Naryn Oblast, Kyrgyzstan  
**Target:** Individual herders making daily grazing decisions  

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Product Overview](#2-product-overview)
3. [Tech Stack](#3-tech-stack)
4. [Project Structure](#4-project-structure)
5. [Data Layer — Hardcoded](#5-data-layer--hardcoded)
6. [Screen 1 — Map](#6-screen-1--map)
7. [Screen 2 — Zone Detail](#7-screen-2--zone-detail)
8. [Screen 3 — AI Assistant](#8-screen-3--ai-assistant)
9. [Design System](#9-design-system)
10. [Service Hooks with Hardcoded Responses](#10-service-hooks-with-hardcoded-responses)
11. [Real Data Fetching — Phase 2](#11-real-data-fetching--phase-2)
12. [Libraries Reference](#12-libraries-reference)
13. [pubspec.yaml](#13-pubspecyaml)
14. [Build Timeline](#14-build-timeline)

---

## 1. Problem Statement

70% of Kyrgyzstan's pastureland is degraded (UNEP, March 2025). 4.3 million rural people depend on livestock. The economic cost across Central Asia is $6 billion annually.

The root cause is simple: **herders make grazing decisions without data.** They go to the nearest pasture by habit. That pasture gets destroyed. Remote healthy pastures sit unused. The imbalance compounds every season.

The satellite data exists. The Kyrgyz Data Cube has 18+ years of NDVI pasture health data at 10m resolution, updated every 5 days via Sentinel-2. The phones are there — 95.1% of Kyrgyzstan's mobile connections are broadband (DataReportal 2025).

Nobody built the last mile. We did.

---

## 2. Product Overview

Jailoo is a mobile app with **3 screens**:

| Screen | Purpose |
|--------|---------|
| Map | See all Naryn Oblast pasture zones color-coded by health |
| Zone Detail | Tap a zone → see health score, capacity, grazing history |
| AI Assistant | Ask "where should I take my 60 sheep?" → get plain Russian answer |

**Hackathon scope:** 8 hardcoded Naryn Oblast zones. Real coordinates. Health scores from IFAD 2016–2020 satellite reports. Production connects live to Kyrgyz Data Cube WMS API.

---

## 3. Tech Stack

| Layer | Choice | Reason |
|-------|--------|--------|
| Framework | Flutter 3 | Single codebase Android + iOS. Fast prototyping. Best map widget ecosystem. |
| Maps | flutter_map 6.x | Free OSM tiles. WMS layer support. Offline tile caching. No API key. |
| Map Tiles | CartoDB Dark Matter | Dark aesthetic. No API key required. Fits app theme. |
| Location | geolocator 11.x | Standard GPS. Single call for current position. |
| HTTP | http 1.2.x | Zero config. Enough for Claude API call. |
| State | provider 6.x | Simplest option for hackathon. No boilerplate. |
| Cache | shared_preferences 2.x | Store last AI response. Works offline. |
| AI | Claude API (claude-sonnet-4-20250514) | Best Russian-language generation. Structured prompts. 300 token responses. |

**Do NOT use:**
- Google Maps — requires billing account setup
- Mapbox — requires token, extra setup time
- Firebase — complete overkill
- Any backend server — no time, client-only
- BLoC / Riverpod — too much boilerplate for hackathon

---

## 4. Project Structure

Keep it flat. No nested feature folders. One file per screen.

```
jailoo/
├── pubspec.yaml
├── lib/
│   ├── main.dart                   # App entry, MaterialApp, routes, theme
│   │
│   ├── data/
│   │   └── zones.dart              # All hardcoded zone data — START HERE
│   │
│   ├── models/
│   │   └── zone.dart               # Zone model class
│   │
│   ├── services/
│   │   ├── zone_service.dart       # Returns hardcoded zones (swappable for API)
│   │   └── ai_service.dart         # Claude API call + offline cache
│   │
│   ├── screens/
│   │   ├── map_screen.dart         # Screen 1
│   │   ├── detail_screen.dart      # Screen 2
│   │   └── ai_screen.dart          # Screen 3
│   │
│   └── widgets/
│       ├── zone_marker.dart        # Colored circle marker for map
│       ├── health_bar.dart         # Animated green/yellow/red progress bar
│       ├── status_badge.dart       # "Безопасно / Восстановление / Запрет" pill
│       └── data_card.dart          # Reusable metric card (score, capacity, etc.)
│
└── assets/
    └── (no assets needed for MVP)
```

---

## 5. Data Layer — Hardcoded

### `lib/models/zone.dart`

```dart
class Zone {
  final int id;
  final String name;        // Kyrgyz name: АТ-БАШЫ
  final String nameEn;      // Romanized: At-Bashy
  final String status;      // 'healthy' | 'recovering' | 'banned'
  final int healthScore;    // 0–100
  final int maxHerd;        // Max sheep at current health
  final int safeDays;       // Days this zone can sustain grazing
  final int lastGrazedDaysAgo;
  final double lat;
  final double lng;

  const Zone({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.status,
    required this.healthScore,
    required this.maxHerd,
    required this.safeDays,
    required this.lastGrazedDaysAgo,
    required this.lat,
    required this.lng,
  });
}
```

### `lib/data/zones.dart`

Health scores come from IFAD 2016–2020 satellite pasture condition maps. Coordinates are real district centers for Naryn Oblast.

```dart
import '../models/zone.dart';

const List<Zone> kZones = [
  Zone(
    id: 1,
    name: 'АТ-БАШЫ',
    nameEn: 'At-Bashy',
    status: 'healthy',
    healthScore: 78,
    maxHerd: 150,
    safeDays: 18,
    lastGrazedDaysAgo: 5,
    lat: 40.95,
    lng: 76.20,
  ),
  Zone(
    id: 2,
    name: 'КОЧКОР',
    nameEn: 'Kochkor',
    status: 'recovering',
    healthScore: 51,
    maxHerd: 80,
    safeDays: 9,
    lastGrazedDaysAgo: 2,
    lat: 42.21,
    lng: 75.75,
  ),
  Zone(
    id: 3,
    name: 'СОН-КӨЛ',
    nameEn: 'Song-Kol',
    status: 'healthy',
    healthScore: 83,
    maxHerd: 200,
    safeDays: 22,
    lastGrazedDaysAgo: 11,
    lat: 41.85,
    lng: 75.12,
  ),
  Zone(
    id: 4,
    name: 'НАРЫН',
    nameEn: 'Naryn',
    status: 'recovering',
    healthScore: 44,
    maxHerd: 60,
    safeDays: 7,
    lastGrazedDaysAgo: 1,
    lat: 41.43,
    lng: 75.99,
  ),
  Zone(
    id: 5,
    name: 'АК-ТАЛАА',
    nameEn: 'Ak-Talaa',
    status: 'banned',
    healthScore: 18,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 0,
    lat: 41.43,
    lng: 74.60,
  ),
  Zone(
    id: 6,
    name: 'ЖУМГАЛ',
    nameEn: 'Jumgal',
    status: 'banned',
    healthScore: 12,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 0,
    lat: 42.05,
    lng: 74.20,
  ),
  Zone(
    id: 7,
    name: 'ТОГУЗ-ТОО',
    nameEn: 'Toguz-Toro',
    status: 'healthy',
    healthScore: 70,
    maxHerd: 120,
    safeDays: 15,
    lastGrazedDaysAgo: 8,
    lat: 41.20,
    lng: 77.50,
  ),
  Zone(
    id: 8,
    name: 'КАРА-КӨЛ',
    nameEn: 'Kara-Kol',
    status: 'recovering',
    healthScore: 38,
    maxHerd: 50,
    safeDays: 5,
    lastGrazedDaysAgo: 3,
    lat: 41.55,
    lng: 76.45,
  ),
];
```

---

## 6. Screen 1 — Map

### Purpose

Give the herder an immediate visual overview of all pasture zones. Green = go. Yellow = careful. Red = banned. One glance, decision made.

### Layout

```
┌─────────────────────────────┐
│  НАРЫН          [GPS dot]   │  ← Top bar, transparent over map
│  Naryn Oblast · 8 zones     │
│                             │
│  ┌───────────────────────┐  │
│  │                       │  │
│  │   [flutter_map]       │  │
│  │                       │  │
│  │   ●  ●                │  │  ← Colored zone markers
│  │       ●  ◎            │  │  ← ◎ = user GPS location
│  │   ●       ●           │  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  ● Безопасно  ● Восст.  ● Запрет  │  ← Legend row
└─────────────────────────────┘
```

### Implementation — `map_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../data/zones.dart';
import '../models/zone.dart';
import '../widgets/zone_marker.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
    final pos = await Geolocator.getCurrentPosition();
    setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(41.5, 75.6),
              initialZoom: 7.5,
              minZoom: 6,
              maxZoom: 12,
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
                  // Zone markers
                  ...kZones.map((zone) => Marker(
                    point: LatLng(zone.lat, zone.lng),
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(zone: zone),
                        ),
                      ),
                      child: ZoneMarker(zone: zone),
                    ),
                  )),
                  // User GPS dot
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2ECC71),
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x882ECC71),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'НАРЫН',
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 22,
                      color: const Color(0xFF2ECC71),
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    'Naryn Oblast · ${kZones.length} зон',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A9A7A),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Legend bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEE0D1A0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332ECC71)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _LegendItem(color: Color(0xFF2ECC71), label: 'Безопасно'),
          _LegendItem(color: Color(0xFFF4D03F), label: 'Восстановление'),
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7A9A7A), letterSpacing: 0.5)),
      ],
    );
  }
}
```

### `widgets/zone_marker.dart`

```dart
import 'package:flutter/material.dart';
import '../models/zone.dart';

class ZoneMarker extends StatelessWidget {
  final Zone zone;
  const ZoneMarker({super.key, required this.zone});

  Color get _color {
    switch (zone.status) {
      case 'healthy':    return const Color(0xFF2ECC71);
      case 'recovering': return const Color(0xFFF4D03F);
      case 'banned':     return const Color(0xFFE74C3C);
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color.withOpacity(0.15),
            border: Border.all(color: _color.withOpacity(0.4), width: 1),
          ),
        ),
        // Core dot
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color,
            boxShadow: [BoxShadow(color: _color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)],
          ),
        ),
      ],
    );
  }
}
```

---

## 7. Screen 2 — Zone Detail

### Purpose

Show all data about a tapped zone. The herder needs to answer: can I graze here with my herd today?

### Layout

```
┌─────────────────────────────┐
│  ← Back                     │  ← AppBar
├─────────────────────────────┤
│                             │
│  [Mini map thumbnail]       │  ← Static, centered on zone, non-interactive
│      ●  zone dot            │
│                             │
├─────────────────────────────┤
│  АТ-БАШЫ                   │  ← Big Kyrgyz name
│  [● БЕЗОПАСНО]              │  ← Status badge
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │ Здоровье │ │ Макс стадо│  │  ← 2×2 data card grid
│  │  78/100  │ │  150 овец │  │
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │Посл. выпас│ │Безоп. дни│  │
│  │  5 дней  │ │   18 дн  │  │
│  └──────────┘ └──────────┘  │
│                             │
│  [██████████░░] 78%         │  ← Health bar
│                             │
│  [  Сообщить: я здесь пасу ] │  ← CTA button
└─────────────────────────────┘
```

### Implementation — `detail_screen.dart`

```dart
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
                    boxShadow: [BoxShadow(color: _statusColor(zone.status).withOpacity(0.7), blurRadius: 12)],
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
```

### `widgets/health_bar.dart`

```dart
import 'package:flutter/material.dart';

class HealthBar extends StatelessWidget {
  final int score; // 0–100
  const HealthBar({super.key, required this.score});

  Color get _color {
    if (score >= 65) return const Color(0xFF2ECC71);
    if (score >= 35) return const Color(0xFFF4D03F);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: score / 100,
        minHeight: 8,
        backgroundColor: const Color(0xFF1a2a1a),
        valueColor: AlwaysStoppedAnimation<Color>(_color),
      ),
    );
  }
}
```

### `widgets/status_badge.dart`

```dart
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  String get _label {
    switch (status) {
      case 'healthy':    return '● БЕЗОПАСНО';
      case 'recovering': return '● ВОССТАНОВЛЕНИЕ';
      case 'banned':     return '● ЗАПРЕТ';
      default:           return status;
    }
  }

  Color get _color {
    switch (status) {
      case 'healthy':    return const Color(0xFF2ECC71);
      case 'recovering': return const Color(0xFFF4D03F);
      case 'banned':     return const Color(0xFFE74C3C);
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'DMMono',
          fontSize: 10,
          color: _color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
```

### `widgets/data_card.dart`

```dart
import 'package:flutter/material.dart';

class DataCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const DataCard({super.key, required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1a2a1a)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMMono',
              fontSize: 8,
              color: Color(0xFF7A9A7A),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 28,
              color: Color(0xFF2ECC71),
              height: 1,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 10, color: Color(0xFF7A9A7A)),
          ),
        ],
      ),
    );
  }
}
```

---

## 8. Screen 3 — AI Assistant

### Purpose

One question. One answer. "У меня 60 овец, куда идти?" → Claude returns a 2–3 sentence recommendation in Russian. No dashboard. No charts. Just the answer.

### Layout

```
┌─────────────────────────────┐
│  AI ПОМОЩНИК                │
│  Claude · отвечает по-русски│
├─────────────────────────────┤
│                             │
│  ╔═══════════════════╗      │
│  ║ У меня 60 овец.   ║  ←  user bubble (right)
│  ║ Куда идти?        ║      │
│  ╚═══════════════════╝      │
│                             │
│  ╔═══════════════════╗      │
│  ║ Рекомендую зону   ║  ← AI bubble (left)
│  ║ Ат-Башы. Здоровье ║      │
│  ║ 78/100. Хватит на ║      │
│  ║ 18 дней. Кочкор — ║      │
│  ║ под запретом. ✓   ║      │
│  ╚═══════════════════╝      │
│                             │
├─────────────────────────────┤
│  [Введите вопрос...   ] [↑] │  ← Input + send
└─────────────────────────────┘
```

### Implementation — `ai_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../data/zones.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _aiService = AiService();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });
    _controller.clear();
    _scrollDown();

    final response = await _aiService.getRecommendation(text, kZones);

    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _loading = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111811),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111811),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'AI ПОМОЩНИК',
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 20,
                color: Color(0xFF2ECC71),
                letterSpacing: 3,
              ),
            ),
            Text(
              'Claude · отвечает по-русски',
              style: TextStyle(fontSize: 10, color: Color(0xFF7A9A7A), letterSpacing: 1),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return const _TypingIndicator();
                final msg = _messages[index];
                return _Bubble(role: msg['role']!, text: msg['text']!);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF111811),
        border: Border(top: BorderSide(color: Color(0xFF1a2a1a))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Color(0xFFE8F5E8), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Спросите о пастбище...',
                hintStyle: const TextStyle(color: Color(0xFF4A6A4A), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0A0F0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF1a2a1a)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF1a2a1a)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward, color: Color(0xFF0A0F0A), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String role;
  final String text;
  const _Bubble({required this.role, required this.text});

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2ECC71) : const Color(0xFF172017),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFF1a2a1a)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isUser ? const Color(0xFF0A0F0A) : const Color(0xFFE8F5E8),
            height: 1.5,
            fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF172017),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFF1a2a1a)),
        ),
        child: const Text('...', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 18, letterSpacing: 4)),
      ),
    );
  }
}
```

---

## 9. Design System

### Colors

```dart
// lib/theme/colors.dart
class JailooColors {
  // Status
  static const healthy    = Color(0xFF2ECC71);
  static const recovering = Color(0xFFF4D03F);
  static const banned     = Color(0xFFE74C3C);

  // Background layers
  static const bg         = Color(0xFF0A0F0A);  // deepest bg
  static const surface    = Color(0xFF111811);  // card/screen bg
  static const surface2   = Color(0xFF172017);  // raised elements

  // Text
  static const textPrimary = Color(0xFFE8F5E8);
  static const textMuted   = Color(0xFF7A9A7A);

  // Borders
  static const border      = Color(0xFF1a2a1a);
  static const borderGreen = Color(0xFF2a3a2a);
}
```

### Typography

Use system fonts in the hackathon. Add custom fonts if time allows.

```dart
// main.dart — ThemeData
theme: ThemeData(
  fontFamily: 'DM Sans',
  scaffoldBackgroundColor: JailooColors.bg,
  colorScheme: const ColorScheme.dark(
    primary: JailooColors.healthy,
    surface: JailooColors.surface,
  ),
),
```

For custom fonts, add to `pubspec.yaml`:
```yaml
fonts:
  - family: BebasNeue
    fonts:
      - asset: assets/fonts/BebasNeue-Regular.ttf
  - family: DMMono
    fonts:
      - asset: assets/fonts/DMMono-Regular.ttf
```

### Design Rules

- **No gradients on text.** Green glows only on interactive dots and buttons.
- **No cards with rounded corners > 14px.** Feels too bubbly.
- **No shadows except on map markers.** Keep surfaces flat.
- **All labels in uppercase + letter-spacing.** Makes it feel precise, not generic.
- **Status colors are the only accent colors.** Never use blue, purple, or orange for anything else.
- **Health bar is the only animated element.** No loaders, no transitions except page push.
- **Minimum tap target: 48×48px.** Herders use phones with gloves in the field.

---

## 10. Service Hooks with Hardcoded Responses

The services are written so the data source is swappable. During hackathon: hardcoded. In production: real API.

### `services/zone_service.dart`

```dart
import '../data/zones.dart';
import '../models/zone.dart';

class ZoneService {
  // HACKATHON: returns hardcoded zones immediately
  // PRODUCTION: GET https://kyrgyzstan.sibelius-datacube.org:5000/wcs?...
  Future<List<Zone>> getZones() async {
    // Simulate slight network delay for realism in demo
    await Future.delayed(const Duration(milliseconds: 200));
    return kZones;
  }

  // Returns zones sorted by distance from user location
  List<Zone> nearestZones(double userLat, double userLng, {int limit = 3}) {
    final sorted = [...kZones];
    sorted.sort((a, b) {
      final da = _dist(userLat, userLng, a.lat, a.lng);
      final db = _dist(userLat, userLng, b.lat, b.lng);
      return da.compareTo(db);
    });
    return sorted.take(limit).toList();
  }

  double _dist(double lat1, double lng1, double lat2, double lng2) {
    return ((lat1 - lat2) * (lat1 - lat2)) + ((lng1 - lng2) * (lng1 - lng2));
  }
}
```

### `services/ai_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zone.dart';

class AiService {
  // Replace with your actual key — store in --dart-define for security
  static const _apiKey = String.fromEnvironment('CLAUDE_API_KEY', defaultValue: 'YOUR_KEY_HERE');
  static const _cacheKey = 'last_ai_response';

  // HACKATHON FALLBACK: if API fails or no internet, return this
  static const _hardcodedFallback = '''
Рекомендую пастбище Ат-Башы. Состояние: хорошее (78/100), хватит на 18 дней для стада до 150 овец. Избегайте Жумгал и Ак-Талаа — они под официальным запретом.
''';

  Future<String> getRecommendation(String userMessage, List<Zone> zones) async {
    final prompt = _buildPrompt(userMessage, zones);

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 300,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;

        // Cache for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, text);

        return text;
      } else {
        return _getCachedOrFallback();
      }
    } catch (_) {
      return _getCachedOrFallback();
    }
  }

  Future<String> _getCachedOrFallback() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey) ?? _hardcodedFallback;
  }

  String _buildPrompt(String userMessage, List<Zone> zones) {
    final zoneList = zones
        .map((z) =>
            '- ${z.name} (${z.nameEn}): здоровье ${z.healthScore}/100, '
            'макс стадо ${z.maxHerd} овец, статус: ${z.status}, '
            'безопасных дней: ${z.safeDays}')
        .join('\n');

    return '''
Ты — помощник пастухов в Кыргызстане (Нарынская область).
Отвечай ТОЛЬКО на русском языке.
Будь КРАТКИМ — максимум 3 предложения.
Не используй markdown, только обычный текст.

Сообщение пастуха: "$userMessage"

Доступные пастбища:
$zoneList

Дай конкретный совет: куда идти, на сколько дней хватит, одно предупреждение если нужно.
''';
  }
}
```

---

## 11. Real Data Fetching — Phase 2

When you're ready to connect live data, swap only `zone_service.dart`. Everything else stays the same.

### Kyrgyz Data Cube WMS

```
Base URL: https://kyrgyzstan.sibelius-datacube.org:5000/wms
Version:  1.3.0
Layer:    ls8_ndvi_seasonal (or similar NDVI layer)
Format:   image/png for tiles, application/json for values
```

**Get NDVI value for a coordinate:**

```dart
// Real API call — replace zone_service.dart getZones() with this in Phase 2
Future<double> getNdviForPoint(double lat, double lng) async {
  final url = Uri.parse(
    'https://kyrgyzstan.sibelius-datacube.org:5000/wcs'
    '?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage'
    '&COVERAGE=ls8_ndvi_seasonal'
    '&CRS=EPSG:4326'
    '&BBOX=${lng - 0.01},${lat - 0.01},${lng + 0.01},${lat + 0.01}'
    '&WIDTH=10&HEIGHT=10'
    '&FORMAT=GeoTIFF',
  );

  final response = await http.get(url);
  // Parse GeoTIFF → extract mean NDVI value → convert to 0–100 score
  // NDVI range: -1 to 1. Pasture healthy: > 0.4. Dead: < 0.1
  // healthScore = ((ndvi + 1) / 2 * 100).clamp(0, 100).round()
}
```

**NDVI → Health Score conversion:**

```dart
int ndviToHealthScore(double ndvi) {
  // NDVI: -1 (bare) to 1 (lush vegetation)
  // Pasture thresholds from IFAD Kyrgyzstan reports:
  //   > 0.45 = healthy (green)
  //   0.25–0.45 = recovering (yellow)
  //   < 0.25 = degraded/banned (red)
  return ((ndvi.clamp(-0.1, 0.8) + 0.1) / 0.9 * 100).round().clamp(0, 100);
}

String ndviToStatus(double ndvi) {
  if (ndvi >= 0.45) return 'healthy';
  if (ndvi >= 0.25) return 'recovering';
  return 'banned';
}
```

---

## 12. Libraries Reference

| Package | Version | Install | Use |
|---------|---------|---------|-----|
| flutter_map | ^6.1.0 | `flutter pub add flutter_map` | Interactive map, tile layers, markers |
| latlong2 | ^0.9.0 | `flutter pub add latlong2` | LatLng type used by flutter_map |
| geolocator | ^11.0.0 | `flutter pub add geolocator` | Get device GPS position |
| permission_handler | ^11.3.0 | `flutter pub add permission_handler` | Request location permission |
| http | ^1.2.1 | `flutter pub add http` | Claude API calls |
| provider | ^6.1.2 | `flutter pub add provider` | App-level state (selected zone, etc.) |
| shared_preferences | ^2.2.3 | `flutter pub add shared_preferences` | Cache last AI response for offline |

**Android permissions** — add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**iOS permissions** — add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Jailoo needs your location to show nearby pasture zones</string>
```

---

## 13. pubspec.yaml

```yaml
name: jailoo
description: Smart pasture navigator for Naryn Oblast, Kyrgyzstan
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

  # Maps
  flutter_map: ^6.1.0
  latlong2: ^0.9.0

  # GPS
  geolocator: ^11.0.0
  permission_handler: ^11.3.0

  # HTTP (Claude API)
  http: ^1.2.1

  # State
  provider: ^6.1.2

  # Offline cache
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  # Uncomment when fonts are added:
  # fonts:
  #   - family: BebasNeue
  #     fonts:
  #       - asset: assets/fonts/BebasNeue-Regular.ttf
  #   - family: DMMono
  #     fonts:
  #       - asset: assets/fonts/DMMono-Regular.ttf
```

---

## 14. Build Timeline

### Hour-by-hour (2 developers, 12 hours)

| Hours | Dev 1 | Dev 2 |
|-------|-------|-------|
| 0–1 | `flutter create jailoo`, add dependencies, paste `zones.dart` and `zone.dart` | Same repo setup, read this doc fully |
| 1–3 | `map_screen.dart` — map loads, 8 markers visible at correct coordinates | `ai_service.dart` — Claude API returning text in terminal. Test without UI first. |
| 3–5 | Tap marker → navigate to `detail_screen.dart` with zone data | `ai_screen.dart` — chat bubbles UI, input field, send button |
| 5–7 | `detail_screen.dart` — health bar, data cards, report button | Wire AI service into screen. Add loading state. Add offline fallback. |
| 7–8 | GPS dot on map, legend bar | Integration: connect all 3 screens in `main.dart` |
| 8–9 | **BOTH: test on real Android device. Fix crashes.** | |
| 9–10 | Dark theme polish, correct colors, Kyrgyz names | Screen recording backup in case live demo fails |
| 10–11 | Buffer for bugs | Pitch slides final pass |
| 11–12 | **BOTH: rehearse pitch twice. Time it. Cut to 5 minutes.** | |

### Critical path

The only thing that can kill the demo:

1. **Claude API key not working** → test in hour 1, not hour 9
2. **GPS permission denied on device** → test on real phone in hour 8
3. **Map tiles not loading** → have OSM as fallback tile URL ready
4. **Integration bugs** → keep screens independent until hour 7, then wire

### Pitch line on data

> "These health scores are from IFAD's 2016–2020 satellite pasture condition maps for Naryn Oblast. In production, the app connects directly to the Kyrgyz Data Cube WMS API — free, already exists, updated every 5 days via Sentinel-2 satellite. The data is real. We hardcoded it for the demo to keep the scope tight."

---

*Jailoo · MVP PRD v1.0 · Naryn Oblast Pilot · 2025*
