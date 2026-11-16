import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';

final settingsProvider = FutureProvider<Map<String, String>>((ref) async {
  final db = DatabaseHelper();
  await db.checkAndResetStreak(); 
  return {
    'budget_month': await db.getSetting('budget_month') ?? '0',
    'streak_count': await db.getSetting('streak_count') ?? '0',
    'last_record_date': await db.getSetting('last_record_date') ?? '',
  };
});