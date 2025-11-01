import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BuyerBluetoothService {
  static const String kServiceUuid = "0000ffaa-0000-1000-8000-00805f9b34fb";
  static const String kCharUuid = "0000ffab-0000-1000-8000-00805f9b34fb";

  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar;

  Future<bool> connectFirstMerchant() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    final scanRes = await FlutterBluePlus.scanResults.first;
    await FlutterBluePlus.stopScan();

    for (final r in scanRes) {
      final name = r.device.platformName;
      if (name.toLowerCase().contains("soma-merchant")) {
        _device = r.device;
        break;
      }
    }
    _device ??= scanRes.isNotEmpty ? scanRes.first.device : null;
    if (_device == null) return false;

    await _device!.connect(autoConnect: false, timeout: const Duration(seconds: 8)).onError((_, __){});
    final services = await _device!.discoverServices();
    for (final s in services) {
      if (s.uuid.str128.toLowerCase() == kServiceUuid) {
        for (final c in s.characteristics) {
          if (c.uuid.str128.toLowerCase() == kCharUuid) {
            _txChar = c;
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<bool> sendPayment({
    required int amount,
    required String wallet,
    required String txId,
  }) async {
    if (_txChar == null) return false;
    final payload = jsonEncode({
      "type": "PAY",
      "amount": amount,
      "wallet": wallet,
      "txId": txId,
      "ts": DateTime.now().toIso8601String()
    });
    final bytes = utf8.encode(payload);
    await _txChar!.write(bytes, withoutResponse: true);
    return true;
  }

  Future<void> dispose() async {
    try { await _device?.disconnect(); } catch (_) {}
  }
}
