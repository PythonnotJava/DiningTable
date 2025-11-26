import 'package:hive/hive.dart';

part 'card_info.g.dart';

@HiveType(typeId: 1)
class CardInfo {
  /// 目标title
  @HiveField(0)
  final String target;

  /// 目标subtitle
  @HiveField(1)
  final String sign;

  /// 内容
  @HiveField(2)
  final String content;

  /// 唯一键值对，同时充当hive的记录键
  @HiveField(3)
  final String key;

  /// 记录时间
  @HiveField(4)
  final String time;

  const CardInfo({
    required this.target,
    required this.sign,
    required this.content,
    required this.key,
    required this.time
  });
}
