class Category {
  final int? id;
  final String name;
  final String? icon;
  final String? color;
  final bool isDefault;

  Category({this.id, required this.name, this.icon, this.color, this.isDefault = false});

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String?,
        color: map['color'] as String?,
        isDefault: (map['is_default'] as int? ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'is_default': isDefault ? 1 : 0,
      };
}