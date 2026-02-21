import 'dart:math';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/zone.dart';

// Generates a perfect circle boundary adjusted for Mercator projection
// so circles look round on screen regardless of latitude.
// In production, GeoJSON zone features are fetched from OSM Overpass API:
//
//   POST https://overpass-api.de/api/interpreter
//   [out:json];
//   area["name"="Naryn Region"]->.nr;
//   relation["admin_level"="6"]["boundary"="administrative"](area.nr);
//   out geom;
//
// Each relation maps 1:1 to a Zone: boundary.coordinates → zone.boundary
List<LatLng> _circle(double lat, double lng, {double radiusDeg = 0.055, int points = 48}) {
  final lngScale = 1.0 / cos(lat * pi / 180);
  return List.generate(points, (i) {
    final angle = 2 * pi * i / points;
    return LatLng(
      lat + radiusDeg * sin(angle),
      lng + radiusDeg * lngScale * cos(angle),
    );
  });
}

// User's hardcoded position — on the main A-365 highway in Naryn valley.
// In production this comes from Geolocator.getCurrentPosition().
final kUserLocation = LatLng(41.43, 75.99);

// Zone centers are spaced so that for any pair (a, b):
//   (Δlat / (2·r))² + (Δlng / (2·r·lngScale))² > 1
// guaranteeing zero circle overlap.
//
// GeoJSON equivalent structure for each zone:
// {
//   "type": "Feature",
//   "properties": { "id": 1, "name": "КЫЗАРТ", "status": "banned", ... },
//   "geometry": { "type": "Polygon", "coordinates": [[...]] }
// }
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
    lat: 41.30,
    lng: 75.50,
    boundary: _circle(41.30, 75.50),
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
    lat: 41.55,
    lng: 75.60,
    boundary: _circle(41.55, 75.60),
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
    lat: 41.60,
    lng: 75.82,
    boundary: _circle(41.60, 75.82),
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
    lat: 41.45,
    lng: 76.08,
    boundary: _circle(41.45, 76.08),
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
    lat: 41.40,
    lng: 75.72,
    boundary: _circle(41.40, 75.72),
    areaKm2: 1420,
    elevation: '1600–3100 m',
    seasonNote: 'Closed. Soil erosion along Chaek river basin.',
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
    lat: 41.30,
    lng: 75.87,
    boundary: _circle(41.30, 75.87),
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
    lat: 41.53,
    lng: 75.97,
    boundary: _circle(41.53, 75.97),
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
    lat: 41.30,
    lng: 76.28,
    boundary: _circle(41.30, 76.28),
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

late final List<Zone> kZonesByRenderOrder = List.of(kZones)
  ..sort((a, b) => _statusPriority(a.status).compareTo(_statusPriority(b.status)));

late final List<Zone> kZonesByTapOrder = List.of(kZones)
  ..sort((a, b) => _statusPriority(b.status).compareTo(_statusPriority(a.status)));
