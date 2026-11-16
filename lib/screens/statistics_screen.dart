import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});
  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  // Переменная для хранения выбранного месяца
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                  });
                },
              ),
              Text(
                DateFormat('LLLL yyyy', 'ru').format(_selectedMonth).toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final now = DateTime.now();
                  // Запрещаем уходить в будущее
                  if (_selectedMonth.year < now.year || (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final Map<int, double> sums = data['sums'];
          final List<Category> cats = data['categories'];
          final double totalExpense = data['totalExpense'];
          final double totalIncome = data['totalIncome'];
          final int countExpense = data['countExpense'];

          if (sums.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/monkey/monkey_sad.png', width: 120),
                  const SizedBox(height: 16),
                  const Text('Нет данных за этот месяц', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final formatter = NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 0);
          final avgCheck = countExpense > 0 ? totalExpense / countExpense : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Блок цифр
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatRow('Расходы', formatter.format(totalExpense), Colors.red),
                      const Divider(),
                      _buildStatRow('Доходы', formatter.format(totalIncome), Colors.green),
                      const Divider(),
                      _buildStatRow('Средний чек', formatter.format(avgCheck), Colors.blueGrey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Круговая диаграмма
              const Text('Распределение по категориям', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _buildPieSections(sums, cats, totalExpense),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Легенда
              ...sums.entries.map((entry) {
                final cat = cats.firstWhere((c) => c.id == entry.key, orElse: () => Category(name: 'Другое', icon: 'other', color: '#A9A9A9'));
                final percent = (entry.value / totalExpense) * 100;
                final color = _hexToColor(cat.color ?? '#A9A9A9');
                
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(backgroundColor: color, radius: 8),
                  title: Text(cat.name),
                  trailing: Text('${percent.toStringAsFixed(0)}% (${formatter.format(entry.value)})'),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadData() async {
    final db = DatabaseHelper();
    final txsMaps = await db.getAllTransactions();
    final txs = txsMaps.map((m) => Transaction.fromMap(m)).toList();
    
    final catsMaps = await db.getAllCategories();
    final cats = catsMaps.map((c) => Category.fromMap(c)).toList();

    // ФИЛЬТРУЕМ ПО ВЫБРАННОМУ МЕСЯЦУ
    final monthTxs = txs.where((t) => 
      t.date.month == _selectedMonth.month && t.date.year == _selectedMonth.year
    ).toList();

    double totalExpense = 0;
    double totalIncome = 0;
    int countExpense = 0;
    final Map<int, double> sums = {};

    for (var t in monthTxs) {
      if (t.type == 'expense') {
        totalExpense += t.amount;
        countExpense++;
        sums[t.categoryId] = (sums[t.categoryId] ?? 0) + t.amount;
      } else {
        totalIncome += t.amount;
      }
    }

    return {
      'sums': sums,
      'categories': cats,
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
      'countExpense': countExpense,
    };
  }

  List<PieChartSectionData> _buildPieSections(Map<int, double> sums, List<Category> cats, double total) {
    return sums.entries.map((entry) {
      final cat = cats.firstWhere((c) => c.id == entry.key, orElse: () => Category(name: 'Другое', icon: 'other', color: '#A9A9A9'));
      final percent = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percent.toStringAsFixed(0)}%',
        color: _hexToColor(cat.color ?? '#A9A9A9'),
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}