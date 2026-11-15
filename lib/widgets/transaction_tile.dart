import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    required this.onTap,
    required this.onLongPress,
  });

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final amountColor = isExpense ? Colors.red.shade700 : Colors.green.shade700;
    final amountPrefix = isExpense ? '-' : '+';
    
    // Оставляем 2 знака после запятой, чтобы копейки отображались
    final formatter = NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 2);

    final catColor = category?.color != null ? _hexToColor(category!.color!) : Colors.grey;
    final catIcon = category?.icon ?? 'other';

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: CircleAvatar(
        backgroundColor: catColor.withOpacity(0.2),
        child: SvgPicture.asset(
          'assets/icons/$catIcon.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
        ),
      ),
      title: Text(
        category?.name ?? 'Без категории',
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis, // Защита для длинных названий категорий
      ),
      subtitle: transaction.description != null && transaction.description!.isNotEmpty
          ? Text(
              transaction.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: SizedBox(
        width: 110, // Ограничиваем ширину, чтобы длинная сумма не ломала экран
        child: Text(
          '$amountPrefix${formatter.format(transaction.amount)}',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}