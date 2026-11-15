import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';

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
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
);

class MonkeyApp extends StatelessWidget {
  const MonkeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MONkEY',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFA0522D),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}