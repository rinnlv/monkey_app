import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../db/database_helper.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _budgetController = TextEditingController();

  void _updateBudget() async {
    final db = DatabaseHelper();
    final currentBudget = await db.getSetting('budget_month') ?? '0';
    _budgetController.text = currentBudget;
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Бюджет на месяц'),
        content: TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '₽'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              await db.setSetting('budget_month', _budgetController.text);
              ref.invalidate(settingsProvider);
              if (mounted) Navigator.pop(ctx);
            }, 
            child: const Text('Сохранить')
          ),
        ],
      ),
    );
  }

  void _addCategory() {
    final nameController = TextEditingController();
    String selectedIcon = 'food';
    String selectedColor = '#A0522D';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Новая категория'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Название')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedIcon,
                  decoration: const InputDecoration(labelText: 'Иконка'),
                  items: ['food', 'transport', 'cafe', 'fun', 'health', 'clothes', 'other'].map((i) => DropdownMenuItem(
                    value: i, 
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/icons/$i.svg', width: 24),
                        const SizedBox(width: 8),
                        Text(i),
                      ],
                    )
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedIcon = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  await DatabaseHelper().insertCategory({
                    'name': nameController.text,
                    'icon': selectedIcon,
                    'color': selectedColor,
                    'is_default': 0,
                  });
                  ref.invalidate(categoryProvider);
                  if (mounted) Navigator.pop(ctx);
                }, 
                child: const Text('Создать')
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          const ListTile(title: Text('БЮДЖЕТ НА МЕСЯЦ', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))),
          settingsAsync.when(
            data: (settings) => ListTile(
              title: const Text('Лимит расходов'),
              subtitle: Text('${settings['budget_month']} ₽'),
              trailing: const Icon(Icons.edit),
              onTap: _updateBudget,
            ),
            loading: () => const ListTile(title: Text('Загрузка...')),
            error: (e, st) => const SizedBox(),
          ),
          const Divider(),
          
          const ListTile(title: Text('КАТЕГОРИИ', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))),
          categoriesAsync.when(
            data: (cats) => Column(
              children: [
                ...cats.map((c) => ListTile(
                  leading: SvgPicture.asset('assets/icons/${c.icon}.svg', width: 24),
                  title: Text(c.name),
                  subtitle: c.isDefault ? const Text('Предустановленная', style: TextStyle(fontSize: 12)) : null,
                )),
                TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить категорию'),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Ошибка: $e'),
          ),
          const Divider(),
          
          const ListTile(title: Text('О ПРИЛОЖЕНИИ', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))),
          const ListTile(title: Text('MONkEY Lite v1.0'), subtitle: const Text('Трекер расходов с мартышкой 🐒')),
        ],
      ),
    );
  }
}