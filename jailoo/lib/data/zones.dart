import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/zone.dart';

// Generates a natural-looking irregular polygon around a center point.
// Each zone gets a unique seed so shapes are deterministic but distinct.
// In production, real boundaries can be fetched from OSM Overpass API:
//   [out:json];
//   area["name"="Naryn Region"]->.nr;
//   relation["admin_level"="6"](area.nr);
//   out geom;
List<LatLng> _naturalBoundary(
  double lat,
  double lng, {
  double rLat = 0.25,
  double rLng = 0.35,
  int points = 12,
  int seed = 0,
}) {
  final rand = Random(seed);
  return List.generate(points, (i) {
    final angle = 2 * pi * i / points;
    final jLat = rLat * (0.65 + rand.nextDouble() * 0.7);
    final jLng = rLng * (0.65 + rand.nextDouble() * 0.7);
    return LatLng(lat + jLat * sin(angle), lng + jLng * cos(angle));
  });
}

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
    lat: 42.10,
    lng: 74.15,
    boundary: _naturalBoundary(42.10, 74.15, rLat: 0.26, rLng: 0.34, points: 14, seed: 17),
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
    lat: 41.78,
    lng: 75.10,
    boundary: _naturalBoundary(41.78, 75.10, rLat: 0.24, rLng: 0.30, points: 13, seed: 42),
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
    lat: 42.25,
    lng: 75.75,
    boundary: _naturalBoundary(42.25, 75.75, rLat: 0.22, rLng: 0.32, points: 12, seed: 73),
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
    lat: 41.78,
    lng: 76.55,
    boundary: _naturalBoundary(41.78, 76.55, rLat: 0.22, rLng: 0.28, points: 11, seed: 55),
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
    lat: 41.42,
    lng: 74.50,
    boundary: _naturalBoundary(41.42, 74.50, rLat: 0.24, rLng: 0.32, points: 13, seed: 31),
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
    lat: 40.95,
    lng: 76.10,
    boundary: _naturalBoundary(40.95, 76.10, rLat: 0.28, rLng: 0.38, points: 14, seed: 88),
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
    lat: 41.43,
    lng: 75.90,
    boundary: _naturalBoundary(41.43, 75.90, rLat: 0.20, rLng: 0.26, points: 11, seed: 64),
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
    lat: 41.18,
    lng: 77.40,
    boundary: _naturalBoundary(41.18, 77.40, rLat: 0.26, rLng: 0.36, points: 13, seed: 99),
    areaKm2: 5210,
    elevation: '2100–3800 m',
    seasonNote: 'Remote, underused. Mountain passes accessible Jul–Oct.',
  ),
];
