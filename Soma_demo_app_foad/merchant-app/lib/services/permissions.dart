// merchant-app/lib/services/permissions.dart
class AppPermissions {
  AppPermissions._();

  static Future<bool> ensureCamera() async {
    return true;
  }

  static Future<bool> ensureBluetooth() async {
    return true;
  }
}
