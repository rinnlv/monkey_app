class Template {
  final int? id;
  final String name;
  final double amount;
  final int categoryId;
  final String? description;
  final String type; // НОВОЕ ПОЛЕ

  Template({
    this.id, 
    required this.name, 
    required this.amount, 
    required this.categoryId, 
    this.description, 
    this.type = 'expense', // По умолчанию расход
  });

  factory Template.fromMap(Map<String, dynamic> map) => Template(
        id: map['id'] as int?,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['category_id'] as int,
        description: map['description'] as String?,
        type: map['type'] as String? ?? 'expense',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'amount': amount,
        'category_id': categoryId,
        'description': description,
        'type': type,
      };
}