import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> ensureBTAndCamera() async {
    final cam = await Permission.camera.request();
    final bt = await Permission.bluetoothScan.request();
    final btC = await Permission.bluetoothConnect.request();

    return cam.isGranted && (bt.isGranted || bt.isLimited) && (btC.isGranted || btC.isLimited);
  }
}
