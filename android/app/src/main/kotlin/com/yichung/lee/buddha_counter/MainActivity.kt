package com.yichung.lee.buddha_counter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yichung.lee.buddha_counter/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val title = call.argument<String>("title") ?: "念佛、拜佛計數器"
                    val chant = call.argument<String>("chant") ?: "南無阿彌陀佛 · 念佛梵音播放中"
                    ChantMediaService.start(this, title, chant)
                    result.success(true)
                }
                "stopService" -> {
                    ChantMediaService.stop(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
