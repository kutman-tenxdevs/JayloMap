import '../data/zones.dart';
import '../models/zone.dart';

class ZoneService {
  // HACKATHON: returns hardcoded zones immediately
  // PRODUCTION: GET https://kyrgyzstan.sibelius-datacube.org:5000/wcs?...
  Future<List<Zone>> getZones() async {
    // Simulate slight network delay for realism in demo
    await Future.delayed(const Duration(milliseconds: 200));
    return kZones;
  }

  // Returns zones sorted by distance from user location
  List<Zone> nearestZones(double userLat, double userLng, {int limit = 3}) {
    final sorted = [...kZones];
    sorted.sort((a, b) {
      final da = _dist(userLat, userLng, a.lat, a.lng);
      final db = _dist(userLat, userLng, b.lat, b.lng);
      return da.compareTo(db);
    });
    return sorted.take(limit).toList();
  }

  double _dist(double lat1, double lng1, double lat2, double lng2) {
    return ((lat1 - lat2) * (lat1 - lat2)) + ((lng1 - lng2) * (lng1 - lng2));
  }
}
