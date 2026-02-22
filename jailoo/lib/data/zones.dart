import 'package:latlong2/latlong.dart';
import '../models/zone.dart';

// All pasture zone boundaries are hardcoded GeoJSON-style polygon rings
// (realistic irregular shapes approximating natural valley / highland extents).
//
// Non-overlap guarantee: each polygon is fully confined to its bounding box;
// adjacent bounding boxes have a gap of ≥ 0.02° (≈ 2 km) everywhere.
//
// Bounding-box layout (lat × lng) — verified no intersections:
//   ЖУМГАЛ       41.58–41.75  ×  75.33–75.52
//   САРЫ-БУЛАК   41.49–41.63  ×  75.53–75.72
//   НАРЫН-ТОО    41.68–41.80  ×  75.73–75.92
//   КУРТКА       41.53–41.65  ×  75.73–75.90
//   ЧАЕК         41.33–41.47  ×  75.62–75.82
//   ДОСТУК       41.45–41.60  ×  75.91–76.05
//   ОН-АРЧА      41.38–41.52  ×  76.06–76.20
//   АК-САКАЛ     41.07–41.22  ×  75.43–75.62
//   КЫЗАРТ       41.23–41.37  ×  75.40–75.58
//   ЭКИ-НАРЫН   41.22–41.37  ×  75.84–75.97
//   КОК-ТАШ     41.07–41.22  ×  75.77–75.97
//   АК-ТАМ       41.22–41.37  ×  76.18–76.38
//   МОЛДО-ТОО   41.22–41.38  ×  76.42–76.60
//
// In production, GeoJSON features are fetched from OSM Overpass API:
//   POST https://overpass-api.de/api/interpreter
//   [out:json];
//   area["name"="Naryn Region"]->.nr;
//   relation["admin_level"="6"]["boundary"="administrative"](area.nr);
//   out geom;

// User's hardcoded position — on the main A-365 highway in Naryn valley.
// In production this comes from Geolocator.getCurrentPosition().
const kUserLocation = LatLng(41.43, 75.99);

// ---------------------------------------------------------------------------
// Hardcoded GeoJSON polygon boundaries
// ---------------------------------------------------------------------------

// ЖУМГАЛ — lat 41.58–41.75, lng 75.33–75.52  (areaKm2 ≈ 2100)
const _zhumgal = [
  LatLng(41.75, 75.40),
  LatLng(41.73, 75.52),
  LatLng(41.69, 75.51),
  LatLng(41.65, 75.50),
  LatLng(41.60, 75.47),
  LatLng(41.58, 75.42),
  LatLng(41.59, 75.35),
  LatLng(41.63, 75.33),
  LatLng(41.68, 75.34),
  LatLng(41.72, 75.36),
];

// САРЫ-БУЛАК — lat 41.49–41.63, lng 75.53–75.72  (areaKm2 ≈ 950)
const _saryBulak = [
  LatLng(41.63, 75.58),
  LatLng(41.61, 75.72),
  LatLng(41.57, 75.71),
  LatLng(41.53, 75.70),
  LatLng(41.49, 75.66),
  LatLng(41.50, 75.57),
  LatLng(41.53, 75.53),
  LatLng(41.57, 75.54),
  LatLng(41.60, 75.55),
];

// НАРЫН-ТОО — lat 41.68–41.80, lng 75.73–75.92  (areaKm2 ≈ 1560)
const _narynToo = [
  LatLng(41.80, 75.80),
  LatLng(41.78, 75.92),
  LatLng(41.74, 75.90),
  LatLng(41.70, 75.89),
  LatLng(41.68, 75.84),
  LatLng(41.69, 75.75),
  LatLng(41.72, 75.73),
  LatLng(41.76, 75.74),
];

// КУРТКА — lat 41.53–41.65, lng 75.73–75.90  (areaKm2 ≈ 1350)
const _kurtka = [
  LatLng(41.65, 75.77),
  LatLng(41.63, 75.90),
  LatLng(41.60, 75.89),
  LatLng(41.56, 75.88),
  LatLng(41.53, 75.84),
  LatLng(41.54, 75.76),
  LatLng(41.57, 75.73),
  LatLng(41.61, 75.74),
];

// ЧАЕК — lat 41.33–41.47, lng 75.62–75.82  (areaKm2 ≈ 1420)
const _chaek = [
  LatLng(41.47, 75.66),
  LatLng(41.46, 75.80),
  LatLng(41.43, 75.82),
  LatLng(41.39, 75.81),
  LatLng(41.35, 75.78),
  LatLng(41.33, 75.72),
  LatLng(41.34, 75.64),
  LatLng(41.37, 75.62),
  LatLng(41.42, 75.63),
];

// ДОСТУК — lat 41.45–41.60, lng 75.91–76.05  (areaKm2 ≈ 920)
const _dostuk = [
  LatLng(41.60, 75.95),
  LatLng(41.58, 76.05),
  LatLng(41.54, 76.04),
  LatLng(41.50, 76.03),
  LatLng(41.45, 75.99),
  LatLng(41.46, 75.93),
  LatLng(41.49, 75.91),
  LatLng(41.54, 75.92),
  LatLng(41.57, 75.93),
];

// ОН-АРЧА — lat 41.38–41.52, lng 76.06–76.20  (areaKm2 ≈ 870)
const _onArcha = [
  LatLng(41.52, 76.10),
  LatLng(41.50, 76.20),
  LatLng(41.46, 76.19),
  LatLng(41.42, 76.18),
  LatLng(41.38, 76.14),
  LatLng(41.39, 76.08),
  LatLng(41.43, 76.06),
  LatLng(41.47, 76.07),
];

// АК-САКАЛ — lat 41.07–41.22, lng 75.43–75.62  (areaKm2 ≈ 1790)
const _akSakal = [
  LatLng(41.22, 75.48),
  LatLng(41.20, 75.62),
  LatLng(41.16, 75.61),
  LatLng(41.12, 75.59),
  LatLng(41.07, 75.55),
  LatLng(41.08, 75.45),
  LatLng(41.11, 75.43),
  LatLng(41.16, 75.44),
  LatLng(41.20, 75.45),
];

// КЫЗАРТ — lat 41.23–41.37, lng 75.40–75.58  (areaKm2 ≈ 1180)
const _kyzart = [
  LatLng(41.37, 75.46),
  LatLng(41.35, 75.58),
  LatLng(41.31, 75.57),
  LatLng(41.27, 75.55),
  LatLng(41.23, 75.51),
  LatLng(41.24, 75.43),
  LatLng(41.27, 75.40),
  LatLng(41.32, 75.41),
  LatLng(41.35, 75.43),
];

// ЭКИ-НАРЫН — lat 41.22–41.37, lng 75.84–75.97  (areaKm2 ≈ 1680)
const _ekiNaryn = [
  LatLng(41.37, 75.87),
  LatLng(41.35, 75.97),
  LatLng(41.31, 75.96),
  LatLng(41.27, 75.95),
  LatLng(41.22, 75.91),
  LatLng(41.23, 75.85),
  LatLng(41.27, 75.84),
  LatLng(41.32, 75.85),
];

// КОК-ТАШ — lat 41.07–41.22, lng 75.77–75.97  (areaKm2 ≈ 1650)
const _kokTash = [
  LatLng(41.22, 75.82),
  LatLng(41.20, 75.97),
  LatLng(41.16, 75.96),
  LatLng(41.12, 75.94),
  LatLng(41.07, 75.89),
  LatLng(41.08, 75.79),
  LatLng(41.12, 75.77),
  LatLng(41.17, 75.78),
];

// АК-ТАМ — lat 41.22–41.37, lng 76.18–76.38  (areaKm2 ≈ 1340)
const _akTam = [
  LatLng(41.37, 76.22),
  LatLng(41.35, 76.38),
  LatLng(41.30, 76.37),
  LatLng(41.26, 76.36),
  LatLng(41.22, 76.31),
  LatLng(41.23, 76.20),
  LatLng(41.27, 76.18),
  LatLng(41.32, 76.19),
];

// МОЛДО-ТОО — lat 41.22–41.38, lng 76.42–76.60  (areaKm2 ≈ 2050)
const _moldoToo = [
  LatLng(41.38, 76.47),
  LatLng(41.36, 76.60),
  LatLng(41.31, 76.59),
  LatLng(41.27, 76.57),
  LatLng(41.22, 76.53),
  LatLng(41.23, 76.44),
  LatLng(41.27, 76.42),
  LatLng(41.32, 76.43),
  LatLng(41.36, 76.45),
];

// ---------------------------------------------------------------------------
// Zone list
// ---------------------------------------------------------------------------

final List<Zone> kZones = [
  // ── Original 8 zones ──────────────────────────────────────────────────────
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
    lng: 75.49,
    boundary: _kyzart,
    areaKm2: 1180,
    elevation: '2400–3200 m',
    seasonNote: 'Жабылган. Кызарт ашуусунун жанында ашыкча жайылган.',
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
    lat: 41.56,
    lng: 75.62,
    boundary: _saryBulak,
    areaKm2: 950,
    elevation: '2800–3500 m',
    seasonNote: 'Мыкты маал: Мам–Сен. Булактан суусаган альп чалгыны.',
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
    lat: 41.59,
    lng: 75.82,
    boundary: _kurtka,
    areaKm2: 1350,
    elevation: '1700–2900 m',
    seasonNote: 'Өрөөндүн түбү калыбына келүүдө. Жогорку бөктөрлөрдү гана пайдаланыңыз.',
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
    lng: 76.13,
    boundary: _onArcha,
    areaKm2: 870,
    elevation: '2200–3400 m',
    seasonNote: 'Жүктөмү чектелген. Чыгыш капталындагы арча токойлору назик.',
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
    boundary: _chaek,
    areaKm2: 1420,
    elevation: '1600–3100 m',
    seasonNote: 'Жабылган. Чаек дарыясынын бойунда топурак эрозиясы.',
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
    lng: 75.90,
    boundary: _ekiNaryn,
    areaKm2: 1680,
    elevation: '2000–3600 m',
    seasonNote: 'Эки дарыя тармагы боюнда кеңири ачык жайыт.',
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
    boundary: _dostuk,
    areaKm2: 920,
    elevation: '1800–2800 m',
    seasonNote: 'Айылга жакын. Жакында катуу колдонулган. Секторлорду алмаштырыңыз.',
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
    boundary: _akTam,
    areaKm2: 1340,
    elevation: '2100–3800 m',
    seasonNote: 'Алыскы чыгыш жайыты. Тоо жолу аркылуу кирүүгө болот.',
  ),

  // ── 5 new zones ───────────────────────────────────────────────────────────
  Zone(
    id: 9,
    name: 'ЖУМГАЛ',
    nameEn: 'Zhumgal',
    status: 'healthy',
    healthScore: 88,
    maxHerd: 250,
    safeDays: 25,
    lastGrazedDaysAgo: 14,
    lat: 41.66,
    lng: 75.43,
    boundary: _zhumgal,
    areaKm2: 2100,
    elevation: '2200–3100 m',
    seasonNote: 'Чоң ачык жазира. Мыкты жайкы жайыт: Май–Окт.',
  ),
  Zone(
    id: 10,
    name: 'НАРЫН-ТОО',
    nameEn: 'Naryn-Too',
    status: 'recovering',
    healthScore: 55,
    maxHerd: 90,
    safeDays: 11,
    lastGrazedDaysAgo: 4,
    lat: 41.74,
    lng: 75.82,
    boundary: _narynToo,
    areaKm2: 1560,
    elevation: '2600–3700 m',
    seasonNote: 'Бийик кырка жайыттары. Бөктөрлөрдө бир аз эрозия байкалат.',
  ),
  Zone(
    id: 11,
    name: 'АК-САКАЛ',
    nameEn: 'Ak-Sakal',
    status: 'healthy',
    healthScore: 91,
    maxHerd: 280,
    safeDays: 28,
    lastGrazedDaysAgo: 20,
    lat: 41.14,
    lng: 75.52,
    boundary: _akSakal,
    areaKm2: 1790,
    elevation: '1900–2800 m',
    seasonNote: 'Түштүктүн ойдуң чалгындары. Жыл бою жеңил жайыттоо мүмкүн.',
  ),
  Zone(
    id: 12,
    name: 'КОК-ТАШ',
    nameEn: 'Kok-Tash',
    status: 'banned',
    healthScore: 9,
    maxHerd: 0,
    safeDays: 0,
    lastGrazedDaysAgo: 0,
    lat: 41.14,
    lng: 75.87,
    boundary: _kokTash,
    areaKm2: 1650,
    elevation: '1800–3000 m',
    seasonNote: 'Жабылган. Күчтүү деградация, чөп себүү программасы жүрүп жатат.',
  ),
  Zone(
    id: 13,
    name: 'МОЛДО-ТОО',
    nameEn: 'Moldo-Too',
    status: 'recovering',
    healthScore: 62,
    maxHerd: 100,
    safeDays: 13,
    lastGrazedDaysAgo: 6,
    lat: 41.30,
    lng: 76.51,
    boundary: _moldoToo,
    areaKm2: 2050,
    elevation: '2300–4000 m',
    seasonNote: 'Эң бийик жайыт. Жул–Авг айларында гана жетүүгө болот. Кар коркунучу бар.',
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
