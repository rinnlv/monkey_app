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
        if (budget <= 0) return const SizedBox.shrink();

        return FutureBuilder<double>(
          future: DatabaseHelper().getSpentThisMonth(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            
            final spent = snapshot.data!;
            final percent = (spent / budget) * 100;
            
            Color barColor = const Color(0xFF688B4B); // Зеленый по умолчанию
            if (percent >= 75 && percent <= 100) barColor = Colors.orange;
            if (percent > 100) barColor = const Color(0xFF85422D); // Коричневый при перерасходе

            final formatter = NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 2);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Бюджет месяца', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF85422D))
                      ),
                      Text(
                        '${formatter.format(spent)} из ${formatter.format(budget)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Тонкая полоска
                  LinearProgressIndicator(
                    value: spent / budget,
                    color: barColor,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
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