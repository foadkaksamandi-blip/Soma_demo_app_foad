import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> ensureBluetooth() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  static Future<bool> ensureCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> ensureLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
}
