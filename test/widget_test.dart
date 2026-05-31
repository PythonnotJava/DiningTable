// DiningTable 共享功能单元测试。
//
// 覆盖不依赖 Hive/平台的纯逻辑：
//  1. 二维码连接信息的编码 / 解码往返
//  2. CardInfo 的 JSON 序列化往返
//  3. 非法二维码内容的健壮性

import 'package:flutter_test/flutter_test.dart';

import 'package:diningtable/Logic/card_info.dart';
import 'package:diningtable/Logic/lan_share_service.dart';

void main() {
  group('ShareConnectInfo 二维码编解码', () {
    test('永久模式编码后能正确解码', () {
      final info = ShareConnectInfo(
        ip: '192.168.1.20',
        port: 53217,
        mode: ShareMode.permanent,
        token: 'abc123',
      );
      final payload = info.toQrPayload();
      final parsed = ShareConnectInfo.tryParse(payload);

      expect(parsed, isNotNull);
      expect(parsed!.ip, '192.168.1.20');
      expect(parsed.port, 53217);
      expect(parsed.mode, ShareMode.permanent);
      expect(parsed.token, 'abc123');
    });

    test('临时模式编码后能正确解码', () {
      final info = ShareConnectInfo(
        ip: '10.0.0.5',
        port: 8080,
        mode: ShareMode.temporary,
        token: 't',
      );
      final parsed = ShareConnectInfo.tryParse(info.toQrPayload());
      expect(parsed, isNotNull);
      expect(parsed!.mode, ShareMode.temporary);
    });

    test('非本应用二维码返回 null', () {
      expect(ShareConnectInfo.tryParse('https://example.com'), isNull);
      expect(ShareConnectInfo.tryParse('随便一段文字'), isNull);
      expect(ShareConnectInfo.tryParse(''), isNull);
    });

    test('缺少必需字段返回 null', () {
      expect(
        ShareConnectInfo.tryParse('diningtable://share?token=x'),
        isNull,
      );
    });
  });

  group('CardInfo JSON 往返', () {
    test('toJson / fromJson 字段一致', () {
      final card = CardInfo(
        target: '目标',
        sign: '标签',
        content: '内容\n多行',
        key: '42',
        time: '2026-05-31 10:00:00.000',
      );
      final restored = CardInfo.fromJson(card.toJson());
      expect(restored.target, card.target);
      expect(restored.sign, card.sign);
      expect(restored.content, card.content);
      expect(restored.key, card.key);
      expect(restored.time, card.time);
    });

    test('字段缺失时回退为空串', () {
      final restored = CardInfo.fromJson({'key': '1'});
      expect(restored.key, '1');
      expect(restored.target, '');
      expect(restored.content, '');
    });
  });
}
