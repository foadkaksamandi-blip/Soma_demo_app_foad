// buyer-app/lib/services/transaction_service.dart
import '../models/tx_log.dart';

/// فرمت سادهٔ پیام‌های دمو روی QR/Bluetooth:
/// SOMA|K1=V1|K2=V2|...
class TransactionService {
  static String buildRequestPayload({required int amount, required String source}) {
    // درخواستی که فروشنده تولید می‌کند و خریدار اسکن می‌کند
    return _encode({
      'TYPE': 'REQ',
      'AMOUNT': amount.toString(),
      'SOURCE': source,
    });
  }

  static String buildBuyerConfirmQr(TxLog log) {
    // تاییدیه پرداخت که خریدار نمایش می‌دهد تا فروشنده اسکن کند
    return _encode({
      'TYPE': 'CONFIRM',
      'ID': log.id,
      'AMOUNT': log.amount.toString(),
      'SOURCE': log.source,
      'METHOD': log.method,
      'CP': log.counterparty,
      'TS': log.at.millisecondsSinceEpoch.toString(),
    });
  }

  static String buildMerchantConfirm({required TxLog log}) {
    // پیام تایید برای نمایش/ثبت (سناریوی بلوتوث دمو)
    return _encode({
      'TYPE': 'CONFIRM',
      'ID': log.id,
      'AMOUNT': log.amount.toString(),
      'SOURCE': log.source,
      'METHOD': log.method,
      'CP': log.counterparty,
      'TS': log.at.millisecondsSinceEpoch.toString(),
    });
  }

  static Map<String, String> parseInboundPayload(String raw) {
    // raw: SOMA|K=V|K=V...
    final out = <String, String>{};
    if (!raw.startsWith('SOMA')) return out;
    final parts = raw.split('|');
    for (int i = 1; i < parts.length; i++) {
      final kv = parts[i].split('=');
      if (kv.length == 2) out[kv[0]] = kv[1];
    }
    return out;
  }

  static String _encode(Map<String, String> m) {
    final buf = StringBuffer('SOMA');
    m.forEach((k, v) => buf.write('|$k=$v'));
    return buf.toString();
  }
}
