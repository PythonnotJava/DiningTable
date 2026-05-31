package com.pythonnotjava.diningtable

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "diningtable/file_intent"
    private var methodChannel: MethodChannel? = null

    /// 启动时若是通过打开文件进来的，先把路径暂存，等 Flutter 主动来取
    private var pendingFilePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // Flutter 启动后主动查询是否有待导入的文件
                "getInitialFile" -> {
                    result.success(pendingFilePath)
                    pendingFilePath = null
                }
                else -> result.notImplemented()
            }
        }

        // 处理冷启动时携带的 intent
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // App 已在运行时打开文件，处理后主动推给 Flutter
        val path = extractFile(intent)
        if (path != null) {
            if (methodChannel != null) {
                methodChannel?.invokeMethod("onFileOpened", path)
            } else {
                pendingFilePath = path
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        val path = extractFile(intent)
        if (path != null) {
            pendingFilePath = path
        }
    }

    /// 从 VIEW intent 中取出文件，拷贝到 cache 目录，返回本地可读路径。
    private fun extractFile(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action != Intent.ACTION_VIEW) return null
        val uri: Uri = intent.data ?: return null
        return try {
            val fileName = "imported_${System.currentTimeMillis()}.hive"
            val outFile = File(cacheDir, fileName)
            contentResolver.openInputStream(uri)?.use { input ->
                outFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            } ?: return null
            outFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
