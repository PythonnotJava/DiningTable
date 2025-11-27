import 'package:flutter/material.dart';

/// 密码校验结果
class PasswordValidationResult {
  final bool isValid;
  final String? message;   // isValid == false 时说明原因
  final String? password;  // isValid == true 时返回处理后的密码（这里就是原密码）

  const PasswordValidationResult.valid(String pwd)
      : isValid = true,
        message = null,
        password = pwd;

  const PasswordValidationResult.invalid(String errorMessage)
      : isValid = false,
        message = errorMessage,
        password = null;
}

/// 校验密码是否符合规则：6~12 位、只能是英文和数字
PasswordValidationResult validateAppPassword(String input) {
  // 去除首尾空格（用户可能手滑）
  final pwd = input.trim();

  if (pwd.isEmpty) {
    return const PasswordValidationResult.invalid("密码不能为空");
  }

  if (pwd.length < 6 || pwd.length > 12) {
    return const PasswordValidationResult.invalid("密码长度必须为 6～12 位");
  }

  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(pwd)) {
    return const PasswordValidationResult.invalid("密码只能包含英文和数字");
  }

  // 全部通过
  return PasswordValidationResult.valid(pwd);
}

class SetPasswordPage extends StatefulWidget {
  final Function(String) onPasswordSet;
  const SetPasswordPage({super.key, required this.onPasswordSet});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final p1 = TextEditingController();
  final p2 = TextEditingController();
  String? error;

  void submit() {
    setState(() => error = null);

    if (p1.text.isEmpty || p2.text.isEmpty) {
      setState(() => error = "密码不能为空");
      return;
    }

    if (p1.text != p2.text) {
      setState(() => error = "两次密码不一致");
      return;
    }

    // 使用统一的校验函数
    final result = validateAppPassword(p1.text);

    if (!result.isValid) {
      setState(() => error = result.message);
      return;
    }

    // 校验通过 → 传入处理后的干净密码（已 trim）
    widget.onPasswordSet(result.password!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("设置密码", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("6～12位，只能用英文和数字", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 20),

              TextField(
                controller: p1,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "输入密码",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: p2,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "再次输入确认",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13.5)),
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("确定", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}