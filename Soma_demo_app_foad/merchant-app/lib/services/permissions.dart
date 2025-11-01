import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> ensureBtAndCamera() async {
    final bt = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request();
    final loc = await Permission.locationWhenInUse.request();
    final cam = await Permission.camera.request();
    return bt.isGranted && scan.isGranted && loc.isGranted && cam.isGranted;
  }
}
