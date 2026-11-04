package com.yichung.lee.buddha_counter

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 佛曲專用的 Android 原生播放器：用兩個 MediaPlayer 以 [MediaPlayer.setNextMediaPlayer] 接力，
 * 做到無縫單曲循環。
 *
 * 為什麼不用 MediaPlayer 自己的 setLooping：它在每一遍結尾會先停掉音訊輸出、跳回開頭、
 * 再重新啟動 (實測 Pixel 7 每次停頓約 0.5 ~ 0.65 秒)。setNextMediaPlayer 讓系統在這一遍
 * 結束的瞬間直接接上已經準備好的下一遍，接縫不經過 Dart。
 *
 * 方法與事件和 iOS 的 ChantLoopPlayer.swift 相同，Dart 端共用
 * lib/core/services/native_loop_chant_engine.dart。
 */
class ChantLoopPlayer private constructor(private val context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "buddha_counter/chant_loop_player"
        const val EVENT_CHANNEL = "buddha_counter/chant_loop_player/events"

        // audio_service 讓 Flutter engine 在 Activity 關掉後繼續存在 (背景播放)，
        // 所以播放器也只建立一次，Activity 重建時只重新接上通道
        private var instance: ChantLoopPlayer? = null

        fun attach(engine: FlutterEngine, context: Context) {
            val player = instance ?: ChantLoopPlayer(context.applicationContext).also { instance = it }
            val messenger = engine.dartExecutor.binaryMessenger
            MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler(player)
            EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(player)
        }
    }

    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    /** 正在出聲的這一遍 */
    private var current: MediaPlayer? = null

    /** 已準備好、排在 [current] 後面的下一遍 (只在單曲循環時存在) */
    private var next: MediaPlayer? = null
    private var nextReady = false

    private var path: String? = null
    private var looping = true

    /** Dart 端要求的播放狀態；暫時失去音訊焦點 (例如來電) 時維持 true，焦點回來後自動續播 */
    private var playing = false
    private var eventSink: EventChannel.EventSink? = null

    // --- 通道 ---

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "load" -> {
                    val newPath = call.argument<String>("path")
                    if (newPath == null) {
                        result.error("bad_args", "path is required", null)
                        return
                    }
                    result.success(load(newPath, call.argument<Boolean>("looping") ?: true))
                }
                "play" -> {
                    play()
                    result.success(null)
                }
                "pause" -> {
                    playing = false
                    current?.pause()
                    result.success(null)
                }
                "stop" -> {
                    playing = false
                    current?.pause()
                    current?.seekTo(0)
                    abandonFocus()
                    result.success(null)
                }
                "seek" -> {
                    val ms = call.argument<Number>("positionMs")?.toInt() ?: 0
                    current?.seekTo(ms)
                    result.success(null)
                }
                "getPosition" -> result.success(current?.currentPosition)
                "getDuration" -> result.success(current?.duration?.takeIf { it > 0 })
                "setLooping" -> {
                    setLooping(call.argument<Boolean>("looping") ?: true)
                    result.success(null)
                }
                "dispose" -> {
                    playing = false
                    releaseAll()
                    abandonFocus()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            log("${call.method} failed: $e")
            result.error("player_error", e.message, null)
        }
    }

    // --- 播放 ---

    /** 載入音檔 (停在開頭，尚未播放)，回傳長度 (毫秒) */
    private fun load(newPath: String, loop: Boolean): Int? {
        playing = false
        releaseAll()
        path = newPath
        looping = loop
        val player = createPlayer(newPath)
        player.prepare() // 本機檔案，同步準備只需幾毫秒
        current = player
        if (looping) prepareNext()
        return player.duration.takeIf { it > 0 }
    }

    private fun play() {
        val player = current ?: return
        playing = true
        if (requestFocus()) player.start()
    }

    private fun setLooping(loop: Boolean) {
        if (looping == loop) return
        looping = loop
        if (loop) {
            prepareNext()
        } else {
            current?.setNextMediaPlayer(null)
            releaseNext()
        }
    }

    private fun createPlayer(file: String): MediaPlayer = MediaPlayer().apply {
        setAudioAttributes(attributes)
        setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK)
        setDataSource(file)
        setOnCompletionListener { onCompleted(it) }
        setOnErrorListener { _, what, extra ->
            log("MediaPlayer error what=$what extra=$extra")
            false
        }
    }

    /** 在背景準備下一遍，準備好就排到目前這一遍後面 */
    private fun prepareNext() {
        val file = path ?: return
        if (next != null || current == null) return
        val player = createPlayer(file)
        next = player
        nextReady = false
        player.setOnPreparedListener { prepared ->
            if (prepared !== next) return@setOnPreparedListener
            nextReady = true
            current?.setNextMediaPlayer(prepared)
        }
        player.prepareAsync()
    }

    private fun onCompleted(finished: MediaPlayer) {
        if (finished !== current) return
        val following = next
        if (looping && following != null && nextReady) {
            // 系統已經直接接著播下一遍；換手後再準備下下一遍
            current = following
            next = null
            nextReady = false
            finished.release()
            prepareNext()
            return
        }
        if (looping) {
            // 下一遍還沒準備好 (極短的曲目)：在原生端立刻回到開頭，仍不經過 Dart
            finished.seekTo(0)
            finished.start()
            return
        }
        playing = false
        eventSink?.success(mapOf("event" to "complete"))
    }

    private fun releaseNext() {
        next?.release()
        next = null
        nextReady = false
    }

    private fun releaseAll() {
        releaseNext()
        current?.release()
        current = null
    }

    // --- 音訊焦點 (與原本 audioplayers 的 AndroidAudioFocus.gain 行為相同) ---

    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_GAIN -> if (playing) current?.start()
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> current?.pause()
            AudioManager.AUDIOFOCUS_LOSS -> {
                playing = false
                current?.pause()
            }
            // AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK：系統會自動降低音量，繼續播放
        }
    }

    private val focusRequest: AudioFocusRequest? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attributes)
                .setOnAudioFocusChangeListener(focusListener)
                .build()
        } else {
            null
        }

    private fun requestFocus(): Boolean {
        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.requestAudioFocus(focusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                focusListener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN
            )
        }
        return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.abandonAudioFocusRequest(focusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusListener)
        }
    }

    private fun log(message: String) {
        eventSink?.success(mapOf("event" to "log", "message" to message))
    }
}
