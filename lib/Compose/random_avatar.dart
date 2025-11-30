import 'dart:math';
import 'package:flutter/material.dart';

const styles = [
  'bottts',
  'adventurer',
  'avataaars',
  'identicon',
  'lorelei',
  'pixel-art',
  'bottts-neutral',
];

String randomStyle() {
  final r = Random();
  return styles[r.nextInt(styles.length)];
}

class RandomAvatar extends StatefulWidget {
  final double size;

  const RandomAvatar({
    super.key,
    this.size = 80,
  });

  @override
  State<RandomAvatar> createState() => _RandomAvatarState();
}

class _RandomAvatarState extends State<RandomAvatar> {
  late int _seed;
  late String _style;

  @override
  void initState() {
    super.initState();
    _seed = Random().nextInt(1 << 16);
    _style = randomStyle();
  }

  /// 可选：你可以随时调用这个方法来刷新头像
  void refreshAvatar() {
    setState(() {
      _seed = Random().nextInt(1 << 16);
      _style = randomStyle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = "https://api.dicebear.com/9.x/$_style/png?seed=$_seed";

    return InkWell(
      onTap: refreshAvatar,
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            return Image.asset(
              'assets/img/unicorn.png',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}
