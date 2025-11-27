import 'dart:math' as math;

import 'package:diningtable/Logic/file_system.dart';
import 'package:flutter/material.dart';

import '../Logic/card_info.dart';
import 'expand_widget.dart';

class CardItem extends StatefulWidget {
  final CardInfo cardInfo;
  final Future<void> Function({CardInfo? editInfo}) editFunc;
  const CardItem({super.key, required this.cardInfo, required this.editFunc});

  @override
  State<StatefulWidget> createState() => CardItemState();
}

class CardItemState extends State<CardItem> with TickerProviderStateMixin {
  late final CardInfo cardInfo;

  bool expanded = false;

  @override
  void initState() {
    cardInfo = widget.cardInfo;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cardInfo.target,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.pages_outlined, color: Colors.grey),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpandCardPage(cardInfo: cardInfo),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                const SizedBox(width: 10),

                IconButton(
                  icon: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => setState(() => expanded = !expanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cardInfo.sign,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            AnimatedSize(
              duration: Duration(milliseconds: math.min(cardInfo.content.length ~/ 10, 500).clamp(200, 500)),
              curve: Curves.easeInOut,
              child: expanded
                  ? Text(
                cardInfo.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              )
                  : Text(
                cardInfo.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.bottomRight,
              child: PopupMenuButton<int>(
                icon: const Icon(Icons.more_horiz),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 0:
                      widget.editFunc(editInfo: widget.cardInfo);
                      break;
                    case 1:
                      cardsBox.delete(cardInfo.key);
                      break;
                    default:
                      debugPrint("Can't find the value.");
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0,
                    child: Row(
                      children: const [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 10),
                        Text("编辑"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: const [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 10),
                        Text("删除"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}