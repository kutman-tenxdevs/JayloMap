import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../data/zones.dart';
import '../widgets/zone_marker.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
    final pos = await Geolocator.getCurrentPosition();
    setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(41.5, 75.6),
              initialZoom: 7.5,
              minZoom: 6,
              maxZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.jailoo.app',
              ),
              MarkerLayer(
                markers: [
                  // Zone markers
                  ...kZones.map((zone) => Marker(
                    point: LatLng(zone.lat, zone.lng),
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(zone: zone),
                        ),
                      ),
                      child: ZoneMarker(zone: zone),
                    ),
                  )),
                  // User GPS dot
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2ECC71),
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x882ECC71),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'НАРЫН',
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 22,
                      color: Color(0xFF2ECC71),
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    'Naryn Oblast · ${kZones.length} зон',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A9A7A),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Legend bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEE0D1A0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332ECC71)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(color: Color(0xFF2ECC71), label: 'Безопасно'),
          _LegendItem(color: Color(0xFFF4D03F), label: 'Восстановление'),
          _LegendItem(color: Color(0xFFE74C3C), label: 'Запрет'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7A9A7A), letterSpacing: 0.5)),
      ],
    );
  }
}
