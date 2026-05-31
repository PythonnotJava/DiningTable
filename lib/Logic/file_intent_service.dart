import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 监听"用 DiningTable 打开 .hive 文件"的系统事件。
///
/// - 冷启动：通过 [getInitialFile] 主动查询启动时携带的文件路径。
/// - 热启动：通过 [onFileOpened] 回调接收运行时打开的文件路径。
///
/// 目前仅 Android 侧实现了原生 MethodChannel；其他平台调用安全返回 null/不触发。
class FileIntentService {
  static const MethodChannel _channel =
      MethodChannel('diningtable/file_intent');

  /// 运行时被打开文件的回调，由上层注册。
  static void Function(String path)? onFileOpened;

  static bool _handlerSet = false;

  /// 在 App 启动后调用一次：注册热启动回调，并返回冷启动时待导入的文件路径。
  static Future<String?> init() async {
    if (!_handlerSet) {
      _channel.setMethodCallHandler(_handleNativeCall);
      _handlerSet = true;
    }
    return getInitialFile();
  }

  static Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onFileOpened') {
      final path = call.arguments as String?;
      if (path != null && path.isNotEmpty) {
        onFileOpened?.call(path);
      }
    }
  }

  /// 查询冷启动时携带的文件路径（无则返回 null）。
  static Future<String?> getInitialFile() async {
    try {
      final path = await _channel.invokeMethod<String>('getInitialFile');
      if (path != null && path.isNotEmpty) return path;
      return null;
    } on MissingPluginException {
      // 平台未实现该 channel（如 iOS/PC），安全忽略
      return null;
    } catch (e) {
      debugPrint('getInitialFile 失败: $e');
      return null;
    }
  }
}
