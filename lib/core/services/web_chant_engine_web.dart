import 'dart:async';
import 'dart:js_interop';

import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'chant_music_engine.dart';

ChantMusicEngine createWebChantEngine() => WebAudioChantEngine();

/// Web 版佛曲引擎：用 Web Audio API 把整首解碼成 AudioBuffer，再以
/// `AudioBufferSourceNode.loop` 循環。接縫由瀏覽器的音訊執行緒處理，沒有停頓
/// (`<audio loop>` 在部分瀏覽器的接縫仍會頓一下)。
///
/// 音檔是按下播放時才向伺服器下載 (Flutter Web 的資源檔本來就是用到才抓)，
/// 記憶體裡只保留目前這一首。
///
/// [ChantMusicEngine.playFile] 的 `path` 在 Web 上是資源鍵 (例如 `assets/audio/xxx.ogg`)。
class WebAudioChantEngine implements ChantMusicEngine {
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<void> _completeController =
      StreamController<void>.broadcast();

  web.AudioContext? _context;
  web.AudioBuffer? _buffer;
  web.AudioBufferSourceNode? _source;

  bool _looping = true;

  /// 播放中：曲目開頭對應的 `AudioContext.currentTime` (秒)
  double _startedAt = 0;

  /// 暫停 / 停止時的位置 (秒)
  double _pausedAt = 0;

  /// 每次載入加一；較早的載入解碼完成時已經過時，直接丟棄
  int _loadId = 0;

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

  web.AudioContext get _ctx => _context ??= web.AudioContext();

  @override
  Future<void> init() async {}

  @override
  Future<void> playFile(String path, {required bool looping}) async {
    final loadId = ++_loadId;
    _stopSource();
    _looping = looping;

    final data = await rootBundle.load(path);
    // decodeAudioData 會接管 (detach) 傳入的 ArrayBuffer，所以複製一份
    final bytes = Uint8List.fromList(Uint8List.sublistView(data));
    final buffer = await _ctx.decodeAudioData(bytes.buffer.toJS).toDart;
    if (loadId != _loadId) return;

    _buffer = buffer;
    if (!_durationController.isClosed) {
      _durationController.add(_seconds(buffer.duration));
    }
    await _resumeContext();
    _startAt(0);
    _setState(PlayerState.playing);
  }

  @override
  Future<void> resume() async {
    if (_buffer == null) return;
    await _resumeContext();
    if (_source == null) _startAt(_pausedAt);
    _setState(PlayerState.playing);
  }

  @override
  Future<void> pause() async {
    _pausedAt = _positionSeconds;
    _stopSource();
    _setState(PlayerState.paused);
  }

  @override
  Future<void> stop() async {
    _stopSource();
    _pausedAt = 0;
    _setState(PlayerState.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    final seconds = position.inMicroseconds / Duration.microsecondsPerSecond;
    if (_source != null) {
      _stopSource();
      _startAt(seconds);
    } else {
      _pausedAt = seconds;
    }
  }

  @override
  Future<Duration?> getPosition() async =>
      _buffer == null ? null : _seconds(_positionSeconds);

  @override
  Future<Duration?> getDuration() async {
    final buffer = _buffer;
    return buffer == null ? null : _seconds(buffer.duration);
  }

  @override
  Future<void> setLooping(bool looping) async {
    if (_looping == looping) return;
    // 先記下目前位置：從循環切成單次時，位置不能再對曲長取餘數
    final position = _positionSeconds;
    _looping = looping;
    final source = _source;
    if (source != null) {
      source.loop = looping;
      _startedAt = _ctx.currentTime - position;
    }
  }

  @override
  Future<void> dispose() async {
    _loadId++;
    _stopSource();
    await _context?.close().toDart;
    _context = null;
    await _stateController.close();
    await _durationController.close();
    await _completeController.close();
  }

  // --- 內部 ---

  /// 瀏覽器規定要使用者點擊後才能出聲；播放鍵本身就是點擊，這裡確保 context 已啟動
  Future<void> _resumeContext() async {
    if (_ctx.state == 'suspended') await _ctx.resume().toDart;
  }

  void _startAt(double offsetSeconds) {
    final buffer = _buffer;
    if (buffer == null) return;
    final offset = offsetSeconds.clamp(0.0, buffer.duration).toDouble();
    final node = _ctx.createBufferSource()
      ..buffer = buffer
      ..loop = _looping;
    node.connect(_ctx.destination);
    node.onended = ((web.Event _) => _onEnded(node)).toJS;
    node.start(0, offset);
    _source = node;
    _startedAt = _ctx.currentTime - offset;
  }

  void _onEnded(web.AudioBufferSourceNode node) {
    // 暫停 / 換曲時主動停掉的節點也會觸發 ended，只處理目前這一個自然播完的情況
    if (!identical(node, _source) || _looping) return;
    _source = null;
    _pausedAt = 0;
    // 先發 complete 再改狀態：處理器收到 complete 時才能以「仍在播放」判斷要不要接下一首
    if (!_completeController.isClosed) _completeController.add(null);
    _setState(PlayerState.completed);
  }

  void _stopSource() {
    final source = _source;
    if (source == null) return;
    _source = null;
    source.onended = null;
    try {
      source.stop();
    } catch (e) {
      debugPrint('WebAudioChantEngine: stop failed: $e');
    }
    source.disconnect();
  }

  double get _positionSeconds {
    final buffer = _buffer;
    if (buffer == null) return 0;
    if (_source == null) return _pausedAt;
    final elapsed = _ctx.currentTime - _startedAt;
    final duration = buffer.duration;
    if (duration <= 0) return 0;
    if (_looping) return elapsed % duration;
    return elapsed.clamp(0.0, duration).toDouble();
  }

  static Duration _seconds(double s) =>
      Duration(microseconds: (s * Duration.microsecondsPerSecond).round());
}
