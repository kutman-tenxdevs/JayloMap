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
