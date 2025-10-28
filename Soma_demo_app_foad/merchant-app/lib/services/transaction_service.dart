// merchant-app/lib/services/transaction_service.dart
import 'dart:convert';
import '../models/tx_log.dart';
import 'local_db.dart';

/// سرویس مرکزی تراکنش در اپ فروشنده.
/// - دریافت درخواست مبلغ از خریدار (QR/بلوتوث)
/// - اعتبارسنجی و افزایش موجودی فروشنده
/// - تولید رسید و پاسخ تایید (برای ثبت در خریدار)
class TransactionService {
  TransactionService._();

  /// اعمال تراکنش دریافت (واریز به فروشنده).
  static TxLog applyMerchantCredit({
    required int amount,
    required String source,
    required String method, // 'Bluetooth' | 'QR'
    String counterparty = 'buyer',
  }) {
    // افزایش موجودی نمایشی فروشنده
    LocalDBMerchant.instance.addMerchantBalance(amount);

    // رسید موفق
    final log = TxLog.success(
      amount: amount,
      source: source,
      method: method,
      counterparty: counterparty,
    );

    // (اختیاری) ذخیره در لاگ محلی—می‌توان بعداً اضافه کرد
    // LocalDBMerchant.instance.appendMerchantTx(log);

    return log;
  }

  /// ساخت payload درخواست (فروشنده → خریدار) برای اسکن توسط خریدار
  /// SOMA|ROLE=MERCHANT|AMOUNT=100000|SOURCE=یارانه|TS=...|REQ=...
  static String buildRequestPayload({
    required int amount,
    required String source,
  }) {
    final now = DateTime.now();
    final req = 'REQ-${now.millisecondsSinceEpoch}';
    final fields = [
      'SOMA',
      'ROLE=MERCHANT',
      'AMOUNT=$amount',
      'SOURCE=$source',
      'TS=${now.toIso8601String()}',
      'REQ=$req',
    ];
    return fields.join('|');
  }

  /// پارس کردن payload دریافتی
  static Map<String, String> parseInboundPayload(String raw) {
    final out = <String, String>{};
    for (final part in raw.split('|')) {
      if (!part.contains('=')) continue;
      final i = part.indexOf('=');
      final k = part.substring(0, i);
      final v = part.substring(i + 1);
      out[k] = v;
    }
    return out;
  }

  /// بررسی تطابق مبالغ (در صورت لزوم)
  static bool amountsMatch({required int expected, required int claimed}) {
    return expected > 0 && claimed > 0 && expected == claimed;
  }

  /// تولید پاسخ تایید (برای نمایش خریدار یا ثبت)
  /// SOMA|ROLE=MERCHANT|CONFIRM=OK|TX=...|AMOUNT=...|SOURCE=...
  static String buildMerchantConfirm({
    required TxLog log,
  }) {
    final fields = [
      'SOMA',
      'ROLE=MERCHANT',
      'CONFIRM=OK',
      'TX=${log.id}',
      'AMOUNT=${log.amount}',
      'SOURCE=${log.source}',
      'TS=${log.createdAt.toIso8601String()}',
    ];
    return fields.join('|');
  }

  /// نسخه JSON از رسید (برای نمایش/دیباگ)
  static String logAsPrettyJson(TxLog log) {
    return const JsonEncoder.withIndent('  ').convert(log.toJson());
  }
}
