import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../providers/settings_provider.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    const colorBrown = Color(0xFF85422D);
    const colorBeige = Color(0xFFEFE4D4);

    return settingsAsync.when(
      loading: () => const SizedBox(height: 260),
      error: (e, st) => const SizedBox(),
      data: (settings) {
        final streak = int.tryParse(settings['streak_count'] ?? '0') ?? 0;
        final budget = double.tryParse(settings['budget_month'] ?? '0') ?? 0.0;

        // Выбор мартышки
        String imagePath = 'assets/monkey/monkey_sad.png';
        if (streak >= 3) {
          imagePath = 'assets/monkey/monkey_happy.png';
        } else if (streak >= 1) {
          imagePath = 'assets/monkey/monkey_neutral.png';
        }

        return FutureBuilder<double>(
          future: DatabaseHelper().getSpentThisMonth(),
          builder: (context, snapshot) {
            final spent = snapshot.data ?? 0.0;
            final now = DateTime.now();
            final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
            final daysLeft = lastDayOfMonth - now.day + 1;

            double safeAmount = budget > 0 ? (budget - spent) / daysLeft : spent / now.day;
            final formatter = NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 2);
            final amountString = safeAmount < 0 ? 'Перерасход' : formatter.format(safeAmount);

            String adviceText = 'Совет: трать в день\nне более';
            if (budget > 0 && spent > budget) adviceText = 'Бюджет превышен!';
            else if (budget > 0 && spent > budget * 0.9) adviceText = 'Ты потратил 90% бюджета';

            return SizedBox(
              height: 260, 
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. МАРТЫШКА (Нижний слой, с тенью)
                  Positioned(
                    top: -20, 
                    right: -25, 
                    child: Transform.rotate(
                      angle: 0.35, 
                      child: _buildShadowImage(
                        imagePath: imagePath,
                        width: 240, 
                        height: 240,
                        blur: 15,
                        offset: const Offset(-5, 10),
                      ),
                    ),
                  ),

                  // 2. ЗЕЛЕНАЯ КАРТОЧКА
                  Positioned(
                    top: 65, 
                    left: 16,
                    child: Container(
                      width: 220, 
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7BA359), Color(0xFF5A7A3F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5A7A3F).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            adviceText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: colorBeige, 
                              fontSize: 12, 
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            amountString,
                            style: const TextStyle(
                              fontFamily: 'Gluten',
                              fontSize: 30, 
                              fontWeight: FontWeight.bold,
                              color: colorBeige,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. ЛИАНА (С тенью)
                  Positioned(
                    top: 150, 
                    left: -20, 
                    child: Transform.rotate(
                      angle: 0.25, 
                      child: _buildShadowImage(
                        imagePath: 'assets/icons/liana.png',
                        width: 240, 
                        height: 80,
                        blur: 8,
                        offset: const Offset(0, 6),
                      ),
                    ),
                  ),

                  // 4. ЛОГОТИП
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Gluten',
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: colorBrown,
                            letterSpacing: 2.0,
                          ),
                          children: const [
                            TextSpan(text: 'MON'),
                            TextSpan(text: 'k', style: TextStyle(fontSize: 30)),
                            TextSpan(text: 'EY'),
                          ],
                        ),
                      ),
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

  // Функция для создания красивой тени по контуру картинки без сторонних пакетов
  Widget _buildShadowImage({
    required String imagePath,
    required double width,
    required double height,
    required double blur,
    required Offset offset,
  }) {
    return Stack(
      children: [
        // Слой тени
        Transform.translate(
          offset: offset,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: ColorFiltered(
              // Красим картинку в черный цвет с прозрачностью 15%
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.15), BlendMode.srcIn),
              child: Image.asset(
                imagePath,
                width: width,
                height: height,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Оригинальная картинка (сверху)
        Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}