import 'package:latlong2/latlong.dart';

class Zone {
  final int id;
  final String name;
  final String nameEn;
  final String status; // 'healthy' | 'recovering' | 'banned'
  final int healthScore;
  final int maxHerd;
  final int safeDays;
  final int lastGrazedDaysAgo;
  final double lat;
  final double lng;
  final List<LatLng> boundary;
  final double areaKm2;
  final String elevation;
  final String seasonNote;

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
    required this.boundary,
    required this.areaKm2,
    required this.elevation,
    required this.seasonNote,
  });

  LatLng get center => LatLng(lat, lng);
}
