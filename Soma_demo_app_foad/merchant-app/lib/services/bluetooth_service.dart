import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MerchantBluetoothService {
  static const String kServiceUuid = "0000ffaa-0000-1000-8000-00805f9b34fb";
  static const String kCharUuid = "0000ffab-0000-1000-8000-00805f9b34fb";

  BluetoothCharacteristic? _rxChar;

  Future<void> advertise() async {
    // FlutterBluePlus فعلاً تبلیغ BLE ندارد؛ روی دستگاه فروشنده فقط منتظر اتصال می‌مانیم و از characteristic نوتیفیکیشن می‌گیریم.
  }

  Future<bool> attachToCharacteristic(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final s in services) {
      if (s.uuid.str128.toLowerCase() == kServiceUuid) {
        for (final c in s.characteristics) {
          if (c.uuid.str128.toLowerCase() == kCharUuid) {
            _rxChar = c;
            await _rxChar!.setNotifyValue(true);
            return true;
          }
        }
      }
    }
    return false;
  }

  Stream<Map<String, dynamic>> onPayments() async* {
    if (_rxChar == null) return;
    await for (final v in _rxChar!.value) {
      try {
        final s = utf8.decode(v);
        final m = jsonDecode(s) as Map<String, dynamic>;
        if (m['type'] == 'PAY') yield m;
      } catch (_) {}
    }
  }
}
