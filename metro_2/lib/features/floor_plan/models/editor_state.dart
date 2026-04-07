/// Состояние редактора плана
class EditorState {
  final List<RoomState> rooms;
  final double totalWidth;
  final double totalHeight;

  const EditorState({
    required this.rooms,
    required this.totalWidth,
    required this.totalHeight,
  });

  EditorState copyWith({
    List<RoomState>? rooms,
    double? totalWidth,
    double? totalHeight,
  }) {
    return EditorState(
      rooms: rooms ?? this.rooms,
      totalWidth: totalWidth ?? this.totalWidth,
      totalHeight: totalHeight ?? this.totalHeight,
    );
  }
}

/// Состояние отдельной комнаты
class RoomState {
  final String id;
  final String type;
  double x, y, width, height;
  final List<DoorState> doors;
  final List<WindowState> windows;

  RoomState({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.doors = const [],
    this.windows = const [],
  });

  double get area => width * height;

  RoomState copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    List<DoorState>? doors,
    List<WindowState>? windows,
  }) {
    return RoomState(
      id: id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
    );
  }
}

/// Состояние двери
class DoorState {
  final String id;
  final double x, y;
  final double width;
  final String type; // internal, entrance, balcony

  const DoorState({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    this.type = 'internal',
  });

  DoorState copyWith({double? x, double? y, double? width, String? type}) {
    return DoorState(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      type: type ?? this.type,
    );
  }
}

/// Состояние окна
class WindowState {
  final String id;
  final double x, y;
  final double width;
  final String type;

  const WindowState({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    this.type = 'standard',
  });

  WindowState copyWith({double? x, double? y, double? width, String? type}) {
    return WindowState(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      type: type ?? this.type,
    );
  }
}

/// Результат валидации
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}
