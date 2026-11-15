import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final int? transactionId;
  const AddTransactionScreen({super.key, this.transactionId});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'expense';
  int? _selectedCategoryId;
  
  bool _isSaving = false;
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _loadTransaction();
    }
  }

  Future<void> _loadTransaction() async {
    final db = DatabaseHelper();
    final transactions = await db.getAllTransactions();
    final t = transactions.firstWhere((element) => element['id'] == widget.transactionId);
    
    setState(() {
      _amountController.text = t['amount'].toString();
      _descriptionController.text = t['description'] ?? '';
      _selectedDate = DateTime.parse(t['date']);
      _selectedType = t['type'];
      _selectedCategoryId = t['category_id'];
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    final rules = await DatabaseHelper().getRulesForPrefix(query.toLowerCase());
    final cats = await DatabaseHelper().getAllCategories();
    
    setState(() {
      _suggestions = rules.map((r) {
        final cat = cats.firstWhere((c) => c['id'] == r['category_id']);
        return {'category_id': r['category_id'], 'category_name': cat['name']};
      }).toList();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите категорию')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final row = {
        'amount': amount,
        'date': _selectedDate.toIso8601String().substring(0, 10),
        'type': _selectedType,
        'category_id': _selectedCategoryId!,
        'description': _descriptionController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final actions = ref.read(transactionActionsProvider);
      if (widget.transactionId != null) {
        await actions.update(widget.transactionId!, row);
      } else {
        await actions.add(row);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сохранено')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.transactionId == null ? 'Новая транзакция' : 'Редактирование')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Сумма', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Введите сумму';
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return 'Некорректная сумма';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Выбор типа
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Расход')),
                ButtonSegment(value: 'income', label: Text('Доход')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedType = newSelection.first);
              },
            ),
            const SizedBox(height: 16),

            // Выбор даты
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Дата', border: OutlineInputBorder()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('d MMMM yyyy', 'ru').format(_selectedDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Выбор категории
            categoriesAsync.when(
              data: (cats) => DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
                items: cats.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                validator: (val) => val == null ? 'Выберите категорию' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, st) => Text('Ошибка загрузки категорий: $e'),
            ),
            const SizedBox(height: 16),

            // Описание и автоклассификация
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание (необязательно)', border: OutlineInputBorder()),
              onChanged: (val) {
                _fetchSuggestions(val);
              },
            ),
            
            if (_suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: _suggestions.map((s) => ActionChip(
                    label: Text('${s['category_name']}'),
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = s['category_id'];
                        _suggestions = [];
                      });
                    },
                  )).toList(),
                ),
              ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: _isSaving ? const CircularProgressIndicator() : const Text('Сохранить'),
            )
          ],
        ),
      ),
    );
  }
}