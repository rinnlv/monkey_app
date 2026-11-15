import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';
import '../providers/transaction_provider.dart';

// Добавляем провайдер для шаблонов
final templatesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Следим за транзакциями, чтобы при добавлении новой траты обновлять и шаблоны
  ref.watch(transactionProvider); 
  return await DatabaseHelper().getAllTemplates();
});

class TemplateChips extends ConsumerWidget {
  const TemplateChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return templatesAsync.when(
      loading: () => const SizedBox(),
      error: (e, st) => const SizedBox(),
      data: (templates) {
        if (templates.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final t = templates[index];
              return ActionChip(
                label: Text('${t['name']} (${t['amount']} ₽)'),
                onPressed: () => _addTransactionFromTemplate(context, ref, t),
              );
            },
          ),
        );
      },
    );
  }

  void _addTransactionFromTemplate(BuildContext context, WidgetRef ref, Map<String, dynamic> template) {
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
              // Принудительно обновляем список шаблонов
              ref.invalidate(templatesProvider); 
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