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
    await configFile.writeAsString(prettyEncoder.convert({"pwd": null}));
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

  debugPrint(">>> 资产目录初始化完毕: ${assetsDir.path}");
  debugPrint("\tconfig.json初始化完毕: ${configFile.path}");
  debugPrint("\thive cards database初始化完毕: ${hiveDir.path}");
}

Future<void> writeToConfigJson({required String key, dynamic value}) async {
  /// 内容极其少
  configFileData[key] = value;
  await configFile.writeAsString(prettyEncoder.convert(configFileData));
}
