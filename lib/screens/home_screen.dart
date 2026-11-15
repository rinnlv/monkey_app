import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/monkey_header.dart';
import '../widgets/safe_to_spend_widget.dart';
import '../widgets/budget_progress.dart';
import '../widgets/monkey_advice.dart';
import '../widgets/template_chips.dart';
import '../db/database_helper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _filterType = 'all';
  int? _filterCategoryId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MONkEY'),
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart), onPressed: () => context.push('/stats')),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: Column(
        children: [
          // 1. Карточка мартышки со streak
          const MonkeyHeader(), 
          
          // 2. Главная цифра
          const SafeToSpendWidget(),

          // 3. Прогресс-бар бюджета
          const BudgetProgress(),

          // 4. Совет мартышки
          const MonkeyAdvice(),
          // НОВЫЙ БЛОК: ПРОГНОЗ
          FutureBuilder<List<double>>(
            future: DatabaseHelper().getMonthlyExpenseSums(3),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.length < 2) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Недостаточно данных для прогноза', style: TextStyle(color: Colors.grey, fontSize: 12)),
                );
              }
              final sums = snapshot.data!;
              final average = sums.reduce((a, b) => a + b) / sums.length;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.show_chart, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      'Прогноз на след. месяц: ~${average.toStringAsFixed(0)} ₽',
                      style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),


          // 5. Шаблоны для быстрого ввода
          const TemplateChips(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Все')),
                      DropdownMenuItem(value: 'expense', child: Text('Расходы')),
                      DropdownMenuItem(value: 'income', child: Text('Доходы')),
                    ],
                    onChanged: (val) => setState(() => _filterType = val!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: categoriesAsync.when(
                    data: (cats) => DropdownButtonFormField<int?>(
                      value: _filterCategoryId,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10), isDense: true),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все категории')),
                        ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (val) => setState(() => _filterCategoryId = val),
                    ),
                    loading: () => const SizedBox(),
                    error: (e, st) => const SizedBox(),
                  ),
                ),
              ],
            ),
          ),

          // Список транзакций
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Ошибка: $e')),
              data: (transactions) {
                final filtered = transactions.where((t) {
                  if (_filterType != 'all' && t.type != _filterType) return false;
                  if (_filterCategoryId != null && t.categoryId != _filterCategoryId) return false;
                  if (_searchQuery.isNotEmpty && 
                      (t.description == null || !t.description!.toLowerCase().contains(_searchQuery.toLowerCase()))) return false;
                  return true;
                }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                     child: Text('Пока пусто. Добавь первую трату!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                // Группировка по датам
                final grouped = <String, List<Transaction>>{};
                for (var t in filtered) {
                  final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
                  grouped.putIfAbsent(dateStr, () => []).add(t);
                }

                return ListView.builder(
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final dateKey = grouped.keys.elementAt(index);
                    final dayTransactions = grouped[dateKey]!;
                    final date = DateTime.parse(dateKey);
                    
                    double dayTotal = 0;
                    for (var t in dayTransactions) {
                      if (t.type == 'expense') dayTotal -= t.amount;
                      if (t.type == 'income') dayTotal += t.amount;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('d MMMM yyyy', 'ru').format(date), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text(NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 0).format(dayTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                        ),
                        ...dayTransactions.map((t) {
                          final cat = categoriesAsync.valueOrNull?.firstWhere(
                            (c) => c.id == t.categoryId,
                            orElse: () => Category(name: 'Другое', icon: 'other', color: '#A9A9A9'),
                          );
                          
                          return Dismissible(
                            key: Key(t.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Удалить?'),
                                  content: const Text('Вы уверены, что хотите удалить эту транзакцию?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              ref.read(transactionActionsProvider).delete(t.id!);
                            },
                            child: TransactionTile(
                              transaction: t,
                              category: cat,
                              onTap: () => context.push('/add?id=${t.id}'),
                              onLongPress: () async {
                                // Действия по долгому нажатию (Повторить или Шаблон)
                                showModalBottomSheet(
                                  context: context,
                                  builder: (ctx) => Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.repeat),
                                        title: const Text('Повторить сегодня'),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          final newRow = t.toMap()..remove('id')..['date'] = DateTime.now().toIso8601String().substring(0, 10);
                                          ref.read(transactionActionsProvider).add(newRow);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.bookmark_add),
                                        title: const Text('Сохранить как шаблон'),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          // Здесь позже добавим логику сохранения шаблона
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}