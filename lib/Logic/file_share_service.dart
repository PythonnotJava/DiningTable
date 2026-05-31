import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'card_info.dart';
import 'file_system.dart';

/// 文件分享 / 文件导入服务。
///
/// - 导出：把当前 cards_box.hive 复制一份到临时目录（保持 .hive 后缀），
///   再调用系统分享面板，让用户通过微信 / 蓝牙 / AirDrop 等任意渠道发送。
/// - 导入：主路径是 App 内「从文件导入」（用文件选择器选中任意 .hive 文件）。
///   读取时把目标文件复制为 cards_box.hive 后打开为临时 Hive box，
///   取出全部 CardInfo，再调用 mergeCards 合并（key 相同跳过）。
class FileShareService {
  /// 导出数据并弹出系统分享面板。返回是否成功发起分享。
  static Future<bool> shareHiveFile() async {
    /// 先确保 Hive 把内存数据落盘
    await cardsBox.flush();

    final sourcePath = '${hiveDir.path}/cards_box.hive';
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw const FileShareException('找不到数据文件 cards_box.hive');
    }

    /// 复制到临时目录，文件名带时间戳，保持 .hive 后缀便于辨认
    final tempDir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toString()
        .substring(0, 19)
        .replaceAll(RegExp(r'[:\s]'), '-');
    final exportPath = '${tempDir.path}/DiningTable-$stamp.hive';
    await sourceFile.copy(exportPath);

    final result = await Share.shareXFiles(
      [XFile(exportPath, mimeType: 'application/octet-stream')],
      subject: 'DiningTable 卡片数据',
      text: 'DiningTable 卡片数据文件（.hive），可在 DiningTable 内「从文件导入」',
    );
    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  }

  /// 从指定 .hive 文件读取全部卡片（不写入本机数据库）。
  /// 通过把目标文件复制进一个隔离的临时 Hive 目录后打开，避免污染主库。
  static Future<List<CardInfo>> readCardsFromHiveFile(String filePath) async {
    final src = File(filePath);
    if (!await src.exists()) {
      throw const FileShareException('文件不存在或无法访问');
    }

    /// 建一个一次性临时目录，box 名固定为 cards_box（与文件内部名一致）
    final tempRoot = await getTemporaryDirectory();
    final importDir = Directory(
      '${tempRoot.path}/import_${DateTime.now().microsecondsSinceEpoch}',
    );
    await importDir.create(recursive: true);

    final targetFile = File('${importDir.path}/cards_box.hive');
    await src.copy(targetFile.path);

    Box<CardInfo>? tempBox;
    try {
      /// 用独立 Hive 实例打开，不影响已初始化的全局 Hive
      final hive = HiveImpl();
      hive.init(importDir.path);
      if (!hive.isAdapterRegistered(1)) {
        hive.registerAdapter(CardInfoAdapter());
      }
      final box = await hive.openBox<CardInfo>('cards_box');
      tempBox = box;
      final cards = box.values.toList();
      await box.close();
      return cards;
    } on HiveError catch (e) {
      throw FileShareException('无法读取该文件，可能不是有效的 DiningTable 数据: ${e.message}');
    } catch (e) {
      throw FileShareException('读取文件失败: $e');
    } finally {
      try {
        if (tempBox != null && tempBox.isOpen) await tempBox.close();
        if (await importDir.exists()) {
          await importDir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('清理导入临时目录失败: $e');
      }
    }
  }
}

class FileShareException implements Exception {
  final String message;
  const FileShareException(this.message);
  @override
  String toString() => message;
}
