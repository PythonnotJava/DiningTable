import 'package:flutter/material.dart';

import 'Compose/my_app.dart';
import 'Logic/file_system.dart';
import 'Compose/set_page.dart';
import 'Compose/verify_page.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  late String? pwd;
  bool initialized = false;

  /// 是否初次登录，true表示不是，则需要验证密码，false表示是的，则需要设置密码
  bool passwordSet = false;

  /// 是否已验证通过
  bool passwordVerified = false;

  @override
  void initState() {
    super.initState();
    initPwd();
  }

  Future<void> initPwd() async {
    pwd = configFileData['pwd'];
    passwordSet = pwd != null;
    setState(() => initialized = true);
  }

  void verifySuccess() {
    setState(() => passwordVerified = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    /// 1. 首次使用 → 强制设置密码
    if (!passwordSet) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SetPasswordPage(
          onPasswordSet: (newPwd) {
            writeToConfigJson(key: 'pwd', value: newPwd);
            setState(() {
              passwordSet = true;

              /// 首次设置后直接通过
              passwordVerified = true;
            });
          },
        ),
      );
    }

    /// 2. 已有密码但未验证 → 显示输入密码页面
    if (!passwordVerified) {
      return VerifyPasswordPage(
        correctPassword: pwd!,
        onVerified: verifySuccess,
      );
    }

    /// 3. 验证通过 → 正常进入主界面
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 全局初始化
  await initAssetsDir();

  runApp(const MainApp());
}
