import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../data/zones.dart';
import '../models/zone.dart';
import '../services/app_controller.dart';
import '../theme/colors.dart';

// ---------------------------------------------------------------------------
// Global user-added pastures list (runtime only; use a DB in production)
// ---------------------------------------------------------------------------
final List<_UserPasture> kUserPastures = [];

class _UserPasture {
  final String name;
  final List<LatLng> corners; // always 4 points
  const _UserPasture({required this.name, required this.corners});
}

// ---------------------------------------------------------------------------

class AddPastureScreen extends StatefulWidget {
  const AddPastureScreen({super.key});

  @override
  State<AddPastureScreen> createState() => _AddPastureScreenState();
}

class _AddPastureScreenState extends State<AddPastureScreen> {
  final _mapController = MapController();
  final _nameController = TextEditingController();

  bool _mapReady = false;
  bool _isDragging = false; // while dragging a corner — disable map pan

  // Default rectangle placed around a central view point
  static const _center = LatLng(41.42, 75.88);
  static const _delta = 0.03; // ~3 km half-size

  // 4 corners: NW, NE, SE, SW
  late final List<LatLng> _corners = [
    LatLng(_center.latitude + _delta, _center.longitude - _delta),
    LatLng(_center.latitude + _delta, _center.longitude + _delta),
    LatLng(_center.latitude - _delta, _center.longitude + _delta),
    LatLng(_center.latitude - _delta, _center.longitude - _delta),
  ];

  // Index of corner being dragged (-1 = none)
  int _draggingIndex = -1;
  // Screen point of the corner at drag start (for accuracy)
  math.Point<double>? _dragStartScreen;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название пастбища')),
      );
      return;
    }
    kUserPastures.add(_UserPasture(name: name, corners: List.of(_corners)));
    // Pop back to the shell and switch to the Map tab
    context.read<AppController>().goToMap();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts a screen point (within map widget) to LatLng.
  LatLng _screenToLatLng(math.Point<double> pt) =>
      _mapController.camera.pointToLatLng(pt);

  /// Returns all polygons to draw: existing kZones + user pastures + current draft.
  List<Polygon> _buildPolygons(JailooColors c) {
    final list = <Polygon>[];

    // Existing shared zones (read-only display)
    for (final z in kZones) {
      final color = JailooColors.statusColor(z.status);
      list.add(Polygon(
        points: z.boundary,
        color: color.withValues(alpha: 0.10),
        borderColor: color.withValues(alpha: 0.45),
        borderStrokeWidth: 1.4,
      ));
    }

    // Previously saved user pastures
    for (final p in kUserPastures) {
      list.add(Polygon(
        points: [...p.corners, p.corners.first],
        color: const Color(0xFF6366F1).withValues(alpha: 0.18),
        borderColor: const Color(0xFF6366F1).withValues(alpha: 0.7),
        borderStrokeWidth: 2,
      ));
    }

    // Current draft rectangle
    list.add(Polygon(
      points: [..._corners, _corners.first],
      color: c.accent.withValues(alpha: 0.18),
      borderColor: c.accent,
      borderStrokeWidth: 2.5,
    ));

    return list;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Map area ──────────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 10.5,
                    minZoom: 7,
                    maxZoom: 18,
                    interactionOptions: InteractionOptions(
                      flags: _isDragging
                          ? InteractiveFlag.none
                          : InteractiveFlag.all,
                    ),
                    onMapReady: () => setState(() => _mapReady = true),
                  ),
                  children: [
                    // Tile layer
                    TileLayer(
                      urlTemplate: isDark
                          ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.jailoo',
                    ),

                    // Polygons
                    if (_mapReady)
                      PolygonLayer(polygons: _buildPolygons(c)),

                    // Corner drag handles
                    if (_mapReady)
                      MarkerLayer(
                        markers: List.generate(_corners.length, (i) {
                          return Marker(
                            point: _corners[i],
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                setState(() {
                                  _isDragging = true;
                                  _draggingIndex = i;
                                  _dragStartScreen = _mapController.camera
                                      .latLngToScreenPoint(_corners[i]);
                                });
                              },
                              onPanUpdate: (details) {
                                if (_draggingIndex != i) return;
                                // Get current screen position of this corner
                                final currentScreen = _mapController.camera
                                    .latLngToScreenPoint(_corners[i]);
                                final newScreen = math.Point(
                                  currentScreen.x + details.delta.dx,
                                  currentScreen.y + details.delta.dy,
                                );
                                setState(() {
                                  _corners[i] = _screenToLatLng(newScreen);
                                });
                              },
                              onPanEnd: (details) {
                                setState(() {
                                  _isDragging = false;
                                  _draggingIndex = -1;
                                  _dragStartScreen = null;
                                });
                              },
                              child: _CornerHandle(
                                isActive: _draggingIndex == i,
                                c: c,
                              ),
                            ),
                          );
                        }),
                      ),

                    // Center handle (moves whole zone)
                    if (_mapReady)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _centroid(),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                setState(() => _isDragging = true);
                              },
                              onPanUpdate: (details) {
                                // Move all 4 corners by the same delta
                                setState(() {
                                  for (int j = 0; j < 4; j++) {
                                    final s = _mapController.camera
                                        .latLngToScreenPoint(_corners[j]);
                                    final ns = math.Point(
                                      s.x + details.delta.dx,
                                      s.y + details.delta.dy,
                                    );
                                    _corners[j] = _screenToLatLng(ns);
                                  }
                                });
                              },
                              onPanEnd: (details) {
                                setState(() => _isDragging = false);
                              },
                              child: _CenterHandle(c: c),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Back button ───────────────────────────────────────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: c.surface.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.border),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: c.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: c.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.border),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            'Новое пастбище',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 13,
                              fontFamily: 'DMMono',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Hint label ────────────────────────────────────────────
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        'Тяните углы ◆ или по центру ✛ для перемещения',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 10,
                          fontFamily: 'DMMono',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom panel ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(top: BorderSide(color: c.border)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info row
                Row(
                  children: [
                    _InfoChip(
                      c: c,
                      icon: Icons.square_foot,
                      label: '≈ ${_areaHa().toStringAsFixed(0)} га',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      c: c,
                      icon: Icons.my_location,
                      label: '${_centroid().latitude.toStringAsFixed(3)}°, '
                          '${_centroid().longitude.toStringAsFixed(3)}°',
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Name input
                TextField(
                  controller: _nameController,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontFamily: 'DMMono',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Название пастбища…',
                    hintStyle: TextStyle(
                      color: c.textMuted,
                      fontFamily: 'DMMono',
                    ),
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 12),

                // Save button
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Сохранить пастбище',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'DMMono',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Geometry helpers ──────────────────────────────────────────────────────

  LatLng _centroid() {
    final lat = _corners.map((c) => c.latitude).reduce((a, b) => a + b) / 4;
    final lng = _corners.map((c) => c.longitude).reduce((a, b) => a + b) / 4;
    return LatLng(lat, lng);
  }

  /// Rough area in hectares using shoelace formula on lat/lng→metres conversion.
  double _areaHa() {
    const latM = 111320.0; // metres per degree latitude
    final pts = _corners
        .map((c) => [c.latitude * latM, c.longitude * latM * math.cos(c.latitude * math.pi / 180)])
        .toList();
    double area = 0;
    for (int i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      area += (pts[j][0] + pts[i][0]) * (pts[j][1] - pts[i][1]);
    }
    return (area / 2).abs() / 10000;
  }
}

// ---------------------------------------------------------------------------
// Handle widgets
// ---------------------------------------------------------------------------

class _CornerHandle extends StatelessWidget {
  final bool isActive;
  final JailooColors c;
  const _CornerHandle({required this.isActive, required this.c});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: isActive ? 24 : 18,
        height: isActive ? 24 : 18,
        decoration: BoxDecoration(
          color: isActive ? c.accent : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: c.accent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: c.accent.withValues(alpha: isActive ? 0.45 : 0.25),
              blurRadius: isActive ? 10 : 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterHandle extends StatelessWidget {
  final JailooColors c;
  const _CenterHandle({required this.c});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(color: c.accent, width: 2),
        ),
        child: Icon(Icons.open_with, color: c.accent, size: 16),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final JailooColors c;
  final IconData icon;
  final String label;
  const _InfoChip({required this.c, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: c.textMuted,
              fontSize: 11,
              fontFamily: 'DMMono',
            ),
          ),
        ],
      ),
    );
  }
}
