package com.yichung.lee.buddha_counter

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {
    // audio_service 在這裡建立 (或取回快取的) engine 並開始執行 Dart；在同一個呼叫裡接上
    // 佛曲播放器的通道，Dart 第一次呼叫時就一定找得到
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        val engine = super.provideFlutterEngine(context)
        if (engine != null) ChantLoopPlayer.attach(engine, context)
        return engine
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    1001
                )
            }
        }
    }

    companion object {
        // Explicit references to keep notification drawables during R8 shrinking
        @Suppress("unused")
        private val KEEP_DRAWABLES = intArrayOf(
            R.drawable.ic_stat_music,
            R.drawable.audio_service_stop,
        )
    }
}
