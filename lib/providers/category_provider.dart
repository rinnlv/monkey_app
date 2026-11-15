import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';
import '../models/category.dart';

final categoryProvider = FutureProvider<List<Category>>((ref) async {
  final maps = await DatabaseHelper().getAllCategories();
  return maps.map((m) => Category.fromMap(m)).toList();
});