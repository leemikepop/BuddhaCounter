import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:buddha_counter/core/constants/chant_songs.dart';
import 'package:buddha_counter/core/platform/app_platform.dart';
import 'package:buddha_counter/core/services/chant_audio_handler.dart';
import 'package:buddha_counter/core/services/chant_music_engine.dart';
import 'package:buddha_counter/core/services/native_loop_chant_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 佛曲播放引擎：iOS 與 Android 都走原生 ChantLoopPlayer 通道
/// (無縫循環，不靠 Dart 在播完後重新開始，也不用 MediaPlayer 自己會停頓的 setLooping)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final loopCalls = <MethodCall>[];
  final audioplayersCalls = <MethodCall>[];
  MockStreamHandlerEventSink? loopEvents;

  setUpAll(() {
    AudioPlayer.preparationTimeout = const Duration(milliseconds: 10);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        audioplayersCalls.add(call);
        final playerId = call.arguments?['playerId'];
        if (playerId != null && call.method == 'setSourceUrl') {
          messenger.handlePlatformMessage(
            'xyz.luan/audioplayers/events/$playerId',
            const StandardMethodCodec().encodeSuccessEnvelope(
                {'event': 'audio.onPrepared', 'value': true}),
            (_) {},
          );
        }
        return 1;
      },
    );
    messenger.setMockMethodCallHandler(NativeLoopChantEngine.methodChannel,
        (call) async {
      loopCalls.add(call);
      switch (call.method) {
        case 'load':
          return 62144;
        case 'getDuration':
          return 62144;
        case 'getPosition':
          return 0;
      }
      return null;
    });
    messenger.setMockStreamHandler(
      NativeLoopChantEngine.eventChannel,
      MockStreamHandler.inline(
        onListen: (_, sink) => loopEvents = sink,
        onCancel: (_) => loopEvents = null,
      ),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_service.client.methods'),
      (call) async => {},
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  setUp(() {
    loopCalls.clear();
    audioplayersCalls.clear();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Iterable<MethodCall> loopCallsNamed(String method) =>
      loopCalls.where((c) => c.method == method);

  Iterable<String> chantPlayerIds() => audioplayersCalls
      .map((c) => (c.arguments as Map?)?['playerId'] as String?)
      .whereType<String>()
      .where((id) => id.startsWith('chant_'))
      .toSet();

  group('iOS', () {
    late ChantAudioHandler handler;

    setUp(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      handler = ChantAudioHandler();
      await pumpEventQueue(times: 50);
    });

    tearDown(() async {
      await handler.disposePlayer();
    });

    test('loop mode loads the song into the native looper and plays it',
        () async {
      await handler.playSong(0);

      final load = loopCallsNamed('load').single;
      final args = Map<String, dynamic>.from(load.arguments as Map);
      expect(args['looping'], isTrue);
      expect(args['path'], endsWith('song_0.ogg'));
      expect(loopCallsNamed('play'), isNotEmpty);
      // 佛曲不得再經過 audioplayers (舊的雙播放器接力就是重播停頓的來源)
      expect(chantPlayerIds(), isEmpty);
      expect(handler.currentDuration, const Duration(milliseconds: 62144));
    });

    test('switching to list mode turns native looping off', () async {
      await handler.playSong(0);
      await handler.setReleaseMode(ReleaseMode.stop);

      final args = Map<String, dynamic>.from(
          loopCallsNamed('setLooping').last.arguments as Map);
      expect(args['looping'], isFalse);
    });

    test('in list mode a native completion advances to the next song',
        () async {
      await handler.setReleaseMode(ReleaseMode.stop);
      await handler.playSong(0);
      loopCalls.clear();

      loopEvents!.success({'event': 'complete'});
      // 下一首要從資產解出音檔 (真實檔案 I/O)，等到原生 load 被呼叫為止
      for (var i = 0; i < 200 && loopCallsNamed('load').isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      final args = Map<String, dynamic>.from(
          loopCallsNamed('load').single.arguments as Map);
      expect(args['path'], endsWith('song_1.ogg'));
      expect(args['looping'], isFalse);
      expect(handler.currentSongId, 1);
    });

    test('pause, resume and seek go to the native player', () async {
      await handler.playSong(0);
      loopCalls.clear();

      await handler.pause();
      await handler.play();
      await handler.seek(const Duration(seconds: 3));

      expect(loopCalls.map((c) => c.method),
          containsAllInOrder(['pause', 'play', 'seek']));
      expect(loopCallsNamed('load'), isEmpty,
          reason: 'resuming a paused song must not reload it');
      final seekArgs = Map<String, dynamic>.from(
          loopCallsNamed('seek').single.arguments as Map);
      expect(seekArgs['positionMs'], 3000);
    });
  });

  group('Android', () {
    test('loop mode also goes to the native looper, not audioplayers',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final handler = ChantAudioHandler();
      await pumpEventQueue(times: 50);
      await handler.playSong(0);

      final args = Map<String, dynamic>.from(
          loopCallsNamed('load').single.arguments as Map);
      expect(args['looping'], isTrue);
      expect(loopCallsNamed('play'), isNotEmpty);
      // MediaPlayer 自己的循環每一遍結尾會停頓約半秒，佛曲不得再經過 audioplayers
      expect(chantPlayerIds(), isEmpty);
      await handler.disposePlayer();
    });
  });

  group('Web', () {
    tearDown(() => AppPlatform.debugIsWebOverride = null);

    test('hands the engine the asset key instead of extracting a file',
        () async {
      // iPhone 的瀏覽器：defaultTargetPlatform 是 iOS，但不能走原生 iOS 的設定
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AppPlatform.debugIsWebOverride = true;
      final engine = _RecordingEngine();
      final handler = ChantAudioHandler(engine: engine);
      await pumpEventQueue(times: 50);
      await handler.playSong(0);

      expect(engine.loaded.single,
          'assets/${ChantConstants.getSongById(0).assetPath}');
      expect(loopCalls, isEmpty, reason: 'no native player on the web');
      await handler.disposePlayer();
    });
  });
}

/// 只記錄被要求播放哪個路徑的引擎
class _RecordingEngine implements ChantMusicEngine {
  final loaded = <String>[];
  PlayerState _state = PlayerState.stopped;

  @override
  Stream<PlayerState> get onStateChanged => const Stream.empty();
  @override
  Stream<Duration> get onDurationChanged => const Stream.empty();
  @override
  Stream<void> get onComplete => const Stream.empty();
  @override
  PlayerState get state => _state;
  @override
  Future<void> init() async {}
  @override
  Future<void> playFile(String path, {required bool looping}) async {
    loaded.add(path);
    _state = PlayerState.playing;
  }

  @override
  Future<void> resume() async => _state = PlayerState.playing;
  @override
  Future<void> pause() async => _state = PlayerState.paused;
  @override
  Future<void> stop() async => _state = PlayerState.stopped;
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<Duration?> getPosition() async => Duration.zero;
  @override
  Future<Duration?> getDuration() async => null;
  @override
  Future<void> setLooping(bool looping) async {}
  @override
  Future<void> dispose() async {}
}
