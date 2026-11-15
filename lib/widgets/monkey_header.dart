import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class MonkeyHeader extends ConsumerWidget {
  const MonkeyHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const SizedBox(height: 100),
      error: (e, st) => const SizedBox(),
      data: (settings) {
        final streak = int.tryParse(settings['streak_count'] ?? '0') ?? 0;
        final budget = double.tryParse(settings['budget_month'] ?? '0') ?? 0.0;

        // Определяем картинку и текст в зависимости от streak
        String imagePath = 'assets/monkey/monkey_sad.png';
        String title = 'Записей подряд: 0';
        String subtitle = 'Начни серию!';
        Color bgColor = Colors.brown.shade50;

        if (streak >= 3) {
          imagePath = 'assets/monkey/monkey_happy.png';
          title = '$streak дня подряд! 🍌';
          subtitle = 'Так держать!';
          bgColor = Colors.green.shade50;
        } else if (streak >= 1) {
          imagePath = 'assets/monkey/monkey_neutral.png';
          title = 'Записей подряд: $streak';
          subtitle = 'Продолжай в том же духе';
          bgColor = Colors.orange.shade50;
        }

        // Если бюджет превышен, делаем фон красноватым (даже если streak хороший)
        if (budget > 0) {
          // Пока мы не считаем потраченное здесь (это будет в SafeToSpend),
          // просто оставим логику цвета по streak.
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Image.asset(imagePath, width: 70, height: 70),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}