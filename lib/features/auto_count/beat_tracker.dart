import '../../core/constants/chant_songs.dart';

/// 依佛曲播放進度判斷「又念了幾聲」(純 Dart，不碰播放器)。
///
/// - 有佛號標記 ([ChantSong.phraseMarkersMs]) 的曲目：進度跨過一個標記算一聲。
/// - 沒有標記的曲目：每 [ChantSong.effectiveBeatIntervalMs] 算一聲。
///
/// 保護機制 (都是為了不多算)：
/// - [restart] 之後，要等播放器回報的位置回到開頭附近才開始算，
///   忽略切歌前殘留的舊進度。
/// - 進度倒退 (單曲循環回到開頭) 時，從第一聲重新對齊。
/// - 進度一次跳太遠 (拖曳或延遲的推播) 時，被跳過的部分不算。
class BeatTracker {
  BeatTracker(ChantSong song) : _song = song {
    _resetToStart();
  }

  /// 播放位置在這個範圍內，才視為「已回到開頭」
  static const int restartWindowMs = 350;

  /// 標記被跳過超過這個距離就不算 (拖曳進度條造成的跳躍)
  static const int maxMarkerLagMs = 3000;

  ChantSong _song;
  int _nextBeatMs = 0;
  int _nextMarkerIndex = 0;
  int _lastPositionMs = 0;
  bool _waitingForRestart = false;

  ChantSong get song => _song;

  /// 是否還在等播放器回到開頭
  bool get isWaitingForRestart => _waitingForRestart;

  /// 從頭開始計數 (開始念、換曲目)
  void restart(ChantSong song) {
    _song = song;
    _resetToStart();
    _lastPositionMs = 0;
    _waitingForRestart = true;
  }

  /// 從指定位置接續 (暫停後繼續、拖曳進度條)：下一聲是該位置之後的第一個標記或節拍
  void alignTo(int positionMs, {ChantSong? song}) {
    if (song != null) _song = song;
    final markers = _song.phraseMarkersMs;
    final next = markers.indexWhere((m) => m > positionMs);
    _nextMarkerIndex = next == -1 ? markers.length : next;
    final interval = _song.effectiveBeatIntervalMs;
    _nextBeatMs = (positionMs ~/ interval + 1) * interval;
    _lastPositionMs = positionMs;
    _waitingForRestart = false;
  }

  /// 回報新的播放位置，回傳這次跨過幾聲；最多算到 [maxBeats] 聲 (念滿目標就停)
  int advance(int positionMs, {int? maxBeats}) {
    if (_waitingForRestart) {
      if (positionMs > restartWindowMs) return 0;
      _waitingForRestart = false;
      _resetToStart();
      _lastPositionMs = positionMs;
      return 0;
    }

    final loopedBack = positionMs < _lastPositionMs - 800 ||
        (positionMs < 250 && _lastPositionMs > 1000);
    if (loopedBack) _resetToStart();

    final limit = maxBeats ?? 1 << 30;
    final beats = _song.hasMarkers
        ? _advanceMarkers(positionMs, limit)
        : _advanceInterval(positionMs, limit);
    _lastPositionMs = positionMs;
    return beats;
  }

  int _advanceMarkers(int positionMs, int limit) {
    final markers = _song.phraseMarkersMs;
    var beats = 0;
    while (beats < limit &&
        _nextMarkerIndex < markers.length &&
        positionMs >= markers[_nextMarkerIndex]) {
      if (positionMs - markers[_nextMarkerIndex] <= maxMarkerLagMs) beats++;
      _nextMarkerIndex++;
    }
    return beats;
  }

  int _advanceInterval(int positionMs, int limit) {
    if (positionMs < _nextBeatMs) return 0;
    final interval = _song.effectiveBeatIntervalMs;
    if ((positionMs - _nextBeatMs) ~/ interval > 1) {
      // 一次跳太遠：對齊到下一拍，跳過的時間不算
      _nextBeatMs = (positionMs ~/ interval + 1) * interval;
      return 0;
    }
    var beats = 0;
    while (beats < limit && positionMs >= _nextBeatMs) {
      beats++;
      _nextBeatMs += interval;
    }
    return beats;
  }

  void _resetToStart() {
    _nextBeatMs = _song.effectiveBeatIntervalMs;
    _nextMarkerIndex = 0;
  }
}
