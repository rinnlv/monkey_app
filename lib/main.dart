import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  runApp(const ProviderScope(child: MonkeyApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/add', builder: (context, state) {
      final id = state.uri.queryParameters['id'];
      return AddTransactionScreen(transactionId: id != null ? int.parse(id) : null);
    }),
    GoRoute(path: '/stats', builder: (context, state) => const StatisticsScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
);

class MonkeyApp extends StatelessWidget {
  const MonkeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ваши фирменные цвета
    const colorBrown = Color(0xFF85422D);
    const colorBeige = Color(0xFFEFE4D4);
    const colorGreen = Color(0xFF688B4B);

    return MaterialApp.router(
      title: 'MONkEY',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: colorBeige, // Бежевый фон везде
        fontFamily: 'Geologica', // Основной шрифт
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorGreen,
          primary: colorGreen,
          secondary: colorBrown,
          background: colorBeige,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: colorBeige,
          foregroundColor: colorBrown,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Gluten', // Для заголовков в AppBar используем Gluten
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorBrown,
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}