class CardInfo {
  /// 目标title
  final String target;
  /// 目标subtitle
  final String sign;
  /// 内容，card的UI最多显示3行，多余的使用省略号
  final String content;

  const CardInfo({
    required this.target,
    required this.sign,
    required this.content,
  });
}
