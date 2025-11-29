// pwd_checker.dart  文件末尾添加这个类（和 SetPasswordPage 同文件）

import 'package:flutter/material.dart';

class VerifyPasswordPage extends StatefulWidget {
  final String correctPassword;
  final VoidCallback onVerified;

  const VerifyPasswordPage({
    super.key,
    required this.correctPassword,
    required this.onVerified,
  });

  @override
  State<VerifyPasswordPage> createState() => _VerifyPasswordPageState();
}

class _VerifyPasswordPageState extends State<VerifyPasswordPage> {
  final controller = TextEditingController();
  bool isChecking = false;
  bool showAngry = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _check() async {
    if (isChecking) return;

    setState(() {
      isChecking = true;
      showAngry = false;
    });

    // 模拟一点点延迟，让转圈圈看起来真实
    await Future.delayed(const Duration(milliseconds: 600));

    if (controller.text == widget.correctPassword) {
      widget.onVerified();
    } else {
      setState(() {
        isChecking = false;
        showAngry = true;
      });
      controller.clear();

      // 2秒后自动恢复转圈圈状态，方便继续输入
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => showAngry = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 大头像 + 转圈圈 / angry
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isChecking && !showAngry)
                      const CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation(Colors.blue),
                      ),

                    if (showAngry)
                      Image.asset(
                        'assets/img/angry.png',
                        width: 100,
                        height: 100,
                      ),

                    if (!isChecking && !showAngry)
                      Image.asset(
                        'assets/img/guess.png', // 初始
                        width: 100,
                        height: 100,
                        color: Colors.grey[400],
                        colorBlendMode: BlendMode.modulate,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // 输入框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: controller,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: "输入密码解锁",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  onSubmitted: (_) => _check(),
                ),
              ),

              const SizedBox(height: 20),

              // 手动点也行
              TextButton(
                onPressed: _check,
                child: const Text(
                  "解锁",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}