import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TransactionService {
  double buyerBalance = 50000;
  double sellerBalance = 30000;

  String generateQrData(double amount) {
    final data = {
      "id": const Uuid().v4(),
      "amount": amount,
      "timestamp": DateTime.now().toIso8601String()
    };
    return jsonEncode(data);
  }

  bool processBluetoothPayment(double amount) {
    if (buyerBalance >= amount) {
      buyerBalance -= amount;
      sellerBalance += amount;
      return true;
    }
    return false;
  }

  Map<String, double> getBalances() {
    return {
      "buyer": buyerBalance,
      "seller": sellerBalance,
    };
  }
}
