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
import '../widgets/template_chips.dart';
import '../widgets/custom_bottom_nav.dart'; // Импорт для нового нижнего бара

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _filterType = 'all';
  int? _filterCategoryId;
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    
    // Проверяем, открыта ли клавиатура
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      // AppBar полностью удален!
      
      // Новая круглая кнопка по центру
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        backgroundColor: const Color(0xFF688B4B), // Зеленый цвет
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Новый нижний бар
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0), 

      // Оборачиваем всё в SafeArea, чтобы не налезало на статус-бар
      body: SafeArea(
        child: Column(
          children: [
            // 1. Шапка (скрывается при клавиатуре)
            if (!isKeyboardOpen) const MonkeyHeader(), 
            
            // 2. Зеленая карточка с советом (скрывается при клавиатуре)
            if (!isKeyboardOpen) const SafeToSpendWidget(),

            // 3. Прогресс-бар бюджета (скрывается при клавиатуре)
            if (!isKeyboardOpen) const BudgetProgress(),

            // 4. Прогноз на следующий месяц (скрывается при клавиатуре)
            if (!isKeyboardOpen)
              FutureBuilder<List<double>>(
                future: DatabaseHelper().getMonthlyExpenseSums(3),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.length < 2) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                      child: Text('Недостаточно данных для прогноза', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    );
                  }
                  final sums = snapshot.data!;
                  final average = sums.reduce((a, b) => a + b) / sums.length;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                    child: Row(
                      children: [
                        const Icon(Icons.show_chart, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Прогноз на след. месяц: ~${average.toStringAsFixed(0)} ₽',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // 5. Шаблоны
            const TemplateChips(),
            const SizedBox(height: 4),

            // 6. Строка поиска
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск по описанию...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // 7. Панель фильтров
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filterType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10), 
                        isDense: true, 
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
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
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10), 
                          isDense: true, 
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
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
                  IconButton(
                    icon: Icon(Icons.date_range, color: _dateRange != null ? const Color(0xFF85422D) : Colors.grey),
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

            // 8. Список транзакций
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Ошибка: $e')),
                data: (transactions) {
                  final filtered = transactions.where((t) {
                    if (_filterType != 'all' && t.type != _filterType) return false;
                    if (_filterCategoryId != null && t.categoryId != _filterCategoryId) return false;
                    
                    if (_searchQuery.isNotEmpty && 
                        (t.description == null || !t.description!.toLowerCase().contains(_searchQuery.toLowerCase()))) {
                      return false;
                    }
                    
                    if (_dateRange != null) {
                      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
                      final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
                      final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
                      if (tDate.isBefore(start) || tDate.isAfter(end)) return false;
                    }
                    
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
                                Text(DateFormat('d MMMM yyyy', 'ru').format(date), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                                Text(NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 2).format(dayTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
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
                                                        'type': t.type,
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
      ),
    );
  }
}