import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(MerchantApp());

class MerchantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SOMA Merchant', home: MerchantHome());
  }
}

class MerchantHome extends StatefulWidget {
  @override
  _MerchantHomeState createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHome> {
  FlutterBluePlus fb = FlutterBluePlus.instance;
  List<ScanResult> devices = [];
  String last = '';
  final uuid = Uuid();

  @override
  void initState() {
    super.initState();
    requestPermissions();
    startScan();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
    await Permission.camera.request();
  }

  void startScan() {
    devices.clear();
    fb.startScan(timeout: Duration(seconds: 6)).listen((r) {
      if (!devices.any((d) => d.device.id == r.device.id)) {
        setState(() => devices.add(r));
      }
    }, onDone: () => setState(() {}));
  }

  String makeMerchantQr() {
    final data = {'type': 'soma_request', 'merchant': 'shop-123', 'tx': uuid.v4()};
    return jsonEncode(data);
  }

  void openQrScanner() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MerchantQrScanner()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SOMA Merchant — Demo')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Text('Nearby BLE devices: ${devices.length}'),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (c, i) {
                final r = devices[i];
                return ListTile(
                  title: Text(r.device.name.isNotEmpty ? r.device.name : r.device.id.id),
                  subtitle: Text('RSSI: ${r.rssi}'),
                );
              },
            ),
          ),
          Divider(),
          Text('Merchant QR (request)'),
          SizedBox(height: 8),
          QrImage(data: makeMerchantQr(), size: 180),
          SizedBox(height: 8),
          ElevatedButton(onPressed: openQrScanner, child: Text('Scan Buyer QR')),
        ]),
      ),
    );
  }
}

class MerchantQrScanner extends StatefulWidget {
  @override
  _MerchantQrScannerState createState() => _MerchantQrScannerState();
}

class _MerchantQrScannerState extends State<MerchantQrScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'merchantQr');
  QRViewController? controller;
  String scanned = '';

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController c) {
    controller = c;
    controller!.scannedDataStream.listen((d) {
      setState(() {
        scanned = d.code ?? '';
      });
      controller?.pauseCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Merchant — Scan')),
      body: Column(children: [
        Expanded(child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated)),
        Text('Scanned: $scanned'),
        ElevatedButton(onPressed: () => controller?.resumeCamera(), child: Text('Restart'))
      ]),
    );
  }
}
