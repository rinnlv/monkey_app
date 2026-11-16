import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF688B4B); // Ваш зеленый

    return BottomAppBar(
      color: primaryColor,
      shape: const CircularNotchedRectangle(), 
      notchMargin: 6.0,
      height: 60, // 👈 Уменьшили высоту зеленого фона
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            // 👈 Увеличили размер иконок до 30
            icon: Icon(Icons.home_rounded, size: 30, color: currentIndex == 0 ? Colors.white : Colors.white54),
            onPressed: () => context.go('/'),
          ),
          IconButton(
            icon: Icon(Icons.bar_chart_rounded, size: 30, color: currentIndex == 1 ? Colors.white : Colors.white54),
            onPressed: () => context.go('/stats'),
          ),
          const SizedBox(width: 48), // Место под круглую кнопку "Плюс"
          IconButton(
            icon: Icon(Icons.person_rounded, size: 30, color: currentIndex == 2 ? Colors.white : Colors.white54),
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: Icon(Icons.settings_rounded, size: 30, color: currentIndex == 3 ? Colors.white : Colors.white54),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}