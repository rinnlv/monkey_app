import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class MonkeyHeader extends ConsumerWidget {
  const MonkeyHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    const colorBrown = Color(0xFF85422D);

    return settingsAsync.when(
      loading: () => const SizedBox(height: 180),
      error: (e, st) => const SizedBox(),
      data: (settings) {
        final streak = int.tryParse(settings['streak_count'] ?? '0') ?? 0;
        
        // Логика выбора мартышки
        String imagePath = 'assets/monkey/monkey_sad.png';
        if (streak >= 3) {
          imagePath = 'assets/monkey/monkey_happy.png';
        } else if (streak >= 1) {
          imagePath = 'assets/monkey/monkey_neutral.png';
        }

        return SizedBox(
          height: 190, // Высота под лиану и мартышку
          child: Stack(
            clipBehavior: Clip.none, 
            children: [
              // 1. Логотип по центру
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Gluten',
                        fontSize: 36, 
                        fontWeight: FontWeight.bold,
                        color: colorBrown,
                        letterSpacing: 3.0,
                      ),
                      children: const [
                        TextSpan(text: 'MON'),
                        TextSpan(
                          text: 'k',
                          style: TextStyle(fontSize: 32), 
                        ),
                        TextSpan(text: 'EY'),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Лиана (растянута по ширине)
              Positioned(
                top: 50, // Под логотипом
                left: -20, // Немного вылезает за края для естественности
                right: -20,
                child: Image.asset(
                  'assets/icons/liana.png',
                  fit: BoxFit.cover,
                  height: 100,
                ),
              ),

              // 3. Мартышка (справа, висит на лиане)
              Positioned(
                right: -5, 
                top: -10,
                child: Image.asset(
                  imagePath,
                  width: 150, 
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}