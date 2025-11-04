import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/tx_log.dart';

class QrService {
  static String encode(TxLog tx) {
    return base64Encode(utf8.encode(jsonEncode(tx.toMap())));
  }

  static TxLog decode(String data) {
    final decoded = utf8.decode(base64Decode(data));
    return TxLog.fromMap(Map<String, String>.from(jsonDecode(decoded)));
  }

  static QrImage generateQr(TxLog tx, {double size = 200}) {
    final data = encode(tx);
    return QrImage(
      data: data,
      version: QrVersions.auto,
      size: size,
    );
  }
}
