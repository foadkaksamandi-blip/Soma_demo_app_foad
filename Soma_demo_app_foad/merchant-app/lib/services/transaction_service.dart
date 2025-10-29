import 'package:uuid/uuid.dart';

class MerchantReceipt {
  final String id;
  final double amount;
  final String method;
  final DateTime timestamp;

  MerchantReceipt({
    required this.id,
    required this.amount,
    required this.method,
    required this.timestamp,
  });
}

class MerchantService {
  double merchantBalance = 2500000;
  MerchantReceipt? lastReceipt;

  bool acceptPayment({required double amount, required String method}) {
    if (amount <= 0) return false;
    merchantBalance += amount;
    lastReceipt = MerchantReceipt(
      id: const Uuid().v4(),
      amount: amount,
      method: method,
      timestamp: DateTime.now(),
    );
    return true;
  }
}
