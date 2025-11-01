import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> ensureBTAndCamera() async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) return false;

    if (Platform.isAndroid) {
      final btScan = await Permission.bluetoothScan.request();
      final btConnect = await Permission.bluetoothConnect.request();
      final loc = await Permission.locationWhenInUse.request();
      if (!(btScan.isGranted && btConnect.isGranted && loc.isGranted)) {
        return false;
      }
    }
    return true;
  }
}
