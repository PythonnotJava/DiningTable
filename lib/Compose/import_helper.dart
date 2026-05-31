import 'package:flutter/material.dart';

import '../Logic/card_info.dart';
import '../Logic/file_share_service.dart';
import '../Logic/file_system.dart';

/// 通用导入流程：读取数据文件 → 弹出合并确认 → 合并(key 相同跳过) → 结果提示。
///
/// 同时供两处复用：
///  1. 分享中心「从文件导入」按钮（用户主动选文件）
///  2. 文件关联打开（系统把 .hive 文件交给本 App）
///
/// [context] 必须是能找到 Navigator 的有效上下文。
Future<void> runImportFlow(BuildContext context, String filePath) async {
  List<CardInfo> cards;
  try {
    cards = await FileShareService.readCardsFromHiveFile(filePath);
  } catch (e) {
    if (!context.mounted) return;
    await _showInfoDialog(context, '导入失败', e.toString(), isError: true);
    return;
  }

  if (!context.mounted) return;

  if (cards.isEmpty) {
    await _showInfoDialog(context, '导入提示', '该文件里没有任何卡片', isError: true);
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      icon: const Icon(
        Icons.download_for_offline,
        color: Colors.blue,
        size: 48,
      ),
      title: const Text('导入数据文件'),
      content: Text(
        '检测到 ${cards.length} 张卡片。\n是否合并到本机？key 相同的卡片会自动跳过。',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx, false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dctx, true),
          child: const Text('合并'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final result = mergeCards(cards);
  if (!context.mounted) return;
  await _showInfoDialog(
    context,
    '导入完成',
    '新增 ${result[0]} 张，跳过 ${result[1]} 张（key 重复）',
  );
}

Future<void> _showInfoDialog(
  BuildContext context,
  String title,
  String message, {
  bool isError = false,
}) {
  return showDialog(
    context: context,
    builder: (dctx) => AlertDialog(
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle,
        color: isError ? Colors.red : Colors.green,
        size: 48,
      ),
      title: Text(title),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
