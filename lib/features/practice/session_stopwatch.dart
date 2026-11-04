import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/utils/time_format.dart';

/// 手動計數頁上方的禪修碼表 (不保存，App 重開即歸零)
class SessionStopwatch extends ChangeNotifier {
  Timer? _timer;
  int _elapsedSeconds = 0;

  bool get isRunning => _timer != null;
  int get elapsedSeconds => _elapsedSeconds;
  String get formatted => formatHms(_elapsedSeconds);

  void start() {
    if (isRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void toggle() => isRunning ? stop() : start();

  void reset() {
    _timer?.cancel();
    _timer = null;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
