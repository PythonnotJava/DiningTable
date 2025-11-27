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

class RandomAvatar extends StatelessWidget {
  final int seed;
  final double size;
  final String style;

  const RandomAvatar({
    super.key,
    required this.seed,
    this.size = 80,
    required this.style
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        "https://api.dicebear.com/9.x/$style/png?seed=$seed";

    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          return Image.asset(
            'assets/img/unicorn.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
