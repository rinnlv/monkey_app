import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MONkEY')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Главный экран (в разработке)'),
            ElevatedButton(onPressed: () => context.push('/add'), child: const Text('Добавить')),
            ElevatedButton(onPressed: () => context.push('/stats'), child: const Text('Статистика')),
            ElevatedButton(onPressed: () => context.push('/settings'), child: const Text('Настройки')),
          ],
        ),
      ),
    );
  }
}