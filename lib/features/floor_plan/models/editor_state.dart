import 'floor_plan_models.dart';

/// Состояние редактора плана
class EditorState {
  final List<RoomState> rooms;
  final double totalWidth;
  final double totalHeight;
  
  // Дополнительные элементы (не привязаны к комнатам)
  final List<DoorState> doors;
  final List<WindowState> windows;
  final List<RadiatorState> radiators;
  final List<PlumbingFixtureState> plumbingFixtures;
  final List<ElectricalPointState> electricalPoints;

  const EditorState({
    required this.rooms,
    required this.totalWidth,
    required this.totalHeight,
    this.doors = const [],
    this.windows = const [],
    this.radiators = const [],
    this.plumbingFixtures = const [],
    this.electricalPoints = const [],
  });

  /// Создание EditorState из FloorPlan
  factory EditorState.fromFloorPlan(FloorPlan plan) {
    return EditorState(
      rooms: plan.rooms
          .map((room) => RoomState(
                id: DateTime.now().millisecondsSinceEpoch.toString() +
                    room.type.name,
                type: room.type.name,
                x: room.x,
                y: room.y,
                width: room.width,
                height: room.height,
                doors: room.doors
                    .map((d) => DoorState(
                          id: d.x.toString() + d.y.toString(),
                          x: d.x,
                          y: d.y,
                          width: d.width,
                          type: d.type.name,
                        ))
                    .toList(),
                windows: room.windows
                    .map((w) => WindowState(
                          id: w.x.toString() + w.y.toString(),
                          x: w.x,
                          y: w.y,
                          width: w.width,
                        ))
                    .toList(),
              ))
          .toList(),
      totalWidth: plan.totalWidth,
      totalHeight: plan.totalHeight,
    );
  }

  EditorState copyWith({
    List<RoomState>? rooms,
    double? totalWidth,
    double? totalHeight,
    List<DoorState>? doors,
    List<WindowState>? windows,
    List<RadiatorState>? radiators,
    List<PlumbingFixtureState>? plumbingFixtures,
    List<ElectricalPointState>? electricalPoints,
  }) {
    return EditorState(
      rooms: rooms ?? this.rooms,
      totalWidth: totalWidth ?? this.totalWidth,
      totalHeight: totalHeight ?? this.totalHeight,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      radiators: radiators ?? this.radiators,
      plumbingFixtures: plumbingFixtures ?? this.plumbingFixtures,
      electricalPoints: electricalPoints ?? this.electricalPoints,
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
  final double x, y; // Позиция относительно комнаты или абсолютная
  final double width;
  final String type; // internal, entrance, balcony
  final String? roomId; // ID комнаты, к которой привязана дверь (null = свободная)
  final double rotation; // Угол поворота в градусах

  const DoorState({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    this.type = 'internal',
    this.roomId,
    this.rotation = 0,
  });

  DoorState copyWith({
    double? x,
    double? y,
    double? width,
    String? type,
    String? roomId,
    double? rotation,
  }) {
    return DoorState(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      rotation: rotation ?? this.rotation,
    );
  }
}

/// Состояние окна
class WindowState {
  final String id;
  final double x, y;
  final double width;
  final String type;
  final String? roomId; // ID комнаты, к которой привязано окно
  final double rotation;

  const WindowState({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    this.type = 'standard',
    this.roomId,
    this.rotation = 0,
  });

  WindowState copyWith({
    double? x,
    double? y,
    double? width,
    String? type,
    String? roomId,
    double? rotation,
  }) {
    return WindowState(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      rotation: rotation ?? this.rotation,
    );
  }
}

/// Состояние радиатора
class RadiatorState {
  final String id;
  final double x, y;
  final double length; // Длина радиатора в метрах
  final String type; // panel, sectional, convector

  const RadiatorState({
    required this.id,
    required this.x,
    required this.y,
    this.length = 1.0,
    this.type = 'panel',
  });

  RadiatorState copyWith({
    double? x,
    double? y,
    double? length,
    String? type,
  }) {
    return RadiatorState(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      length: length ?? this.length,
      type: type ?? this.type,
    );
  }
}

/// Состояние сантехнического прибора
class PlumbingFixtureState {
  final String id;
  final double x, y;
  final String type; // toilet, bathtub, sink, shower, washingMachine
  final double rotation; // Угол поворота

  const PlumbingFixtureState({
    required this.id,
    required this.x,
    required this.y,
    this.type = 'sink',
    this.rotation = 0,
  });

  PlumbingFixtureState copyWith({
    double? x,
    double? y,
    String? type,
    double? rotation,
  }) {
    return PlumbingFixtureState(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      rotation: rotation ?? this.rotation,
    );
  }
}

/// Состояние электрической точки
class ElectricalPointState {
  final String id;
  final double x, y;
  final String type; // socket, switch, lightPoint, internetSocket
  final double height; // Высота от пола (метры)

  const ElectricalPointState({
    required this.id,
    required this.x,
    required this.y,
    this.type = 'socket',
    this.height = 0.3,
  });

  ElectricalPointState copyWith({
    double? x,
    double? y,
    String? type,
    double? height,
  }) {
    return ElectricalPointState(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      height: height ?? this.height,
    );
  }
}
