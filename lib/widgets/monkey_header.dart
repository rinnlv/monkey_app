import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class MonkeyHeader extends ConsumerWidget {
  const MonkeyHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    
    const colorBrown = Color(0xFF85422D);
    const colorBeige = Color(0xFFEFE4D4);

    return settingsAsync.when(
      loading: () => const SizedBox(height: 200),
      error: (e, st) => const SizedBox(),
      data: (settings) {
        final streak = int.tryParse(settings['streak_count'] ?? '0') ?? 0;
        
        String imagePath = 'assets/monkey/monkey_sad.png';
        if (streak >= 3) {
          imagePath = 'assets/monkey/monkey_happy.png';
        } else if (streak >= 1) {
          imagePath = 'assets/monkey/monkey_neutral.png';
        }

        return SizedBox(
          height: 200, 
          child: Stack(
            clipBehavior: Clip.none, 
            children: [
              // 1. Логотип по центру (k = 32)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Gluten',
                        fontSize: 36, // Базовый размер
                        fontWeight: FontWeight.bold,
                        color: colorBrown,
                        letterSpacing: 2.0,
                      ),
                      children: const [
                        TextSpan(text: 'MON'),
                        TextSpan(
                          text: 'k',
                          style: TextStyle(fontSize: 32), // 👈 Уменьшили до 32
                        ),
                        TextSpan(text: 'EY'),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Плашка "Серия" (слева, увеличенная)
              Positioned(
                left: 24, // Вернули к левому краю (чуть больше отступ)
                top: 80,  // Опустили под логотип
                child: Container(
                  height: 64, // 👈 Увеличили высоту (было 60)
                  decoration: BoxDecoration(
                    border: Border.all(color: colorBrown, width: 4.0),
                    borderRadius: BorderRadius.circular(32), // 64 / 2
                  ),
                  clipBehavior: Clip.antiAlias, 
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Левая часть (текст)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24), // Больше отступов
                        child: const Text(
                          'Серия',
                          style: TextStyle(
                            fontFamily: 'Geologica',
                            color: colorBrown,
                            fontSize: 28, // 👈 Увеличили текст (было 26)
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Правая часть (коричневая с цифрой)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: colorBrown,
                          // Закругляем левый край (32 внешний радиус - 4 обводка = 28)
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(28),
                          ),
                        ),
                        constraints: const BoxConstraints(minWidth: 70), 
                        child: Text(
                          '$streak',
                          style: const TextStyle(
                            fontFamily: 'Gluten',
                            color: colorBeige, 
                            fontSize: 36, // 👈 Увеличили цифру (было 34)
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Большая мартышка
              Positioned(
                right: -30, 
                top: -35,   
                child: Transform.rotate(
                  angle: 0.3, 
                  child: Image.asset(
                    imagePath,
                    width: 230, 
                    height: 230,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}