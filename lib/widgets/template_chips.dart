import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../providers/transaction_provider.dart';

class TemplateChips extends ConsumerStatefulWidget {
  const TemplateChips({super.key});
  @override
  ConsumerState<TemplateChips> createState() => _TemplateChipsState();
}

class _TemplateChipsState extends ConsumerState<TemplateChips> {
  List<Map<String, dynamic>> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final t = await DatabaseHelper().getAllTemplates();
    if (mounted) setState(() => _templates = t);
  }

  @override
  Widget build(BuildContext context) {
    if (_templates.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _templates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final t = _templates[index];
          return ActionChip(
            label: Text('${t['name']} (${t['amount']} ₽)'),
            onPressed: () => _addTransactionFromTemplate(t),
          );
        },
      ),
    );
  }

  void _addTransactionFromTemplate(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить трату?'),
        content: Text('Добавить "${template['name']}" на сегодня?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(transactionActionsProvider).add({
                'amount': template['amount'],
                'date': DateTime.now().toIso8601String().substring(0, 10),
                'type': 'expense',
                'category_id': template['category_id'],
                'description': template['name'],
                'created_at': DateTime.now().toIso8601String(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавлено')));
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}