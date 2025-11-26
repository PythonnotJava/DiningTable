import 'package:flutter/material.dart';

import 'Compose/home.dart';
import 'Compose/myself.dart';
import 'Logic/file_system.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  static List<StatefulWidget> sheets = [
    const HomePage(),
    const Myself()
  ];

  late int index;

  @override
  void initState() {
    index = 0;
    super.initState();
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
          selectedFontSize: 24,
          unselectedFontSize: 18,
          unselectedItemColor: Colors.grey,
          selectedIconTheme: const IconThemeData(size: 30),
          unselectedIconTheme: const IconThemeData(size: 22),
          onTap: toggleIndex,
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 全局初始化
  await initAssetsDir();

  runApp(MyApp());
}