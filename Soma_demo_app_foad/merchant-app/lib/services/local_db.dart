import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tx_log.dart';

class LocalDB {
  static const _key = 'merchant_txn_logs';

  Future<void> save(TxLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(jsonEncode(log.toMap()));
    await prefs.setStringList(_key, list);
  }

  Future<List<TxLog>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list
        .map((e) => TxLog.fromMap(Map<String, String>.from(jsonDecode(e))))
        .toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
