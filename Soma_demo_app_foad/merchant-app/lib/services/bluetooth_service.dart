import 'dart:convert';
import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// MerchantBluetoothService
/// - قابل discoverable شدن
/// - مدیریت اتصال ورودی (RFCOMM)
/// - ارائه stream از خطوط ورودی JSON
class MerchantBluetoothService {
  MerchantBluetoothService._();
  static final MerchantBluetoothService instance = MerchantBluetoothService._();

  final FlutterBluetoothSerial _bt = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  StreamController<String>? _linesCtrl;

  Future<bool> ensureEnabled() async {
    final state = await _bt.state;
    if (state == BluetoothState.STATE_OFF) {
      final enabled = await _bt.requestEnable();
      return enabled ?? false;
    }
    return true;
  }

  Future<bool> becomeDiscoverable({int seconds = 120}) async {
    final ok = await ensureEnabled();
    if (!ok) return false;
    final allowed = await _bt.requestDiscoverable(seconds);
    return (allowed ?? 0) > 0;
  }

  /// در این پیاده‌سازی ساده: اتصال از سمت خریدار برقرار می‌شود و این تابع connection را می‌پذیرد
  Future<void> setConnection(BluetoothConnection connection) async {
    await disconnect();
    _connection = connection;
    _linesCtrl = StreamController<String>();
    _connection!.input!.listen((data) {
      try {
        final text = utf8.decode(data);
        // ممکن است چند خطی برسد؛ جداکن با \n
        final parts = text.split('\n');
        for (final p in parts) {
          if (p.trim().isNotEmpty) {
            _linesCtrl?.add(p.trim());
          }
        }
      } catch (_) {}
    }, onDone: () {
      _linesCtrl?.close();
    });
  }

  Stream<String>? get inboundLines => _linesCtrl?.stream;

  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection?.dispose();
    } catch (_) {}
    try {
      await _linesCtrl?.close();
    } catch (_) {}
    _connection = null;
    _linesCtrl = null;
  }
}
