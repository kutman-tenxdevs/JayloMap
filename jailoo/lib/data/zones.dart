import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/zone.dart';

// User's hardcoded position — Naryn city center (A-365 highway).
// In production: replace with Geolocator.getCurrentPosition()
const kUserLocation = LatLng(41.43, 75.99);

// ---------------------------------------------------------------------------
// Naryn Oblast — 5 administrative districts
//
// Boundary polygons traced from official Naryn Oblast district map (WGS84).
// Coordinates: LatLng(latitude, longitude) — standard GPS order.
//
// Tap order: banned → recovering → healthy (top priority = most critical)
// Render order: healthy → recovering → banned (banned drawn on top)
// ---------------------------------------------------------------------------

final List<Zone> kZones = [

  // ── ЖУМГАЛ (Jumgal) ─────────────────────────────────────────────────────
  // Northwest district — large, irregular shape
  Zone(
    id: 1,
    name: 'ЖУМГАЛ',
    nameEn: 'Jumgal',
    status: 'banned',
    healthScore: 12,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 3,
    lat: 41.90,
    lng: 74.60,
    boundary: [
      LatLng(42.32, 73.80),
      LatLng(42.38, 74.20),
      LatLng(42.30, 74.65),
      LatLng(42.18, 75.00),
      LatLng(42.05, 75.10),
      LatLng(41.90, 75.05),
      LatLng(41.75, 74.90),
      LatLng(41.65, 74.70),
      LatLng(41.55, 74.50),
      LatLng(41.50, 74.20),
      LatLng(41.55, 73.90),
      LatLng(41.70, 73.75),
      LatLng(41.90, 73.70),
      LatLng(42.10, 73.72),
      LatLng(42.25, 73.78),
      LatLng(42.32, 73.80),
    ],
    areaKm2: 8600,
    elevation: '1500–4000 m',
    seasonNote: 'Banned. Recent overgrazing. Soil recovery in progress.',
  ),

  // ── КОЧКОР (Kochkor) ────────────────────────────────────────────────────
  // Northeast district — smaller, near Son-Kol lake
  Zone(
    id: 2,
    name: 'КОЧКОР',
    nameEn: 'Kochkor',
    status: 'recovering',
    healthScore: 51,
    maxHerd: 200,
    safeDays: 14,
    lastGrazedDaysAgo: 18,
    lat: 42.12,
    lng: 75.75,
    boundary: [
      LatLng(42.38, 75.10),
      LatLng(42.42, 75.50),
      LatLng(42.38, 75.90),
      LatLng(42.25, 76.20),
      LatLng(42.10, 76.35),
      LatLng(41.95, 76.20),
      LatLng(41.85, 76.00),
      LatLng(41.80, 75.70),
      LatLng(41.85, 75.40),
      LatLng(41.90, 75.15),
      LatLng(42.05, 75.10),
      LatLng(42.20, 75.05),
      LatLng(42.38, 75.10),
    ],
    areaKm2: 5000,
    elevation: '1700–3500 m',
    seasonNote: 'Recovering. Use upper alpine meadows. Avoid valley floor.',
  ),

  // ── НАРЫН (Naryn) ───────────────────────────────────────────────────────
  // Central district — includes Naryn city
  Zone(
    id: 3,
    name: 'НАРЫН',
    nameEn: 'Naryn',
    status: 'recovering',
    healthScore: 44,
    maxHerd: 150,
    safeDays: 10,
    lastGrazedDaysAgo: 7,
    lat: 41.60,
    lng: 76.00,
    boundary: [
      LatLng(41.90, 75.15),
      LatLng(41.85, 75.40),
      LatLng(41.85, 75.70),
      LatLng(41.80, 76.00),
      LatLng(41.85, 76.35),
      LatLng(41.75, 76.60),
      LatLng(41.60, 76.80),
      LatLng(41.45, 76.70),
      LatLng(41.35, 76.50),
      LatLng(41.30, 76.20),
      LatLng(41.35, 75.90),
      LatLng(41.45, 75.65),
      LatLng(41.55, 75.45),
      LatLng(41.65, 75.20),
      LatLng(41.75, 75.05),
      LatLng(41.90, 75.15),
    ],
    areaKm2: 7500,
    elevation: '1500–3800 m',
    seasonNote: 'Includes Naryn city valley. Rotate grazing sectors.',
  ),

  // ── АК-ТАЛАА (Ak-Talaa) ─────────────────────────────────────────────────
  // West-central district — large southern area
  Zone(
    id: 4,
    name: 'АК-ТАЛАА',
    nameEn: 'Ak-Talaa',
    status: 'banned',
    healthScore: 18,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 1,
    lat: 41.25,
    lng: 74.90,
    boundary: [
      LatLng(41.55, 74.50),
      LatLng(41.65, 74.70),
      LatLng(41.75, 74.90),
      LatLng(41.75, 75.05),
      LatLng(41.65, 75.20),
      LatLng(41.55, 75.45),
      LatLng(41.45, 75.65),
      LatLng(41.35, 75.50),
      LatLng(41.20, 75.30),
      LatLng(41.10, 75.10),
      LatLng(40.95, 74.90),
      LatLng(40.90, 74.60),
      LatLng(40.95, 74.20),
      LatLng(41.10, 74.00),
      LatLng(41.30, 73.95),
      LatLng(41.50, 74.05),
      LatLng(41.55, 74.30),
      LatLng(41.55, 74.50),
    ],
    areaKm2: 9000,
    elevation: '1600–4000 m',
    seasonNote: 'Closed. Heavy erosion along river tributaries.',
  ),

  // ── АТ-БАШЫ (At-Bashy) ──────────────────────────────────────────────────
  // Large eastern district — borders China
  Zone(
    id: 5,
    name: 'АТ-БАШЫ',
    nameEn: 'At-Bashy',
    status: 'healthy',
    healthScore: 78,
    maxHerd: 500,
    safeDays: 28,
    lastGrazedDaysAgo: 45,
    lat: 41.00,
    lng: 76.20,
    boundary: [
      LatLng(41.35, 75.90),
      LatLng(41.30, 76.20),
      LatLng(41.35, 76.50),
      LatLng(41.45, 76.70),
      LatLng(41.60, 76.80),
      LatLng(41.65, 77.20),
      LatLng(41.55, 77.60),
      LatLng(41.35, 77.90),
      LatLng(41.10, 78.00),
      LatLng(40.85, 77.80),
      LatLng(40.65, 77.50),
      LatLng(40.50, 77.00),
      LatLng(40.45, 76.40),
      LatLng(40.50, 75.90),
      LatLng(40.65, 75.50),
      LatLng(40.80, 75.20),
      LatLng(40.95, 74.90),
      LatLng(41.10, 75.10),
      LatLng(41.20, 75.30),
      LatLng(41.35, 75.50),
      LatLng(41.35, 75.90),
    ],
    areaKm2: 17000,
    elevation: '1700–4500 m',
    seasonNote: 'Wide open range. Remote eastern pasture borders China.',
  ),

  // ── СОН-КӨЛ (Son-Kol) ───────────────────────────────────────────────────
  // High alpine lake meadows — prime summer pasture
  Zone(
    id: 6,
    name: 'СОН-КӨЛ',
    nameEn: 'Son-Kol',
    status: 'healthy',
    healthScore: 92,
    maxHerd: 800,
    safeDays: 60,
    lastGrazedDaysAgo: 90,
    lat: 41.87,
    lng: 75.12,
    boundary: [
      LatLng(42.05, 74.88),
      LatLng(42.08, 75.05),
      LatLng(42.05, 75.22),
      LatLng(41.98, 75.35),
      LatLng(41.88, 75.42),
      LatLng(41.78, 75.38),
      LatLng(41.72, 75.25),
      LatLng(41.70, 75.08),
      LatLng(41.74, 74.92),
      LatLng(41.83, 74.82),
      LatLng(41.95, 74.80),
      LatLng(42.05, 74.88),
    ],
    areaKm2: 1400,
    elevation: '3016 m',
    seasonNote: 'Prime alpine meadow around Son-Kol Lake. Accessible Jun–Sep only.',
  ),

  // ── КАРАГОЙ (Karagoy) ───────────────────────────────────────────────────
  // Karakol Valley — northern Jumgal sub-pasture
  Zone(
    id: 7,
    name: 'КАРАГОЙ',
    nameEn: 'Karagoy Valley',
    status: 'recovering',
    healthScore: 58,
    maxHerd: 250,
    safeDays: 20,
    lastGrazedDaysAgo: 25,
    lat: 42.24,
    lng: 74.14,
    boundary: [
      LatLng(42.35, 73.90),
      LatLng(42.40, 74.08),
      LatLng(42.38, 74.28),
      LatLng(42.28, 74.38),
      LatLng(42.15, 74.35),
      LatLng(42.08, 74.20),
      LatLng(42.10, 74.02),
      LatLng(42.20, 73.90),
      LatLng(42.35, 73.90),
    ],
    areaKm2: 620,
    elevation: '1800–3200 m',
    seasonNote: 'Northern valley pasture. Stream-fed grasslands. Moderate recovery.',
  ),

  // ── ТАШ-РАБАТ (Tash-Rabat) ──────────────────────────────────────────────
  // Historic silk road plateau pasture
  Zone(
    id: 8,
    name: 'ТАШ-РАБАТ',
    nameEn: 'Tash-Rabat',
    status: 'healthy',
    healthScore: 85,
    maxHerd: 400,
    safeDays: 45,
    lastGrazedDaysAgo: 60,
    lat: 40.84,
    lng: 75.92,
    boundary: [
      LatLng(40.98, 75.75),
      LatLng(41.02, 75.92),
      LatLng(40.98, 76.08),
      LatLng(40.88, 76.15),
      LatLng(40.76, 76.10),
      LatLng(40.70, 75.95),
      LatLng(40.72, 75.78),
      LatLng(40.82, 75.68),
      LatLng(40.95, 75.70),
      LatLng(40.98, 75.75),
    ],
    areaKm2: 980,
    elevation: '3200–4000 m',
    seasonNote: 'High plateau near historic Tash-Rabat caravanserai. Excellent pasture.',
  ),

  // ── ДОЛОН (Dolon Pass) ──────────────────────────────────────────────────
  // Alpine pass meadows between Jumgal and Kochkor
  Zone(
    id: 9,
    name: 'ДОЛОН',
    nameEn: 'Dolon Pass',
    status: 'recovering',
    healthScore: 63,
    maxHerd: 180,
    safeDays: 18,
    lastGrazedDaysAgo: 22,
    lat: 42.08,
    lng: 75.48,
    boundary: [
      LatLng(42.18, 75.32),
      LatLng(42.22, 75.48),
      LatLng(42.18, 75.64),
      LatLng(42.08, 75.70),
      LatLng(41.98, 75.65),
      LatLng(41.95, 75.48),
      LatLng(41.98, 75.32),
      LatLng(42.08, 75.25),
      LatLng(42.18, 75.32),
    ],
    areaKm2: 480,
    elevation: '2800–3500 m',
    seasonNote: 'Dolon Pass alpine meadow. Gently recovering after last season.',
  ),

  // ── СУСАМЫР (Suusamyr) ──────────────────────────────────────────────────
  // Broad high plateau valley (touches Jumgal northwest)
  Zone(
    id: 10,
    name: 'СУСАМЫР',
    nameEn: 'Suusamyr',
    status: 'healthy',
    healthScore: 81,
    maxHerd: 600,
    safeDays: 40,
    lastGrazedDaysAgo: 50,
    lat: 42.16,
    lng: 73.52,
    boundary: [
      LatLng(42.30, 73.25),
      LatLng(42.35, 73.50),
      LatLng(42.32, 73.72),
      LatLng(42.20, 73.82),
      LatLng(42.05, 73.78),
      LatLng(41.98, 73.60),
      LatLng(42.00, 73.38),
      LatLng(42.12, 73.25),
      LatLng(42.30, 73.25),
    ],
    areaKm2: 1100,
    elevation: '2000–3500 m',
    seasonNote: 'Suusamyr plateau — lush wide valley. Excellent spring/summer grazing.',
  ),

  // ── АРПА (Arpa Valley) ──────────────────────────────────────────────────
  // Remote high-altitude southern valley
  Zone(
    id: 11,
    name: 'АРПА',
    nameEn: 'Arpa Valley',
    status: 'healthy',
    healthScore: 89,
    maxHerd: 700,
    safeDays: 55,
    lastGrazedDaysAgo: 80,
    lat: 40.56,
    lng: 75.67,
    boundary: [
      LatLng(40.72, 75.42),
      LatLng(40.75, 75.65),
      LatLng(40.70, 75.88),
      LatLng(40.58, 75.98),
      LatLng(40.45, 75.92),
      LatLng(40.38, 75.70),
      LatLng(40.40, 75.48),
      LatLng(40.52, 75.35),
      LatLng(40.65, 75.38),
      LatLng(40.72, 75.42),
    ],
    areaKm2: 1650,
    elevation: '2500–4200 m',
    seasonNote: 'Vast Arpa Valley — pristine remote pasture rarely reached by herders.',
  ),

  // ── НАРЫН КАНЬОН (Naryn Canyon) ─────────────────────────────────────────
  // River canyon pasture strip along Naryn River
  Zone(
    id: 12,
    name: 'НАРЫН КАНЬОН',
    nameEn: 'Naryn Canyon',
    status: 'banned',
    healthScore: 22,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 2,
    lat: 41.40,
    lng: 76.38,
    boundary: [
      LatLng(41.50, 76.18),
      LatLng(41.54, 76.32),
      LatLng(41.52, 76.48),
      LatLng(41.44, 76.58),
      LatLng(41.35, 76.58),
      LatLng(41.28, 76.48),
      LatLng(41.28, 76.30),
      LatLng(41.35, 76.18),
      LatLng(41.44, 76.12),
      LatLng(41.50, 76.18),
    ],
    areaKm2: 340,
    elevation: '1400–2200 m',
    seasonNote: 'Canyon slopes severely overgrazed. Closure enforced for erosion control.',
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
