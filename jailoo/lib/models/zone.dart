import 'package:latlong2/latlong.dart';

class Zone {
  final int id;
  final String name;
  final String nameEn;
  final String status; // 'healthy' | 'recovering' | 'banned'
  final int healthScore; // 0-100
  final int maxHerd;
  final int safeDays;
  final int lastGrazedDaysAgo;
  final double lat;
  final double lng;
  final List<LatLng> boundary;

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
  });

  LatLng get center => LatLng(lat, lng);
}
