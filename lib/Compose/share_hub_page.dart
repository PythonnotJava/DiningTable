import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../Logic/file_share_service.dart';
import '../Logic/lan_share_service.dart';
import 'import_helper.dart';
import 'scan_receiver_page.dart';
import 'share_sender_page.dart';

/// 分享中心：汇总「面对面扫码局域网共享」与「文件分享」入口。
class ShareHubPage extends StatelessWidget {
  const ShareHubPage({super.key});

  void _openSender(BuildContext context, ShareMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShareSenderPage(mode: mode)),
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanReceiverPage()),
    );
  }

  Future<void> _shareFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FileShareService.shareHiveFile();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('分享失败：$e')),
      );
    }
  }

  /// 从本地选择 .hive 文件并导入。
  /// 这是最可靠的导入方式：绕开系统对自定义扩展名的 MIME 识别。
  Future<void> _importFromFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    String? path;
    try {
      // 用 any 类型，避免不同系统对自定义扩展名过滤后选不到文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return; // 用户取消
      path = result.files.single.path;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('选择文件失败：$e')));
      return;
    }

    if (path == null) {
      messenger.showSnackBar(const SnackBar(content: Text('无法读取所选文件路径')));
      return;
    }
    if (!context.mounted) return;
    await runImportFlow(context, path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分享与同步')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('面对面共享'),
          _ShareTile(
            icon: Icons.qr_code_scanner,
            color: Colors.indigo,
            title: '扫码接收',
            subtitle: '扫描对方二维码，接收他分享的卡片',
            onTap: () => _openScanner(context),
          ),
          _ShareTile(
            icon: Icons.qr_code_2,
            color: Colors.teal,
            title: '临时分享',
            subtitle: '生成二维码，对方扫码后仅能临时查看，不写入其数据库',
            onTap: () => _openSender(context, ShareMode.temporary),
          ),
          _ShareTile(
            icon: Icons.merge_type,
            color: Colors.deepPurple,
            title: '永久合并分享',
            subtitle: '生成二维码，对方扫码后合并到数据库，key 相同的卡片自动跳过',
            onTap: () => _openSender(context, ShareMode.permanent),
          ),
          const SizedBox(height: 8),
          _sectionTitle('文件分享'),
          _ShareTile(
            icon: Icons.ios_share,
            color: Colors.orange,
            title: '导出并分享数据文件',
            subtitle: '通过微信、蓝牙等任意渠道发送 .hive 文件，对方可在 DiningTable 内「从文件导入」',
            onTap: () => _shareFile(context),
          ),
          _ShareTile(
            icon: Icons.folder_open,
            color: Colors.green,
            title: '从文件导入',
            subtitle: '选择本地的 .hive 文件（如 Download 里的文件）合并到本机',
            onTap: () => _importFromFile(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );
}

class _ShareTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
