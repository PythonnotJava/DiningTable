import 'package:flutter/material.dart';

import '../Logic/card_info.dart';
import '../Logic/file_system.dart';
import 'expand_widget.dart';

/// 临时预览页：展示从对方拉取到的卡片，仅在内存中，不写入数据库。
/// 提供"全部合并保存"按钮，可一键转为永久存储。
class TempPreviewPage extends StatelessWidget {
  final List<CardInfo> cards;
  const TempPreviewPage({super.key, required this.cards});

  Future<void> _mergeAll(BuildContext context) async {
    final result = mergeCards(cards);
    final added = result[0];
    final skipped = result[1];
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('已保存'),
        content: Text(
          '新增 $added 张，跳过 $skipped 张（key 重复）',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // 关弹窗
              Navigator.pop(context); // 退出预览页
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('临时预览（${cards.length}）'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: cards.isEmpty
          ? const Center(child: Text('对方没有任何卡片'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.teal.withOpacity(0.08),
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    '这些卡片仅临时查看，未保存到本机。点击下方按钮可永久保存。',
                    style: TextStyle(fontSize: 13, color: Colors.teal),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: cards.length,
                    itemBuilder: (_, index) {
                      final card = cards[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.style_outlined,
                            color: Colors.teal,
                          ),
                          title: Text(
                            card.target,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            card.sign,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpandCardPage(cardInfo: card),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cards.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _mergeAll(context),
                  icon: const Icon(Icons.save_alt),
                  label: const Text('全部合并保存到本机'),
                ),
              ),
            ),
    );
  }
}
