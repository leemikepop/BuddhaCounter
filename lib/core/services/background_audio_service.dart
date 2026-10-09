import 'dart:io';
import 'package:flutter/services.dart';

/// 負責與原生 Android Foreground Service 通訊之服務
/// 確保在螢幕關閉、鎖定或退至背景時，系統不凍結程序，維持佛曲無縫播放
class BackgroundAudioService {
  static const MethodChannel _channel =
      MethodChannel('com.yichung.lee.buddha_counter/foreground_service');

  /// 啟動原生前景服務並顯示念佛常駐通知
  static Future<void> start({
    required String title,
    required String chantName,
  }) async {
    try {
      if (!Platform.isAndroid) return;
      await _channel.invokeMethod('startService', {
        'title': title,
        'chant': chantName,
      });
    } catch (_) {}
  }

  /// 停止原生前景服務並釋放 WakeLock
  static Future<void> stop() async {
    try {
      if (!Platform.isAndroid) return;
      await _channel.invokeMethod('stopService');
    } catch (_) {}
  }
}

