import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../providers/settings_provider.dart';

class SafeToSpendWidget extends ConsumerWidget {
  const SafeToSpendWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const SizedBox(),
      error: (e, st) => const SizedBox(),
      data: (settings) {
        final budget = double.tryParse(settings['budget_month'] ?? '0') ?? 0.0;

        return FutureBuilder<double>(
          future: DatabaseHelper().getSpentThisMonth(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final spent = snapshot.data!;
            
            final now = DateTime.now();
            final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
            final daysLeft = lastDayOfMonth - now.day + 1;

            double safeAmount;
            String label;
            String subLabel;
            Color textColor = Colors.green.shade800;

            if (budget > 0) {
              final remaining = budget - spent;
              safeAmount = remaining / daysLeft;
              label = 'Безопасно тратить в день';
              subLabel = 'Осталось $daysLeft дней';
              if (safeAmount < 0) textColor = Colors.red;
            } else {
              safeAmount = spent / now.day; // средний расход
              label = 'Средний расход в день';
              subLabel = 'Бюджет не установлен';
              textColor = Colors.grey.shade800;
            }

            final formatter = NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    safeAmount < 0 ? 'Бюджет превышен' : formatter.format(safeAmount),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(subLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}