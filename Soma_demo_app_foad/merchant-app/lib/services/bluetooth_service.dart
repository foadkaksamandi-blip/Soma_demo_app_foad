import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// BuyerBluetoothService
/// - اسکن دستگاه‌های جفت‌شده
/// - اتصال به آدرس MAC
/// - ارسال پیام JSON خط‌دار (\n)
class BuyerBluetoothService {
  BuyerBluetoothService._();
  static final BuyerBluetoothService instance = BuyerBluetoothService._();

  final FlutterBluetoothSerial _bt = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;

  Future<bool> ensureEnabled() async {
    final state = await _bt.state;
    if (state == BluetoothState.STATE_OFF) {
      final enabled = await _bt.requestEnable();
      return enabled ?? false;
    }
    return true;
  }

  Future<List<BluetoothDevice>> scanDevices({Duration timeout = const Duration(seconds: 4)}) async {
    final ok = await ensureEnabled();
    if (!ok) return [];
    try {
      final bonded = await _bt.getBondedDevices();
      return bonded;
    } catch (_) {
      return [];
    }
  }

  Future<bool> connect(String address) async {
    await disconnect();
    try {
      _connection = await BluetoothConnection.toAddress(address);
      // optionally listen to input here
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

  Future<bool> sendJson(String jsonPayload) async {
    if (_connection == null || !(_connection?.isConnected ?? false)) return false;
    try {
      final data = utf8.encode('$jsonPayload\n');
      _connection!.output.add(data);
      await _connection!.output.allSent;
      return true;
    } catch (_) {
      return false;
    }
  }
}
