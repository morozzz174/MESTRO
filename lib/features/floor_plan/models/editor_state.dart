import 'floor_plan_models_extended.dart' as ext;

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

  // === РАСШИРЕННЫЕ ЭЛЕМЕНТЫ ===
  final List<WallState> walls;
  final FoundationState? foundation;
  final RoofState? roof;
  final List<CeilingState> ceilings;
  final List<AxisLineState> axisLines;
  final List<DimensionLineState> dimensionLines;
  final List<LevelMarkState> levelMarks;
  final List<ColumnState> columns;
  final EngineeringSystemsState? engineeringSystems;
  final List<OutdoorElementState> outdoorElements;
  final List<FloorState> floors;
  final int currentFloorIndex;

  const EditorState({
    required this.rooms,
    required this.totalWidth,
    required this.totalHeight,
    this.doors = const [],
    this.windows = const [],
    this.radiators = const [],
    this.plumbingFixtures = const [],
    this.electricalPoints = const [],
    this.walls = const [],
    this.foundation,
    this.roof,
    this.ceilings = const [],
    this.axisLines = const [],
    this.dimensionLines = const [],
    this.levelMarks = const [],
    this.columns = const [],
    this.engineeringSystems,
    this.outdoorElements = const [],
    this.floors = const [],
    this.currentFloorIndex = 0,
  });

  factory EditorState.fromFloorPlan(ext.FloorPlan plan) {
    return EditorState(
      rooms: plan.rooms
          .map(
            (room) => RoomState(
              id:
                  DateTime.now().millisecondsSinceEpoch.toString() +
                  room.type.name,
              type: room.type.name,
              x: room.x,
              y: room.y,
              width: room.width,
              height: room.height,
              doors: room.doors
                  .map(
                    (d) => DoorState(
                      id: d.x.toString() + d.y.toString(),
                      x: d.x,
                      y: d.y,
                      width: d.width,
                      type: d.type.name,
                    ),
                  )
                  .toList(),
              windows: room.windows
                  .map(
                    (w) => WindowState(
                      id: w.x.toString() + w.y.toString(),
                      x: w.x,
                      y: w.y,
                      width: w.width,
                      type: w.type.name,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      totalWidth: plan.totalWidth,
      totalHeight: plan.totalHeight,
      walls: plan.walls.map((w) => WallState.fromWall(w)).toList(),
      foundation: plan.foundation != null
          ? FoundationState.fromFoundation(plan.foundation!)
          : null,
      roof: plan.roof != null ? RoofState.fromRoof(plan.roof!) : null,
      ceilings: plan.ceilings.map((c) => CeilingState.fromCeiling(c)).toList(),
      axisLines: plan.axisLines.map((a) => AxisLineState.fromAxis(a)).toList(),
      dimensionLines: plan.dimensionLines
          .map((d) => DimensionLineState.fromDimension(d))
          .toList(),
      levelMarks: plan.levelMarks
          .map((l) => LevelMarkState.fromLevelMark(l))
          .toList(),
      columns: plan.columns.map((c) => ColumnState.fromColumn(c)).toList(),
      engineeringSystems: plan.engineeringSystems.isEmpty
          ? null
          : EngineeringSystemsState.fromSystems(plan.engineeringSystems),
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
    List<WallState>? walls,
    FoundationState? foundation,
    RoofState? roof,
    List<CeilingState>? ceilings,
    List<AxisLineState>? axisLines,
    List<DimensionLineState>? dimensionLines,
    List<LevelMarkState>? levelMarks,
    List<ColumnState>? columns,
    EngineeringSystemsState? engineeringSystems,
    List<OutdoorElementState>? outdoorElements,
    List<FloorState>? floors,
    int? currentFloorIndex,
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
      walls: walls ?? this.walls,
      foundation: foundation ?? this.foundation,
      roof: roof ?? this.roof,
      ceilings: ceilings ?? this.ceilings,
      axisLines: axisLines ?? this.axisLines,
      dimensionLines: dimensionLines ?? this.dimensionLines,
      levelMarks: levelMarks ?? this.levelMarks,
      columns: columns ?? this.columns,
      engineeringSystems: engineeringSystems ?? this.engineeringSystems,
      outdoorElements: outdoorElements ?? this.outdoorElements,
      floors: floors ?? this.floors,
      currentFloorIndex: currentFloorIndex ?? this.currentFloorIndex,
    );
  }
}

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

class DoorState {
  final String id;
  final double x, y, width;
  final String type;
  final String? roomId;
  final double rotation;
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

class WindowState {
  final String id;
  final double x, y, width;
  final String type;
  final String? roomId;
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

class RadiatorState {
  final String id;
  final double x, y, length;
  final String type;
  const RadiatorState({
    required this.id,
    required this.x,
    required this.y,
    this.length = 1.0,
    this.type = 'panel',
  });
  RadiatorState copyWith({double? x, double? y, double? length, String? type}) {
    return RadiatorState(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      length: length ?? this.length,
      type: type ?? this.type,
    );
  }
}

class PlumbingFixtureState {
  final String id;
  final double x, y;
  final String type;
  final double rotation;
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

class ElectricalPointState {
  final String id;
  final double x, y;
  final String type;
  final double height;
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

// ===== РАСШИРЕННЫЕ STATE-КЛАССЫ =====
// (Все они находятся в этом файле, но ссылаются на ext.* из floor_plan_models_extended.dart)

// Объявим их как часть этого файла — см. продолжение ниже.
// Чтобы не дублировать, они уже определены через префикс ext. в EditorState.
// Теперь нужно добавить их определения.

// ===== WALL STATE =====
class WallState {
  final String id;
  final double x1, y1, x2, y2;
  final double thickness, height;
  final String type, material;
  final bool isLoadBearing;
  final double insulationThickness;
  final String interiorFinishing, exteriorFinishing;

  const WallState({
    required this.id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.thickness = 0.2,
    this.type = 'interior',
    this.material = 'brick',
    this.height = 2.7,
    this.isLoadBearing = false,
    this.insulationThickness = 0,
    this.interiorFinishing = 'plaster',
    this.exteriorFinishing = 'none',
  });

  double get length => ((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));

  factory WallState.fromWall(ext.Wall w) => WallState(
    id: '${w.x1}_${w.y1}_${w.x2}_${w.y2}',
    x1: w.x1,
    y1: w.y1,
    x2: w.x2,
    y2: w.y2,
    thickness: w.thickness,
    type: w.type.name,
    material: w.material.name,
    height: w.height,
    isLoadBearing: w.isLoadBearing,
    insulationThickness: w.insulationThickness,
    interiorFinishing: w.interiorFinishing.name,
    exteriorFinishing: w.exteriorFinishing.name,
  );

  ext.Wall toWall() => ext.Wall(
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    thickness: thickness,
    type: ext.WallType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ext.WallType.interior,
    ),
    material: ext.WallMaterial.values.firstWhere(
      (e) => e.name == material,
      orElse: () => ext.WallMaterial.brick,
    ),
    height: height,
    isLoadBearing: isLoadBearing,
    insulationThickness: insulationThickness,
    interiorFinishing: ext.FinishingType.values.firstWhere(
      (e) => e.name == interiorFinishing,
      orElse: () => ext.FinishingType.plaster,
    ),
    exteriorFinishing: ext.FinishingType.values.firstWhere(
      (e) => e.name == exteriorFinishing,
      orElse: () => ext.FinishingType.none,
    ),
  );

  WallState copyWith({
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    double? thickness,
    String? type,
    String? material,
    double? height,
    bool? isLoadBearing,
    double? insulationThickness,
  }) {
    return WallState(
      id: id,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      thickness: thickness ?? this.thickness,
      type: type ?? this.type,
      material: material ?? this.material,
      height: height ?? this.height,
      isLoadBearing: isLoadBearing ?? this.isLoadBearing,
      insulationThickness: insulationThickness ?? this.insulationThickness,
    );
  }
}

// ===== FOUNDATION STATE =====
class FoundationState {
  final String id;
  final String type;
  final double width, depth, height, embedmentDepth;
  final String concreteGrade, concreteClass, rebarClass;
  final int mainBarDiameter, mainBarsCount, stirrupDiameter, stirrupSpacing;
  final bool hasWaterproofing, hasInsulation, hasDrainage;
  final double sandCushionThickness;

  const FoundationState({
    required this.id,
    this.type = 'strip',
    this.width = 0.4,
    this.depth = 1.2,
    this.height = 0.5,
    this.embedmentDepth = 1.2,
    this.concreteGrade = 'М300',
    this.concreteClass = 'B22_5',
    this.mainBarDiameter = 12,
    this.mainBarsCount = 4,
    this.stirrupDiameter = 8,
    this.stirrupSpacing = 200,
    this.rebarClass = 'A500C',
    this.hasWaterproofing = false,
    this.hasInsulation = false,
    this.hasDrainage = false,
    this.sandCushionThickness = 0.2,
  });

  factory FoundationState.fromFoundation(ext.Foundation f) => FoundationState(
    id: 'foundation',
    type: f.type.name,
    width: f.width,
    depth: f.depth,
    height: f.height,
    embedmentDepth: f.embedmentDepth,
    concreteGrade: f.concreteGrade,
    concreteClass: f.concreteClass.name,
    mainBarDiameter: f.reinforcement.mainBarDiameter,
    mainBarsCount: f.reinforcement.mainBarsCount,
    stirrupDiameter: f.reinforcement.stirrupDiameter,
    stirrupSpacing: f.reinforcement.stirrupSpacing,
    rebarClass: f.reinforcement.rebarClass,
    hasWaterproofing: f.hasWaterproofing,
    hasInsulation: f.hasInsulation,
    hasDrainage: f.hasDrainage,
    sandCushionThickness: f.sandCushionThickness,
  );

  ext.Foundation toFoundation() => ext.Foundation(
    type: ext.FoundationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ext.FoundationType.strip,
    ),
    width: width,
    depth: depth,
    height: height,
    embedmentDepth: embedmentDepth,
    concreteGrade: concreteGrade,
    concreteClass: ext.ConcreteClass.values.firstWhere(
      (e) => e.name == concreteClass,
      orElse: () => ext.ConcreteClass.B22_5,
    ),
    reinforcement: ext.ReinforcementInfo(
      mainBarDiameter: mainBarDiameter,
      mainBarsCount: mainBarsCount,
      stirrupDiameter: stirrupDiameter,
      stirrupSpacing: stirrupSpacing,
      rebarClass: rebarClass,
    ),
    hasWaterproofing: hasWaterproofing,
    hasInsulation: hasInsulation,
    hasDrainage: hasDrainage,
    sandCushionThickness: sandCushionThickness,
  );

  FoundationState copyWith({
    String? type,
    double? width,
    double? depth,
    double? height,
    bool? hasWaterproofing,
    bool? hasInsulation,
    bool? hasDrainage,
    double? sandCushionThickness,
    String? concreteGrade,
    String? concreteClass,
    int? mainBarDiameter,
    int? mainBarsCount,
  }) {
    return FoundationState(
      id: id,
      type: type ?? this.type,
      width: width ?? this.width,
      depth: depth ?? this.depth,
      height: height ?? this.height,
      hasWaterproofing: hasWaterproofing ?? this.hasWaterproofing,
      hasInsulation: hasInsulation ?? this.hasInsulation,
      hasDrainage: hasDrainage ?? this.hasDrainage,
      sandCushionThickness: sandCushionThickness ?? this.sandCushionThickness,
      concreteGrade: concreteGrade ?? this.concreteGrade,
      concreteClass: concreteClass ?? this.concreteClass,
      mainBarDiameter: mainBarDiameter ?? this.mainBarDiameter,
      mainBarsCount: mainBarsCount ?? this.mainBarsCount,
    );
  }
}

// ===== ROOF STATE =====
class RoofState {
  final String id;
  final String type, roofingMaterial, rafterMaterial, insulationMaterial;
  final double area, slopeAngle, rafterLength, insulationThickness;
  final int rafterSpacing, rafterSectionWidth, rafterSectionHeight;
  final int rafterCount, snowRetentionCount;
  final bool hasWaterproofingMembrane, hasVaporBarrier, hasSnowRetention;

  const RoofState({
    required this.id,
    this.type = 'gable',
    this.area = 100,
    this.slopeAngle = 30,
    this.roofingMaterial = 'metalTile',
    this.rafterSpacing = 600,
    this.rafterSectionWidth = 50,
    this.rafterSectionHeight = 200,
    this.rafterLength = 5,
    this.rafterCount = 10,
    this.rafterMaterial = 'pine',
    this.insulationThickness = 0.2,
    this.insulationMaterial = 'mineralWool',
    this.hasWaterproofingMembrane = false,
    this.hasVaporBarrier = false,
    this.hasSnowRetention = false,
    this.snowRetentionCount = 0,
  });

  factory RoofState.fromRoof(ext.Roof r) => RoofState(
    id: 'roof',
    type: r.type.name,
    area: r.area,
    slopeAngle: r.slopeAngle,
    roofingMaterial: r.roofingMaterial.name,
    rafterSpacing: r.rafters.spacing,
    rafterSectionWidth: r.rafters.sectionWidth,
    rafterSectionHeight: r.rafters.sectionHeight,
    rafterLength: r.rafters.length,
    rafterCount: r.rafters.count,
    rafterMaterial: r.rafters.material.name,
    insulationThickness: r.insulation.thickness,
    insulationMaterial: r.insulation.material.name,
    hasWaterproofingMembrane: r.hasWaterproofingMembrane,
    hasVaporBarrier: r.hasVaporBarrier,
    hasSnowRetention: r.hasSnowRetention,
    snowRetentionCount: r.snowRetentionCount,
  );

  ext.Roof toRoof() => ext.Roof(
    type: ext.RoofType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ext.RoofType.gable,
    ),
    area: area,
    slopeAngle: slopeAngle,
    roofingMaterial: ext.RoofMaterial.values.firstWhere(
      (e) => e.name == roofingMaterial,
      orElse: () => ext.RoofMaterial.metalTile,
    ),
    rafters: ext.RafterSystem(
      spacing: rafterSpacing,
      sectionWidth: rafterSectionWidth,
      sectionHeight: rafterSectionHeight,
      length: rafterLength,
      count: rafterCount,
      material: ext.RafterMaterial.values.firstWhere(
        (e) => e.name == rafterMaterial,
        orElse: () => ext.RafterMaterial.pine,
      ),
    ),
    insulation: ext.RoofInsulation(
      thickness: insulationThickness,
      material: ext.InsulationMaterial.values.firstWhere(
        (e) => e.name == insulationMaterial,
        orElse: () => ext.InsulationMaterial.mineralWool,
      ),
    ),
    hasWaterproofingMembrane: hasWaterproofingMembrane,
    hasVaporBarrier: hasVaporBarrier,
    hasSnowRetention: hasSnowRetention,
    snowRetentionCount: snowRetentionCount,
  );

  RoofState copyWith({
    String? type,
    String? roofingMaterial,
    double? slopeAngle,
    double? area,
    double? insulationThickness,
    bool? hasWaterproofingMembrane,
    bool? hasVaporBarrier,
    bool? hasSnowRetention,
  }) {
    return RoofState(
      id: id,
      type: type ?? this.type,
      area: area ?? this.area,
      slopeAngle: slopeAngle ?? this.slopeAngle,
      roofingMaterial: roofingMaterial ?? this.roofingMaterial,
      rafterSpacing: rafterSpacing,
      rafterSectionWidth: rafterSectionWidth,
      rafterSectionHeight: rafterSectionHeight,
      rafterLength: rafterLength,
      rafterCount: rafterCount,
      rafterMaterial: rafterMaterial,
      insulationThickness: insulationThickness ?? this.insulationThickness,
      insulationMaterial: insulationMaterial,
      hasWaterproofingMembrane:
          hasWaterproofingMembrane ?? this.hasWaterproofingMembrane,
      hasVaporBarrier: hasVaporBarrier ?? this.hasVaporBarrier,
      hasSnowRetention: hasSnowRetention ?? this.hasSnowRetention,
      snowRetentionCount: snowRetentionCount,
    );
  }
}

// ===== CEILING STATE =====
class CeilingState {
  final String id;
  final String type, material;
  final double thickness, area, insulationThickness;
  final bool hasSoundproofing, hasWaterproofing;
  final int floorLevel;
  const CeilingState({
    required this.id,
    this.type = 'monolithic',
    this.material = 'concreteSlab',
    this.thickness = 0.2,
    this.area = 100,
    this.insulationThickness = 0,
    this.hasSoundproofing = false,
    this.hasWaterproofing = false,
    this.floorLevel = 0,
  });
  factory CeilingState.fromCeiling(ext.Ceiling c) => CeilingState(
    id: 'ceiling_${c.floorLevel}',
    type: c.type.name,
    material: c.material.name,
    thickness: c.thickness,
    area: c.area,
    insulationThickness: c.insulationThickness,
    hasSoundproofing: c.hasSoundproofing,
    hasWaterproofing: c.hasWaterproofing,
    floorLevel: c.floorLevel,
  );
  ext.Ceiling toCeiling() => ext.Ceiling(
    type: ext.CeilingType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ext.CeilingType.monolithic,
    ),
    material: ext.CeilingMaterial.values.firstWhere(
      (e) => e.name == material,
      orElse: () => ext.CeilingMaterial.concreteSlab,
    ),
    thickness: thickness,
    area: area,
    insulationThickness: insulationThickness,
    hasSoundproofing: hasSoundproofing,
    hasWaterproofing: hasWaterproofing,
    floorLevel: floorLevel,
  );

  CeilingState copyWith({
    String? type,
    String? material,
    double? thickness,
    double? area,
    bool? hasSoundproofing,
  }) {
    return CeilingState(
      id: id,
      type: type ?? this.type,
      material: material ?? this.material,
      thickness: thickness ?? this.thickness,
      area: area ?? this.area,
      hasSoundproofing: hasSoundproofing ?? this.hasSoundproofing,
      hasWaterproofing: hasWaterproofing,
      floorLevel: floorLevel,
    );
  }
}

// ===== AXIS LINE STATE =====
class AxisLineState {
  final String id, label;
  final double x1, y1, x2, y2;
  const AxisLineState({
    required this.id,
    required this.label,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });
  factory AxisLineState.fromAxis(ext.AxisLine a) => AxisLineState(
    id: 'axis_${a.label}',
    label: a.label,
    x1: a.x1,
    y1: a.y1,
    x2: a.x2,
    y2: a.y2,
  );
  ext.AxisLine toAxis() =>
      ext.AxisLine(label: label, x1: x1, y1: y1, x2: x2, y2: y2);

  AxisLineState copyWith({
    String? label,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
  }) {
    return AxisLineState(
      id: id,
      label: label ?? this.label,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
    );
  }
}

// ===== DIMENSION LINE STATE =====
class DimensionLineState {
  final String id;
  final double x1, y1, x2, y2, offset;
  final String value;
  const DimensionLineState({
    required this.id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.value,
    this.offset = 0.5,
  });
  factory DimensionLineState.fromDimension(ext.DimensionLine d) =>
      DimensionLineState(
        id: 'dim_${d.x1}_${d.y1}',
        x1: d.x1,
        y1: d.y1,
        x2: d.x2,
        y2: d.y2,
        value: d.value,
        offset: d.offset,
      );
  ext.DimensionLine toDimension() => ext.DimensionLine(
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    value: value,
    offset: offset,
  );
}

// ===== LEVEL MARK STATE =====
class LevelMarkState {
  final String id;
  final double x, y, level;
  final String? description;
  const LevelMarkState({
    required this.id,
    required this.x,
    required this.y,
    required this.level,
    this.description,
  });
  factory LevelMarkState.fromLevelMark(ext.LevelMark l) => LevelMarkState(
    id: 'level_${l.x}_${l.y}',
    x: l.x,
    y: l.y,
    level: l.level,
    description: l.description,
  );
  ext.LevelMark toLevelMark() =>
      ext.LevelMark(x: x, y: y, level: level, description: description);
}

// ===== COLUMN STATE =====
class ColumnState {
  final String id;
  final double x, y, width, height;
  final String material;
  const ColumnState({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.material = 'reinforcedConcrete',
  });
  factory ColumnState.fromColumn(ext.Column c) => ColumnState(
    id: 'col_${c.x}_${c.y}',
    x: c.x,
    y: c.y,
    width: c.width,
    height: c.height,
    material: c.material.name,
  );
  ext.Column toColumn() => ext.Column(
    x: x,
    y: y,
    width: width,
    height: height,
    material: ext.ColumnMaterial.values.firstWhere(
      (e) => e.name == material,
      orElse: () => ext.ColumnMaterial.reinforcedConcrete,
    ),
  );
}

// ===== ENGINEERING SYSTEMS STATE =====
class EngineeringSystemsState {
  final HeatingSystemState? heating;
  final WaterSupplyState? waterSupply;
  final SewageState? sewage;
  final VentilationState? ventilation;
  final ElectricalState? electrical;
  final GasSupplyState? gas;
  const EngineeringSystemsState({
    this.heating,
    this.waterSupply,
    this.sewage,
    this.ventilation,
    this.electrical,
    this.gas,
  });
  factory EngineeringSystemsState.fromSystems(ext.EngineeringSystems s) =>
      EngineeringSystemsState(
        heating: s.heating != null
            ? HeatingSystemState.fromHeating(s.heating!)
            : null,
        waterSupply: s.waterSupply != null
            ? WaterSupplyState.fromWaterSupply(s.waterSupply!)
            : null,
        sewage: s.sewage != null ? SewageState.fromSewage(s.sewage!) : null,
        ventilation: s.ventilation != null
            ? VentilationState.fromVentilation(s.ventilation!)
            : null,
        electrical: s.electrical != null
            ? ElectricalState.fromElectrical(s.electrical!)
            : null,
        gas: s.gas != null ? GasSupplyState.fromGas(s.gas!) : null,
      );
  ext.EngineeringSystems toSystems() => ext.EngineeringSystems(
    heating: heating?.toHeating(),
    waterSupply: waterSupply?.toWaterSupply(),
    sewage: sewage?.toSewage(),
    ventilation: ventilation?.toVentilation(),
    electrical: electrical?.toElectrical(),
    gas: gas?.toGas(),
  );
}

class HeatingSystemState {
  final String type;
  final int radiatorCount;
  final double pipeLength, boilerPower;
  final bool hasWarmFloor;
  final double warmFloorArea;
  const HeatingSystemState({
    this.type = 'radiators',
    this.radiatorCount = 0,
    this.pipeLength = 0,
    this.boilerPower = 0,
    this.hasWarmFloor = false,
    this.warmFloorArea = 0,
  });
  factory HeatingSystemState.fromHeating(ext.HeatingSystem h) =>
      HeatingSystemState(
        type: h.type.name,
        radiatorCount: h.radiatorCount,
        pipeLength: h.pipeLength,
        boilerPower: h.boilerPower,
        hasWarmFloor: h.hasWarmFloor,
        warmFloorArea: h.warmFloorArea,
      );
  ext.HeatingSystem toHeating() => ext.HeatingSystem(
    type: ext.HeatingType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ext.HeatingType.radiators,
    ),
    radiatorCount: radiatorCount,
    pipeLength: pipeLength,
    boilerPower: boilerPower,
    hasWarmFloor: hasWarmFloor,
    warmFloorArea: warmFloorArea,
  );
}

class WaterSupplyState {
  final double coldPipeLength, hotPipeLength, waterHeaterVolume;
  final int fixtureCount;
  final bool hasWaterHeater;
  const WaterSupplyState({
    this.coldPipeLength = 0,
    this.hotPipeLength = 0,
    this.fixtureCount = 0,
    this.hasWaterHeater = false,
    this.waterHeaterVolume = 0,
  });
  factory WaterSupplyState.fromWaterSupply(ext.WaterSupplySystem w) =>
      WaterSupplyState(
        coldPipeLength: w.coldPipeLength,
        hotPipeLength: w.hotPipeLength,
        fixtureCount: w.fixtureCount,
        hasWaterHeater: w.hasWaterHeater,
        waterHeaterVolume: w.waterHeaterVolume,
      );
  ext.WaterSupplySystem toWaterSupply() => ext.WaterSupplySystem(
    coldPipeLength: coldPipeLength,
    hotPipeLength: hotPipeLength,
    fixtureCount: fixtureCount,
    hasWaterHeater: hasWaterHeater,
    waterHeaterVolume: waterHeaterVolume,
  );
}

class SewageState {
  final double pipeLength;
  final int fixtureCount;
  final bool hasSeptic;
  final String? septicType;
  const SewageState({
    this.pipeLength = 0,
    this.fixtureCount = 0,
    this.hasSeptic = false,
    this.septicType,
  });
  factory SewageState.fromSewage(ext.SewageSystem s) => SewageState(
    pipeLength: s.pipeLength,
    fixtureCount: s.fixtureCount,
    hasSeptic: s.hasSeptic,
    septicType: s.septicType?.name,
  );
  ext.SewageSystem toSewage() => ext.SewageSystem(
    pipeLength: pipeLength,
    fixtureCount: fixtureCount,
    hasSeptic: hasSeptic,
    septicType: septicType != null
        ? ext.SepticType.values.firstWhere((e) => e.name == septicType)
        : null,
  );
}

class VentilationState {
  final String type;
  final int exhaustPoints, supplyPoints;
  final double ductLength;
  final bool hasRecuperator;
  const VentilationState({
    this.type = 'natural',
    this.exhaustPoints = 0,
    this.supplyPoints = 0,
    this.ductLength = 0,
    this.hasRecuperator = false,
  });
  factory VentilationState.fromVentilation(ext.VentilationSystem v) =>
      VentilationState(
        type: v.type.name,
        exhaustPoints: v.exhaustPoints,
        supplyPoints: v.supplyPoints,
        ductLength: v.ductLength,
        hasRecuperator: v.hasRecuperator,
      );
  ext.VentilationSystem toVentilation() => ext.VentilationSystem(
    type: ext.VentilationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ext.VentilationType.natural,
    ),
    exhaustPoints: exhaustPoints,
    supplyPoints: supplyPoints,
    ductLength: ductLength,
    hasRecuperator: hasRecuperator,
  );
}

class ElectricalState {
  final double cableLength;
  final int socketCount, switchCount, lightPointCount, breakerCount;
  final bool hasRCD, hasGrounding, hasLightningProtection, hasSmartHome;
  const ElectricalState({
    this.cableLength = 0,
    this.socketCount = 0,
    this.switchCount = 0,
    this.lightPointCount = 0,
    this.breakerCount = 0,
    this.hasRCD = false,
    this.hasGrounding = false,
    this.hasLightningProtection = false,
    this.hasSmartHome = false,
  });
  factory ElectricalState.fromElectrical(ext.ElectricalSystem e) =>
      ElectricalState(
        cableLength: e.cableLength,
        socketCount: e.socketCount,
        switchCount: e.switchCount,
        lightPointCount: e.lightPointCount,
        breakerCount: e.breakerCount,
        hasRCD: e.hasRCD,
        hasGrounding: e.hasGrounding,
        hasLightningProtection: e.hasLightningProtection,
        hasSmartHome: e.hasSmartHome,
      );
  ext.ElectricalSystem toElectrical() => ext.ElectricalSystem(
    cableLength: cableLength,
    socketCount: socketCount,
    switchCount: switchCount,
    lightPointCount: lightPointCount,
    breakerCount: breakerCount,
    hasRCD: hasRCD,
    hasGrounding: hasGrounding,
    hasLightningProtection: hasLightningProtection,
    hasSmartHome: hasSmartHome,
  );
}

class GasSupplyState {
  final double pipeLength;
  final int applianceCount;
  final bool hasGasMeter, hasGasBoiler;
  const GasSupplyState({
    this.pipeLength = 0,
    this.applianceCount = 0,
    this.hasGasMeter = false,
    this.hasGasBoiler = false,
  });
  factory GasSupplyState.fromGas(ext.GasSupplySystem g) => GasSupplyState(
    pipeLength: g.pipeLength,
    applianceCount: g.applianceCount,
    hasGasMeter: g.hasGasMeter,
    hasGasBoiler: g.hasGasBoiler,
  );
  ext.GasSupplySystem toGas() => ext.GasSupplySystem(
    pipeLength: pipeLength,
    applianceCount: applianceCount,
    hasGasMeter: hasGasMeter,
    hasGasBoiler: hasGasBoiler,
  );
}

// ===== OUTDOOR ELEMENT STATE =====
class OutdoorElementState {
  final String id, type;
  final double x, y, width, height;
  final String? material;
  final Map<String, dynamic> properties;
  const OutdoorElementState({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.width = 0,
    this.height = 0,
    this.material,
    this.properties = const {},
  });
}

// ===== FLOOR STATE (multistorey) =====
class FloorState {
  final String id, name;
  final double floorHeight, floorLevel;
  final int floorIndex;
  const FloorState({
    required this.id,
    required this.name,
    required this.floorHeight,
    required this.floorLevel,
    required this.floorIndex,
  });
}
