import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class SomaPermissions {
  static Future<bool> forCamera() async {
    final st = await Permission.camera.request();
    return st.isGranted;
  }

  static Future<bool> forBluetooth() async {
    if (Platform.isAndroid) {
      final r1 = await Permission.bluetoothScan.request();
      final r2 = await Permission.bluetoothConnect.request();
      return r1.isGranted && r2.isGranted;
    }
    return true;
  }
}
