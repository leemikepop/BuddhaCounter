import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/chant_audio_handler.dart';

/// 記錄送往原生端的 audioplayers 呼叫，驗證 iOS 全域音訊 session 只被設定成「可成為 Now Playing」的模式
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final playerCalls = <MethodCall>[];
  final globalCalls = <MethodCall>[];

  setUpAll(() {
    AudioPlayer.preparationTimeout = const Duration(milliseconds: 10);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async {
        globalCalls.add(call);
        return 1;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        playerCalls.add(call);
        return 1;
      },
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
    playerCalls.clear();
    globalCalls.clear();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<void> createAudioStack() async {
    final handler = ChantAudioHandler();
    AudioService(handler: handler);
    await pumpEventQueue(times: 50);
  }

  Iterable<MethodCall> contextCalls(List<MethodCall> calls) =>
      calls.where((c) => c.method == 'setAudioContext');

  test('iOS: one non-mixable playback session, no per-player contexts',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await createAudioStack();

    // 任何單一播放器的 setAudioContext 在 iOS 都會覆蓋全域 session，因此一律不得呼叫
    expect(contextCalls(playerCalls), isEmpty);

    final global = contextCalls(globalCalls).toList();
    expect(global, isNotEmpty);
    for (final call in global) {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      expect(args['category'], 'playback');
      // mixWithOthers 會讓 iOS 不把 App 當成「正在播放」→ 控制中心 / 鎖定畫面不顯示控制
      expect(args['options'], isNot(contains('mixWithOthers')));
      // defaultToSpeaker 只能搭配 playAndRecord，搭配 playback 會讓整個設定失敗
      expect(args['options'], isNot(contains('defaultToSpeaker')));
    }
  });

  test('Android: music and click-sound players each get their own context',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await createAudioStack();

    final perPlayer = contextCalls(playerCalls).toList();
    final musicIds = {'chant_music_player', 'chant_standby_player'};
    final musicCalls = perPlayer
        .where((c) => musicIds.contains((c.arguments as Map)['playerId']));
    final sfxCalls = perPlayer.where((c) =>
        ((c.arguments as Map)['playerId'] as String).startsWith('sfx_pool_'));

    expect(musicCalls.length, 2, reason: 'music players must get gain focus');
    expect(sfxCalls.length, 6, reason: 'click sounds must not take focus');
    for (final c in musicCalls) {
      expect((c.arguments as Map)['audioFocus'], AndroidAudioFocus.gain.value);
    }
    for (final c in sfxCalls) {
      expect((c.arguments as Map)['audioFocus'], AndroidAudioFocus.none.value);
    }
  });
}
