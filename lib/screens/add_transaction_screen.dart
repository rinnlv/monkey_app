import 'package:flutter/material.dart';
class AddTransactionScreen extends StatelessWidget {
  final int? transactionId;
  const AddTransactionScreen({super.key, this.transactionId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Добавить')), body: const Center(child: Text('Экран добавления')));
}