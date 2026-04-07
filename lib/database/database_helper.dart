import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order.dart';
import '../models/user.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mestro.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Миграция v1 -> v2: добавляем таблицу пользователей
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          phone TEXT NOT NULL UNIQUE,
          full_name TEXT,
          consent_date TEXT NOT NULL,
          consent_version TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Миграция v2 -> v3: добавляем колонки для календаря и таблицу уведомлений
      await db.execute('ALTER TABLE orders ADD COLUMN appointment_date TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN appointment_end TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN client_phone TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN notes TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          template_id TEXT NOT NULL,
          recipient_phone TEXT,
          scheduled_at TEXT NOT NULL,
          sent_at TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notif_order ON notifications (order_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notif_scheduled ON notifications (scheduled_at)',
      );
    }
    if (oldVersion < 4) {
      // Миграция v3 -> v4: добавляем ниши пользователей
      await db.execute(
        'ALTER TABLE users ADD COLUMN selected_work_types TEXT DEFAULT ""',
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица пользователей
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        phone TEXT NOT NULL UNIQUE,
        full_name TEXT,
        consent_date TEXT NOT NULL,
        consent_version TEXT NOT NULL,
        selected_work_types TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Таблица заявок
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        client_name TEXT NOT NULL,
        address TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        work_type TEXT NOT NULL,
        checklist_data TEXT,
        estimated_cost REAL,
        appointment_date TEXT,
        appointment_end TEXT,
        client_phone TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Таблица фото
    await db.execute('''
      CREATE TABLE photo_annotations (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        annotated_path TEXT,
        checklist_field_id TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // Таблица уведомлений
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        template_id TEXT NOT NULL,
        recipient_phone TEXT,
        scheduled_at TEXT NOT NULL,
        sent_at TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // Индекс для быстрого поиска по заявке
    await db.execute(
      'CREATE INDEX idx_photo_order ON photo_annotations (order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_notif_order ON notifications (order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_notif_scheduled ON notifications (scheduled_at)',
    );
  }

  // ===== CRUD для заявок =====

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final maps = await db.query('orders', orderBy: 'created_at DESC');
    final orders = <Order>[];
    for (final map in maps) {
      final order = Order.fromMap(map);
      final photos = await getPhotosForOrder(order.id);
      orders.add(order.copyWith(photos: photos));
    }
    return orders;
  }

  Future<Order?> getOrder(String id) async {
    final db = await database;
    final maps = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final order = Order.fromMap(maps.first);
    final photos = await getPhotosForOrder(id);
    return order.copyWith(photos: photos);
  }

  Future<void> insertOrder(Order order) async {
    final db = await database;
    await db.insert('orders', order.toMap());
  }

  Future<void> updateOrder(Order order) async {
    final db = await database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> deleteOrder(String id) async {
    final db = await database;
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
    // Фото удалятся каскадно (если поддерживается) или вручную
    await db.delete(
      'photo_annotations',
      where: 'order_id = ?',
      whereArgs: [id],
    );
  }

  // ===== CRUD для фото =====

  Future<List<PhotoAnnotation>> getPhotosForOrder(String orderId) async {
    final db = await database;
    final maps = await db.query(
      'photo_annotations',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return maps.map((map) => PhotoAnnotation.fromMap(map)).toList();
  }

  Future<void> insertPhoto(PhotoAnnotation photo) async {
    final db = await database;
    await db.insert('photo_annotations', photo.toMap());
  }

  Future<void> updatePhoto(PhotoAnnotation photo) async {
    final db = await database;
    await db.update(
      'photo_annotations',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.delete('photo_annotations', where: 'id = ?', whereArgs: [id]);
  }

  // ===== CRUD для пользователей =====

  Future<User?> getCurrentUser() async {
    final db = await database;
    final maps = await db.query('users', limit: 1, orderBy: 'created_at DESC');
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<bool> isUserRegistered() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // ===== Методы для календаря =====

  /// Получить заявки за конкретную дату (по appointment_date или date)
  Future<List<Order>> getOrdersByDate(DateTime date) async {
    final db = await database;
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final maps = await db.rawQuery(
      '''
      SELECT * FROM orders
      WHERE (
        (appointment_date IS NOT NULL AND appointment_date >= ? AND appointment_date <= ?)
        OR
        (appointment_date IS NULL AND date >= ? AND date <= ?)
      )
      ORDER BY 
        CASE WHEN appointment_date IS NOT NULL THEN appointment_date ELSE date END ASC
    ''',
      [
        dateStart.toIso8601String(),
        dateEnd.toIso8601String(),
        dateStart.toIso8601String(),
        dateEnd.toIso8601String(),
      ],
    );

    final orders = <Order>[];
    for (final map in maps) {
      final order = Order.fromMap(map);
      final photos = await getPhotosForOrder(order.id);
      orders.add(order.copyWith(photos: photos));
    }
    return orders;
  }

  /// Получить все заявки с датой замера (для календаря)
  Future<Map<DateTime, List<Order>>> getAllCalendarOrders() async {
    final orders = await getAllOrders();
    final Map<DateTime, List<Order>> result = {};

    for (final order in orders) {
      final calDate = order.calendarDate;
      final key = DateTime(calDate.year, calDate.month, calDate.day);
      result.putIfAbsent(key, () => []);
      result[key]!.add(order);
    }

    return result;
  }

  /// Получить будущие замеры
  Future<List<Order>> getFutureAppointments() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.rawQuery(
      '''
      SELECT * FROM orders
      WHERE (appointment_date IS NOT NULL AND appointment_date > ?)
         OR (appointment_date IS NULL AND date > ?)
      ORDER BY 
        CASE WHEN appointment_date IS NOT NULL THEN appointment_date ELSE date END ASC
    ''',
      [now, now],
    );

    final orders = <Order>[];
    for (final map in maps) {
      final order = Order.fromMap(map);
      final photos = await getPhotosForOrder(order.id);
      orders.add(order.copyWith(photos: photos));
    }
    return orders;
  }

  /// Получить прошедшие замеры
  Future<List<Order>> getPastAppointments() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.rawQuery(
      '''
      SELECT * FROM orders
      WHERE (appointment_date IS NOT NULL AND appointment_date <= ?)
         OR (appointment_date IS NULL AND date <= ?)
      ORDER BY 
        CASE WHEN appointment_date IS NOT NULL THEN appointment_date ELSE date END DESC
    ''',
      [now, now],
    );

    final orders = <Order>[];
    for (final map in maps) {
      final order = Order.fromMap(map);
      final photos = await getPhotosForOrder(order.id);
      orders.add(order.copyWith(photos: photos));
    }
    return orders;
  }

  // ===== CRUD для уведомлений =====

  /// Получить ожидающие уведомления
  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.query(
      'notifications',
      where: 'status = ? AND scheduled_at <= ?',
      whereArgs: ['pending', now],
      orderBy: 'scheduled_at ASC',
    );
  }

  /// Создать уведомление
  Future<void> insertNotification(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('notifications', data);
  }

  /// Обновить статус уведомления
  Future<void> updateNotificationStatus(
    String id,
    String status, {
    DateTime? sentAt,
  }) async {
    final db = await database;
    final data = <String, dynamic>{
      'status': status,
      if (sentAt != null) 'sent_at': sentAt.toIso8601String(),
    };
    await db.update('notifications', data, where: 'id = ?', whereArgs: [id]);
  }

  /// Получить уведомления для заявки
  Future<List<Map<String, dynamic>>> getNotificationsForOrder(
    String orderId,
  ) async {
    final db = await database;
    return db.query(
      'notifications',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'scheduled_at DESC',
    );
  }
}
