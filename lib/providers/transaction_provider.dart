import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';
import '../models/transaction.dart';
import 'settings_provider.dart';

// Провайдер для чтения списка транзакций
final transactionProvider = FutureProvider<List<Transaction>>((ref) async {
  final maps = await DatabaseHelper().getAllTransactions();
  return maps.map((m) => Transaction.fromMap(m)).toList();
});

// Класс для действий
class TransactionActions {
  final Ref ref;
  TransactionActions(this.ref);

  Future<void> add(Map<String, dynamic> row) async {
    final db = DatabaseHelper();
    await db.insertTransaction(row);
    
    // Обновляем streak, если это первая запись за сегодня
    await db.updateStreak();

    // Обновляем правило классификации
    if (row['description'] != null && row['description'].toString().isNotEmpty) {
      await db.upsertClassificationRule(
        row['description'].toString().toLowerCase(),
        row['category_id'] as int,
      );
    }

    ref.invalidate(transactionProvider);
    ref.invalidate(settingsProvider);
  }

  Future<void> update(int id, Map<String, dynamic> row) async {
    await DatabaseHelper().updateTransaction(id, row);
    ref.invalidate(transactionProvider);
    ref.invalidate(settingsProvider);
  }

  Future<void> delete(int id) async {
    await DatabaseHelper().deleteTransaction(id);
    ref.invalidate(transactionProvider);
    ref.invalidate(settingsProvider);
  }
}

final transactionActionsProvider = Provider((ref) => TransactionActions(ref));