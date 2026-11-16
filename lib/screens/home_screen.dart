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
import '../widgets/custom_bottom_nav.dart';

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
  
  // Состояние для отображения поиска
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Оформление для выпадающих списков
  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
      filled: true,
      fillColor: Colors.transparent, // Прозрачный фон
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20), // Капсула
        borderSide: const BorderSide(color: Colors.black87, width: 1.5), // Черный контур
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF85422D), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        backgroundColor: const Color(0xFF688B4B), 
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0), 

      body: SafeArea(
        child: Column(
          children: [
            if (!isKeyboardOpen) const MonkeyHeader(), 
            if (!isKeyboardOpen) const SafeToSpendWidget(),
            if (!isKeyboardOpen) const BudgetProgress(),

            if (!isKeyboardOpen)
              FutureBuilder<List<double>>(
                // ... (ваш старый код прогноза, я его не меняю)
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

            const TemplateChips(),
            const SizedBox(height: 8),

            // 👇 НОВАЯ ПАНЕЛЬ ПОИСКА И ФИЛЬТРОВ 👇
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _isSearching 
                ? _buildSearchField() // Если поиск открыт - показываем поле ввода
                : _buildFilterRow(categoriesAsync), // Если закрыт - показываем строку с фильтрами
            ),
            const SizedBox(height: 8),

            // 8. Список транзакций
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Ошибка: $e')),
                data: (transactions) {
                  // ... (ваш старый код фильтрации, я его не меняю)
                  final filtered = transactions.where((t) {
                    if (_filterType != 'all' && t.type != _filterType) return false;
                    if (_filterCategoryId != null && t.categoryId != _filterCategoryId) return false;
                    if (_searchQuery.isNotEmpty && 
                        (t.description == null || !t.description!.toLowerCase().contains(_searchQuery.toLowerCase()))) return false;
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

                  final grouped = <String, List<Transaction>>{};
                  for (var t in filtered) {
                    final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
                    grouped.putIfAbsent(dateStr, () => []).add(t);
                  }

                  return ListView.builder(
                    // ... (ваш старый код ListView и карточек, я его не меняю)
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
                                  // ... ваш старый код долгого нажатия ...
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
                                                content: TextField(controller: templateNameController, decoration: const InputDecoration(labelText: 'Название шаблона')),
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
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Шаблон сохранен!')));
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

  // 👇 Виджет строки фильтров (Лупа + Списки + Календарь) 👇
  Widget _buildFilterRow(AsyncValue<List<Category>> categoriesAsync) {
    return Row(
      children: [
        // Кнопка поиска (Лупа)
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87, size: 28),
          onPressed: () {
            setState(() => _isSearching = true);
          },
        ),
        
        // Выпадающий список типов
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _filterType,
            isExpanded: true,
            decoration: _dropdownDecoration(),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Все', style: TextStyle(fontSize: 14))),
              DropdownMenuItem(value: 'expense', child: Text('Расходы', style: TextStyle(fontSize: 14))),
              DropdownMenuItem(value: 'income', child: Text('Доходы', style: TextStyle(fontSize: 14))),
            ],
            onChanged: (val) => setState(() => _filterType = val!),
          ),
        ),
        const SizedBox(width: 8),
        
        // Выпадающий список категорий
        Expanded(
          flex: 2, // Чуть шире, так как названия длиннее
          child: categoriesAsync.when(
            data: (cats) => DropdownButtonFormField<int?>(
              value: _filterCategoryId,
              isExpanded: true,
              decoration: _dropdownDecoration(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
              items: [
                const DropdownMenuItem(
                  value: null, 
                  child: Text('Категории', style: TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)
                ),
                ...cats.map((c) => DropdownMenuItem(
                  value: c.id, 
                  child: Text(c.name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)
                )),
              ],
              onChanged: (val) => setState(() => _filterCategoryId = val),
            ),
            loading: () => const SizedBox(),
            error: (e, st) => const SizedBox(),
          ),
        ),
        const SizedBox(width: 4),

        // Кнопка календаря (или крестик сброса)
        _dateRange != null 
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 24),
              tooltip: 'Сбросить дату',
              onPressed: () => setState(() => _dateRange = null),
            )
          : IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.black87, size: 28),
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _dateRange,
                );
                if (picked != null) {
                  setState(() => _dateRange = picked);
                }
              },
            ),
      ],
    );
  }

  // 👇 Виджет поля поиска (открывается по клику на лупу) 👇
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Поиск по описанию...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), // Капсула
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }
}