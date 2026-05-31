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

  /// 内容，可变
  @HiveField(2)
  String content;

  /// 唯一键值对，同时充当hive的记录键
  @HiveField(3)
  final String key;

  /// 记录时间，自动可变
  @HiveField(4)
  String time;

  CardInfo({
    required this.target,
    required this.sign,
    required this.content,
    required this.key,
    required this.time
  });

  /// 序列化为 Map，用于局域网传输 / 导出
  Map<String, dynamic> toJson() => {
    'target': target,
    'sign': sign,
    'content': content,
    'key': key,
    'time': time,
  };

  /// 从 Map 反序列化，字段缺失时回退为空串，保证健壮性
  factory CardInfo.fromJson(Map<String, dynamic> json) => CardInfo(
    target: (json['target'] ?? '').toString(),
    sign: (json['sign'] ?? '').toString(),
    content: (json['content'] ?? '').toString(),
    key: (json['key'] ?? '').toString(),
    time: (json['time'] ?? '').toString(),
  );
}
