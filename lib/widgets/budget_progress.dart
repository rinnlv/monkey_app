import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../providers/settings_provider.dart';

class BudgetProgress extends ConsumerWidget {
  const BudgetProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const SizedBox(),
      error: (e, st) => const SizedBox(),
      data: (settings) {
        final budget = double.tryParse(settings['budget_month'] ?? '0') ?? 0.0;
        if (budget <= 0) return const SizedBox.shrink(); // Если бюджет не задан, ничего не показываем

        return FutureBuilder<double>(
          future: DatabaseHelper().getSpentThisMonth(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            
            final spent = snapshot.data!;
            final percent = (spent / budget) * 100;
            
            Color barColor = Colors.green;
            if (percent >= 75 && percent <= 100) barColor = Colors.orange;
            if (percent > 100) barColor = Colors.red;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Бюджет месяца', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 0).format(spent)} из ${NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 0).format(budget)}',
                        style: TextStyle(color: barColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: spent / budget,
                    color: barColor,
                    backgroundColor: Colors.grey.shade300,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}