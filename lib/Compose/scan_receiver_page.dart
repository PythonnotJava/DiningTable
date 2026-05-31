import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../Logic/card_info.dart';
import '../Logic/file_system.dart';
import '../Logic/lan_share_service.dart';
import 'temp_preview_page.dart';

/// 扫码接收页：扫描对方二维码 → 拉取卡片 → 临时预览 / 永久合并。
class ScanReceiverPage extends StatefulWidget {
  const ScanReceiverPage({super.key});

  @override
  State<ScanReceiverPage> createState() => _ScanReceiverPageState();
}

class _ScanReceiverPageState extends State<ScanReceiverPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// 防止扫到一次后重复处理
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null) return;

    final info = ShareConnectInfo.tryParse(raw);
    if (info == null) {
      /// 不是本应用的二维码，忽略继续扫
      return;
    }

    setState(() => _handling = true);
    await _controller.stop();
    await _handleConnect(info);
  }

  Future<void> _handleConnect(ShareConnectInfo info) async {
    _showLoading('正在接收数据...');
    try {
      final cards = await LanShareReceiver.fetchCards(info);
      if (!mounted) return;
      _dismissLoading(); // 关闭 loading

      if (info.mode == ShareMode.temporary) {
        await _enterTempPreview(cards);
      } else {
        await _doPermanentMerge(cards);
      }
    } catch (e) {
      if (!mounted) return;
      _dismissLoading(); // 关闭 loading
      await _showResultDialog(
        success: false,
        title: '接收失败',
        message: e.toString(),
      );
      _resumeScan();
    }
  }

  Future<void> _enterTempPreview(List<CardInfo> cards) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TempPreviewPage(cards: cards),
      ),
    );
  }

  Future<void> _doPermanentMerge(List<CardInfo> cards) async {
    final result = mergeCards(cards);
    final added = result[0];
    final skipped = result[1];
    await _showResultDialog(
      success: true,
      title: '合并完成',
      message: '收到 ${cards.length} 张卡片\n新增 $added 张，跳过 $skipped 张（key 重复）',
    );
    if (mounted) Navigator.pop(context); // 返回上一页
  }

  /// 持有 loading 弹窗自己的 context，确保能精确关闭它
  /// （本 app 存在嵌套 MaterialApp，用页面 context.pop 会错位）
  BuildContext? _loadingCtx;

  void _showLoading(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogCtx) {
        _loadingCtx = dialogCtx;
        return Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(text),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 关闭 loading 弹窗（用弹窗自身的 context，避免导航器错位）
  void _dismissLoading() {
    final ctx = _loadingCtx;
    if (ctx != null && Navigator.canPop(ctx)) {
      Navigator.pop(ctx);
    }
    _loadingCtx = null;
  }

  Future<void> _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          success ? Icons.check_circle : Icons.error_outline,
          color: success ? Colors.green : Colors.red,
          size: 48,
        ),
        title: Text(title),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _resumeScan() {
    if (!mounted) return;
    setState(() => _handling = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫码接收'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.no_photography,
                        color: Colors.white70,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '无法打开相机\n${error.errorDetails?.message ?? error.errorCode.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          /// 取景框装饰
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          Positioned(
            bottom: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '将取景框对准对方的分享二维码',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
