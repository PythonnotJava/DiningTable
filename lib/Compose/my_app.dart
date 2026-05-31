import 'package:flutter/material.dart';

import '../Logic/file_intent_service.dart';
import 'home.dart';
import 'import_helper.dart';
import 'myself.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  static List<Widget> sheets = [
    const HomePage(),
    const Myself()
  ];

  late int index;

  /// 用于在没有 BuildContext 时也能弹窗
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    index = 0;
    super.initState();
    _initFileIntent();
  }

  /// 初始化"用 DiningTable 打开文件"的处理
  Future<void> _initFileIntent() async {
    FileIntentService.onFileOpened = _handleImportFile;
    final initialPath = await FileIntentService.init();
    if (initialPath != null) {
      // 等首帧渲染完再弹窗，确保 Navigator 可用
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleImportFile(initialPath);
      });
    }
  }

  Future<void> _handleImportFile(String path) async {
    final navigator = _navKey.currentState;
    if (navigator == null) return;
    final ctx = navigator.context;
    await runImportFlow(ctx, path);
  }

  void toggleIndex(int i) => setState(() {
    if (index != i){
      index = i;
    }
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      home: Scaffold(
        body: IndexedStack(
          index: index,
          children: sheets,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home), label: "主页"),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: "我的"),
          ],
          currentIndex: index,
          selectedItemColor: Colors.blue,
          selectedFontSize: 20,
          unselectedFontSize: 14,
          unselectedItemColor: Colors.grey,
          selectedIconTheme: const IconThemeData(size: 26),
          unselectedIconTheme: const IconThemeData(size: 20),
          onTap: toggleIndex,
        ),
      ),
    );
  }
}