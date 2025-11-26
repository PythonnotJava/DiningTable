import 'package:diningtable/Compose/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Logic/card_info.dart';
import 'card_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  static List<CardInfo> infos = [
    CardInfo(
      target: 'target',
      sign: 'sign',
      content: '使用Flutter制作一个卡片,右上角是展开按钮（展开UI我自己写），右下角是dot按钮，表示更多选项，第一层是红色⚪，然后target，第二层是蓝色⚪然后subtitle，下面一大块是content占三层且表面内容最多三层，这是传入信息：class CardInfo'
    ),
    CardInfo(
      target: 'target',
      sign: 'sign',
      content: '使用Flutter制作一个卡片,右上角是展开按钮（展开UI我自己写），右下角是dot按钮，表示更多选项，第一层是红色⚪，然后target，第二层是蓝色⚪然后subtitle，下面一大块是content占三层且表面内容最多三层，这是传入信息：class CardInfo'
    ),
    CardInfo(
      target: 'target',
      sign: 'sign',
      content: '使用Flutter制作一个卡片,右上角是展开按钮（展开UI我自己写），右下角是dot按钮，表示更多选项，第一层是红色⚪，然后target，第二层是蓝色⚪然后subtitle，下面一大块是content占三层且表面内容最多三层，这是传入信息：class CardInfo'
    ),
    CardInfo(
      target: 'target',
      sign: 'sign',
      content: '使用Flutter制作一个卡片,右上角是展开按钮（展开UI我自己写），右下角是dot按钮，表示更多选项，第一层是红色⚪，然后target，第二层是蓝色⚪然后subtitle，下面一大块是content占三层且表面内容最多三层，这是传入信息：class CardInfo'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          maxLines: 1,
          decoration: InputDecoration(
            hintText: '请输入名称或者标签',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.blue,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          itemBuilder: (context, index) {
            return CardItem(cardInfo: infos[index]);
          },
          itemCount: infos.length,
        ),
      ),
    );
  }
}
