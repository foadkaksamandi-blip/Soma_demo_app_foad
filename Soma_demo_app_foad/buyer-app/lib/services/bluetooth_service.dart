import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// سرویس ساده برای اتصال، ارسال و دریافت پیام (UTF8) از طریق Bluetooth RFCOMM
class BluetoothService {
  static final BluetoothService _i = BluetoothService._();
  BluetoothService._();
  factory BluetoothService() => _i;

  BluetoothConnection? _conn;
  final _stream = StreamController<String>.broadcast();

  Stream<String> get onData => _stream.stream;
  bool get isConnected => _conn?.isConnected ?? false;

  Future<bool> connect(String address) async {
    try {
      _conn = await BluetoothConnection.toAddress(address);
      _conn!.input?.listen((data) {
        final msg = utf8.decode(data);
        _stream.add(msg);
      }, onDone: () => disconnect());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendJson(Map<String, dynamic> json) async {
    if (!isConnected) return;
    final line = jsonEncode(json) + '\n';
    _conn!.output.add(utf8.encode(line));
    await _conn!.output.allSent;
  }

  void disconnect() {
    _conn?.dispose();
    _conn = null;
  }
}
