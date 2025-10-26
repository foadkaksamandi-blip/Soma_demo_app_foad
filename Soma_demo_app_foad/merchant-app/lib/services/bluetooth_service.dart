import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// سرویس بلوتوث واقعی (Classic RFCOMM) برای فروشنده
/// قابلیت‌ها: روشن‌کردن بلوتوث، قابل‌مشاهده کردن دستگاه، گوش‌دادن به اتصال ورودی، دریافت JSON
class MerchantBluetoothService {
  MerchantBluetoothService._();
  static final MerchantBluetoothService instance = MerchantBluetoothService._();

  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  Stream<String>? _inbound;

  Future<bool> ensureEnabled() async {
    final state = await _bluetooth.state;
    if (state == BluetoothState.STATE_OFF) {
      final enabled = await _bluetooth.requestEnable();
      return enabled ?? false;
    }
    return true;
  }

  /// فعال کردن discoverable تا خریدار دستگاه را ببیند (نیازمند تأیید کاربر در اندروید)
  Future<bool> becomeDiscoverable({int seconds = 120}) async {
    final ok = await ensureEnabled();
    if (!ok) return false;
    final allowed = await _bluetooth.requestDiscoverable(seconds);
    return (allowed ?? 0) > 0;
  }

  /// منتظر اتصال از طرف خریدار (با آدرس)
  /// توجه: در RFCOMM غالباً یک آدرس مقصد لازم است؛ برای سادگی دمو، پس از discoverable شدن،
  /// اتصال معمولاً توسط خریدار برقرار می‌شود و فروشنده فقط پیام‌ها را می‌خواند.
  Future<void> setConnection(BluetoothConnection connection) async {
    // در این دمو، اتصال می‌تواند از بیرون پاس داده شود یا با نقش سرور سفارشی پیاده‌سازی شود.
    _connection = connection;
    _inbound = _connection!.input!
        .map((data) => utf8.decode(data))
        .transform(const LineSplitter()); // پیام‌ها با \n جدا می‌شوند
  }

  Stream<String>? get inboundLines => _inbound;

  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection?.dispose();
    } catch (_) {}
    _connection = null;
  }
}
