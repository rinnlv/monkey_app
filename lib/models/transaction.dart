class Transaction {
  final int? id;
  final double amount;
  final DateTime date;
  final String type; // 'expense' или 'income'
  final int categoryId;
  final String? description;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.categoryId,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        type: map['type'] as String,
        categoryId: map['category_id'] as int,
        description: map['description'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'amount': amount,
        'date': date.toIso8601String().substring(0, 10),
        'type': type,
        'category_id': categoryId,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}