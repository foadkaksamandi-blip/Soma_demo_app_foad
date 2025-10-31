import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(BuyerApp());
}

class BuyerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Buyer Demo',
      home: BuyerHomePage(),
    );
  }
}

class BuyerHomePage extends StatefulWidget {
  @override
  _BuyerHomePageState createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  String lastMessage = '';
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
    scanResults.clear();
    flutterBlue.startScan(timeout: Duration(seconds: 6)).listen((result) {
      setState(() {
        if (!scanResults.any((r) => r.device.id == result.device.id)) {
          scanResults.add(result);
        }
      });
    }, onDone: () {
      setState(() {});
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(timeout: Duration(seconds: 10)).catchError((e) {});
    setState(() {
      connectedDevice = device;
    });
    // discover services
    List<BluetoothService> services = await device.discoverServices();
    // For demo: try to write/read first writable characteristic found
    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.properties.write) {
          try {
            var payload = utf8.encode('SOMA:${uuid.v4()}');
            await c.write(payload, withoutResponse: false);
            lastMessage = 'Wrote to ${c.uuid}';
            setState(() {});
            // Try read if readable
            if (c.properties.read) {
              var value = await c.read();
              lastMessage = 'Read: ${utf8.decode(value)}';
              setState(() {});
            }
            return;
          } catch (e) {
            // ignore demo errors
          }
        }
      }
    }
  }

  void disconnect() {
    connectedDevice?.disconnect();
    connectedDevice = null;
    setState(() {});
  }

  // QR generation sample
  String generatePaymentQr() {
    // simple JSON payload; in real product sign & encrypt
    final data = {'type': 'soma_payment', 'amount': 1000, 'tx': uuid.v4()};
    return jsonEncode(data);
  }

  // Navigate to QR scanner page
  void openQrScanner() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => QrScannerPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('SOMA Buyer — Demo')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text('BLE Scan Results (${scanResults.length})'),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: scanResults.length,
                  itemBuilder: (context, idx) {
                    final r = scanResults[idx];
                    return ListTile(
                      title: Text(r.device.name.isNotEmpty ? r.device.name : r.device.id.id),
                      subtitle: Text(r.rssi.toString()),
                      trailing: ElevatedButton(
                        child: Text('Connect'),
                        onPressed: () => connectToDevice(r.device),
                      ),
                    );
                  },
                ),
              ),
              if (connectedDevice != null) ...[
                Text('Connected: ${connectedDevice!.id.id}'),
                ElevatedButton(onPressed: disconnect, child: Text('Disconnect')),
                Text('Last: $lastMessage'),
              ],
              Divider(),
              Text('QR Payment'),
              SizedBox(height: 8),
              QrImage(data: generatePaymentQr(), size: 180),
              SizedBox(height: 8),
              ElevatedButton(onPressed: openQrScanner, child: Text('Scan QR')),
            ],
          ),
        ));
  }
}

class QrScannerPage extends StatefulWidget {
  @override
  _QrScannerPageState createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String scanned = '';

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) {
      setState(() {
        scanned = scanData.code ?? '';
      });
      controller?.pauseCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Scan QR')),
        body: Column(
          children: [
            Expanded(child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated)),
            SizedBox(height: 8),
            Text('Scanned: $scanned'),
            ElevatedButton(
              onPressed: () {
                controller?.resumeCamera();
                setState(() {
                  scanned = '';
                });
              },
              child: Text('Restart'),
            )
          ],
        ));
  }
}
