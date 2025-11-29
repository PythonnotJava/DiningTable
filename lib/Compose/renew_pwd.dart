import 'package:flutter/material.dart';

import '../Logic/file_system.dart';
import 'set_page.dart';

/// 修改密码对话框（不可通过返回键或点击外部关闭）
Future<bool> showChangePasswordDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 点击外部不关闭
    builder: (ctx) => _ChangePasswordDialog(context),
  ) ??
      false; // 用户强制关闭（极少发生）算取消
}

class _ChangePasswordDialog extends StatefulWidget {
  final BuildContext parentContext;
  const _ChangePasswordDialog(this.parentContext);

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldController = TextEditingController();
  final _new1Controller = TextEditingController();
  final _new2Controller = TextEditingController();

  String? _errorText;
  bool _obscureOld = true;
  bool _obscureNew1 = true;
  bool _obscureNew2 = true;

  @override
  void dispose() {
    _oldController.dispose();
    _new1Controller.dispose();
    _new2Controller.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _errorText = null);

    final oldPwd = _oldController.text.trim();
    final new1 = _new1Controller.text;
    final new2 = _new2Controller.text;

    // 1. 原密码不能为空
    if (oldPwd.isEmpty) {
      setState(() => _errorText = "请输入原密码");
      return;
    }

    // 2. 两次新密码一致
    if (new1.isEmpty || new2.isEmpty) {
      setState(() => _errorText = "新密码不能为空");
      return;
    }
    if (new1 != new2) {
      setState(() => _errorText = "两次输入的新密码不一致");
      return;
    }

    // 3. 新密码符合 6~12 位英文数字规则
    final validateResult = validateAppPassword(new1);
    if (!validateResult.isValid) {
      setState(() => _errorText = validateResult.message);
      return;
    }

    try {
      await writeToConfigJson(key: 'pwd', value: validateResult.password);

      if (!mounted) return;
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text("密码修改成功")),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _errorText = "保存失败，请重试");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 禁用返回键
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("修改密码"),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 原密码
              TextField(
                controller: _oldController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: "原密码",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              // 新密码1
              TextField(
                controller: _new1Controller,
                obscureText: _obscureNew1,
                decoration: InputDecoration(
                  labelText: "新密码（6～12位英文数字）",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew1 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew1 = !_obscureNew1),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              // 新密码2
              TextField(
                controller: _new2Controller,
                obscureText: _obscureNew2,
                decoration: InputDecoration(
                  labelText: "再次输入新密码",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew2 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew2 = !_obscureNew2),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (_) => _submit(),
              ),

              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 13.5),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // 取消
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: _submit,
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }
}