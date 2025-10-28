// buyer-app/lib/services/permissions.dart
/// Helper ساده برای اجازه‌ها (بی‌نیاز از وابستگی خارجی برای حفظ بیلد سبز).
/// در فاز بعدی، این متدها با permission_handler یا PlatformChannel تکمیل می‌شوند.
class AppPermissions {
  AppPermissions._();

  /// اجازهٔ دوربین برای اسکن QR (فعلاً true تا دمو جلو بره)
  static Future<bool> ensureCamera() async {
    return true;
  }

  /// اجازه‌های لازم برای Bluetooth (فعلاً true تا دمو جلو بره)
  static Future<bool> ensureBluetooth() async {
    return true;
  }
}
