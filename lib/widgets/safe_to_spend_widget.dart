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
            if (budget > 0) {
              safeAmount = (budget - spent) / daysLeft;
            } else {
              safeAmount = spent / now.day; 
            }

            final formatter = NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 2);
            final amountString = safeAmount < 0 ? 'Перерасход' : formatter.format(safeAmount);

            // 👇 Выравниваем по левому краю
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                width: 220, // 👈 Фиксированная ширина, чтобы не растягивалась
                decoration: BoxDecoration(
                  color: const Color(0xFF688B4B), 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF688B4B).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    const Text(
                      'Совет: трать в день\nне более',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFEFE4D4), 
                        fontSize: 12, 
                        height: 1.2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        amountString,
                        key: ValueKey<String>(amountString),
                        style: const TextStyle(
                          fontFamily: 'Gluten', 
                          fontSize: 30, 
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEFE4D4), 
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}