import 'package:equatable/equatable.dart';

/// Тип помещения
enum RoomType {
  kitchen('Кухня', minArea: 8.0, icon: '🍳'),
  livingRoom('Гостиная', minArea: 16.0, icon: '🛋️'),
  bedroom('Спальня', minArea: 12.0, icon: '🛏️'),
  bathroom('Ванная', minArea: 3.5, icon: '🚿'),
  toilet('Туалет', minArea: 1.2, icon: '🚽'),
  hallway('Коридор', minArea: 0, icon: '🚶'),
  balcony('Балкон/Лоджия', minArea: 0, icon: '🌿'),
  storage('Кладовая', minArea: 2.0, icon: '📦'),
  office('Кабинет', minArea: 9.0, icon: '💼'),
  childrenRoom('Детская', minArea: 12.0, icon: '🧸');

  final String label;
  final double minArea; // минимальная площадь по СНиП (м²)
  final String icon;

  const RoomType(this.label, {required this.minArea, required this.icon});
}

/// Дверь
class Door extends Equatable {
  /// Позиция двери относительно комнаты (метры)
  final double x, y;

  /// Ширина двери (метры)
  final double width;

  /// Направление открывания: true = по часовой, false = против
  final bool clockwise;

  /// Тип двери
  final DoorType type;

  const Door({
    required this.x,
    required this.y,
    this.width = 0.9,
    this.clockwise = true,
    this.type = DoorType.internal,
  });

  @override
  List<Object?> get props => [x, y, width, clockwise, type];
}

enum DoorType {
  internal('Межкомнатная'),
  entrance('Входная'),
  balcony('Балконная');

  final String label;
  const DoorType(this.label);
}

/// Окно
class Window extends Equatable {
  /// Позиция окна относительно комнаты (метры)
  final double x, y;

  /// Ширина окна (метры)
  final double width;

  /// Высота подоконника от пола (метры)
  final double sillHeight;

  /// Тип окна
  final WindowType type;

  const Window({
    required this.x,
    required this.y,
    this.width = 1.2,
    this.sillHeight = 0.9,
    this.type = WindowType.standard,
  });

  @override
  List<Object?> get props => [x, y, width, sillHeight, type];
}

enum WindowType {
  standard('Обычное'),
  balcony('Балконное'),
  french('Французское (в пол)');

  final String label;
  const WindowType(this.label);
}

/// Комната/помещение
class Room extends Equatable {
  final RoomType type;

  /// Позиция левого верхнего угла (метры от начала плана)
  final double x, y;

  /// Размеры (метры)
  final double width, height;

  final List<Door> doors;
  final List<Window> windows;

  /// Флаги для специальных параметров
  final bool hasBalconyAccess;
  final bool hasVentilation;

  Room({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.doors = const [],
    this.windows = const [],
    this.hasBalconyAccess = false,
    this.hasVentilation = true,
  });

  /// Площадь комнаты (м²)
  double get area => width * height;

  /// Периметр (метры)
  double get perimeter => 2 * (width + height);

  /// Соответствует ли СНиП по площади
  bool get isAreaCompliant => type.minArea == 0 || area >= type.minArea;

  /// Есть ли естественное освещение
  bool get hasNaturalLight => windows.isNotEmpty;

  /// Соответствует ли СНиП по освещению
  bool get isLightCompliant =>
      hasNaturalLight ||
      type == RoomType.bathroom ||
      type == RoomType.toilet ||
      type == RoomType.storage;

  /// Общий compliance score (0.0 - 1.0)
  double get complianceScore {
    double score = 1.0;
    if (!isAreaCompliant) score -= 0.4;
    if (!isLightCompliant) score -= 0.3;
    if (type == RoomType.kitchen && !hasVentilation) score -= 0.3;
    return score.clamp(0.0, 1.0);
  }

  /// Предупреждения для комнаты
  List<String> get warnings {
    final result = <String>[];
    if (!isAreaCompliant) {
      result.add(
        '${type.label}: площадь ${area.toStringAsFixed(1)}м² < мин. ${type.minArea}м²',
      );
    }
    if (!isLightCompliant) {
      result.add('${type.label}: нет естественного освещения');
    }
    if (type == RoomType.kitchen && !hasVentilation) {
      result.add('${type.label}: нет вентиляции');
    }
    if (doors.isEmpty && type != RoomType.balcony) {
      result.add('${type.label}: нет двери');
    }
    return result;
  }

  Room copyWith({
    RoomType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    List<Door>? doors,
    List<Window>? windows,
    bool? hasBalconyAccess,
    bool? hasVentilation,
  }) {
    return Room(
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      hasBalconyAccess: hasBalconyAccess ?? this.hasBalconyAccess,
      hasVentilation: hasVentilation ?? this.hasVentilation,
    );
  }

  @override
  List<Object?> get props => [
    type,
    x,
    y,
    width,
    height,
    doors,
    windows,
    hasBalconyAccess,
    hasVentilation,
  ];
}

/// План помещения
class FloorPlan extends Equatable {
  final List<Room> rooms;

  /// Общие размеры (метры)
  final double totalWidth, totalHeight;

  /// Тип объекта
  final FloorPlanType objectType;

  FloorPlan({
    required this.rooms,
    required this.totalWidth,
    required this.totalHeight,
    this.objectType = FloorPlanType.apartment,
  });

  /// Общая площадь (м²)
  double get totalArea => totalWidth * totalHeight;

  /// Жилая площадь (м²)
  double get livingArea => rooms
      .where(
        (r) =>
            r.type == RoomType.bedroom ||
            r.type == RoomType.livingRoom ||
            r.type == RoomType.childrenRoom,
      )
      .fold(0.0, (sum, r) => sum + r.area);

  /// Общий compliance score
  double get complianceScore {
    if (rooms.isEmpty) return 0.0;
    return rooms.map((r) => r.complianceScore).reduce((a, b) => a + b) /
        rooms.length;
  }

  /// Все предупреждения
  List<String> get allWarnings => rooms.expand((r) => r.warnings).toList();

  /// Количество комнат (без коридоров, санузлов, балконов)
  int get roomCount => rooms
      .where(
        (r) =>
            r.type == RoomType.bedroom ||
            r.type == RoomType.livingRoom ||
            r.type == RoomType.kitchen ||
            r.type == RoomType.childrenRoom ||
            r.type == RoomType.office,
      )
      .length;

  /// Комнаты по типу
  List<Room> roomsByType(RoomType type) =>
      rooms.where((r) => r.type == type).toList();

  /// Проверка что план валиден
  bool get isValid => allWarnings.isEmpty;

  FloorPlan copyWith({
    List<Room>? rooms,
    double? totalWidth,
    double? totalHeight,
    FloorPlanType? objectType,
  }) {
    return FloorPlan(
      rooms: rooms ?? this.rooms,
      totalWidth: totalWidth ?? this.totalWidth,
      totalHeight: totalHeight ?? this.totalHeight,
      objectType: objectType ?? this.objectType,
    );
  }

  @override
  List<Object?> get props => [rooms, totalWidth, totalHeight, objectType];
}

enum FloorPlanType {
  apartment('Квартира'),
  house('Частный дом'),
  office('Офис'),
  studio('Студия');

  final String label;
  const FloorPlanType(this.label);
}
