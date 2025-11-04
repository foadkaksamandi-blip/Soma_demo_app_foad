import 'dart:async';

class BluetoothService {
  bool _connected = false;
  bool get isConnected => _connected;

  Future<void> waitForBuyer() async {
    await Future.delayed(const Duration(seconds: 2));
    _connected = true;
  }

  Future<void> disconnect() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _connected = false;
  }

  Future<String> receivePayment() async {
    if (!_connected) throw Exception('Bluetooth not connected');
    await Future.delayed(const Duration(milliseconds: 800));
    return 'RECV-${DateTime.now().millisecondsSinceEpoch}';
  }
}
