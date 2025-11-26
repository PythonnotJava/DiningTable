import 'package:diningtable/Compose/empty_widget.dart';
import 'package:diningtable/Logic/file_system.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:uuid/uuid.dart';

import '../Logic/card_info.dart';
import 'card_item.dart';

const uuidGen = Uuid();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late final TextEditingController targetController;
  late final TextEditingController signController;
  late final TextEditingController contentController;
  late final TextEditingController searchController;

  @override
  void initState() {
    targetController = TextEditingController();
    signController = TextEditingController();
    contentController = TextEditingController();
    searchController = TextEditingController();

    /// 添加监听：输入搜索文字时刷新 UI
    searchController.addListener(() {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    targetController.dispose();
    signController.dispose();
    contentController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: '请输入名称或者标签',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          IconButton(
            onPressed: appendToHive,
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.blue,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: cardsBox.listenable(),
        builder: (_, Box<CardInfo> box, _) {
          final query = searchController.text.toLowerCase().trim();

          final cards = box.values.where((c) {
            if (query.isEmpty) return true;
            return c.target.toLowerCase().contains(query) ||
                c.sign.toLowerCase().contains(query);
          }).toList();

          if (cards.isEmpty) {
            return const EmptyStateWidget(title: Text('没有卡片哦~'));
          }

          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (_, index) {
              final CardInfo cardInfo = cards[index];
              return CardItem(cardInfo: cardInfo, key: ValueKey(cardInfo.key));
            },
          );
        },
      ),
    );
  }

  /// 弹出对话框：添加一条 CardInfo
  Future<void> appendToHive() async {
    contentController.clear();
    signController.clear();
    targetController.clear();

    bool isTargetEmptyChecked = false;
    bool isSignEmptyChecked = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.1,
            vertical: size.height * 0.1,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: size.width * 0.8,
                height: size.height * 0.8,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.blue),
                          Text(
                            "添加卡片",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: targetController,
                                maxLines: null,
                                maxLength: 100,
                                decoration: const InputDecoration(
                                  labelText: "目标",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              if (isTargetEmptyChecked)
                                const Text(
                                  '*目标不能为空',
                                  style: TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: signController,
                                maxLines: null,
                                maxLength: 100,
                                decoration: const InputDecoration(
                                  labelText: "标记",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              if (isSignEmptyChecked)
                                const Text(
                                  '*标记不能为空',
                                  style: TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: contentController,
                                maxLines: null,
                                maxLength: 10000,
                                minLines: 6,
                                decoration: const InputDecoration(
                                  hintText: '随便写写吧',
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("取消"),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isTargetEmptyChecked = targetController.text.trim().isEmpty;
                              isSignEmptyChecked = signController.text.trim().isEmpty;
                            });
                            if (!isTargetEmptyChecked && !isSignEmptyChecked) {
                              final info = CardInfo(
                                key: uuidGen.v1(),
                                time: DateTime.now().toString(),
                                target: targetController.text.trim(),
                                sign: signController.text.trim(),
                                content: contentController.text.trim(),
                              );
                              cardsBox.put(info.key, info);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("确定"),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
