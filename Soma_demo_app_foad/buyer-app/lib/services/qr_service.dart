import 'dart:convert';

/// سرویس ساده QR برای خریدار: ساخت/تجزیه Payload تراکنش.
/// این نسخه وابستگی خارجی ندارد و فقط JSON ساده تولید/تحلیل می‌کند.
class BuyerQrService {
  const BuyerQrService();

  /// ساخت payload استاندارد سوما
  String buildPayload({
    required int amount,
    required String txId,
  }) {
    final map = {
      'type': 'soma_tx',
      'amount': amount,
      'tx_id': txId,
    };
    return jsonEncode(map);
  }

  /// تبدیل String به Map (در صورت نامعتبر بودن null برمی‌گرداند)
  Map<String, dynamic>? parse(String raw) {
    try {
      final obj = jsonDecode(raw);
      if (obj is Map<String, dynamic> &&
          obj['type'] == 'soma_tx' &&
          obj.containsKey('amount') &&
          obj.containsKey('tx_id')) {
        return obj;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
