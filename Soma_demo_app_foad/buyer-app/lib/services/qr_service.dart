import 'dart:convert';

class BuyerQrService {
  const BuyerQrService();

  String buildPayload({required int amount, required String txId}) {
    final map = {
      'type': 'soma_tx',
      'amount': amount,
      'tx_id': txId,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(map);
  }

  Map<String, dynamic>? parse(String raw) {
    try {
      final obj = jsonDecode(raw);
      if (obj is Map<String, dynamic> && obj['type'] == 'soma_tx' && obj.containsKey('amount') && obj.containsKey('tx_id')) {
        return obj;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
