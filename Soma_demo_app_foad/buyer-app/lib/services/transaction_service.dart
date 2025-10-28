// buyer-app/lib/services/transaction_service.dart
import 'dart:convert';
import '../models/tx_log.dart';
import 'local_db.dart';

/// سرویس مرکزی تراکنش در اپ خریدار.
/// - مسئول محاسبه و اعمال تغییر موجودی (لوکال)
/// - ساخت رسید (TxLog)
/// - تولید payload برای QR یا Bluetooth
class TransactionService {
  TransactionService._();

  /// بررسی کفایت موجودی بر اساس منبع انتخابی.
  static bool hasSufficientBalance(int amount, String source) {
    // در دمو: موجودی واحد داریم؛ در آینده می‌توان برای هر کیف جداگانه نگه داشت.
    return LocalDB.instance.buyerBalance >= amount;
  }

  /// اعمال تراکنش خرید (کسر از خریدار).
  static TxLog applyBuyerDebit({
    required int amount,
    required String source,
    required String method, // 'Bluetooth' | 'QR'
    String counterparty = 'merchant',
  }) {
    // کنترل موجودی
    if (!hasSufficientBalance(amount, source)) {
      // خطای کمبود موجودی: رسید ناموفق (در صورت نیاز)
      return TxLog(
        id: 'FAIL-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        source: source,
        method: method,
        createdAt: DateTime.now(),
        counterparty: counterparty,
        success: false,
      );
    }

    // کسر از موجودی
    LocalDB.instance.addBuyerBalance(-amount);

    // رسید موفق
    final log = TxLog.success(
      amount: amount,
      source: source,
      method: method,
      counterparty: counterparty,
    );

    // (اختیاری) ذخیره در لاگ محلی—در این دمو می‌تونیم بعداً اضافه کنیم
    // LocalDB.instance.appendBuyerTx(log);

    return log;
  }

  /// تولید payload برای ارسال به فروشنده (Bluetooth/QR)
  /// فرمت ساده و خوانا برای دمو:
  /// SOMA|ROLE=BUYER|AMOUNT=100000|SOURCE=یارانه|TS=...|TX=...
  static String buildOutboundPayload(TxLog log) {
    final fields = [
      'SOMA',
      'ROLE=BUYER',
      'AMOUNT=${log.amount}',
      'SOURCE=${log.source}',
      'TX=${log.id}',
      'TS=${log.createdAt.toIso8601String()}',
    ];
    return fields.join('|');
  }

  /// پارس کردن payload دریافتی از فروشنده (مثلاً در اسکن QR فروشنده)
  /// انتظار: SOMA|ROLE=MERCHANT|AMOUNT=...|SOURCE=...|TS=...|REQ=...
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

  /// تایید تطابق مبلغ ادعایی فروشنده با ورودی خریدار
  static bool amountsMatch({required int expected, required int claimed}) {
    return expected > 0 && claimed > 0 && expected == claimed;
  }

  /// تولید QR برای پاسخ (مرحله دوم): پس از موفقیت پرداخت خریدار، QR جهت ثبت در فروشنده.
  /// SOMA|ROLE=BUYER|CONFIRM=OK|TX=...|AMOUNT=...|SOURCE=...
  static String buildBuyerConfirmQr(TxLog log) {
    final fields = [
      'SOMA',
      'ROLE=BUYER',
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
