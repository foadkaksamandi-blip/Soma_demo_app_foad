import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// سرویس بلوتوث واقعی (Classic RFCOMM) برای خریدار
/// قابلیت‌ها: روشن‌کردن بلوتوث، اسکن دستگاه‌ها، اتصال به یک دستگاه، ارسال پیام JSON
class BuyerBluetoothService {
  BuyerBluetoothService._();
  static final BuyerBluetoothService instance = BuyerBluetoothService._();

  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;

  Future<bool> ensureEnabled() async {
    final state = await _bluetooth.state;
    if (state == BluetoothState.STATE_OFF) {
      final enabled = await _bluetooth.requestEnable();
      return enabled ?? false;
    }
    return true;
  }

  /// جستجو برای دستگاه‌های نزدیک (فروشنده)
  Future<List<BluetoothDevice>> scanDevices({Duration duration = const Duration(seconds: 4)}) async {
    final ok = await ensureEnabled();
    if (!ok) return [];
    final bonded = await _bluetooth.getBondedDevices();
    // در دمو: لیست پیوندشده‌ها سریع‌تر است. (در صورت نیاز، می‌توان Discovery را هم فعال کرد)
    return bonded;
  }

  /// اتصال به دستگاه با آدرس مک
  Future<bool> connect(String address) async {
    await disconnect();
    try {
      _connection = await BluetoothConnection.toAddress(address);
      return _connection?.isConnected ?? false;
    } catch (_) {
      _connection = null;
      return false;
    }
  }

  bool get isConnected => _connection?.isConnected ?? false;

  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection?.dispose();
    } catch (_) {}
    _connection = null;
  }

  /// ارسال پیام تراکنش به فروشنده
  /// payload باید JSON String باشد (مثلاً: {"type":"soma_tx","amount":...,"tx_id":"...","method":"BT"})
  Future<bool> sendJson(String jsonPayload) async {
    if (_connection == null || !(_connection?.isConnected ?? false)) return false;
    try {
      final data = utf8.encode('$jsonPayload\n'); // با \n برای تفکیک پیام‌ها
      _connection!.output.add(data);
      await _connection!.output.allSent;
      return true;
    } catch (_) {
      return false;
    }
  }
}
