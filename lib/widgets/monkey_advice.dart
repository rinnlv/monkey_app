import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';
import '../providers/settings_provider.dart';

class MonkeyAdvice extends ConsumerWidget {
  const MonkeyAdvice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const SizedBox(),
      error: (e, st) => const SizedBox(),
      data: (settings) {
        final streak = int.tryParse(settings['streak_count'] ?? '0') ?? 0;
        final budget = double.tryParse(settings['budget_month'] ?? '0') ?? 0.0;

        return FutureBuilder<double>(
          future: DatabaseHelper().getSpentThisMonth(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final spent = snapshot.data!;

            String advice = _generateAdvice(streak, spent, budget);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(child: Text(advice, style: const TextStyle(fontSize: 14))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _generateAdvice(int streak, double spent, double budget) {
    if (streak >= 7) return 'Больше недели без пропусков! Ты лучший финансист среди обезьян 🍌';
    if (budget > 0 && spent > budget) return 'Бюджет месяца превышен на ${(spent - budget).toStringAsFixed(0)} ₽. Мартышка советует проверить траты.';
    if (budget > 0 && spent > budget * 0.9) return 'Ты потратил 90% бюджета. Может, сварить кофе дома?';
    if (streak >= 3) return '$streak дня подряд! Продолжай записывать траты, и я смогу дать точный прогноз.';
    
    return 'Записывай траты каждый день — и я смогу дать точный совет по экономии!';
  }
}