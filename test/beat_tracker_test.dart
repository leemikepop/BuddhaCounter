import 'package:buddha_counter/core/constants/chant_songs.dart';
import 'package:buddha_counter/features/auto_count/beat_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

/// 自動計數的節拍判斷 (純 Dart，不需要播放器)
void main() {
  const fixed = ChantSong(
    id: 0,
    title: 'fixed',
    assetPath: 'a.ogg',
    phraseMarkersMs: [],
    beatIntervalMs: 1000,
  );
  const marked = ChantSong(
    id: 1,
    title: 'marked',
    assetPath: 'b.ogg',
    phraseMarkersMs: [1000, 2500, 4000, 10000],
  );

  /// 已從頭開始並對齊開頭 (等待結束) 的追蹤器
  BeatTracker startedAtZero(ChantSong song) {
    final t = BeatTracker(song)..restart(song);
    expect(t.advance(0), 0);
    return t;
  }

  group('restart', () {
    test('ignores stale positions until the player is back near the start', () {
      final t = BeatTracker(fixed)..restart(fixed);
      expect(t.isWaitingForRestart, isTrue);

      // 舊曲目殘留的進度推播不能被當成「念了好幾聲」
      expect(t.advance(5000), 0);
      expect(t.isWaitingForRestart, isTrue);

      expect(t.advance(200), 0);
      expect(t.isWaitingForRestart, isFalse);
      expect(t.advance(1000), 1);
    });
  });

  group('fixed beat interval', () {
    test('counts one beat per interval', () {
      final t = startedAtZero(fixed);
      expect(t.advance(500), 0);
      expect(t.advance(1000), 1);
      expect(t.advance(1900), 0);
      expect(t.advance(2100), 1);
    });

    test('a late update that skips one beat still counts both', () {
      final t = startedAtZero(fixed);
      expect(t.advance(2000), 2);
    });

    test('a big jump realigns without counting the skipped time', () {
      final t = startedAtZero(fixed);
      expect(t.advance(8500), 0);
      expect(t.advance(9000), 1);
    });
  });

  group('phrase markers', () {
    test('each marker counts once when playback passes it', () {
      final t = startedAtZero(marked);
      expect(t.advance(900), 0);
      expect(t.advance(1000), 1);
      expect(t.advance(1200), 0);
      expect(t.advance(4100), 2);
    });

    test('markers jumped over by more than 3 seconds are skipped', () {
      final t = startedAtZero(marked);
      expect(t.advance(1000), 1);
      // 從 1 秒直接跳到 9 秒：2.5 秒與 4 秒的標記離目前位置超過 3 秒，不算
      expect(t.advance(9000), 0);
      expect(t.advance(10000), 1);
    });

    test('looping back to the start resets to the first marker', () {
      final t = startedAtZero(marked);
      expect(t.advance(1000), 1);
      expect(t.advance(4000), 2);
      expect(t.advance(10000), 1);
      // 單曲循環回到開頭
      expect(t.advance(100), 0);
      expect(t.advance(1000), 1);
    });
  });

  group('maxBeats', () {
    test('stops counting once the limit is reached', () {
      final t = startedAtZero(marked);
      expect(t.advance(4000, maxBeats: 2), 2);
      expect(t.advance(4000, maxBeats: 0), 0);
    });
  });

  group('alignTo', () {
    test('resuming mid-song waits for the next marker after the position', () {
      final t = BeatTracker(marked)..alignTo(3000);
      expect(t.isWaitingForRestart, isFalse);
      expect(t.advance(3500), 0);
      expect(t.advance(4000), 1);
    });

    test('resuming mid-song on a fixed interval waits for the next beat', () {
      final t = BeatTracker(fixed)..alignTo(2300);
      expect(t.advance(2900), 0);
      expect(t.advance(3000), 1);
    });

    test('seeking cancels a pending restart wait', () {
      final t = BeatTracker(fixed)..restart(fixed);
      t.alignTo(25000);
      expect(t.isWaitingForRestart, isFalse);
      expect(t.advance(25500), 0);
      expect(t.advance(26000), 1);
    });
  });
}
