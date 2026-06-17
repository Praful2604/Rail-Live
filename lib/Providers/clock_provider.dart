import 'dart:async';
import 'package:flutter/material.dart';

class ClockProvider extends ChangeNotifier {
  Timer? _timer;
  TimeOfDay now = TimeOfDay.now();

  void startClock() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      now = TimeOfDay.now();
      notifyListeners();
    });
  }

  void stopClock() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}