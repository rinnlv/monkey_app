import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';
import '../providers/transaction_provider.dart';

final templatesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
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
          height: 40, // Чуть ниже
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final t = templates[index];
              final isExpense = t['type'] != 'income'; 
              
              // Цвета из макета
              final borderColor = isExpense ? const Color(0xFF85422D) : const Color(0xFF688B4B);
              final textColor = borderColor;
              final sign = isExpense ? '-' : '+';

              return ActionChip(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: borderColor, width: 1.5),
                ),
                label: Text(
                  '$sign${t['amount']} ${t['name']}', 
                  style: TextStyle(color: textColor, fontSize: 12)
                ),
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
        title: const Text('Добавить транзакцию?'),
        content: Text('Добавить "${template['name']}" на сегодня?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(transactionActionsProvider).add({
                'amount': template['amount'],
                'date': DateTime.now().toIso8601String().substring(0, 10),
                'type': template['type'] ?? 'expense',
                'category_id': template['category_id'],
                'description': template['name'],
                'created_at': DateTime.now().toIso8601String(),
              });
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