import 'dart:async';

import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'chant_music_engine.dart';

/// iOS 佛曲引擎：橋接到 Runner 內的原生 ChantLoopPlayer (ios/Runner/ChantLoopPlayer.swift)。
///
/// 為什麼不用 audioplayers：它要等播完、通知 Dart、再由 Dart 叫播放器重新開始，
/// 這一來一回加上播放器冷啟動，每次重播都會停頓。原生端用 AVPlayerLooper 預先排好下一遍，
/// 接縫完全不經過 Dart。
class IosLoopChantEngine implements ChantMusicEngine {
  static const MethodChannel methodChannel =
      MethodChannel('buddha_counter/chant_loop_player');
  static const EventChannel eventChannel =
      EventChannel('buddha_counter/chant_loop_player/events');

  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<void> _completeController =
      StreamController<void>.broadcast();
  StreamSubscription<dynamic>? _eventSubscription;

  PlayerState _state = PlayerState.stopped;

  @override
  Stream<PlayerState> get onStateChanged => _stateController.stream;

  @override
  Stream<Duration> get onDurationChanged => _durationController.stream;

  @override
  Stream<void> get onComplete => _completeController.stream;

  @override
  PlayerState get state => _state;

  void _setState(PlayerState next) {
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  @override
  Future<void> init() async {
    _eventSubscription ??= eventChannel
        .receiveBroadcastStream()
        .listen(_onNativeEvent, onError: (Object e) {
      debugPrint('IosLoopChantEngine: native event error: $e');
    });
  }

  void _onNativeEvent(dynamic event) {
    if (event is! Map) return;
    switch (event['event']) {
      case 'complete':
        // 先發 complete 再改狀態：處理器收到 complete 時才能以「仍在播放」判斷要不要接下一首
        if (!_completeController.isClosed) _completeController.add(null);
        _setState(PlayerState.completed);
      case 'log':
        debugPrint('ChantLoopPlayer: ${event['message']}');
    }
  }

  @override
  Future<void> playFile(String path, {required bool looping}) async {
    final ms = await methodChannel.invokeMethod<int>('load', {
      'path': path,
      'mimeType': 'audio/ogg',
      'looping': looping,
    });
    if (ms != null && ms > 0 && !_durationController.isClosed) {
      _durationController.add(Duration(milliseconds: ms));
    }
    await methodChannel.invokeMethod<void>('play');
    _setState(PlayerState.playing);
  }

  @override
  Future<void> resume() async {
    await methodChannel.invokeMethod<void>('play');
    _setState(PlayerState.playing);
  }

  @override
  Future<void> pause() async {
    await methodChannel.invokeMethod<void>('pause');
    _setState(PlayerState.paused);
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<void>('stop');
    _setState(PlayerState.stopped);
  }

  @override
  Future<void> seek(Duration position) => methodChannel
      .invokeMethod<void>('seek', {'positionMs': position.inMilliseconds});

  @override
  Future<Duration?> getPosition() => _millis('getPosition');

  @override
  Future<Duration?> getDuration() => _millis('getDuration');

  Future<Duration?> _millis(String method) async {
    final ms = await methodChannel.invokeMethod<int>(method);
    return ms == null ? null : Duration(milliseconds: ms);
  }

  @override
  Future<void> setLooping(bool looping) =>
      methodChannel.invokeMethod<void>('setLooping', {'looping': looping});

  @override
  Future<void> dispose() async {
    await methodChannel.invokeMethod<void>('dispose').catchError((_) {});
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _stateController.close();
    await _durationController.close();
    await _completeController.close();
  }
}
