SOMA Demo — Change log for build-ready step
DATE: <put date>

CHANGES:
- Replaced mobile_scanner and nearby_connections with flutter_blue_plus, qr_code_scanner, qr_flutter.
- Updated android compileSdk to 36 and Kotlin to 1.8.22.
- Added required Android Bluetooth and Camera permissions.
- Added sample lib/main.dart for buyer and merchant (BLE scan/connect + QR generate/scan).
- Added GitHub Actions workflow for building release APKs.
