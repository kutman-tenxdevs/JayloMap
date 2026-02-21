import 'package:flutter/material.dart';

class HerderProfile extends ChangeNotifier {
  String name = 'Алимбек';
  String region = 'Naryn Oblast';

  // Livestock counts
  int sheep = 40;
  int goats = 15;
  int horses = 3;
  int cattle = 0;

  int get total => sheep + goats + horses + cattle;

  // Conventional "sheep unit" equivalents for zone capacity comparison:
  //   1 horse = 6 sheep units, 1 cattle = 7, 1 goat = 0.8
  int get sheepUnits =>
      sheep + (goats * 0.8).round() + horses * 6 + cattle * 7;

  void increment(String animal) {
    switch (animal) {
      case 'sheep':  sheep++;  break;
      case 'goats':  goats++;  break;
      case 'horses': horses++; break;
      case 'cattle': cattle++; break;
    }
    notifyListeners();
  }

  void decrement(String animal) {
    switch (animal) {
      case 'sheep':  if (sheep  > 0) sheep--;  break;
      case 'goats':  if (goats  > 0) goats--;  break;
      case 'horses': if (horses > 0) horses--; break;
      case 'cattle': if (cattle > 0) cattle--; break;
    }
    notifyListeners();
  }

  void set(String animal, int value) {
    final v = value.clamp(0, 9999);
    switch (animal) {
      case 'sheep':  sheep  = v; break;
      case 'goats':  goats  = v; break;
      case 'horses': horses = v; break;
      case 'cattle': cattle = v; break;
    }
    notifyListeners();
  }
}
