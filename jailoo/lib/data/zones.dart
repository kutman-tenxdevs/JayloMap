import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/zone.dart';

// Circle boundary generator. Adjusts lng radius for latitude distortion
// so circles look round on the Mercator-projected map.
// In production, boundaries come from OSM Overpass API.
List<LatLng> _circle(double lat, double lng, {double radius = 0.055, int points = 36}) {
  final lngRadius = radius / cos(lat * pi / 180);
  return List.generate(points, (i) {
    final angle = 2 * pi * i / points;
    return LatLng(lat + radius * sin(angle), lng + lngRadius * cos(angle));
  });
}

// Hardcoded user location near Dostuk settlement
const kUserLocation = LatLng(41.36, 75.73);

// Zone centers are spaced so circles with r=0.055° never overlap.
// Min pairwise distance ≈ 0.15° > 2*0.055 = 0.11°.
// Names are real places in the Naryn river valley area.
final List<Zone> kZones = [
  Zone(
    id: 1,
    name: 'КЫЗАРТ',
    nameEn: 'Kyzart',
    status: 'banned',
    healthScore: 12,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 0,
    lat: 41.58,
    lng: 75.40,
    boundary: _circle(41.58, 75.40),
    areaKm2: 1180,
    elevation: '2400–3200 m',
    seasonNote: 'Closed for restoration. Overgrazing near Kyzart pass.',
  ),
  Zone(
    id: 2,
    name: 'САРЫ-БУЛАК',
    nameEn: 'Sary-Bulak',
    status: 'healthy',
    healthScore: 83,
    maxHerd: 200,
    safeDays: 22,
    lastGrazedDaysAgo: 11,
    lat: 41.50,
    lng: 75.60,
    boundary: _circle(41.50, 75.60),
    areaKm2: 950,
    elevation: '2800–3500 m',
    seasonNote: 'Best Jun–Sep. Spring-fed alpine meadow.',
  ),
  Zone(
    id: 3,
    name: 'КУРТКА',
    nameEn: 'Kurtka',
    status: 'recovering',
    healthScore: 51,
    maxHerd: 80,
    safeDays: 9,
    lastGrazedDaysAgo: 2,
    lat: 41.58,
    lng: 75.76,
    boundary: _circle(41.58, 75.76),
    areaKm2: 1350,
    elevation: '1700–2900 m',
    seasonNote: 'Valley floor recovering. Use upper slopes only.',
  ),
  Zone(
    id: 4,
    name: 'ОН-АРЧА',
    nameEn: 'On-Archa',
    status: 'recovering',
    healthScore: 38,
    maxHerd: 50,
    safeDays: 5,
    lastGrazedDaysAgo: 3,
    lat: 41.50,
    lng: 75.94,
    boundary: _circle(41.50, 75.94),
    areaKm2: 870,
    elevation: '2200–3400 m',
    seasonNote: 'Limited capacity. Juniper groves on east slopes fragile.',
  ),
  Zone(
    id: 5,
    name: 'ЧАЕК',
    nameEn: 'Chaek',
    status: 'banned',
    healthScore: 18,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 0,
    lat: 41.42,
    lng: 75.34,
    boundary: _circle(41.42, 75.34),
    areaKm2: 1420,
    elevation: '1600–3100 m',
    seasonNote: 'Closed. Soil erosion along river basin.',
  ),
  Zone(
    id: 6,
    name: 'ЭКИ-НАРЫН',
    nameEn: 'Eki-Naryn',
    status: 'healthy',
    healthScore: 78,
    maxHerd: 150,
    safeDays: 18,
    lastGrazedDaysAgo: 5,
    lat: 41.35,
    lng: 75.52,
    boundary: _circle(41.35, 75.52),
    areaKm2: 1680,
    elevation: '2000–3600 m',
    seasonNote: 'Wide open range along two river branches.',
  ),
  Zone(
    id: 7,
    name: 'ДОСТУК',
    nameEn: 'Dostuk',
    status: 'recovering',
    healthScore: 44,
    maxHerd: 60,
    safeDays: 7,
    lastGrazedDaysAgo: 1,
    lat: 41.35,
    lng: 75.76,
    boundary: _circle(41.35, 75.76),
    areaKm2: 920,
    elevation: '1800–2800 m',
    seasonNote: 'Near settlement. Heavy recent use. Rotate sectors.',
  ),
  Zone(
    id: 8,
    name: 'АК-ТАМ',
    nameEn: 'Ak-Tam',
    status: 'healthy',
    healthScore: 70,
    maxHerd: 120,
    safeDays: 15,
    lastGrazedDaysAgo: 8,
    lat: 41.40,
    lng: 76.10,
    boundary: _circle(41.40, 76.10),
    areaKm2: 1340,
    elevation: '2100–3800 m',
    seasonNote: 'Remote eastern pasture. Access via mountain road.',
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
