import 'package:permission_handler/permission_handler.dart';

/// AppPermissions — درخواست پرمیشن‌های لازم برای دمو
class AppPermissions {
  /// بلوتوث + لوکیشن (برای Android 12+ الزامی)
  static Future<bool> ensureBT() async {
    final reqs = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    bool allGranted = true;
    for (final p in reqs) {
      final s = await p.request();
      if (!s.isGranted) allGranted = false;
    }
    return allGranted;
  }

  /// بلوتوث + دوربین (برای اسکن/دریافت QR در بعضی صفحات)
  static Future<bool> ensureBTAndCamera() async {
    final okBT = await ensureBT();
    final cam = await Permission.camera.request();
    return okBT && cam.isGranted;
  }

  /// فقط دوربین
  static Future<bool> ensureCamera() async {
    final cam = await Permission.camera.request();
    return cam.isGranted;
  }
}
