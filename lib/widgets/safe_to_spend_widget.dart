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
        final streak = int.tryParse(settings['streak_count'] ?? '0') ?? 0;

        return FutureBuilder<double>(
          future: DatabaseHelper().getSpentThisMonth(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final spent = snapshot.data!;
            
            final now = DateTime.now();
            final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
            final daysLeft = lastDayOfMonth - now.day + 1;

            double safeAmount;
            if (budget > 0) {
              safeAmount = (budget - spent) / daysLeft;
            } else {
              safeAmount = spent / now.day; 
            }

            // Генерируем умный совет для верхней строчки
            String adviceText = 'Совет: трать в день не более';
            if (budget > 0 && spent > budget) adviceText = 'Бюджет превышен!';
            else if (budget > 0 && spent > budget * 0.9) adviceText = 'Ты потратил 90% бюджета';
            else if (streak >= 7) adviceText = 'Неделя без пропусков! Так держать';
            else if (streak >= 3) adviceText = 'Отличная серия! Продолжай';

            final formatter = NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 2);

            return Container(
              // Делаем карточку шире (уменьшаем отступы по бокам) и ниже
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF688B4B), 
                borderRadius: BorderRadius.circular(16), // Чуть меньше скругление
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Карточка обжимает контент
                children: [
                  Text(
                    adviceText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFEFE4D4),
                      fontSize: 13, // Чуть меньше размер
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    safeAmount < 0 ? 'Перерасход' : formatter.format(safeAmount),
                    style: const TextStyle(
                      fontFamily: 'Gluten', 
                      fontSize: 32, // Оптимальный размер цифры
                      fontWeight: FontWeight.bold,
                      color:Color(0xFFEFE4D4),
                    ),
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