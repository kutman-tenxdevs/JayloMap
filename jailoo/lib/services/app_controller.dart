import 'package:flutter/material.dart';
import '../models/zone.dart';

/// Lightweight cross-screen coordinator.
/// AiScreen writes pendingRouteZone & tab; MapScreen and _AppShell read them.
class AppController extends ChangeNotifier {
  int _tab = 0;
  Zone? _pendingRouteZone;

  int get tab => _tab;
  Zone? get pendingRouteZone => _pendingRouteZone;

  /// Switch to any tab by index.
  void selectTab(int index) {
    _tab = index;
    notifyListeners();
  }

  /// Switch to the map tab, optionally starting a route immediately.
  void goToMap({Zone? routeTo}) {
    _tab = 0;
    _pendingRouteZone = routeTo;
    notifyListeners();
  }

  /// Called by MapScreen once it consumes the pending route.
  void clearPendingRoute() {
    if (_pendingRouteZone == null) return;
    _pendingRouteZone = null;
    notifyListeners();
  }
}
