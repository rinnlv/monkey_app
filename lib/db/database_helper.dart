import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'monkey_lite.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Таблица категорий
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Таблица транзакций
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // 3. Таблица шаблонов
    await db.execute('''
      CREATE TABLE templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        description TEXT,
        type TEXT NOT NULL DEFAULT 'expense', 
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // 4. Таблица правил классификации
    await db.execute('''
      CREATE TABLE classification_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        counter INTEGER NOT NULL DEFAULT 1,
        UNIQUE(pattern, category_id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // 5. Таблица настроек
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Заполнение базовыми данными
    await _insertDefaultCategories(db);
    await _insertDefaultRules(db);
    await _insertDefaultSettings(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final categories = [
      {'name': 'Продукты', 'icon': 'food', 'color': '#A0522D', 'is_default': 1},
      {'name': 'Транспорт', 'icon': 'transport', 'color': '#6B8E23', 'is_default': 1},
      {'name': 'Кафе и рестораны', 'icon': 'cafe', 'color': '#D2691E', 'is_default': 1},
      {'name': 'Развлечения', 'icon': 'fun', 'color': '#8B4513', 'is_default': 1},
      {'name': 'Здоровье', 'icon': 'health', 'color': '#556B2F', 'is_default': 1},
      {'name': 'Одежда', 'icon': 'clothes', 'color': '#CD853F', 'is_default': 1},
      {'name': 'Прочее', 'icon': 'other', 'color': '#A9A9A9', 'is_default': 1},
    ];
    for (var cat in categories) {
      await db.insert('categories', cat);
    }
  }

  Future<void> _insertDefaultRules(Database db) async {
    // Получаем ID категорий для привязки
    final cats = await db.query('categories');
    int getCatId(String name) => cats.firstWhere((c) => c['name'] == name)['id'] as int;

    final rules = [
      {'pattern': 'пятёрочка', 'category_id': getCatId('Продукты'), 'counter': 1},
      {'pattern': 'перекрёсток', 'category_id': getCatId('Продукты'), 'counter': 1},
      {'pattern': 'магнит', 'category_id': getCatId('Продукты'), 'counter': 1},
      {'pattern': 'красное&белое', 'category_id': getCatId('Продукты'), 'counter': 1},
      {'pattern': 'яндекс.такси', 'category_id': getCatId('Транспорт'), 'counter': 1},
      {'pattern': 'метро', 'category_id': getCatId('Транспорт'), 'counter': 1},
      {'pattern': 'аптека', 'category_id': getCatId('Здоровье'), 'counter': 1},
      {'pattern': 'кофе', 'category_id': getCatId('Кафе и рестораны'), 'counter': 1},
      {'pattern': 'шаурма', 'category_id': getCatId('Кафе и рестораны'), 'counter': 1},
      {'pattern': 'кино', 'category_id': getCatId('Развлечения'), 'counter': 1},
    ];
    for (var rule in rules) {
      await db.insert('classification_rules', rule);
    }
  }

  Future<void> _insertDefaultSettings(Database db) async {
    final settings = [
      {'key': 'budget_month', 'value': '0'},
      {'key': 'last_record_date', 'value': ''},
      {'key': 'streak_count', 'value': '0'},
      {'key': 'user_name', 'value': 'Друг'},
      {'key': 'user_avatar', 'value': 'avatar1'},
      // Вставляем дату напрямую, чтобы не было ошибки
      {'key': 'first_open_date', 'value': DateTime.now().toIso8601String().substring(0, 10)},
    ];
    for (var s in settings) {
      await db.insert('settings', s);
    }
  }

  // --- МЕТОДЫ ДЛЯ РАБОТЫ С ДАННЫМИ ---

  // Транзакции
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'date DESC, id DESC');
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('transactions', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Категории
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('categories', row);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ? AND is_default = 0', whereArgs: [id]);
  }

  Future<void> transferTransactionsToCategory(int fromId, int toId) async {
    final db = await database;
    await db.update('transactions', {'category_id': toId}, where: 'category_id = ?', whereArgs: [fromId]);
  }

  // Шаблоны
  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final db = await database;
    return await db.query('templates');
  }

  Future<int> insertTemplate(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('templates', row);
  }

  Future<int> deleteTemplate(int id) async {
    final db = await database;
    return await db.delete('templates', where: 'id = ?', whereArgs: [id]);
  }

  // Правила автоклассификации
  Future<void> upsertClassificationRule(String pattern, int categoryId) async {
    final db = await database;
    final existing = await db.query('classification_rules',
        where: 'pattern = ? AND category_id = ?', whereArgs: [pattern, categoryId]);
    
    if (existing.isNotEmpty) {
      await db.rawUpdate('UPDATE classification_rules SET counter = counter + 1 WHERE id = ?', [existing.first['id']]);
    } else {
      await db.insert('classification_rules', {'pattern': pattern, 'category_id': categoryId, 'counter': 1});
    }
  }

  Future<List<Map<String, dynamic>>> getRulesForPrefix(String prefix) async {
    final db = await database;
    return await db.query('classification_rules',
        where: 'pattern LIKE ?', whereArgs: ['$prefix%'], orderBy: 'counter DESC', limit: 3);
  }

  // Настройки
  Future<String?> getSetting(String key) async {
    final db = await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) return res.first['value'] as String?;
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Сложные запросы для статистики и мотивации
  Future<void> updateStreak() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().substring(0, 10);
    
    String lastDate = await getSetting('last_record_date') ?? '';
    int streak = int.tryParse(await getSetting('streak_count') ?? '0') ?? 0;

    if (lastDate == today) {
      // Уже записывали сегодня, ничего не меняем
    } else if (lastDate == yesterday) {
      // Записывали вчера, увеличиваем серию
      await setSetting('streak_count', (streak + 1).toString());
      await setSetting('last_record_date', today);
    } else {
      // Пропустили день или первая запись
      await setSetting('streak_count', '1');
      await setSetting('last_record_date', today);
    }
  }

  Future<double> getSpentThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
    final res = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = "expense" AND date >= ?', [startOfMonth]);
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<double>> getMonthlyExpenseSums(int monthsBack) async {
    final db = await database;
    final now = DateTime.now();
    final startOfPast = DateTime(now.year, now.month - monthsBack, 1).toIso8601String().substring(0, 10);
    final endOfPast = DateTime(now.year, now.month, 0).toIso8601String().substring(0, 10);
    
    final res = await db.rawQuery('''
      SELECT strftime('%Y-%m', date) AS month, SUM(amount) AS s 
      FROM transactions 
      WHERE type = 'expense' AND date >= ? AND date <= ?
      GROUP BY month
    ''', [startOfPast, endOfPast]);
    
    return res.map((r) => (r['s'] as num?)?.toDouble() ?? 0.0).toList();
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('templates');
    await db.delete('classification_rules');
    await db.delete('categories'); // Удаляем всё
    await db.delete('settings');
    
    // ВАЖНО: Сразу же возвращаем базовые данные, чтобы приложение не осталось пустым
    await _insertDefaultCategories(db);
    await _insertDefaultRules(db);
    await _insertDefaultSettings(db);
  }
  
  Future<void> checkAndResetStreak() async {
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterday = "${yesterdayDate.year}-${yesterdayDate.month.toString().padLeft(2, '0')}-${yesterdayDate.day.toString().padLeft(2, '0')}";
    
    String lastDate = await getSetting('last_record_date') ?? '';
    
    // Если дата последней записи не пустая, и это не сегодня и не вчера — сбрасываем
    if (lastDate.isNotEmpty && lastDate != today && lastDate != yesterday) {
      await setSetting('streak_count', '0');
    }
  }
}