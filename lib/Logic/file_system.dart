import 'dart:io';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'card_info.dart';

/// 生成
/// 1.storage/emulated/0/Android/data/com.xxx.yyy/assets/config.json
/// 2.storage/emulated/0/Android/data/com.xxx.yyy/assets/hive的存储库
late final Directory assetsDir;
late final File configFile;
late final Map<String, dynamic> configFileData;
late final Directory hiveDir;
late final Box<CardInfo> cardsBox;
/// 计数器
late final Box<int> metaBox;
late final bool isPc;

/// 两个空格缩进
const prettyEncoder = JsonEncoder.withIndent('  ');

Future<void> initAssetsDir() async {
  isPc = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  /// 获取应用的外部存储目录
  Directory? dir = !isPc
      ? await getExternalStorageDirectory()
      : await getApplicationSupportDirectory();

  if (dir == null) {
    throw Exception("无法获取外部存储目录");
  }

  /// 构造 assets 目录路径
  assetsDir = Directory("${dir.path}/assets");

  /// 如果不存在则创建
  if (!await assetsDir.exists()) {
    await assetsDir.create(recursive: true);
  }

  /// 配置文件路径
  configFile = File("${assetsDir.path}/config.json");
  if (!await configFile.exists()) {
    await configFile.create(recursive: true);
    await configFile.writeAsString(prettyEncoder.convert({"pwd": null, "sortId" : false}));
  }

  configFileData = jsonDecode(await configFile.readAsString());

  /// hive数据库
  hiveDir = Directory("${assetsDir.path}/hive");

  if (!await hiveDir.exists()) {
    await hiveDir.create(recursive: true);
  }

  /// 正确初始化 Hive 到外部目录
  Hive.init(hiveDir.path);

  /// 注册 Adapter
  Hive.registerAdapter(CardInfoAdapter());

  /// 打开 Box 并赋值
  cardsBox = await Hive.openBox<CardInfo>('cards_box');

  /// 在打开 cardsBox 之前或之后加上这几行
  metaBox = await Hive.openBox<int>('meta_box');

  /// 初始化计数器（只有第一次会执行）
  if (!metaBox.containsKey('card_counter')) {
    await metaBox.put('card_counter', 0);
  }

  debugPrint(">>> 资产目录初始化完毕: ${assetsDir.path}");
  debugPrint("\tconfig.json初始化完毕: ${configFile.path}");
  debugPrint("\thive cards database初始化完毕: ${hiveDir.path}");
}

Future<void> writeToConfigJson({required String key, dynamic value}) async {
  /// 内容极其少
  configFileData[key] = value;
  await configFile.writeAsString(prettyEncoder.convert(configFileData));
}

int getNextCardId() {
  int current = metaBox.get('card_counter', defaultValue: 0)!;
  current++;
  metaBox.put('card_counter', current);
  return current;
}

/// 永久合并：把一批 CardInfo 写入 cardsBox。
/// 对 key 相同的卡片直接跳过（不覆盖本机已有数据）。
/// 合并完成后修正本机计数器，确保后续新增卡片的 key 不会与导入数据撞车。
///
/// 返回 [新增数量, 跳过数量]。
List<int> mergeCards(List<CardInfo> incoming) {
  int added = 0;
  int skipped = 0;
  int maxKey = metaBox.get('card_counter', defaultValue: 0)!;

  for (final card in incoming) {
    if (card.key.isEmpty) {
      skipped++;
      continue;
    }
    if (cardsBox.containsKey(card.key)) {
      /// key 相同，跳过
      skipped++;
    } else {
      cardsBox.put(card.key, card);
      added++;
    }
    /// 记录见过的最大数字 key，用于推进计数器
    final parsed = int.tryParse(card.key);
    if (parsed != null && parsed > maxKey) {
      maxKey = parsed;
    }
  }

  /// 推进计数器到已见过的最大 key，避免后续 getNextCardId 生成重复 key
  if (maxKey > metaBox.get('card_counter', defaultValue: 0)!) {
    metaBox.put('card_counter', maxKey);
  }

  return [added, skipped];
}