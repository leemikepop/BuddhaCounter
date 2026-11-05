import 'chant_music_engine.dart';
import 'web_chant_engine_stub.dart'
    if (dart.library.js_interop) 'web_chant_engine_web.dart' as impl;

/// Web 版佛曲引擎 (Web Audio API，無縫循環)。只能在 Web 上建立；
/// 其他平台的建置拿到的是會丟出錯誤的替身，確保原生 App 不會誤用。
ChantMusicEngine createWebChantEngine() => impl.createWebChantEngine();
