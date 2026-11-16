import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  String _filterType = 'all';
  int? _filterCategoryId;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
          if (!isKeyboardOpen) const MonkeyHeader(), 
          
          // 2. Главная цифра
          if (!isKeyboardOpen) const SafeToSpendWidget(),

          // 3. Прогресс-бар бюджета
          if (!isKeyboardOpen) const BudgetProgress(),

          // 4. Совет мартышки
          if (!isKeyboardOpen) const MonkeyAdvice(),

          // 5. Прогноз на следующий месяц
          if (!isKeyboardOpen)
            FutureBuilder<List<double>>(
              future: DatabaseHelper().getMonthlyExpenseSums(3),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.length < 2) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Text('Недостаточно данных для прогноза', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  );
                }
                final sums = snapshot.data!;
                final average = sums.reduce((a, b) => a + b) / sums.length;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.show_chart, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Прогноз на след. месяц: ~${average.toStringAsFixed(0)} ₽',
                          style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // 6. Шаблоны для быстрого ввода
          const TemplateChips(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по описанию...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 8),

          // 7. Панель фильтров
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // 1-й фильтр: Тип (Все / Расходы / Доходы)
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    isExpanded: true, // Защита от переполнения
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10), 
                      isDense: true, 
                      border: OutlineInputBorder()
                    ),
                    items: const [ // <--- ВОТ ОН, СПИСОК ITEMS
                      DropdownMenuItem(value: 'all', child: Text('Все')),
                      DropdownMenuItem(value: 'expense', child: Text('Расходы')),
                      DropdownMenuItem(value: 'income', child: Text('Доходы')),
                    ],
                    onChanged: (val) => setState(() => _filterType = val!),
                  ),
                ),
                const SizedBox(width: 8),
                
                // 2-й фильтр: Категория
                Expanded(
                  child: categoriesAsync.when(
                    data: (cats) => DropdownButtonFormField<int?>(
                      value: _filterCategoryId,
                      isExpanded: true, // Защита от переполнения
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10), 
                        isDense: true, 
                        border: OutlineInputBorder()
                      ),
                      items: [ // <--- И ВОТ ЗДЕСЬ ТОЖЕ
                        const DropdownMenuItem(
                          value: null, 
                          child: Text('Все категории', overflow: TextOverflow.ellipsis)
                        ),
                        ...cats.map((c) => DropdownMenuItem(
                          value: c.id, 
                          child: Text(c.name, overflow: TextOverflow.ellipsis)
                        )),
                      ],
                      onChanged: (val) => setState(() => _filterCategoryId = val),
                    ),
                    loading: () => const SizedBox(),
                    error: (e, st) => const SizedBox(),
                  ),
                ),

                // Кнопка календаря (ровно одна!)
                IconButton(
                  icon: Icon(Icons.date_range, color: _dateRange != null ? Colors.orange : null),
                  tooltip: 'Фильтр по дате',
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) {
                      setState(() => _dateRange = picked);
                    } else {
                      setState(() => _dateRange = null);
                    }
                  },
                ),
                
                // Кнопка сброса даты (появляется только при выборе дат)
                if (_dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    tooltip: 'Показать за всё время',
                    onPressed: () {
                      setState(() => _dateRange = null);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 8. Список транзакций
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Ошибка: $e')),
              data: (transactions) {
                final filtered = transactions.where((t) {
                  // 1. Старое условие: Фильтр по типу (Расход/Доход)
                  if (_filterType != 'all' && t.type != _filterType) return false;
                  
                  // 2. Старое условие: Фильтр по категории
                  if (_filterCategoryId != null && t.categoryId != _filterCategoryId) return false;

                  // 👇 НОВОЕ УСЛОВИЕ 1: Поиск по тексту 👇
                  if (_searchQuery.isNotEmpty && 
                      (t.description == null || !t.description!.toLowerCase().contains(_searchQuery.toLowerCase()))) {
                    return false;
                  }
                  
                  // 👇 НОВОЕ УСЛОВИЕ 2: Фильтр по диапазону дат 👇
                  if (_dateRange != null) {
                    final tDate = DateTime(t.date.year, t.date.month, t.date.day);
                    final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
                    final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
                    if (tDate.isBefore(start) || tDate.isAfter(end)) return false;
                  }
                  // 👆 КОНЕЦ НОВЫХ УСЛОВИЙ 👆

                  return true; // Если трата прошла все проверки — показываем её
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
                                        onTap: () async {
                                          Navigator.pop(ctx);
                                          
                                          final templateNameController = TextEditingController(text: t.description ?? 'Новый шаблон');
                                          
                                          final result = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogCtx) => AlertDialog(
                                              title: const Text('Новый шаблон'),
                                              content: TextField(
                                                controller: templateNameController,
                                                decoration: const InputDecoration(labelText: 'Название шаблона'),
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Отмена')),
                                                TextButton(
                                                  onPressed: () async {
                                                    if (templateNameController.text.trim().isEmpty) return;
                                                    
                                                    await DatabaseHelper().insertTemplate({
                                                      'name': templateNameController.text.trim(),
                                                      'amount': t.amount,
                                                      'category_id': t.categoryId,
                                                      'description': t.description,
                                                    });
                                                    
                                                    ref.invalidate(templatesProvider);
                                                    
                                                    if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                                                  },
                                                  child: const Text('Сохранить'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (result == true && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Шаблон сохранен!')),
                                            );
                                          }
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