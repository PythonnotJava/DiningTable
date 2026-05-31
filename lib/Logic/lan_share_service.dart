import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'card_info.dart';
import 'file_system.dart';

/// 局域网共享模式
enum ShareMode {
  /// 临时分享：接收方仅在内存中预览，不写入数据库
  temporary,

  /// 永久存储合并：接收方把数据合并进 cardsBox，key 相同则跳过
  permanent,
}

/// 二维码 / 网络传输的载荷格式版本号，便于将来兼容升级
const int kSharePayloadVersion = 1;

/// 二维码里编码的连接信息（接收方扫码后据此拉取数据）
class ShareConnectInfo {
  final String ip;
  final int port;
  final ShareMode mode;

  /// 一次性令牌，接收方拉取时需带上，防止同网段他人误连
  final String token;

  ShareConnectInfo({
    required this.ip,
    required this.port,
    required this.mode,
    required this.token,
  });

  /// 编码进二维码的字符串：自定义 scheme，避免被系统误识别为网页
  /// 形如 diningtable://share?ip=192.168.1.5&port=53217&mode=permanent&token=abc
  String toQrPayload() {
    final uri = Uri(
      scheme: 'diningtable',
      host: 'share',
      queryParameters: {
        'v': kSharePayloadVersion.toString(),
        'ip': ip,
        'port': port.toString(),
        'mode': mode == ShareMode.permanent ? 'permanent' : 'temporary',
        'token': token,
      },
    );
    return uri.toString();
  }

  /// 从二维码字符串解析。解析失败返回 null。
  static ShareConnectInfo? tryParse(String raw) {
    try {
      final uri = Uri.parse(raw.trim());
      if (uri.scheme != 'diningtable' || uri.host != 'share') {
        return null;
      }
      final ip = uri.queryParameters['ip'];
      final portStr = uri.queryParameters['port'];
      final token = uri.queryParameters['token'] ?? '';
      if (ip == null || ip.isEmpty || portStr == null) return null;
      final port = int.tryParse(portStr);
      if (port == null) return null;
      final mode = uri.queryParameters['mode'] == 'temporary'
          ? ShareMode.temporary
          : ShareMode.permanent;
      return ShareConnectInfo(ip: ip, port: port, mode: mode, token: token);
    } catch (_) {
      return null;
    }
  }
}

/// 发送端：在本机起一个极简 HTTP 服务，把全部卡片以 JSON 暴露在 /cards 路径。
/// 用法：
///   final sender = LanShareSender();
///   final info = await sender.start(ShareMode.permanent);
///   // 把 info.toQrPayload() 生成二维码展示
///   // 完成后务必调用 sender.stop()
class LanShareSender {
  HttpServer? _server;
  String? _token;
  ShareMode _mode = ShareMode.permanent;

  /// 接收方成功拉取数据后回调（用于在 UI 上提示"已发送给 1 台设备"）
  void Function()? onClientFetched;

  LanShareSender({this.onClientFetched});

  bool get isRunning => _server != null;

  /// 启动服务并返回连接信息。失败抛异常。
  Future<ShareConnectInfo> start(ShareMode mode) async {
    await stop();
    _mode = mode;
    _token = _generateToken();

    final ip = await getLanIpAddress();
    if (ip == null) {
      throw const LanShareException('无法获取局域网 IP，请确认已连接到 Wi-Fi 或热点');
    }

    /// 绑定到 anyIPv4，端口交给系统分配（传 0）
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    server.listen(_handleRequest, onError: (e) {
      debugPrint('LanShareSender 监听出错: $e');
    });

    debugPrint('LanShareSender 已启动: http://$ip:${server.port}');
    return ShareConnectInfo(
      ip: ip,
      port: server.port,
      mode: mode,
      token: _token!,
    );
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      /// 允许跨域，纯局域网场景无安全顾虑
      request.response.headers.set('Access-Control-Allow-Origin', '*');

      if (request.uri.path != '/cards') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      /// 校验令牌
      final token = request.uri.queryParameters['token'];
      if (_token != null && token != _token) {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.write('forbidden');
        await request.response.close();
        return;
      }

      final payload = {
        'version': kSharePayloadVersion,
        'mode': _mode == ShareMode.permanent ? 'permanent' : 'temporary',
        'count': cardsBox.length,
        'cards': cardsBox.values.map((c) => c.toJson()).toList(),
      };

      request.response.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
      request.response.write(jsonEncode(payload));
      await request.response.close();

      onClientFetched?.call();
    } catch (e) {
      debugPrint('处理请求失败: $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      debugPrint('LanShareSender 已停止');
    }
  }

  static String _generateToken() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now.toRadixString(36);
  }
}

/// 接收端：根据连接信息从发送方拉取全部卡片。
class LanShareReceiver {
  /// 从发送方拉取卡片列表。失败抛 [LanShareException]。
  static Future<List<CardInfo>> fetchCards(ShareConnectInfo info) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri(
        scheme: 'http',
        host: info.ip,
        port: info.port,
        path: '/cards',
        queryParameters: {'token': info.token},
      );
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode == HttpStatus.forbidden) {
        throw const LanShareException('连接被拒绝：令牌不匹配，请重新扫码');
      }
      if (response.statusCode != HttpStatus.ok) {
        throw LanShareException('对方返回错误状态码: ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final rawCards = (decoded['cards'] as List?) ?? [];
      return rawCards
          .map((e) => CardInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on SocketException catch (e) {
      throw LanShareException('无法连接到对方设备，请确认两台设备在同一网络: ${e.message}');
    } on TimeoutException {
      throw const LanShareException('连接超时，请确认对方仍在分享页面');
    } finally {
      client.close(force: true);
    }
  }
}

/// 获取本机局域网 IPv4 地址。优先返回常见私有网段地址。
Future<String?> getLanIpAddress() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
      includeLoopback: false,
    );

    String? fallback;
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        final ip = addr.address;
        if (ip.startsWith('127.')) continue;
        /// 优先私有网段（192.168 / 10. / 172.16-31）
        if (_isPrivateIpv4(ip)) {
          return ip;
        }
        fallback ??= ip;
      }
    }
    return fallback;
  } catch (e) {
    debugPrint('获取局域网 IP 失败: $e');
    return null;
  }
}

bool _isPrivateIpv4(String ip) {
  if (ip.startsWith('192.168.')) return true;
  if (ip.startsWith('10.')) return true;
  if (ip.startsWith('172.')) {
    final parts = ip.split('.');
    if (parts.length >= 2) {
      final second = int.tryParse(parts[1]);
      if (second != null && second >= 16 && second <= 31) return true;
    }
  }
  return false;
}

/// 共享相关的统一异常类型，便于 UI 层友好提示
class LanShareException implements Exception {
  final String message;
  const LanShareException(this.message);
  @override
  String toString() => message;
}
