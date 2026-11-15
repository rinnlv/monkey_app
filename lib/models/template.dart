class Template {
  final int? id;
  final String name;
  final double amount;
  final int categoryId;
  final String? description;

  Template({this.id, required this.name, required this.amount, required this.categoryId, this.description});

  factory Template.fromMap(Map<String, dynamic> map) => Template(
        id: map['id'] as int?,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['category_id'] as int,
        description: map['description'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'amount': amount,
        'category_id': categoryId,
        'description': description,
      };
}