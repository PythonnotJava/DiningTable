import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../Logic/lan_share_service.dart';

/// 发送页：起本地 HTTP 服务并展示二维码，等待对方扫码拉取。
class ShareSenderPage extends StatefulWidget {
  final ShareMode mode;
  const ShareSenderPage({super.key, required this.mode});

  @override
  State<ShareSenderPage> createState() => _ShareSenderPageState();
}

class _ShareSenderPageState extends State<ShareSenderPage> {
  LanShareSender? _sender;
  ShareConnectInfo? _info;
  String? _error;
  bool _starting = true;
  int _fetchedCount = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final sender = LanShareSender(
        onClientFetched: () {
          if (mounted) setState(() => _fetchedCount++);
        },
      );
      final info = await sender.start(widget.mode);
      _sender = sender;
      if (mounted) {
        setState(() {
          _info = info;
          _starting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _starting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _sender?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPermanent = widget.mode == ShareMode.permanent;
    return Scaffold(
      appBar: AppBar(
        title: Text(isPermanent ? '永久合并分享' : '临时分享'),
        backgroundColor: isPermanent ? Colors.deepPurple : Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(isPermanent),
        ),
      ),
    );
  }

  Widget _buildBody(bool isPermanent) {
    if (_starting) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在启动分享服务...'),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 56),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _starting = true;
                _error = null;
              });
              _start();
            },
            child: const Text('重试'),
          ),
        ],
      );
    }

    final info = _info!;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                ),
              ],
            ),
            child: QrImageView(
              data: info.toQrPayload(),
              version: QrVersions.auto,
              size: 240,
              gapless: false,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPermanent ? '让对方扫码即可合并你的全部卡片' : '让对方扫码即可临时查看你的全部卡片',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isPermanent
                ? '对方导入时，key 相同的卡片会自动跳过，不会覆盖已有数据'
                : '临时分享：对方只能预览，不会写入对方的数据库',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${info.ip}:${info.port}',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_fetchedCount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '已发送给 $_fetchedCount 台设备',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Text(
            '请保持本页面开启，直到对方接收完成',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
