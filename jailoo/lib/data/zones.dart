import 'package:latlong2/latlong.dart';
import '../models/zone.dart';

// Hex grid parameters:
//   R_lat  = 0.38  (circumradius in latitude degrees)
//   R_lng  = 0.50  (circumradius in longitude degrees, adjusted for ~41° lat)
//   Column spacing = 1.5 * R_lng = 0.75
//   Row spacing    = sqrt(3) * R_lat ≈ 0.658
//   Odd-column vertical offset = 0.329
//
// Grid layout (col, row):
//   (0,0) Jumgal     (1,0) Song-Kol   (2,0) Kochkor    (3,0) Kara-Kol
//   (0,1) Ak-Talaa   (1,1) At-Bashy   (2,1) Naryn      (3,1) Toguz-Toro

List<LatLng> _hex(double lat, double lng) {
  const rLat = 0.38;
  const rLng = 0.50;
  const s = 0.329; // sin(60°) * rLat
  const c = 0.25;  // cos(60°) * rLng
  return [
    LatLng(lat,     lng + rLng), // E
    LatLng(lat + s, lng + c),    // NE
    LatLng(lat + s, lng - c),    // NW
    LatLng(lat,     lng - rLng), // W
    LatLng(lat - s, lng - c),    // SW
    LatLng(lat - s, lng + c),    // SE
  ];
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
    lat: 42.100,
    lng: 74.350,
    boundary: _hex(42.100, 74.350),
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
    lat: 41.771,
    lng: 75.100,
    boundary: _hex(41.771, 75.100),
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
    lat: 42.100,
    lng: 75.850,
    boundary: _hex(42.100, 75.850),
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
    lat: 41.771,
    lng: 76.600,
    boundary: _hex(41.771, 76.600),
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
    lat: 41.442,
    lng: 74.350,
    boundary: _hex(41.442, 74.350),
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
    lat: 41.113,
    lng: 75.100,
    boundary: _hex(41.113, 75.100),
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
    lat: 41.442,
    lng: 75.850,
    boundary: _hex(41.442, 75.850),
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
    lat: 41.113,
    lng: 76.600,
    boundary: _hex(41.113, 76.600),
  ),
];
