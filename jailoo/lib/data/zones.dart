import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/zone.dart';

// Generates a natural-looking irregular polygon around a center point.
// In production, real boundaries from OSM Overpass API:
//   [out:json];
//   area["name"="Naryn Region"]->.nr;
//   relation["admin_level"="6"](area.nr);
//   out geom;
List<LatLng> _naturalBoundary(
  double lat,
  double lng, {
  double rLat = 0.07,
  double rLng = 0.10,
  int points = 12,
  int seed = 0,
}) {
  final rand = Random(seed);
  return List.generate(points, (i) {
    final angle = 2 * pi * i / points;
    final jLat = rLat * (0.7 + rand.nextDouble() * 0.6);
    final jLng = rLng * (0.7 + rand.nextDouble() * 0.6);
    return LatLng(lat + jLat * sin(angle), lng + jLng * cos(angle));
  });
}

// All zones are packed into a compact mountain valley area near Naryn city.
// Tight clustering makes them visible together at high zoom.
final List<Zone> kZones = [
  Zone(
    id: 1,
    name: 'ЖУМГАЛ',
    nameEn: 'Jumgal',
    status: 'banned',
    healthScore: 12,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 0,
    lat: 41.56,
    lng: 75.48,
    boundary: _naturalBoundary(41.56, 75.48, rLat: 0.07, rLng: 0.11, points: 13, seed: 17),
    areaKm2: 4850,
    elevation: '1800–3200 m',
    seasonNote: 'Closed for restoration. Overgrazing damage from 2022–2024.',
  ),
  Zone(
    id: 2,
    name: 'СОН-КӨЛ',
    nameEn: 'Song-Kol',
    status: 'healthy',
    healthScore: 83,
    maxHerd: 200,
    safeDays: 22,
    lastGrazedDaysAgo: 11,
    lat: 41.47,
    lng: 75.65,
    boundary: _naturalBoundary(41.47, 75.65, rLat: 0.08, rLng: 0.12, points: 14, seed: 42),
    areaKm2: 3120,
    elevation: '2800–3500 m',
    seasonNote: 'Best Jun–Sep. High alpine meadow around the lake.',
  ),
  Zone(
    id: 3,
    name: 'КОЧКОР',
    nameEn: 'Kochkor',
    status: 'recovering',
    healthScore: 51,
    maxHerd: 80,
    safeDays: 9,
    lastGrazedDaysAgo: 2,
    lat: 41.57,
    lng: 75.78,
    boundary: _naturalBoundary(41.57, 75.78, rLat: 0.07, rLng: 0.10, points: 12, seed: 73),
    areaKm2: 3680,
    elevation: '1700–2900 m',
    seasonNote: 'Valley floor recovering. Use upper slopes only.',
  ),
  Zone(
    id: 4,
    name: 'КАРА-КӨЛ',
    nameEn: 'Kara-Kol',
    status: 'recovering',
    healthScore: 38,
    maxHerd: 50,
    safeDays: 5,
    lastGrazedDaysAgo: 3,
    lat: 41.48,
    lng: 75.92,
    boundary: _naturalBoundary(41.48, 75.92, rLat: 0.07, rLng: 0.11, points: 11, seed: 55),
    areaKm2: 2100,
    elevation: '2200–3400 m',
    seasonNote: 'Limited capacity. East slopes near lake still fragile.',
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
    lat: 41.45,
    lng: 75.38,
    boundary: _naturalBoundary(41.45, 75.38, rLat: 0.07, rLng: 0.10, points: 13, seed: 31),
    areaKm2: 3940,
    elevation: '1600–3100 m',
    seasonNote: 'Closed. Soil erosion along Ak-Talaa river basin.',
  ),
  Zone(
    id: 6,
    name: 'АТ-БАШЫ',
    nameEn: 'At-Bashy',
    status: 'healthy',
    healthScore: 78,
    maxHerd: 150,
    safeDays: 18,
    lastGrazedDaysAgo: 5,
    lat: 41.36,
    lng: 75.55,
    boundary: _naturalBoundary(41.36, 75.55, rLat: 0.08, rLng: 0.12, points: 14, seed: 88),
    areaKm2: 6420,
    elevation: '2000–4200 m',
    seasonNote: 'Large open range. South slopes best in early summer.',
  ),
  Zone(
    id: 7,
    name: 'НАРЫН',
    nameEn: 'Naryn',
    status: 'recovering',
    healthScore: 44,
    maxHerd: 60,
    safeDays: 7,
    lastGrazedDaysAgo: 1,
    lat: 41.37,
    lng: 75.78,
    boundary: _naturalBoundary(41.37, 75.78, rLat: 0.07, rLng: 0.10, points: 11, seed: 64),
    areaKm2: 2780,
    elevation: '1800–2800 m',
    seasonNote: 'Near city. Heavy recent use. Rotate to west sectors.',
  ),
  Zone(
    id: 8,
    name: 'ТОГУЗ-ТОО',
    nameEn: 'Toguz-Toro',
    status: 'healthy',
    healthScore: 70,
    maxHerd: 120,
    safeDays: 15,
    lastGrazedDaysAgo: 8,
    lat: 41.38,
    lng: 76.00,
    boundary: _naturalBoundary(41.38, 76.00, rLat: 0.08, rLng: 0.11, points: 13, seed: 99),
    areaKm2: 5210,
    elevation: '2100–3800 m',
    seasonNote: 'Remote, underused. Mountain passes accessible Jul–Oct.',
  ),
];

int _statusPriority(String status) {
  switch (status) {
    case 'healthy':    return 0;
    case 'recovering': return 1;
    case 'banned':     return 2;
    default:           return 0;
  }
}

/// Zones sorted for rendering: healthy (bottom) → recovering → banned (top).
late final List<Zone> kZonesByRenderOrder = List.of(kZones)
  ..sort((a, b) => _statusPriority(a.status).compareTo(_statusPriority(b.status)));

/// Zones sorted for tap detection: banned first (top-most gets picked first).
late final List<Zone> kZonesByTapOrder = List.of(kZones)
  ..sort((a, b) => _statusPriority(b.status).compareTo(_statusPriority(a.status)));
