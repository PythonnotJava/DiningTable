import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../Compose/empty_widget.dart';
import '../Logic/file_system.dart';
import '../Logic/card_info.dart';
import 'card_item.dart';

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
            onPressed: appendOrEditToHive,
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.blue,
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<CardInfo>>(
        valueListenable: cardsBox.listenable(),
        builder: (_, Box<CardInfo> box, __) {
          final query = searchController.text.toLowerCase().trim();

          final cards = box.values.where((c) {
            if (query.isEmpty) return true;
            return c.target.toLowerCase().contains(query) ||
                c.sign.toLowerCase().contains(query);
          }).toList();

          if (cards.isEmpty) {
            return const EmptyStateWidget(title: Text('没有卡片哦~'));
          }

          return AnimationLimiter(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: cards.length,
              itemBuilder: (_, index) {
                final CardInfo cardInfo = cards[index];

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 475),
                  child: SlideAnimation(
                    verticalOffset: 80.0,
                    child: FadeInAnimation(
                      delay: const Duration(milliseconds: 100),
                      child: CardItem(
                        cardInfo: cardInfo,
                        key: ValueKey(cardInfo.key),
                        editFunc: appendOrEditToHive,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 弹出对话框：添加或者修改一条 CardInfo
  /// 修改时，只能修改内容，其他两个禁用
  Future<void> appendOrEditToHive({
    CardInfo? editInfo
  }) async {

    contentController.clear();
    signController.clear();
    targetController.clear();

    /// 编辑模式
    bool edit = false;

    if (editInfo != null) {
      contentController.text = editInfo.content;
      signController.text = editInfo.sign;
      targetController.text = editInfo.target;
      edit = true;
    }

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
                                enabled: !edit,
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
                                enabled: !edit,
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
                        ElevatedButton(
                          onPressed: () {
                            if (edit){
                              editInfo!.content = contentController.text.trim();
                              editInfo.time = DateTime.now().toString();
                              cardsBox.put(editInfo.key, editInfo);
                              Navigator.pop(context);
                            } else {
                              setState(() {
                                isTargetEmptyChecked = targetController.text.trim().isEmpty;
                                isSignEmptyChecked = signController.text.trim().isEmpty;
                              });
                              if (!isTargetEmptyChecked && !isSignEmptyChecked) {
                                final info = CardInfo(
                                  key: getNextCardId().toString(),
                                  time: DateTime.now().toString(),
                                  target: targetController.text.trim(),
                                  sign: signController.text.trim(),
                                  content: contentController.text.trim(),
                                );
                                cardsBox.put(info.key, info);
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: const Text("确定"),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("取消"),
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
