import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/zone.dart';

// Converts GeoJSON-style [longitude, latitude] coordinate pairs into LatLng.
// Coordinates are defined in the same format as the mapcn.dev / MapLibre GL
// GeoJSON spec so they can be pasted directly from OSM exports.
//
// In production, fetch real zone GeoJSON from OSM Overpass API:
//   POST https://overpass-api.de/api/interpreter
//   [out:json];
//   area["name"="Naryn Region"]->.nr;
//   relation["admin_level"="6"]["boundary"="administrative"](area.nr);
//   out geom;
List<LatLng> _poly(List<List<double>> coords) =>
    coords.map((c) => LatLng(c[1], c[0])).toList();

// ---------------------------------------------------------------------------
// Zone boundary polygons (GeoJSON coordinate format: [longitude, latitude])
//
// Zones are laid out in three latitudinal bands to guarantee zero overlap:
//   North  (lat 41.54–41.70): Sary-Bulak, Kurtka
//   Middle (lat 41.35–41.53): Chaek, Dostuk, On-Archa
//   South  (lat 41.20–41.34): Kyzart, Eki-Naryn, Ak-Tam
//
// Minimum longitudinal gap between adjacent zones: ≥ 0.04°
// Minimum latitudinal gap between rows:            ≥ 0.01°
// ---------------------------------------------------------------------------

// User's hardcoded position — on the A-365 highway in Naryn valley.
// In production: Geolocator.getCurrentPosition()
const kUserLocation = LatLng(41.43, 75.99);

final List<Zone> kZones = [
  // ── NORTH ROW ─────────────────────────────────────────────────────────────

  Zone(
    id: 1,
    name: 'САРЫ-БУЛАК',
    nameEn: 'Sary-Bulak',
    status: 'healthy',
    healthScore: 83,
    maxHerd: 200,
    safeDays: 22,
    lastGrazedDaysAgo: 11,
    lat: 41.61,
    lng: 75.59,
    boundary: _poly([
      [75.48, 41.55], [75.60, 41.54], [75.70, 41.57], [75.68, 41.65],
      [75.59, 41.68], [75.50, 41.65], [75.48, 41.61],
    ]),
    areaKm2: 950,
    elevation: '2800–3500 m',
    seasonNote: 'Best Jun–Sep. Spring-fed alpine meadow.',
  ),

  Zone(
    id: 2,
    name: 'КУРТКА',
    nameEn: 'Kurtka',
    status: 'recovering',
    healthScore: 51,
    maxHerd: 80,
    safeDays: 9,
    lastGrazedDaysAgo: 2,
    lat: 41.61,
    lng: 75.82,
    boundary: _poly([
      [75.74, 41.54], [75.84, 41.53], [75.90, 41.57], [75.88, 41.65],
      [75.80, 41.68], [75.73, 41.65], [75.73, 41.59],
    ]),
    areaKm2: 1350,
    elevation: '1700–2900 m',
    seasonNote: 'Valley floor recovering. Use upper slopes only.',
  ),

  // ── MIDDLE ROW ────────────────────────────────────────────────────────────

  Zone(
    id: 3,
    name: 'ЧАЕК',
    nameEn: 'Chaek',
    status: 'banned',
    healthScore: 18,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 0,
    lat: 41.43,
    lng: 75.70,
    boundary: _poly([
      [75.62, 41.36], [75.72, 41.35], [75.79, 41.39], [75.77, 41.47],
      [75.69, 41.51], [75.62, 41.49], [75.62, 41.42],
    ]),
    areaKm2: 1420,
    elevation: '1600–3100 m',
    seasonNote: 'Closed. Soil erosion along Chaek river basin.',
  ),

  Zone(
    id: 4,
    name: 'ДОСТУК',
    nameEn: 'Dostuk',
    status: 'recovering',
    healthScore: 44,
    maxHerd: 60,
    safeDays: 7,
    lastGrazedDaysAgo: 1,
    lat: 41.45,
    lng: 76.00,
    boundary: _poly([
      [75.92, 41.39], [76.02, 41.37], [76.08, 41.41], [76.06, 41.51],
      [75.98, 41.53], [75.92, 41.50], [75.92, 41.44],
    ]),
    areaKm2: 920,
    elevation: '1800–2800 m',
    seasonNote: 'Near settlement. Heavy recent use. Rotate sectors.',
  ),

  Zone(
    id: 5,
    name: 'ОН-АРЧА',
    nameEn: 'On-Archa',
    status: 'recovering',
    healthScore: 38,
    maxHerd: 50,
    safeDays: 5,
    lastGrazedDaysAgo: 3,
    lat: 41.45,
    lng: 76.19,
    boundary: _poly([
      [76.12, 41.39], [76.22, 41.37], [76.27, 41.42], [76.25, 41.51],
      [76.17, 41.53], [76.12, 41.49],
    ]),
    areaKm2: 870,
    elevation: '2200–3400 m',
    seasonNote: 'Limited capacity. Juniper groves on east slopes fragile.',
  ),

  // ── SOUTH ROW ─────────────────────────────────────────────────────────────

  Zone(
    id: 6,
    name: 'КЫЗАРТ',
    nameEn: 'Kyzart',
    status: 'banned',
    healthScore: 12,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 0,
    lat: 41.27,
    lng: 75.48,
    boundary: _poly([
      [75.38, 41.22], [75.50, 41.20], [75.58, 41.25], [75.57, 41.31],
      [75.49, 41.34], [75.41, 41.33], [75.38, 41.28],
    ]),
    areaKm2: 1180,
    elevation: '2400–3200 m',
    seasonNote: 'Closed for restoration. Overgrazing near Kyzart pass.',
  ),

  Zone(
    id: 7,
    name: 'ЭКИ-НАРЫН',
    nameEn: 'Eki-Naryn',
    status: 'healthy',
    healthScore: 78,
    maxHerd: 150,
    safeDays: 18,
    lastGrazedDaysAgo: 5,
    lat: 41.26,
    lng: 75.89,
    boundary: _poly([
      [75.81, 41.22], [75.91, 41.20], [75.98, 41.24], [75.96, 41.31],
      [75.87, 41.33], [75.80, 41.30], [75.80, 41.25],
    ]),
    areaKm2: 1680,
    elevation: '2000–3600 m',
    seasonNote: 'Wide open range along two river branches.',
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
    lat: 41.29,
    lng: 76.32,
    boundary: _poly([
      [76.20, 41.23], [76.32, 41.22], [76.44, 41.26], [76.42, 41.34],
      [76.32, 41.36], [76.22, 41.33], [76.20, 41.28],
    ]),
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

final List<Zone> kZonesByRenderOrder = List.of(kZones)
  ..sort((a, b) => _statusPriority(a.status).compareTo(_statusPriority(b.status)));

final List<Zone> kZonesByTapOrder = List.of(kZones)
  ..sort((a, b) => _statusPriority(b.status).compareTo(_statusPriority(a.status)));
