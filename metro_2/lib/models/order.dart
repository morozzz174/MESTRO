import 'dart:convert';

/// Тип работы (тип заявки)
enum WorkType {
  windows('Окна', 'windows'),
  doors('Двери', 'doors'),
  airConditioners('Кондиционеры', 'air_conditioners'),
  kitchens('Кухни', 'kitchens'),
  tiles('Плиточные работы', 'tiles'),
  furniture('Мебельные блоки', 'furniture'),
  engineering('Инженерные системы', 'engineering'),
  electrical('Электрика', 'electrical');

  final String title;
  final String checklistFile;

  const WorkType(this.title, this.checklistFile);
}

/// Статус заявки
enum OrderStatus {
  newOrder('Новая'),
  inProgress('В работе'),
  completed('Завершена'),
  cancelled('Отменена');

  final String label;
  const OrderStatus(this.label);
}

/// Модель заявки
class Order {
  final String id;
  final String clientName;
  final String address;
  final DateTime date;
  final OrderStatus status;
  final WorkType workType;
  final Map<String, dynamic> checklistData;
  final List<PhotoAnnotation> photos;
  final double? estimatedCost;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Поля для календаря и уведомлений
  final DateTime? appointmentDate; // Дата и время замера
  final DateTime? appointmentEnd; // Окончание замера
  final String? clientPhone; // Телефон клиента для SMS
  final String? notes; // Заметки к замеру

  Order({
    required this.id,
    required this.clientName,
    required this.address,
    required this.date,
    this.status = OrderStatus.newOrder,
    required this.workType,
    this.checklistData = const {},
    this.photos = const [],
    this.estimatedCost,
    required this.createdAt,
    required this.updatedAt,
    this.appointmentDate,
    this.appointmentEnd,
    this.clientPhone,
    this.notes,
  });

  Order copyWith({
    String? id,
    String? clientName,
    String? address,
    DateTime? date,
    OrderStatus? status,
    WorkType? workType,
    Map<String, dynamic>? checklistData,
    List<PhotoAnnotation>? photos,
    double? estimatedCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? appointmentDate,
    DateTime? appointmentEnd,
    String? clientPhone,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      date: date ?? this.date,
      status: status ?? this.status,
      workType: workType ?? this.workType,
      checklistData: checklistData ?? this.checklistData,
      photos: photos ?? this.photos,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentEnd: appointmentEnd ?? this.appointmentEnd,
      clientPhone: clientPhone ?? this.clientPhone,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_name': clientName,
      'address': address,
      'date': date.toIso8601String(),
      'status': status.name,
      'work_type': workType.name,
      'checklist_data': jsonEncode(checklistData),
      'estimated_cost': estimatedCost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'appointment_date': appointmentDate?.toIso8601String(),
      'appointment_end': appointmentEnd?.toIso8601String(),
      'client_phone': clientPhone,
      'notes': notes,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    final photosList = map['photos'];
    final List<PhotoAnnotation> photos = photosList is List
        ? photosList
              .map((p) => PhotoAnnotation.fromMap(p as Map<String, dynamic>))
              .toList()
        : [];

    return Order(
      id: map['id'] as String,
      clientName: map['client_name'] as String,
      address: map['address'] as String,
      date: DateTime.parse(map['date'] as String),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.newOrder,
      ),
      workType: WorkType.values.firstWhere(
        (e) => e.name == map['work_type'],
        orElse: () => WorkType.windows,
      ),
      checklistData: _parseChecklistData(map['checklist_data']),
      photos: photos,
      estimatedCost: map['estimated_cost'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      appointmentDate: map['appointment_date'] != null
          ? DateTime.parse(map['appointment_date'] as String)
          : null,
      appointmentEnd: map['appointment_end'] != null
          ? DateTime.parse(map['appointment_end'] as String)
          : null,
      clientPhone: map['client_phone'] as String?,
      notes: map['notes'] as String?,
    );
  }

  /// Проверка: является ли замер "прошедшим"
  bool get isPast {
    final ref = appointmentDate ?? date;
    return ref.isBefore(DateTime.now().subtract(const Duration(hours: 1)));
  }

  /// Проверка: является ли замер "сегодняшним"
  bool get isToday {
    final ref = appointmentDate ?? date;
    final now = DateTime.now();
    return ref.year == now.year && ref.month == now.month && ref.day == now.day;
  }

  /// Проверка: является ли замер "будущим"
  bool get isFuture {
    final ref = appointmentDate ?? date;
    return ref.isAfter(DateTime.now());
  }

  /// Получить дату для календаря (приоритет: appointmentDate → date)
  DateTime get calendarDate => appointmentDate ?? date;

  /// Форматированное время замера
  String? get appointmentTime {
    final appt = appointmentDate;
    if (appt == null) return null;
    final hour = appt.hour.toString().padLeft(2, '0');
    final min = appt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  /// Парсинг checklistData из БД (JSON строка или старый формат)
  static Map<String, dynamic> _parseChecklistData(dynamic data) {
    if (data == null) return {};
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      if (data.isEmpty) return {};
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Старый формат: "{width: 1200, height: 1400}" — пытаемся распарсить
        return _parseLegacyFormat(data);
      }
    }
    return {};
  }

  /// Парсинг старого формата "{key: value, key2: value2}"
  static Map<String, dynamic> _parseLegacyFormat(String data) {
    final result = <String, dynamic>{};
    // Убираем фигурные скобки
    final cleaned = data.replaceAll('{', '').replaceAll('}', '');
    final pairs = cleaned.split(',');
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim();
        var value = parts[1].trim();
        // Пробуем распарсить как число
        final numValue = double.tryParse(value);
        if (numValue != null) {
          result[key] = numValue;
        } else if (value == 'true') {
          result[key] = true;
        } else if (value == 'false') {
          result[key] = false;
        } else {
          result[key] = value.replaceAll("'", '').replaceAll('"', '');
        }
      }
    }
    return result;
  }
}

/// Модель аннотированного фото
class PhotoAnnotation {
  final String id;
  final String orderId;
  final String filePath;
  final String? annotatedPath;
  final String? checklistFieldId;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  const PhotoAnnotation({
    required this.id,
    required this.orderId,
    required this.filePath,
    this.annotatedPath,
    this.checklistFieldId,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'file_path': filePath,
      'annotated_path': annotatedPath,
      'checklist_field_id': checklistFieldId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PhotoAnnotation.fromMap(Map<String, dynamic> map) {
    return PhotoAnnotation(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      filePath: map['file_path'] as String,
      annotatedPath: map['annotated_path'] as String?,
      checklistFieldId: map['checklist_field_id'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// Элемент коммерческого предложения
class QuoteItem {
  final String id;
  final String name;
  final double unitPrice;
  final String unit;
  final double quantity;

  const QuoteItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.unit,
    required this.quantity,
  });

  double get totalPrice => unitPrice * quantity;
}
