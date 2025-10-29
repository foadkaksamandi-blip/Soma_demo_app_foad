import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  BluetoothConnection? _connection;
  final StreamController<String> _onDataReceived = StreamController.broadcast();

  Stream<String> get onData => _onDataReceived.stream;

  Future<bool> connect(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      _connection!.input!.listen((data) {
        final message = utf8.decode(data);
        _onDataReceived.add(message);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendData(String message) async {
    if (_connection?.isConnected ?? false) {
      _connection!.output.add(utf8.encode(message));
      await _connection!.output.allSent;
    }
  }

  void disconnect() {
    _connection?.dispose();
    _connection = null;
  }

  bool get isConnected => _connection?.isConnected ?? false;
}
