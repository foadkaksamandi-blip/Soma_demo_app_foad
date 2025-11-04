class TxLog {
  final String id;
  final int amount;
  final String source;
  final String method;
  final DateTime at;

  TxLog({
    required this.id,
    required this.amount,
    required this.source,
    required this.method,
    required this.at,
  });

  Map<String, String> toMap() => {
        'ID': id,
        'AMOUNT': amount.toString(),
        'SOURCE': source,
        'METHOD': method,
        'TS': at.millisecondsSinceEpoch.toString(),
      };

  static TxLog fromMap(Map<String, String> m) {
    return TxLog(
      id: m['ID'] ?? '',
      amount: int.tryParse(m['AMOUNT'] ?? '0') ?? 0,
      source: m['SOURCE'] ?? 'اصلی',
      method: m['METHOD'] ?? 'QR',
      at: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(m['TS'] ?? '0') ?? 0,
      ),
    );
  }
}
