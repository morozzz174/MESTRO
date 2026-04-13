import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../features/floor_plan/models/floor_plan_models_extended.dart'
    hide Column;

/// AI-генератор Floor Plan на основе реальных данных замера
/// Анализирует чек-лист и строит точный план с реальными размерами
class AIFloorPlanGenerator {
  static const _uuid = Uuid();

  /// Генерация Floor Plan из данных замера
  FloorPlan generateFromOrder(Order order) {
    final data = order.checklistData;
    final workType = order.workType.checklistFile;

    // Для строительных типов — специальные генераторы
    switch (workType) {
      case 'foundations':
        return _generateFoundationPlan(data, order);
      case 'house_construction':
        return _generateHouseConstructionPlan(data, order);
      case 'walls_box':
        return _generateWallsBoxPlan(data, order);
      case 'facades':
        return _generateFacadesPlan(data, order);
      case 'roofing':
        return _generateRoofingPlan(data, order);
      case 'metal_structures':
        return _generateMetalStructuresPlan(data, order);
      case 'external_networks':
        return _generateExternalNetworksPlan(data, order);
      default:
        // Стандартные типы — умная генерация из данных
        return _generateSmartPlan(data, order);
    }
  }

  // ===== Фундаменты =====
  FloorPlan _generateFoundationPlan(Map<String, dynamic> data, Order order) {
    final lengthM = _numToMeters(data['foundation_length']) ?? 10;
    final widthM = _numToMeters(data['foundation_width']) ?? 8;
    final depthM = _numToMeters(data['foundation_depth']) ?? 1.2;
    final heightM = _numToMeters(data['foundation_height']) ?? 0.5;

    // Фундамент — прямоугольный контур
    final rooms = <Room>[];

    // Основная плита/лента
    rooms.add(
      Room(
        type: RoomType.hallway,
        x: 0,
        y: 0,
        width: lengthM,
        height: widthM,
        doors: [],
        windows: [],
        hasBalconyAccess: false,
        hasVentilation: data['has_drainage'] == true,
      ),
    );

    // Если подвал — добавляем внутренние помещения
    if (data['has_basement'] == true || depthM > 2) {
      rooms.add(
        Room(
          type: RoomType.storage,
          x: 0,
          y: 0,
          width: lengthM * 0.4,
          height: widthM * 0.5,
          doors: [
            const Door(x: 0.5, y: 0, width: 0.9, type: DoorType.internal),
          ],
          windows: [],
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );
    }

    return FloorPlan(
      rooms: rooms,
      totalWidth: lengthM,
      totalHeight: widthM,
      objectType: FloorPlanType.house,
    );
  }

  // ===== Строительство ИЖС =====
  FloorPlan _generateHouseConstructionPlan(
    Map<String, dynamic> data,
    Order order,
  ) {
    final houseArea = (data['house_area'] as num?)?.toDouble() ?? 100;
    final floorsCount = _parseFloorsCount(data['floors_count']);
    final areaPerFloor = houseArea / floorsCount;

    // Извлекаем размеры здания
    double? buildingWidth, buildingLength;

    // Попытка извлечь из чеклиста
    final w = data['building_width'];
    final l = data['building_length'];
    if (w != null && l != null) {
      buildingWidth = _numToMeters(w);
      buildingLength = _numToMeters(l);
    }

    // Если нет точных размеров — вычисляем из площади
    buildingLength ??= _sqrt(areaPerFloor * 1.3); // чуть больше квадрата
    buildingWidth ??= areaPerFloor / buildingLength!;

    final rooms = <Room>[];
    double currentX = 0;
    double currentY = 0;
    final maxWidth = buildingLength!;

    // Комнаты по типу дома
    final hasGarage = data['has_garage'] == true;
    final hasBasement = data['has_basement'] == true;
    final garageArea = (data['garage_area'] as num?)?.toDouble() ?? 0;
    final windowCount = (data['window_count'] as num?)?.toInt() ?? 4;
    final doorCount = (data['door_count'] as num?)?.toInt() ?? 2;

    // Определяем состав комнат
    final wallMaterial = data['wall_material'] as String?;
    final isFrame = wallMaterial?.contains('Каркас') == true;

    // Главная комната (гостиная)
    final livingArea = areaPerFloor * 0.25;
    rooms.add(
      Room(
        type: RoomType.livingRoom,
        x: currentX,
        y: currentY,
        width: _sqrt(livingArea * 1.3),
        height: livingArea / _sqrt(livingArea * 1.3),
        doors: [const Door(x: 0, y: 1.0, width: 0.9, type: DoorType.internal)],
        windows: [Window(x: 0.5, y: 0, width: 1.5, sillHeight: 0.9)],
        hasBalconyAccess: false,
        hasVentilation: true,
      ),
    );
    currentX += rooms.last.width + 0.15; // стена 15см

    // Кухня
    final kitchenArea = areaPerFloor * 0.15;
    rooms.add(
      Room(
        type: RoomType.kitchen,
        x: currentX,
        y: currentY,
        width: _sqrt(kitchenArea * 1.2),
        height: kitchenArea / _sqrt(kitchenArea * 1.2),
        doors: [const Door(x: 0, y: 0.8, width: 0.8, type: DoorType.internal)],
        windows: [Window(x: 0.3, y: 0, width: 1.2, sillHeight: 0.9)],
        hasBalconyAccess: false,
        hasVentilation: true,
      ),
    );
    currentX += rooms.last.width + 0.15;

    // Спальни
    final bedroomCount = _estimateBedrooms(houseArea, floorsCount);
    for (int i = 0; i < bedroomCount; i++) {
      if (currentX > maxWidth - 2.5) {
        // Новый ряд
        currentX = 0;
        final maxY = rooms.fold<double>(
          0,
          (max, r) => r.y + r.height > max ? r.y + r.height : max,
        );
        currentY = maxY + 0.15;
      }

      final bedArea = areaPerFloor * 0.12;
      final roomType = i == 0 ? RoomType.bedroom : RoomType.childrenRoom;
      rooms.add(
        Room(
          type: roomType,
          x: currentX,
          y: currentY,
          width: _sqrt(bedArea * 1.2),
          height: bedArea / _sqrt(bedArea * 1.2),
          doors: [
            const Door(x: 0, y: 0.8, width: 0.8, type: DoorType.internal),
          ],
          windows: [Window(x: 0.5, y: 0, width: 1.2, sillHeight: 0.9)],
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );
      currentX += rooms.last.width + 0.15;
    }

    // Ванная
    if (currentX > maxWidth - 2) {
      currentX = 0;
      final maxY = rooms.fold<double>(
        0,
        (max, r) => r.y + r.height > max ? r.y + r.height : max,
      );
      currentY = maxY + 0.15;
    }
    rooms.add(
      Room(
        type: RoomType.bathroom,
        x: currentX,
        y: currentY,
        width: 2.5,
        height: 2.0,
        doors: [const Door(x: 0.5, y: 0, width: 0.7, type: DoorType.internal)],
        windows: [const Window(x: 0.3, y: 0, width: 0.4, sillHeight: 1.2)],
        hasBalconyAccess: false,
        hasVentilation: true,
      ),
    );
    currentX += 2.65;

    // Туалет
    rooms.add(
      Room(
        type: RoomType.toilet,
        x: currentX,
        y: currentY,
        width: 1.5,
        height: 1.5,
        doors: [const Door(x: 0.3, y: 0, width: 0.7, type: DoorType.internal)],
        windows: [],
        hasBalconyAccess: false,
        hasVentilation: true,
      ),
    );
    currentX += 1.65;

    // Коридор
    final remainingWidth = maxWidth - currentX;
    if (remainingWidth > 1) {
      final maxY = rooms.fold<double>(
        0,
        (max, r) => r.y + r.height > max ? r.y + r.height : max,
      );
      rooms.add(
        Room(
          type: RoomType.hallway,
          x: currentX,
          y: currentY,
          width: remainingWidth,
          height: maxY,
          doors: [
            const Door(x: 0.5, y: 0, width: 0.9, type: DoorType.entrance),
          ],
          windows: [],
          hasBalconyAccess: false,
          hasVentilation: false,
        ),
      );
    }

    // Гараж
    if (hasGarage && garageArea > 0) {
      final maxY = rooms.fold<double>(
        0,
        (max, r) => r.y + r.height > max ? r.y + r.height : max,
      );
      rooms.add(
        Room(
          type: RoomType.storage,
          x: 0,
          y: maxY + 0.15,
          width: _sqrt(garageArea * 1.5),
          height: garageArea / _sqrt(garageArea * 1.5),
          doors: [
            const Door(x: 1.5, y: 0, width: 2.5, type: DoorType.entrance),
          ],
          windows: [],
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );
    }

    // Добавляем окна по количеству из чеклиста
    _distributeWindows(rooms, windowCount);

    // Общая площадь
    final planWidth = rooms.fold<double>(
      0,
      (max, r) => r.x + r.width > max ? r.x + r.width : max,
    );
    final planHeight = rooms.fold<double>(
      0,
      (max, r) => r.y + r.height > max ? r.y + r.height : max,
    );

    // === ГЕНЕРАЦИЯ КОНСТРУКТИВНЫХ ЭЛЕМЕНТОВ ===
    final walls = <Wall>[];
    // Наружные стены по периметру
    final wallThickness = isFrame ? 0.2 : 0.3;
    final wallHeight = floorsCount == 1 ? 2.7 : 3.0;

    // 4 наружные стены
    walls.addAll([
      Wall(
        x1: 0,
        y1: 0,
        x2: planWidth,
        y2: 0,
        thickness: wallThickness,
        type: WallType.exterior,
        isLoadBearing: true,
        height: wallHeight,
        material: _parseWallMaterial(data['wall_material']),
      ),
      Wall(
        x1: planWidth,
        y1: 0,
        x2: planWidth,
        y2: planHeight,
        thickness: wallThickness,
        type: WallType.exterior,
        isLoadBearing: true,
        height: wallHeight,
        material: _parseWallMaterial(data['wall_material']),
      ),
      Wall(
        x1: planWidth,
        y1: planHeight,
        x2: 0,
        y2: planHeight,
        thickness: wallThickness,
        type: WallType.exterior,
        isLoadBearing: true,
        height: wallHeight,
        material: _parseWallMaterial(data['wall_material']),
      ),
      Wall(
        x1: 0,
        y1: planHeight,
        x2: 0,
        y2: 0,
        thickness: wallThickness,
        type: WallType.exterior,
        isLoadBearing: true,
        height: wallHeight,
        material: _parseWallMaterial(data['wall_material']),
      ),
    ]);

    // Фундамент
    Foundation? foundation;
    if (data['foundation_type'] != null || data['foundation_depth'] != null) {
      final fType = data['foundation_type'] == 'slab'
          ? FoundationType.slab
          : data['foundation_type'] == 'pile'
          ? FoundationType.pile
          : FoundationType.strip;
      final fDepth = _numToMeters(data['foundation_depth']) ?? 1.2;
      foundation = Foundation(
        type: fType,
        width: planWidth + 0.4,
        depth: planHeight + 0.4,
        height: 0.5,
        embedmentDepth: fDepth,
        concreteGrade: 'М300',
        concreteClass: ConcreteClass.B22_5,
        reinforcement: const ReinforcementInfo(
          mainBarDiameter: 12,
          mainBarsCount: 4,
          stirrupDiameter: 8,
          stirrupSpacing: 200,
          rebarClass: 'A500C',
        ),
        hasWaterproofing: data['foundation_waterproofing'] == true,
        hasInsulation: data['foundation_insulation'] == true,
        hasDrainage: data['has_drainage'] == true,
        sandCushionThickness: 0.2,
      );
    }

    // Кровля
    Roof? roof;
    if (data['roof_type'] != null) {
      final rType = data['roof_type'] == 'flat'
          ? RoofType.flat
          : data['roof_type'] == 'mansard'
          ? RoofType.mansard
          : data['roof_type'] == 'hip'
          ? RoofType.hip
          : RoofType.gable;
      final roofArea =
          planWidth * planHeight * (rType == RoofType.flat ? 1.05 : 1.3);
      roof = Roof(
        type: rType,
        area: roofArea,
        slopeAngle: rType == RoofType.flat ? 5 : 30,
        roofingMaterial: _parseRoofMaterial(data['roof_material']),
        rafters: RafterSystem(
          spacing: 600,
          sectionWidth: 50,
          sectionHeight: 200,
          length: planWidth / 2 + 0.5,
          count: (planHeight / 0.6).round(),
          material: RafterMaterial.pine,
        ),
        insulation: RoofInsulation(
          thickness: 0.2,
          material: InsulationMaterial.mineralWool,
        ),
        hasWaterproofingMembrane: true,
        hasVaporBarrier: true,
        hasSnowRetention: data['has_snow_retention'] ?? true,
        snowRetentionCount: (planWidth / 2).round(),
      );
    }

    // Инженерные системы
    final heatingType = data['heating_type'] as String?;
    final engineeringSystems = EngineeringSystems(
      heating: heatingType != null
          ? HeatingSystem(
              type: heatingType.contains('warm')
                  ? HeatingType.warmFloor
                  : HeatingType.radiators,
              radiatorCount: rooms.length,
              pipeLength: planWidth * 2 + planHeight * 2,
              boilerPower: (houseArea * 0.1).round().toDouble(),
              hasWarmFloor: heatingType.contains('warm'),
              warmFloorArea: 20,
            )
          : null,
      waterSupply: data['has_water'] == true
          ? WaterSupplySystem(
              coldPipeLength: planWidth + planHeight,
              hotPipeLength: planWidth + planHeight,
              fixtureCount: 3,
              hasWaterHeater: true,
              waterHeaterVolume: 100,
            )
          : null,
      sewage: data['has_sewage'] == true
          ? SewageSystem(
              pipeLength: planWidth + planHeight,
              fixtureCount: 2,
              hasSeptic: data['has_septic'] == true,
              septicType: SepticType.plastic,
            )
          : null,
      electrical: ElectricalSystem(
        cableLength: planWidth * planHeight * 5,
        socketCount: rooms.length * 3,
        switchCount: rooms.length,
        lightPointCount: rooms.length,
        breakerCount: 12,
        hasRCD: true,
        hasGrounding: true,
        hasLightningProtection: data['has_lightning'] ?? false,
        hasSmartHome: data['has_smart_home'] ?? false,
      ),
      ventilation: VentilationSystem(
        type: VentilationType.natural,
        exhaustPoints: 2,
        supplyPoints: 1,
        ductLength: planWidth + planHeight,
        hasRecuperator: false,
      ),
    );

    return FloorPlan(
      rooms: rooms,
      totalWidth: planWidth,
      totalHeight: planHeight,
      objectType: FloorPlanType.house,
      walls: walls,
      foundation: foundation,
      roof: roof,
      engineeringSystems: engineeringSystems,
      axisLines: [
        AxisLine(label: '1', x1: 0, y1: 0, x2: planWidth, y2: 0),
        AxisLine(
          label: '2',
          x1: 0,
          y1: planHeight / 2,
          x2: planWidth,
          y2: planHeight / 2,
        ),
        AxisLine(label: 'A', x1: 0, y1: 0, x2: 0, y2: planHeight),
        AxisLine(
          label: 'B',
          x1: planWidth / 2,
          y1: 0,
          x2: planWidth / 2,
          y2: planHeight,
        ),
      ],
    );
  }

  // Вспомогательные методы парсинга материалов
  WallMaterial _parseWallMaterial(dynamic material) {
    if (material == null) return WallMaterial.brick;
    final s = material.toString().toLowerCase();
    if (s.contains('газ') || s.contains('пено'))
      return WallMaterial.gasBlockD500;
    if (s.contains('кирпич')) return WallMaterial.brick;
    if (s.contains('бетон')) return WallMaterial.concrete;
    if (s.contains('дерево') || s.contains('брус') || s.contains('бревн'))
      return WallMaterial.timber;
    if (s.contains('керамо')) return WallMaterial.keramoblock;
    if (s.contains('сип')) return WallMaterial.sipPanel;
    return WallMaterial.brick;
  }

  RoofMaterial _parseRoofMaterial(dynamic material) {
    if (material == null) return RoofMaterial.metalTile;
    final s = material.toString().toLowerCase();
    if (s.contains('мягк') || s.contains('гибк')) return RoofMaterial.softRoof;
    if (s.contains('проф')) return RoofMaterial.profNail;
    if (s.contains('фальц')) return RoofMaterial.seam;
    if (s.contains('керам')) return RoofMaterial.ceramicTile;
    if (s.contains('ондул')) return RoofMaterial.ondulin;
    return RoofMaterial.metalTile;
  }

  // ===== Коробка (стены) =====
  FloorPlan _generateWallsBoxPlan(Map<String, dynamic> data, Order order) {
    final perimeter = (data['perimeter'] as num?)?.toDouble() ?? 40;
    final wallHeight = (data['wall_height'] as num?)?.toDouble() ?? 3;

    // Из периметра вычисляем размеры прямоугольника (квадрат)
    final sideLength = perimeter / 4;

    final windowCount = (data['window_count'] as num?)?.toInt() ?? 3;
    final doorCount = (data['door_ext_count'] as num?)?.toInt() ?? 1;
    final hasInternalWalls = data['has_internal_walls'] == true;

    final rooms = <Room>[];

    if (hasInternalWalls) {
      // С внутренними стенами — делим на комнаты
      final intWallLength = _numToMeters(data['internal_wall_length']) ?? 0;

      // Гостиная (большая)
      rooms.add(
        Room(
          type: RoomType.livingRoom,
          x: 0,
          y: 0,
          width: sideLength * 0.6,
          height: sideLength * 0.6,
          doors: [Door(x: 0, y: 1.0, width: 0.9, type: DoorType.entrance)],
          windows: [
            Window(x: sideLength * 0.15, y: 0, width: 1.5, sillHeight: 0.9),
          ],
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );

      // Кухня
      rooms.add(
        Room(
          type: RoomType.kitchen,
          x: sideLength * 0.6 + 0.15,
          y: 0,
          width: sideLength * 0.4 - 0.15,
          height: sideLength * 0.5,
          doors: [
            const Door(x: 0, y: 0.8, width: 0.8, type: DoorType.internal),
          ],
          windows: [const Window(x: 0.5, y: 0, width: 1.2, sillHeight: 0.9)],
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );

      // Спальня
      rooms.add(
        Room(
          type: RoomType.bedroom,
          x: 0,
          y: sideLength * 0.6 + 0.15,
          width: sideLength * 0.5,
          height: sideLength * 0.4 - 0.15,
          doors: [
            const Door(x: 0.5, y: 0, width: 0.8, type: DoorType.internal),
          ],
          windows: [
            Window(x: sideLength * 0.1, y: 0, width: 1.2, sillHeight: 0.9),
          ],
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );

      // Ванная
      rooms.add(
        Room(
          type: RoomType.bathroom,
          x: sideLength * 0.5 + 0.15,
          y: sideLength * 0.5 + 0.15,
          width: sideLength * 0.5 - 0.15,
          height: sideLength * 0.2,
          doors: [
            const Door(x: 0.3, y: 0, width: 0.7, type: DoorType.internal),
          ],
          windows: [const Window(x: 0.3, y: 0, width: 0.4, sillHeight: 1.2)],
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );
    } else {
      // Без внутренних стен — открытое пространство
      rooms.add(
        Room(
          type: RoomType.livingRoom,
          x: 0,
          y: 0,
          width: sideLength,
          height: sideLength,
          doors: List.generate(
            doorCount,
            (i) => Door(
              x: sideLength / (doorCount + 1) * (i + 1),
              y: 0,
              width: 0.9,
              type: i == 0 ? DoorType.entrance : DoorType.internal,
            ),
          ),
          windows: List.generate(
            windowCount,
            (i) => Window(
              x: sideLength / (windowCount + 1) * (i + 1),
              y: 0,
              width: 1.2,
              sillHeight: 0.9,
            ),
          ),
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );
    }

    return FloorPlan(
      rooms: rooms,
      totalWidth: sideLength,
      totalHeight: sideLength,
      objectType: FloorPlanType.house,
    );
  }

  // ===== Фасады =====
  FloorPlan _generateFacadesPlan(Map<String, dynamic> data, Order order) {
    final facadeArea = (data['facade_area'] as num?)?.toDouble() ?? 100;
    final buildingFloors = _parseFloorsCount(data['building_floors']);

    // Площадь фасада ≈ периметр * высота * этажность
    // Обратный расчёт: примерно 1 этаж = 3м высота
    const floorHeight = 3.0;
    final totalHeight = buildingFloors * floorHeight;
    final perimeter = facadeArea / totalHeight;

    // Прямоугольный дом
    final width = perimeter / 4;
    final length = perimeter / 4;

    final rooms = <Room>[
      Room(
        type: RoomType.livingRoom,
        x: 0,
        y: 0,
        width: length,
        height: width,
        doors: [],
        windows: [],
        hasBalconyAccess: false,
        hasVentilation: true,
      ),
    ];

    return FloorPlan(
      rooms: rooms,
      totalWidth: length,
      totalHeight: width,
      objectType: FloorPlanType.house,
    );
  }

  // ===== Кровля =====
  FloorPlan _generateRoofingPlan(Map<String, dynamic> data, Order order) {
    final roofArea = (data['roof_area'] as num?)?.toDouble() ?? 100;
    final buildingWidth = _numToMeters(data['building_width']) ?? 10;
    final buildingLength = _numToMeters(data['building_length']) ?? 12;

    // План кровли = план дома сверху
    final rooms = <Room>[
      Room(
        type: RoomType.livingRoom,
        x: 0,
        y: 0,
        width: buildingLength,
        height: buildingWidth,
        doors: [],
        windows: [],
        hasBalconyAccess: false,
        hasVentilation: data['has_vapor_barrier'] == true,
      ),
    ];

    // Если мансардная кровля — добавляем мансардные комнаты
    final roofType = data['roof_type'] as String?;
    if (roofType?.contains('Мансард') == true) {
      rooms.add(
        Room(
          type: RoomType.bedroom,
          x: buildingLength * 0.3,
          y: buildingWidth * 0.2,
          width: buildingLength * 0.4,
          height: buildingWidth * 0.6,
          doors: [],
          windows: [
            Window(x: buildingLength * 0.5, y: 0, width: 1.0, sillHeight: 0.5),
          ],
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );
    }

    return FloorPlan(
      rooms: rooms,
      totalWidth: buildingLength,
      totalHeight: buildingWidth,
      objectType: FloorPlanType.house,
    );
  }

  // ===== Металлоконструкции =====
  FloorPlan _generateMetalStructuresPlan(
    Map<String, dynamic> data,
    Order order,
  ) {
    final structLength = _numToMeters(data['structure_length']) ?? 10;
    final structWidth = _numToMeters(data['structure_width']) ?? 6;
    final structHeight = _numToMeters(data['structure_height']) ?? 3;

    final structureType = data['structure_type'] as String?;

    final rooms = <Room>[];

    if (structureType?.contains('Каркас') == true) {
      // Каркас здания — сетка колонн
      rooms.add(
        Room(
          type: RoomType.office,
          x: 0,
          y: 0,
          width: structLength,
          height: structWidth,
          doors: [],
          windows: [],
          hasBalconyAccess: false,
          hasVentilation: false,
        ),
      );
    } else if (structureType?.contains('Навес') == true) {
      // Навес — открытая структура
      rooms.add(
        Room(
          type: RoomType.hallway,
          x: 0,
          y: 0,
          width: structLength,
          height: structWidth,
          doors: [],
          windows: [],
          hasBalconyAccess: false,
          hasVentilation: false,
        ),
      );
    } else {
      // Прочее — базовый прямоугольник
      rooms.add(
        Room(
          type: RoomType.storage,
          x: 0,
          y: 0,
          width: structLength,
          height: structWidth,
          doors: [
            const Door(x: 1.5, y: 0, width: 2.0, type: DoorType.entrance),
          ],
          windows: [],
          hasBalconyAccess: false,
          hasVentilation: false,
        ),
      );
    }

    return FloorPlan(
      rooms: rooms,
      totalWidth: structLength,
      totalHeight: structWidth,
      objectType: FloorPlanType.office,
    );
  }

  // ===== Инженерные сети наружные =====
  FloorPlan _generateExternalNetworksPlan(
    Map<String, dynamic> data,
    Order order,
  ) {
    final trenchLength = (data['trench_length'] as num?)?.toDouble() ?? 50;
    final trenchDepth = (data['trench_depth'] as num?)?.toDouble() ?? 1.5;
    final trenchWidth = _numToMeters(data['trench_width']) ?? 0.6;

    // Трасса — линейный объект
    // Визуализируем как горизонтальную полосу
    final displayLength = trenchLength;
    final displayWidth = trenchWidth * 5; // увеличиваем для видимости

    final rooms = <Room>[
      Room(
        type: RoomType.hallway,
        x: 0,
        y: 0,
        width: displayLength,
        height: displayWidth,
        doors: [],
        windows: [],
        hasBalconyAccess: false,
        hasVentilation: false,
      ),
    ];

    // Колодцы
    final hasWells = data['has_wells'] == true;
    final wellsCount = (data['wells_count'] as num?)?.toInt() ?? 0;

    if (hasWells) {
      for (int i = 0; i < wellsCount; i++) {
        final wellX = displayLength / (wellsCount + 1) * (i + 1);
        rooms.add(
          Room(
            type: RoomType.storage,
            x: wellX - 0.5,
            y: displayWidth / 2 - 0.5,
            width: 1.0,
            height: 1.0,
            doors: [],
            windows: [],
            hasBalconyAccess: false,
            hasVentilation: true,
          ),
        );
      }
    }

    return FloorPlan(
      rooms: rooms,
      totalWidth: displayLength,
      totalHeight: displayWidth,
      objectType: FloorPlanType.house,
    );
  }

  // ===== Умная стандартная генерация =====
  FloorPlan _generateSmartPlan(Map<String, dynamic> data, Order order) {
    final widthM = _numToMeters(data['width']) ?? 5;
    final heightM = _numToMeters(data['height']) ?? 4;
    final area = (data['area'] as num?)?.toDouble();
    final roomCount = (data['room_count'] as num?)?.toInt();

    final rooms = <Room>[];

    if (area != null && area > 10) {
      // Если есть площадь — делим на комнаты
      final roomsCount = roomCount ?? _estimateRoomsFromArea(area);
      final roomArea = area / roomsCount;

      double x = 0;
      double y = 0;
      final rowWidth = widthM > 0 ? widthM : _sqrt(area);

      for (int i = 0; i < roomsCount; i++) {
        if (x + _sqrt(roomArea) > rowWidth + 0.5) {
          x = 0;
          final maxY = rooms.fold<double>(
            0,
            (max, r) => r.y + r.height > max ? r.y + r.height : max,
          );
          y = maxY + 0.15;
        }

        rooms.add(
          Room(
            type: _determineRoomType(i, roomsCount),
            x: x,
            y: y,
            width: _sqrt(roomArea * 1.2),
            height: roomArea / _sqrt(roomArea * 1.2),
            doors: [
              Door(
                x: 0.5,
                y: 0,
                width: 0.8,
                type: i == 0 ? DoorType.entrance : DoorType.internal,
              ),
            ],
            windows: [Window(x: 0.5, y: 0, width: 1.2, sillHeight: 0.9)],
            hasBalconyAccess: false,
            hasVentilation: true,
          ),
        );

        x += rooms.last.width + 0.15;
      }
    } else {
      // Базовый план
      rooms.add(
        Room(
          type: RoomType.livingRoom,
          x: 0,
          y: 0,
          width: widthM,
          height: heightM,
          doors: [
            const Door(x: 0.5, y: 0, width: 0.9, type: DoorType.entrance),
          ],
          windows: [Window(x: widthM / 3, y: 0, width: 1.5, sillHeight: 0.9)],
          hasBalconyAccess: false,
          hasVentilation: true,
        ),
      );
    }

    final planWidth = rooms.fold<double>(
      0,
      (max, r) => r.x + r.width > max ? r.x + r.width : max,
    );
    final planHeight = rooms.fold<double>(
      0,
      (max, r) => r.y + r.height > max ? r.y + r.height : max,
    );

    return FloorPlan(
      rooms: rooms,
      totalWidth: planWidth,
      totalHeight: planHeight,
      objectType: FloorPlanType.apartment,
    );
  }

  // ===== Вспомогательные методы =====

  double? _numToMeters(dynamic value) {
    if (value == null) return null;
    final numVal = (value as num).toDouble();
    // Если значение > 100 — вероятно это мм, конвертируем
    if (numVal > 100) return numVal / 1000;
    return numVal;
  }

  int _parseFloorsCount(dynamic value) {
    if (value == null) return 1;
    final str = value.toString();
    if (str.contains('1.5')) return 2;
    if (str.contains('2')) return 2;
    if (str.contains('3')) return 3;
    return 1;
  }

  int _estimateBedrooms(double houseArea, int floors) {
    final areaPerFloor = houseArea / floors;
    if (areaPerFloor > 80) return 3;
    if (areaPerFloor > 50) return 2;
    if (areaPerFloor > 30) return 1;
    return 1;
  }

  int _estimateRoomsFromArea(double area) {
    if (area > 120) return 5;
    if (area > 80) return 4;
    if (area > 50) return 3;
    if (area > 30) return 2;
    return 1;
  }

  RoomType _determineRoomType(int index, int total) {
    if (index == 0) return RoomType.livingRoom;
    if (index == 1) return RoomType.kitchen;
    if (index == total - 1) return RoomType.bathroom;
    return RoomType.bedroom;
  }

  void _distributeWindows(List<Room> rooms, int windowCount) {
    int remaining = windowCount;
    for (int i = 0; i < rooms.length && remaining > 0; i++) {
      final room = rooms[i];
      if (room.type == RoomType.bathroom || room.type == RoomType.toilet) {
        if (room.windows.isEmpty) {
          rooms[i] = room.copyWith(
            windows: [const Window(x: 0.3, y: 0, width: 0.4, sillHeight: 1.2)],
          );
          remaining--;
        }
      } else if (room.type != RoomType.hallway) {
        final newWindows = List<Window>.from(room.windows);
        newWindows.add(
          Window(x: room.width / 2 - 0.6, y: 0, width: 1.2, sillHeight: 0.9),
        );
        rooms[i] = room.copyWith(windows: newWindows);
        remaining--;
      }
    }
  }

  double _sqrt(double value) {
    if (value <= 0) return 1;
    return value < 0.0001
        ? 0.01
        : value < 0.01
        ? 0.1
        : _sqrtInternal(value);
  }

  double _sqrtInternal(double value) {
    if (value < 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }
}
