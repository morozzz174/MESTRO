import '../models/floor_plan_models_extended.dart';
import 'ai_floor_plan_optimizer.dart';
import '../../../models/order.dart';
import '../../../services/app_logger.dart';

/// Генератор планировки на основе правил СНиП
///
/// Генерирует валидный план помещения без использования ИИ.
/// Оптимизация через AIFloorPlanOptimizer (TFLite).
class FloorPlanRuleEngine {
  final AIFloorPlanOptimizer? _aiOptimizer;

  FloorPlanRuleEngine({AIFloorPlanOptimizer? aiOptimizer})
    : _aiOptimizer = aiOptimizer;

  /// Инициализация AI оптимизатора (опционально)
  Future<void> initializeAI() async {
    if (_aiOptimizer != null) {
      await _aiOptimizer.initialize();
      AppLogger.info('FloorPlan', 'AI оптимизатор инициализирован');
    }
  }

  /// Дефолтные размеры комнат (м)
  static const Map<RoomType, _RoomDefaults> _defaultSizes = {
    RoomType.livingRoom: _RoomDefaults(width: 5.0, height: 3.5),
    RoomType.kitchen: _RoomDefaults(width: 3.5, height: 2.8),
    RoomType.bedroom: _RoomDefaults(width: 4.0, height: 3.2),
    RoomType.childrenRoom: _RoomDefaults(width: 3.5, height: 3.2),
    RoomType.bathroom: _RoomDefaults(width: 2.0, height: 1.8),
    RoomType.toilet: _RoomDefaults(width: 1.2, height: 1.5),
    RoomType.hallway: _RoomDefaults(width: 2.5, height: 2.0),
    RoomType.balcony: _RoomDefaults(width: 3.0, height: 1.2),
    RoomType.storage: _RoomDefaults(width: 1.5, height: 1.5),
    RoomType.office: _RoomDefaults(width: 3.0, height: 3.0),
  };

  /// Рекомендуемые комнаты для типа объекта
  static const Map<FloorPlanType, List<RoomType>> _recommendedRooms = {
    FloorPlanType.apartment: [
      RoomType.livingRoom,
      RoomType.kitchen,
      RoomType.bedroom,
      RoomType.bathroom,
      RoomType.hallway,
    ],
    FloorPlanType.house: [
      RoomType.livingRoom,
      RoomType.kitchen,
      RoomType.bedroom,
      RoomType.bedroom,
      RoomType.bathroom,
      RoomType.toilet,
      RoomType.hallway,
      RoomType.storage,
    ],
    FloorPlanType.office: [
      RoomType.office,
      RoomType.office,
      RoomType.hallway,
      RoomType.bathroom,
    ],
    FloorPlanType.studio: [
      RoomType.livingRoom,
      RoomType.kitchen,
      RoomType.bathroom,
    ],
  };

  /// Генерирует план по размерам из чек-листа
  FloorPlan generateFromMeasurements({
    required double widthMm,
    required double heightMm,
    FloorPlanType objectType = FloorPlanType.apartment,
    List<RoomType>? customRooms,
  }) {
    final widthM = widthMm / 1000; // мм → м
    final heightM = heightMm / 1000;
    final totalArea = widthM * heightM;

    AppLogger.info(
      'FloorPlan',
      'Генерация плана: ${widthM}x${heightM}м (${totalArea.toStringAsFixed(1)}м²), тип: ${objectType.label}',
    );

    final roomTypes =
        customRooms ??
        _recommendedRooms[objectType] ??
        _recommendedRooms[FloorPlanType.apartment]!;

    // Масштабируем комнаты под общую площадь
    final scaleFactor = _calculateScaleFactor(roomTypes, totalArea);

    final rooms = <Room>[];
    var currentX = 0.0;
    var currentY = 0.0;
    var rowMaxHeight = 0.0;

    for (int i = 0; i < roomTypes.length; i++) {
      final roomType = roomTypes[i];
      final defaults = _defaultSizes[roomType]!;

      // Применяем масштабирование
      final roomWidth = defaults.width * scaleFactor;
      final roomHeight = defaults.height * scaleFactor;

      // Проверяем, помещается ли комната в текущий ряд
      if (currentX + roomWidth > widthM) {
        // Переходим на следующий ряд
        currentX = 0.0;
        currentY += rowMaxHeight;
        rowMaxHeight = 0.0;
      }

      // Проверяем, помещается ли комната по высоте
      if (currentY + roomHeight > heightM) {
        AppLogger.warn(
          'FloorPlan',
          'Комната ${roomType.label} не помещается, уменьшаем',
        );
        final remainingHeight = heightM - currentY;
        if (remainingHeight < roomType.minArea / roomWidth) {
          AppLogger.warn(
            'FloorPlan',
            '⚠️ ${roomType.label}: площадь ниже СНиП',
          );
        }
      }

      // Размещаем двери и окна
      final doors = _placeDoors(roomType, i, roomTypes.length);
      final windows = _placeWindows(roomType, roomWidth, roomHeight);

      rooms.add(
        Room(
          type: roomType,
          x: currentX,
          y: currentY,
          width: roomWidth,
          height: roomHeight,
          doors: doors,
          windows: windows,
          hasVentilation:
              roomType == RoomType.kitchen || roomType == RoomType.bathroom,
        ),
      );

      // Обновляем позицию
      currentX += roomWidth;
      if (roomHeight > rowMaxHeight) {
        rowMaxHeight = roomHeight;
      }
    }

    final plan = FloorPlan(
      rooms: rooms,
      totalWidth: widthM,
      totalHeight: heightM,
      objectType: objectType,
      // === ГЕНЕРАЦИЯ КОНСТРУКТИВНЫХ ЭЛЕМЕНТОВ ===
      walls: _generateWalls(rooms, widthM, heightM),
      foundation: _generateFoundation(widthM, heightM),
      roof: _generateRoof(widthM, heightM),
      engineeringSystems: _generateEngineeringSystems(rooms, widthM, heightM),
      axisLines: _generateAxisLines(widthM, heightM),
      columns: _generateColumns(widthM, heightM),
      levelMarks: _generateLevelMarks(),
      dimensionLines: _generateDimensionLines(widthM, heightM),
    );

    AppLogger.info(
      'FloorPlan',
      'План сгенерирован: ${rooms.length} комнат, compliance: ${plan.complianceScore.toStringAsFixed(2)}',
    );

    return plan;
  }

  /// Генерирует план с произвольным набором комнат
  FloorPlan generateCustom({
    required double totalWidth,
    required double totalHeight,
    required List<RoomType> roomTypes,
  }) {
    return generateFromMeasurements(
      widthMm: totalWidth * 1000,
      heightMm: totalHeight * 1000,
      customRooms: roomTypes,
    );
  }

  /// Расчёт коэффициента масштабирования
  double _calculateScaleFactor(List<RoomType> roomTypes, double totalArea) {
    // Считаем суммарную площадь дефолтных комнат
    double defaultTotalArea = 0;
    for (final type in roomTypes) {
      final defaults = _defaultSizes[type]!;
      defaultTotalArea += defaults.width * defaults.height;
    }

    if (defaultTotalArea == 0) return 1.0;

    // Коэффициент: корень из отношения площадей (для сохранения пропорций)
    final ratio = totalArea / defaultTotalArea;
    return ratio > 0 ? ratio.clamp(0.5, 2.0) : 1.0;
  }

  /// Размещение дверей
  List<Door> _placeDoors(RoomType type, int index, int totalRooms) {
    final doors = <Door>[];

    // Входная дверь для первой комнаты (коридор/прихожая)
    if (index == 0 && type == RoomType.hallway) {
      doors.add(const Door(x: 0, y: 1.0, width: 0.9, type: DoorType.entrance));
    }

    // Межкомнатные двери
    if (index > 0 && type != RoomType.balcony) {
      doors.add(
        Door(
          x: 0,
          y: type == RoomType.bathroom ? 0.8 : 1.0,
          width: type == RoomType.bathroom ? 0.7 : 0.8,
          type: DoorType.internal,
        ),
      );
    }

    // Дверь на балкон
    if (type == RoomType.balcony) {
      doors.add(const Door(x: 0, y: 0.6, width: 0.7, type: DoorType.balcony));
    }

    return doors;
  }

  /// Размещение окон
  List<Window> _placeWindows(
    RoomType type,
    double roomWidth,
    double roomHeight,
  ) {
    final windows = <Window>[];

    // Не размещаем окна в санузлах (или маленькие)
    if (type == RoomType.bathroom || type == RoomType.toilet) {
      // Маленькое окно/форточка
      windows.add(const Window(x: 0.5, y: 0, width: 0.4, sillHeight: 1.2));
      return windows;
    }

    // Обычные окна для жилых комнат
    if (type == RoomType.kitchen ||
        type == RoomType.livingRoom ||
        type == RoomType.bedroom ||
        type == RoomType.office ||
        type == RoomType.childrenRoom) {
      // Окно на верхней стене (y = 0)
      final windowWidth = roomWidth > 4 ? 1.5 : 1.2;
      final windowX = (roomWidth - windowWidth) / 2;

      windows.add(
        Window(x: windowX, y: 0, width: windowWidth, sillHeight: 0.9),
      );

      // Второе окно для больших комнат
      if (roomWidth > 5) {
        windows.add(
          Window(
            x: roomWidth - windowWidth - 0.5,
            y: 0,
            width: windowWidth,
            sillHeight: 0.9,
          ),
        );
      }
    }

    // Балконное остекление
    if (type == RoomType.balcony) {
      windows.add(
        Window(
          x: 0,
          y: 0,
          width: roomWidth,
          sillHeight: 0,
          type: WindowType.french,
        ),
      );
    }

    return windows;
  }

  /// Оптимизировать план
  FloorPlan optimize(FloorPlan plan) {
    if (_aiOptimizer != null && _aiOptimizer.isAvailable) {
      AppLogger.info('FloorPlan', 'Запуск AI оптимизации...');
      final optimized = _aiOptimizer.optimize(plan);
      AppLogger.info(
        'FloorPlan',
        'AI оптимизация завершена, compliance: ${optimized.complianceScore.toStringAsFixed(2)}',
      );
      return optimized;
    }

    AppLogger.info(
      'FloorPlan',
      'Оптимизация: используется Rule Engine (AI недоступен)',
    );
    return plan;
  }

  /// Генерация плана помещения из данных заявки (статический метод для PDF)
  static FloorPlan generateFromOrder(Order order) {
    final cd = order.checklistData;

    // Извлекаем размеры (в мм, конвертируем в метры)
    final widthMm = (cd['width'] as num?)?.toDouble();
    final heightMm = (cd['height'] as num?)?.toDouble();
    final floorLengthMm = (cd['floor_length'] as num?)?.toDouble();
    final floorWidthMm = (cd['floor_width'] as num?)?.toDouble();

    final planWidth = (widthMm ?? floorLengthMm ?? 5000) / 1000;
    final planHeight = (heightMm ?? floorWidthMm ?? 4000) / 1000;

    // Определяем тип помещения по workType
    FloorPlanType type = FloorPlanType.apartment;
    switch (order.workType) {
      case WorkType.windows:
      case WorkType.doors:
      case WorkType.tiles:
        type = FloorPlanType.apartment;
        break;
      case WorkType.kitchens:
        type = FloorPlanType.studio;
        break;
      // Строительство ИЖС → тип дома
      case WorkType.foundations:
      case WorkType.houseConstruction:
      case WorkType.wallsBox:
      case WorkType.facades:
      case WorkType.roofing:
      case WorkType.metalStructures:
      case WorkType.externalNetworks:
        type = FloorPlanType.house;
        break;
      default:
        type = FloorPlanType.apartment;
    }

    // Определяем рекомендуемые комнаты
    final roomTypes = _recommendedRooms[type] ?? [RoomType.livingRoom];

    // Создаём комнаты
    final rooms = <Room>[];
    for (final roomType in roomTypes) {
      final defaults =
          _defaultSizes[roomType] ?? const _RoomDefaults(width: 3, height: 3);
      final room = Room(
        type: roomType,
        x: 0,
        y: rooms.length * defaults.height,
        width: defaults.width,
        height: defaults.height,
      );
      rooms.add(room);
    }

    return FloorPlan(
      rooms: rooms,
      totalWidth: planWidth,
      totalHeight: planHeight,
      objectType: type,
    );
  }
}

class _RoomDefaults {
  final double width;
  final double height;
  const _RoomDefaults({required this.width, required this.height});
}

// ===== МЕТОДЫ ГЕНЕРАЦИИ КОНСТРУКТИВНЫХ ЭЛЕМЕНТОВ =====

extension _ConstructionGenerator on FloorPlanRuleEngine {
  /// Генерация наружных стен по периметру + внутренние перегородки
  List<Wall> _generateWalls(List<Room> rooms, double widthM, double heightM) {
    const wallThickness = 0.2; // 20 см наружные
    const partitionThickness = 0.12; // 12 см внутренние
    const wallHeight = 2.7;

    final walls = <Wall>[
      // Наружные стены по периметру
      Wall(
        x1: 0,
        y1: 0,
        x2: widthM,
        y2: 0,
        thickness: wallThickness,
        type: WallType.exterior,
        isLoadBearing: true,
        height: wallHeight,
        material: WallMaterial.brick,
      ),
      Wall(
        x1: widthM,
        y1: 0,
        x2: widthM,
        y2: heightM,
        thickness: wallThickness,
        type: WallType.exterior,
        isLoadBearing: true,
        height: wallHeight,
        material: WallMaterial.brick,
      ),
      Wall(
        x1: widthM,
        y1: heightM,
        x2: 0,
        y2: heightM,
        thickness: wallThickness,
        type: WallType.exterior,
        isLoadBearing: true,
        height: wallHeight,
        material: WallMaterial.brick,
      ),
      Wall(
        x1: 0,
        y1: heightM,
        x2: 0,
        y2: 0,
        thickness: wallThickness,
        type: WallType.exterior,
        isLoadBearing: true,
        height: wallHeight,
        material: WallMaterial.brick,
      ),
    ];

    // Внутренние перегородки между комнатами
    double currentX = 0;
    for (int i = 0; i < rooms.length - 1; i++) {
      currentX += rooms[i].width;
      walls.add(
        Wall(
          x1: currentX,
          y1: 0,
          x2: currentX,
          y2: heightM,
          thickness: partitionThickness,
          type: WallType.partition,
          isLoadBearing: false,
          height: wallHeight,
          material: WallMaterial.gypsumBoard,
        ),
      );
    }

    return walls;
  }

  /// Генерация фундамента (ленточный по умолчанию)
  Foundation _generateFoundation(double widthM, double heightM) {
    return Foundation(
      type: FoundationType.strip,
      width: widthM + 0.4,
      depth: heightM + 0.4,
      height: 0.5,
      embedmentDepth: 1.2,
      concreteGrade: 'М300',
      concreteClass: ConcreteClass.B22_5,
      reinforcement: const ReinforcementInfo(
        mainBarDiameter: 12,
        mainBarsCount: 4,
        stirrupDiameter: 8,
        stirrupSpacing: 200,
        rebarClass: 'A500C',
      ),
      hasWaterproofing: true,
      hasInsulation: false,
      hasDrainage: false,
      sandCushionThickness: 0.2,
    );
  }

  /// Генерация кровли (двускатная по умолчанию)
  Roof _generateRoof(double widthM, double heightM) {
    final roofArea = widthM * heightM * 1.3; // с учётом уклона

    return Roof(
      type: RoofType.gable,
      area: roofArea,
      slopeAngle: 30,
      roofingMaterial: RoofMaterial.metalTile,
      rafters: RafterSystem(
        spacing: 600,
        sectionWidth: 50,
        sectionHeight: 200,
        length: widthM / 2 + 0.5,
        count: (heightM / 0.6).round(),
        material: RafterMaterial.pine,
      ),
      insulation: const RoofInsulation(
        thickness: 0.2,
        material: InsulationMaterial.mineralWool,
      ),
      hasWaterproofingMembrane: true,
      hasVaporBarrier: true,
      hasSnowRetention: true,
      snowRetentionCount: (widthM / 2).round(),
    );
  }

  /// Генерация инженерных систем
  EngineeringSystems _generateEngineeringSystems(
    List<Room> rooms,
    double widthM,
    double heightM,
  ) {
    return EngineeringSystems(
      heating: HeatingSystem(
        type: HeatingType.radiators,
        radiatorCount: rooms.length,
        pipeLength: widthM * 2 + heightM * 2,
        boilerPower: (widthM * heightM * 0.1).round().toDouble(),
        hasWarmFloor: false,
        warmFloorArea: 0,
      ),
      waterSupply: WaterSupplySystem(
        coldPipeLength: widthM + heightM,
        hotPipeLength: widthM + heightM,
        fixtureCount:
            rooms
                .where(
                  (r) =>
                      r.type == RoomType.bathroom || r.type == RoomType.kitchen,
                )
                .length *
            2,
        hasWaterHeater: true,
        waterHeaterVolume: 100,
      ),
      sewage: SewageSystem(
        pipeLength: widthM + heightM,
        fixtureCount:
            rooms
                .where(
                  (r) =>
                      r.type == RoomType.bathroom || r.type == RoomType.toilet,
                )
                .length *
            2,
        hasSeptic: false,
      ),
      electrical: ElectricalSystem(
        cableLength: widthM * heightM * 5,
        socketCount: rooms.length * 3,
        switchCount: rooms.length,
        lightPointCount: rooms.length,
        breakerCount: 12,
        hasRCD: true,
        hasGrounding: true,
        hasLightningProtection: false,
        hasSmartHome: false,
      ),
      ventilation: VentilationSystem(
        type: VentilationType.natural,
        exhaustPoints: 2,
        supplyPoints: 1,
        ductLength: widthM + heightM,
        hasRecuperator: false,
      ),
    );
  }

  /// Генерация осевых линий
  List<AxisLine> _generateAxisLines(double widthM, double heightM) {
    return [
      AxisLine(label: '1', x1: 0, y1: 0, x2: widthM, y2: 0),
      AxisLine(label: '2', x1: 0, y1: heightM / 2, x2: widthM, y2: heightM / 2),
      AxisLine(label: 'A', x1: 0, y1: 0, x2: 0, y2: heightM),
      AxisLine(label: 'B', x1: widthM / 2, y1: 0, x2: widthM / 2, y2: heightM),
    ];
  }

  /// Генерация колонн (по углам и пересечениям стен)
  List<Column> _generateColumns(double widthM, double heightM) {
    return [
      // Угловые колонны
      Column(x: 0, y: 0, width: 0.3, height: 0.3),
      Column(x: widthM, y: 0, width: 0.3, height: 0.3),
      Column(x: widthM, y: heightM, width: 0.3, height: 0.3),
      Column(x: 0, y: heightM, width: 0.3, height: 0.3),
      // Центральная колонна (если площадь > 50 м²)
      if (widthM * heightM > 50)
        Column(x: widthM / 2, y: heightM / 2, width: 0.3, height: 0.3),
    ];
  }

  /// Генерация отметок уровней
  List<LevelMark> _generateLevelMarks() {
    return [
      const LevelMark(x: 0, y: 0, level: 0.0, description: 'Пол 1 этажа'),
      const LevelMark(x: 0, y: 0, level: 2.7, description: 'Потолок'),
      const LevelMark(
        x: 0,
        y: 0,
        level: -1.2,
        description: 'Подошва фундамента',
      ),
    ];
  }

  /// Генерация размерных линий
  List<DimensionLine> _generateDimensionLines(double widthM, double heightM) {
    return [
      // Общий габарит по ширине
      DimensionLine(
        x1: 0,
        y1: -0.5,
        x2: widthM,
        y2: -0.5,
        value: widthM.toStringAsFixed(2),
        offset: 0.5,
      ),
      // Общий габарит по высоте
      DimensionLine(
        x1: -0.5,
        y1: 0,
        x2: -0.5,
        y2: heightM,
        value: heightM.toStringAsFixed(2),
        offset: 0.5,
      ),
      // Оси
      DimensionLine(
        x1: 0,
        y1: heightM + 0.5,
        x2: widthM,
        y2: heightM + 0.5,
        value: widthM.toStringAsFixed(2),
        offset: 0.5,
      ),
    ];
  }
}
