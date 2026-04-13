import 'package:equatable/equatable.dart';
import 'dart:math' as math;

// ============================================================================
// ТИПЫ ПОМЕЩЕНИЙ (расширенный)
// ============================================================================

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
  childrenRoom('Детская', minArea: 12.0, icon: '🧸'),
  garage('Гараж', minArea: 18.0, icon: '🚗'),
  boilerRoom('Котельная', minArea: 6.0, icon: '🔥'),
  terrace('Терраса', minArea: 0, icon: '🏡'),
  attic('Мансарда', minArea: 12.0, icon: '🏠'),
  basement('Подвал', minArea: 0, icon: '🏚️'),
  wardrobe('Гардеробная', minArea: 3.0, icon: '👔'),
  laundry('Прачечная', minArea: 4.0, icon: '🧺'),
  pantry('Кладовая пищевая', minArea: 2.0, icon: '🍎'),
  workshop('Мастерская', minArea: 10.0, icon: '🔧'),
  sauna('Сауна/Баня', minArea: 4.0, icon: '♨️'),
  pool('Бассейн', minArea: 15.0, icon: '🏊'),
  gym('Спортзал', minArea: 12.0, icon: '💪'),
  cinema('Домашний кинотеатр', minArea: 15.0, icon: '🎬'),
  elevator('Лифт', minArea: 0, icon: '🛗');

  final String label;
  final double minArea;
  final String icon;

  const RoomType(this.label, {required this.minArea, required this.icon});

  bool get isLiving =>
      [bedroom, livingRoom, childrenRoom, office, kitchen].contains(this);

  bool get isService => [
    bathroom,
    toilet,
    laundry,
    boilerRoom,
    sauna,
    pool,
    pantry,
    wardrobe,
    elevator,
  ].contains(this);

  bool get isTechnical =>
      [boilerRoom, sauna, pool, workshop, cinema, gym].contains(this);
}

// ============================================================================
// СТЕНЫ (новое)
// ============================================================================

/// Стена
class Wall extends Equatable {
  /// Начальная точка (метры от начала плана)
  final double x1, y1;

  /// Конечная точка (метры)
  final double x2, y2;

  /// Толщина стены (метры)
  final double thickness;

  /// Тип стены
  final WallType type;

  /// Материал стены
  final WallMaterial material;

  /// Высота стены (метры, по умолчанию 2.7)
  final double height;

  /// Несущая ли стена
  final bool isLoadBearing;

  /// Утеплитель (метры)
  final double insulationThickness;

  /// Отделка (внутренняя)
  final FinishingType interiorFinishing;

  /// Отделка (наружная)
  final FinishingType exteriorFinishing;

  const Wall({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.thickness = 0.2,
    this.type = WallType.interior,
    this.material = WallMaterial.brick,
    this.height = 2.7,
    this.isLoadBearing = false,
    this.insulationThickness = 0,
    this.interiorFinishing = FinishingType.plaster,
    this.exteriorFinishing = FinishingType.none,
  });

  double get length => math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));

  double get area => length * height;

  double get volume => area * thickness;

  /// Площадь утеплителя
  double get insulationArea => insulationThickness > 0 ? length * height : 0;

  Wall copyWith({
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    double? thickness,
    WallType? type,
    WallMaterial? material,
    double? height,
    bool? isLoadBearing,
    double? insulationThickness,
    FinishingType? interiorFinishing,
    FinishingType? exteriorFinishing,
  }) {
    return Wall(
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
      interiorFinishing: interiorFinishing ?? this.interiorFinishing,
      exteriorFinishing: exteriorFinishing ?? this.exteriorFinishing,
    );
  }

  @override
  List<Object?> get props => [
    x1,
    y1,
    x2,
    y2,
    thickness,
    type,
    material,
    height,
    isLoadBearing,
    insulationThickness,
  ];
}

enum WallType {
  exterior('Наружная'),
  interior('Внутренняя'),
  partition('Перегородка'),
  foundation('Фундаментная'),
  retaining('Подпорная');

  final String label;
  const WallType(this.label);
}

enum WallMaterial {
  brick('Кирпич керамический', density: 1800),
  brickSilicate('Кирпич силикатный', density: 1900),
  gasBlockD400('Газобетон D400', density: 400),
  gasBlockD500('Газобетон D500', density: 500),
  gasBlockD600('Газобетон D600', density: 600),
  foamBlock('Пеноблок', density: 600),
  keramoblock('Керамоблок', density: 800),
  concrete('Железобетон', density: 2500),
  timber('Брус деревянный', density: 500),
  log('Бревно', density: 550),
  sipPanel('СИП-панель', density: 300),
  metalSandwich('Металлический сэндвич', density: 200),
  gypsumBoard('Гипсокартон', density: 800),
  aeratedConcrete('Легкий бетон', density: 1200);

  final String label;
  final double density; // кг/м³
  const WallMaterial(this.label, {required this.density});

  double get thermalConductivity {
    switch (this) {
      case brick:
      case brickSilicate:
        return 0.7;
      case gasBlockD400:
        return 0.12;
      case gasBlockD500:
        return 0.14;
      case gasBlockD600:
        return 0.18;
      case foamBlock:
        return 0.15;
      case keramoblock:
        return 0.2;
      case concrete:
        return 1.7;
      case timber:
      case log:
        return 0.15;
      case sipPanel:
        return 0.04;
      case metalSandwich:
        return 0.04;
      case gypsumBoard:
        return 0.25;
      case aeratedConcrete:
        return 0.35;
    }
  }

  double calcRValue(double thickness) => thickness / thermalConductivity;
}

enum FinishingType {
  none('Нет'),
  plaster('Штукатурка'),
  paint('Краска'),
  wallpaper('Обои'),
  tile('Плитка'),
  decorativePlaster('Декоративная штукатурка'),
  panel('Панели'),
  siding('Сайдинг'),
  clinker('Клинкер'),
  stone('Камень'),
  wood('Дерево'),
  facadePaint('Фасадная краска');

  final String label;
  const FinishingType(this.label);
}

// ============================================================================
// ПЕРЕКРЫТИЯ (новое)
// ============================================================================

class Ceiling extends Equatable {
  final CeilingType type;
  final CeilingMaterial material;

  /// Толщина перекрытия (метры)
  final double thickness;

  /// Площадь (м²)
  final double area;

  /// Утеплитель (метры)
  final double insulationThickness;

  /// Звукоизоляция
  final bool hasSoundproofing;

  /// Гидроизоляция
  final bool hasWaterproofing;

  /// Этаж (0 = первый, -1 = подвал, и т.д.)
  final int floorLevel;

  const Ceiling({
    required this.type,
    required this.material,
    required this.thickness,
    required this.area,
    this.insulationThickness = 0,
    this.hasSoundproofing = false,
    this.hasWaterproofing = false,
    this.floorLevel = 0,
  });

  double get volume => area * thickness;

  double get weight => volume * material.density;

  @override
  List<Object?> get props => [
    type,
    material,
    thickness,
    area,
    insulationThickness,
    hasSoundproofing,
    hasWaterproofing,
    floorLevel,
  ];
}

enum CeilingType {
  monolithic('Монолитное'),
  precast('Сборное (плиты)'),
  wooden('Деревянное'),
  metal('Металлическое'),
  composite('Композитное');

  final String label;
  const CeilingType(this.label);
}

enum CeilingMaterial {
  concreteSlab('Ж/Б плита', density: 2500),
  hollowCore('Пустотная плита', density: 2200),
  timberBeams('Деревянные балки', density: 500),
  steelBeams('Стальные балки', density: 7850),
  sandwichPanel('Сэндвич-панель', density: 200);

  final String label;
  final double density;
  const CeilingMaterial(this.label, {required this.density});
}

// ============================================================================
// ФУНДАМЕНТ (новое)
// ============================================================================

class Foundation extends Equatable {
  final FoundationType type;
  final double width;
  final double depth;
  final double height;

  /// Глубина заложения (от уровня земли)
  final double embedmentDepth;

  /// Марка бетона
  final String concreteGrade;

  /// Класс бетона
  final ConcreteClass concreteClass;

  /// Арматура
  final ReinforcementInfo reinforcement;

  /// Гидроизоляция
  final bool hasWaterproofing;

  /// Утепление фундамента
  final bool hasInsulation;

  /// Дренаж
  final bool hasDrainage;

  /// Песчаная подушка (метры)
  final double sandCushionThickness;

  const Foundation({
    required this.type,
    required this.width,
    required this.depth,
    required this.height,
    this.embedmentDepth = 1.2,
    this.concreteGrade = 'М300',
    this.concreteClass = ConcreteClass.B22_5,
    required this.reinforcement,
    this.hasWaterproofing = false,
    this.hasInsulation = false,
    this.hasDrainage = false,
    this.sandCushionThickness = 0.2,
  });

  double get volume => width * depth * height;

  double get concreteVolume => volume * 0.92; // ~8% арматура

  double get waterproofingArea => width * depth;

  @override
  List<Object?> get props => [
    type,
    width,
    depth,
    height,
    embedmentDepth,
    concreteGrade,
    concreteClass,
    reinforcement,
    hasWaterproofing,
    hasInsulation,
    hasDrainage,
    sandCushionThickness,
  ];
}

enum FoundationType {
  strip('Ленточный'),
  slab('Плитный'),
  pile('Свайный'),
  column('Столбчатый'),
  screw('Винтовые сваи');

  final String label;
  const FoundationType(this.label);
}

enum ConcreteClass {
  B7_5('B7.5 (М100)'),
  B12_5('B12.5 (М150)'),
  B15('B15 (М200)'),
  B20('B20 (М250)'),
  B22_5('B22.5 (М300)'),
  B25('B25 (М350)'),
  B30('B30 (М400)');

  final String label;
  const ConcreteClass(this.label);

  double get compressiveStrength {
    switch (this) {
      case B7_5:
        return 7.5;
      case B12_5:
        return 12.5;
      case B15:
        return 15;
      case B20:
        return 20;
      case B22_5:
        return 22.5;
      case B25:
        return 25;
      case B30:
        return 30;
    }
  }
}

class ReinforcementInfo extends Equatable {
  /// Диаметр основных стержней (мм)
  final int mainBarDiameter;

  /// Количество стержней
  final int mainBarsCount;

  /// Диаметр хомутов (мм)
  final int stirrupDiameter;

  /// Шаг хомутов (мм)
  final int stirrupSpacing;

  /// Класс арматуры
  final String rebarClass;

  const ReinforcementInfo({
    this.mainBarDiameter = 12,
    this.mainBarsCount = 4,
    this.stirrupDiameter = 8,
    this.stirrupSpacing = 200,
    this.rebarClass = 'A500C',
  });

  double get rebarWeightPerMeter {
    // Приблизительный вес арматуры кг/м
    const weightByDiameter = {
      8: 0.395,
      10: 0.617,
      12: 0.888,
      14: 1.210,
      16: 1.580,
      18: 2.000,
      20: 2.470,
      25: 3.850,
    };
    return (weightByDiameter[mainBarDiameter] ?? 0.888) * mainBarsCount;
  }

  @override
  List<Object?> get props => [
    mainBarDiameter,
    mainBarsCount,
    stirrupDiameter,
    stirrupSpacing,
    rebarClass,
  ];
}

// ============================================================================
// КРОВЛЯ (новое)
// ============================================================================

class Roof extends Equatable {
  final RoofType type;
  final double area;

  /// Угол наклона ската (градусы)
  final double slopeAngle;

  /// Материал кровли
  final RoofMaterial roofingMaterial;

  /// Стропильная система
  final RafterSystem rafters;

  /// Утепление
  final RoofInsulation insulation;

  /// Гидроизоляция
  final bool hasWaterproofingMembrane;

  /// Пароизоляция
  final bool hasVaporBarrier;

  /// Водосток
  final GutterSystem? gutter;

  /// Снегозадержатели
  final bool hasSnowRetention;

  /// Количество снегозадержателей
  final int snowRetentionCount;

  const Roof({
    required this.type,
    required this.area,
    this.slopeAngle = 30,
    this.roofingMaterial = RoofMaterial.metalTile,
    required this.rafters,
    this.insulation = const RoofInsulation.none(),
    this.hasWaterproofingMembrane = false,
    this.hasVaporBarrier = false,
    this.gutter,
    this.hasSnowRetention = false,
    this.snowRetentionCount = 0,
  });

  /// Площадь стропил (погонные метры)
  double get rafterLinearMeters => rafters.count * rafters.length;

  /// Вес кровли (кг)
  double get weight =>
      area * roofingMaterial.weightPerM2 +
      rafterLinearMeters * rafters.weightPerMeter;

  @override
  List<Object?> get props => [
    type,
    area,
    slopeAngle,
    roofingMaterial,
    rafters,
    insulation,
    hasWaterproofingMembrane,
    hasVaporBarrier,
    gutter,
    hasSnowRetention,
    snowRetentionCount,
  ];
}

enum RoofType {
  gable('Двускатная'),
  hip('Четырёхскатная (вальмовая)'),
  shed('Односкатная'),
  flat('Плоская'),
  mansard('Мансардная'),
  tent('Шатровая'),
  barrel('Арочная');

  final String label;
  const RoofType(this.label);
}

enum RoofMaterial {
  metalTile('Металлочерепица', weightPerM2: 5, lifespan: 30),
  softRoof('Мягкая кровля', weightPerM2: 8, lifespan: 20),
  profNail('Профнастил', weightPerM2: 6, lifespan: 25),
  seam('Фальцевая', weightPerM2: 7, lifespan: 40),
  ondulin('Ондулин', weightPerM2: 3.5, lifespan: 15),
  ceramicTile('Керамическая черепица', weightPerM2: 45, lifespan: 100),
  slate('Шифер', weightPerM2: 12, lifespan: 30),
  compositeTile('Композитная черепица', weightPerM2: 6.5, lifespan: 50);

  final String label;
  final double weightPerM2;
  final int lifespan;
  const RoofMaterial(
    this.label, {
    required this.weightPerM2,
    required this.lifespan,
  });
}

class RafterSystem extends Equatable {
  /// Шаг стропил (мм)
  final int spacing;

  /// Сечение (мм)
  final int sectionWidth;
  final int sectionHeight;

  /// Длина стропила (м)
  final double length;

  /// Количество
  final int count;

  /// Материал
  final RafterMaterial material;

  const RafterSystem({
    this.spacing = 600,
    this.sectionWidth = 50,
    this.sectionHeight = 200,
    required this.length,
    required this.count,
    this.material = RafterMaterial.pine,
  });

  double get weightPerMeter {
    final crossSection = sectionWidth / 1000 * sectionHeight / 1000;
    return crossSection * material.density;
  }

  @override
  List<Object?> get props => [
    spacing,
    sectionWidth,
    sectionHeight,
    length,
    count,
    material,
  ];
}

enum RafterMaterial {
  pine('Сосна', density: 500),
  spruce('Ель', density: 450),
  larch('Лиственница', density: 650),
  glueLam('Клеёный брус', density: 550);

  final String label;
  final double density;
  const RafterMaterial(this.label, {required this.density});
}

class RoofInsulation {
  final double thickness;
  final InsulationMaterial material;

  const RoofInsulation({
    this.thickness = 0.2,
    this.material = InsulationMaterial.mineralWool,
  });
  const RoofInsulation.none()
    : thickness = 0,
      material = InsulationMaterial.mineralWool;

  double get thermalResistance => thickness / material.thermalConductivity;
}

enum InsulationMaterial {
  mineralWool('Минеральная вата', thermalConductivity: 0.04, density: 35),
  basaltWool('Базальтовая вата', thermalConductivity: 0.038, density: 50),
  polystyrene('Пенополистирол', thermalConductivity: 0.035, density: 25),
  extruded('Экструдированный ППС', thermalConductivity: 0.03, density: 35),
  ecowool('Эковата', thermalConductivity: 0.04, density: 40),
  penopolyuretan('Пенополиуретан', thermalConductivity: 0.025, density: 40),
  penoizol('Пеноизол', thermalConductivity: 0.04, density: 10);

  final String label;
  final double thermalConductivity;
  final double density;
  const InsulationMaterial(
    this.label, {
    required this.thermalConductivity,
    required this.density,
  });
}

class GutterSystem extends Equatable {
  final GutterMaterial material;
  final double totalLength;
  final int downpipeCount;

  const GutterSystem({
    this.material = GutterMaterial.metal,
    required this.totalLength,
    this.downpipeCount = 2,
  });

  @override
  List<Object?> get props => [material, totalLength, downpipeCount];
}

enum GutterMaterial {
  metal('Металл'),
  plastic('Пластик'),
  copper('Медь'),
  titanium('Титан-цинк');

  final String label;
  const GutterMaterial(this.label);
}

// ============================================================================
// ИНЖЕНЕРНЫЕ СИСТЕМЫ (новое)
// ============================================================================

class EngineeringSystems extends Equatable {
  final HeatingSystem? heating;
  final WaterSupplySystem? waterSupply;
  final SewageSystem? sewage;
  final VentilationSystem? ventilation;
  final ElectricalSystem? electrical;
  final GasSupplySystem? gas;

  const EngineeringSystems({
    this.heating,
    this.waterSupply,
    this.sewage,
    this.ventilation,
    this.electrical,
    this.gas,
  });

  bool get isEmpty =>
      heating == null &&
      waterSupply == null &&
      sewage == null &&
      ventilation == null &&
      electrical == null &&
      gas == null;

  @override
  List<Object?> get props => [
    heating,
    waterSupply,
    sewage,
    ventilation,
    electrical,
    gas,
  ];
}

class HeatingSystem extends Equatable {
  final HeatingType type;
  final int radiatorCount;
  final double pipeLength;
  final double boilerPower; // кВт
  final bool hasWarmFloor;
  final double warmFloorArea;

  const HeatingSystem({
    this.type = HeatingType.radiators,
    this.radiatorCount = 0,
    this.pipeLength = 0,
    this.boilerPower = 0,
    this.hasWarmFloor = false,
    this.warmFloorArea = 0,
  });

  @override
  List<Object?> get props => [
    type,
    radiatorCount,
    pipeLength,
    boilerPower,
    hasWarmFloor,
    warmFloorArea,
  ];
}

enum HeatingType {
  radiators('Радиаторы'),
  warmFloor('Тёплый пол'),
  convectors('Конвекторы'),
  infrared('Инфракрасное'),
  combined('Комбинированное');

  final String label;
  const HeatingType(this.label);
}

class WaterSupplySystem extends Equatable {
  final double coldPipeLength;
  final double hotPipeLength;
  final int fixtureCount;
  final bool hasWaterHeater;
  final double waterHeaterVolume;

  const WaterSupplySystem({
    this.coldPipeLength = 0,
    this.hotPipeLength = 0,
    this.fixtureCount = 0,
    this.hasWaterHeater = false,
    this.waterHeaterVolume = 0,
  });

  @override
  List<Object?> get props => [
    coldPipeLength,
    hotPipeLength,
    fixtureCount,
    hasWaterHeater,
    waterHeaterVolume,
  ];
}

class SewageSystem extends Equatable {
  final double pipeLength;
  final int fixtureCount;
  final bool hasSeptic;
  final SepticType? septicType;

  const SewageSystem({
    this.pipeLength = 0,
    this.fixtureCount = 0,
    this.hasSeptic = false,
    this.septicType,
  });

  @override
  List<Object?> get props => [pipeLength, fixtureCount, hasSeptic, septicType];
}

enum SepticType {
  concreteRings('Ж/Б кольца'),
  plastic('Пластиковый'),
  bio('Биосептик'),
  drainField('Фильтрационное поле');

  final String label;
  const SepticType(this.label);
}

class VentilationSystem extends Equatable {
  final VentilationType type;
  final int exhaustPoints;
  final int supplyPoints;
  final double ductLength;
  final bool hasRecuperator;

  const VentilationSystem({
    this.type = VentilationType.natural,
    this.exhaustPoints = 0,
    this.supplyPoints = 0,
    this.ductLength = 0,
    this.hasRecuperator = false,
  });

  @override
  List<Object?> get props => [
    type,
    exhaustPoints,
    supplyPoints,
    ductLength,
    hasRecuperator,
  ];
}

enum VentilationType {
  natural('Естественная'),
  forced('Принудительная'),
  supply('Приточная'),
  exhaust('Вытяжная'),
  supplyExhaust('Приточно-вытяжная');

  final String label;
  const VentilationType(this.label);
}

class ElectricalSystem extends Equatable {
  final double cableLength;
  final int socketCount;
  final int switchCount;
  final int lightPointCount;
  final int breakerCount;
  final bool hasRCD;
  final bool hasGrounding;
  final bool hasLightningProtection;
  final bool hasSmartHome;

  const ElectricalSystem({
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

  @override
  List<Object?> get props => [
    cableLength,
    socketCount,
    switchCount,
    lightPointCount,
    breakerCount,
    hasRCD,
    hasGrounding,
    hasLightningProtection,
    hasSmartHome,
  ];
}

class GasSupplySystem extends Equatable {
  final double pipeLength;
  final int applianceCount;
  final bool hasGasMeter;
  final bool hasGasBoiler;

  const GasSupplySystem({
    this.pipeLength = 0,
    this.applianceCount = 0,
    this.hasGasMeter = false,
    this.hasGasBoiler = false,
  });

  @override
  List<Object?> get props => [
    pipeLength,
    applianceCount,
    hasGasMeter,
    hasGasBoiler,
  ];
}

// ============================================================================
// РАЗМЕРНЫЕ ЛИНИИ И ОСИ (новое)
// ============================================================================

class DimensionLine extends Equatable {
  /// Начальная точка
  final double x1, y1;

  /// Конечная точка
  final double x2, y2;

  /// Значение (метры)
  final String value;

  /// Смещение от элемента (метры)
  final double offset;

  const DimensionLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.value,
    this.offset = 0.5,
  });

  @override
  List<Object?> get props => [x1, y1, x2, y2, value, offset];
}

class AxisLine extends Equatable {
  final String label; // 1, 2, 3, ... или A, B, C, ...
  final double x1, y1, x2, y2;

  const AxisLine({
    required this.label,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  @override
  List<Object?> get props => [label, x1, y1, x2, y2];
}

// ============================================================================
// ОТМЕТКИ УРОВНЕЙ (новое)
// ============================================================================

class LevelMark extends Equatable {
  final double x, y;

  /// Отметка уровня (метры от ±0.000)
  final double level;

  /// Описание
  final String? description;

  const LevelMark({
    required this.x,
    required this.y,
    required this.level,
    this.description,
  });

  @override
  List<Object?> get props => [x, y, level, description];
}

// ============================================================================
// ЭКСПЛИКАЦИЯ (новое)
// ============================================================================

class RoomExposition {
  final RoomType type;
  final double area;
  final String number;

  const RoomExposition({
    required this.type,
    required this.area,
    required this.number,
  });
}

// ============================================================================
// РАСШИРЕННЫЕ ДВЕРИ И ОКНА
// ============================================================================

class Door extends Equatable {
  final double x, y;
  final double width;
  final double height;
  final bool clockwise;
  final DoorType type;

  /// Материал двери
  final DoorMaterial material;

  /// Теплоизоляция
  final double thermalResistance;

  /// Звукоизоляция (дБ)
  final double soundInsulation;

  /// Класс взломостойкости
  final int securityClass;

  const Door({
    required this.x,
    required this.y,
    this.width = 0.9,
    this.height = 2.1,
    this.clockwise = true,
    this.type = DoorType.internal,
    this.material = DoorMaterial.wood,
    this.thermalResistance = 0.5,
    this.soundInsulation = 25,
    this.securityClass = 0,
  });

  @override
  List<Object?> get props => [x, y, width, height, type, material];

  Door copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    bool? clockwise,
    DoorType? type,
    DoorMaterial? material,
  }) {
    return Door(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      clockwise: clockwise ?? this.clockwise,
      type: type ?? this.type,
      material: material ?? this.material,
    );
  }
}

enum DoorType {
  internal('Межкомнатная'),
  entrance('Входная'),
  balcony('Балконная'),
  technical('Техническая'),
  sliding('Раздвижная'),
  double('Двустворчатая');

  final String label;
  const DoorType(this.label);
}

enum DoorMaterial {
  wood('Дерево'),
  mdf('МДФ'),
  metal('Металл'),
  glass('Стекло'),
  pvc('ПВХ'),
  aluminum('Алюминий');

  final String label;
  const DoorMaterial(this.label);
}

class Window extends Equatable {
  final double x, y;
  final double width;
  final double height;
  final double sillHeight;
  final WindowType type;

  /// Профиль
  final WindowProfile profile;

  /// Стеклопакет
  final GlassUnit glassUnit;

  /// Откосы
  final bool hasSlopes;

  /// Отлив
  final bool hasDripCap;

  /// Москитная сетка
  final bool hasMosquitoNet;

  const Window({
    required this.x,
    required this.y,
    this.width = 1.2,
    this.height = 1.4,
    this.sillHeight = 0.9,
    this.type = WindowType.standard,
    this.profile = WindowProfile.pvc,
    this.glassUnit = GlassUnit.doubleChamber,
    this.hasSlopes = false,
    this.hasDripCap = false,
    this.hasMosquitoNet = false,
  });

  double get area => width * height;

  @override
  List<Object?> get props => [
    x,
    y,
    width,
    height,
    sillHeight,
    type,
    profile,
    glassUnit,
  ];

  Window copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? sillHeight,
    WindowType? type,
    WindowProfile? profile,
    GlassUnit? glassUnit,
  }) {
    return Window(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      sillHeight: sillHeight ?? this.sillHeight,
      type: type ?? this.type,
      profile: profile ?? this.profile,
      glassUnit: glassUnit ?? this.glassUnit,
    );
  }
}

enum WindowType {
  standard('Обычное'),
  balcony('Балконное'),
  french('Французское (в пол)'),
  attic('Мансардное'),
  panoramic('Панорамное');

  final String label;
  const WindowType(this.label);
}

enum WindowProfile {
  wood('Дерево'),
  pvc('ПВХ'),
  aluminum('Алюминий'),
  aluminumWarm('Алюминий с терморазрывом');

  final String label;
  const WindowProfile(this.label);
}

enum GlassUnit {
  single('Однокамерный'),
  doubleChamber('Двухкамерный'),
  energy('Энергосберегающий'),
  multiFunctional('Мультифункциональный'),
  tripleChamber('Трёхкамерный');

  final String label;
  const GlassUnit(this.label);

  double get thermalResistance {
    switch (this) {
      case single:
        return 0.35;
      case doubleChamber:
        return 0.55;
      case energy:
        return 0.65;
      case multiFunctional:
        return 0.7;
      case tripleChamber:
        return 0.8;
    }
  }
}

// ============================================================================
// КОМНАТА (расширенная)
// ============================================================================

class Room extends Equatable {
  final RoomType type;
  final double x, y;
  final double width, height;

  /// Высота потолка (по умолчанию 2.7)
  final double ceilingHeight;

  final List<Door> doors;
  final List<Window> windows;

  /// Номер комнаты (для экспликации)
  final String roomNumber;

  /// Отметка пола (от ±0.000)
  final double floorLevel;

  /// Чистая площадь (с вычетом стен, колонн)
  final double? netArea;

  /// Стены комнаты (для точного чертежа)
  final List<Wall> walls;

  /// Колонны в комнате
  final List<Column> columns;

  /// Ниши
  final List<Niche> niches;

  /// Радиаторы отопления
  final List<Radiator> radiators;

  /// Сантехника
  final List<PlumbingFixture> plumbingFixtures;

  /// Электрические точки
  final List<ElectricalPoint> electricalPoints;

  final bool hasBalconyAccess;
  final bool hasVentilation;

  /// Система отопления в комнате
  final HeatingSystem? heating;

  /// Вентиляция в комнате
  final VentilationSystem? ventilation;

  Room({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.ceilingHeight = 2.7,
    this.roomNumber = '',
    this.floorLevel = 0,
    this.netArea,
    this.doors = const [],
    this.windows = const [],
    this.walls = const [],
    this.columns = const [],
    this.niches = const [],
    this.radiators = const [],
    this.plumbingFixtures = const [],
    this.electricalPoints = const [],
    this.hasBalconyAccess = false,
    this.hasVentilation = true,
    this.heating,
    this.ventilation,
  });

  double get area => width * height;
  double get perimeter => 2 * (width + height);
  double get volume => area * ceilingHeight;
  double get effectiveArea => netArea ?? area;

  bool get isAreaCompliant =>
      type.minArea == 0 || effectiveArea >= type.minArea;
  bool get hasNaturalLight => windows.isNotEmpty;

  bool get isLightCompliant =>
      hasNaturalLight ||
      type == RoomType.bathroom ||
      type == RoomType.toilet ||
      type == RoomType.storage;

  double get complianceScore {
    double score = 1.0;
    if (!isAreaCompliant) score -= 0.3;
    if (!isLightCompliant) score -= 0.2;
    if (type == RoomType.kitchen && !hasVentilation) score -= 0.2;
    if (doors.isEmpty && type != RoomType.balcony) score -= 0.1;
    return score.clamp(0.0, 1.0);
  }

  List<String> get warnings {
    final result = <String>[];
    if (!isAreaCompliant) {
      result.add(
        '${type.label}: ${effectiveArea.toStringAsFixed(1)}м² < ${type.minArea}м²',
      );
    }
    if (!isLightCompliant)
      result.add('${type.label}: нет естественного освещения');
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
    double? ceilingHeight,
    String? roomNumber,
    double? floorLevel,
    double? netArea,
    List<Door>? doors,
    List<Window>? windows,
    List<Wall>? walls,
    List<Column>? columns,
    List<Niche>? niches,
    List<Radiator>? radiators,
    List<PlumbingFixture>? plumbingFixtures,
    List<ElectricalPoint>? electricalPoints,
    bool? hasBalconyAccess,
    bool? hasVentilation,
    HeatingSystem? heating,
    VentilationSystem? ventilation,
  }) {
    return Room(
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      ceilingHeight: ceilingHeight ?? this.ceilingHeight,
      roomNumber: roomNumber ?? this.roomNumber,
      floorLevel: floorLevel ?? this.floorLevel,
      netArea: netArea ?? this.netArea,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      walls: walls ?? this.walls,
      columns: columns ?? this.columns,
      niches: niches ?? this.niches,
      radiators: radiators ?? this.radiators,
      plumbingFixtures: plumbingFixtures ?? this.plumbingFixtures,
      electricalPoints: electricalPoints ?? this.electricalPoints,
      hasBalconyAccess: hasBalconyAccess ?? this.hasBalconyAccess,
      hasVentilation: hasVentilation ?? this.hasVentilation,
      heating: heating ?? this.heating,
      ventilation: ventilation ?? this.ventilation,
    );
  }

  @override
  List<Object?> get props => [
    type,
    x,
    y,
    width,
    height,
    ceilingHeight,
    roomNumber,
    floorLevel,
    netArea,
    doors,
    windows,
    walls,
    columns,
    niches,
    radiators,
    plumbingFixtures,
    electricalPoints,
    hasBalconyAccess,
    hasVentilation,
    heating,
    ventilation,
  ];
}

// ============================================================================
// КОНСТРУКТИВНЫЕ ЭЛЕМЕНТЫ
// ============================================================================

class Column extends Equatable {
  final double x, y;
  final double width, height;
  final ColumnMaterial material;

  const Column({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.material = ColumnMaterial.reinforcedConcrete,
  });

  double get area => width * height;

  @override
  List<Object?> get props => [x, y, width, height, material];
}

enum ColumnMaterial {
  reinforcedConcrete('Железобетон'),
  steel('Стальная'),
  wood('Деревянная'),
  brick('Кирпичная');

  final String label;
  const ColumnMaterial(this.label);
}

class Niche extends Equatable {
  final double x, y, width, height;
  final double depth;
  final NicheType type;

  const Niche({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.depth,
    this.type = NicheType.technical,
  });

  @override
  List<Object?> get props => [x, y, width, height, depth, type];
}

enum NicheType {
  technical('Техническая'),
  decorative('Декоративная'),
  storage('Хранение'),
  ventilation('Вентиляционная');

  final String label;
  const NicheType(this.label);
}

class Radiator extends Equatable {
  final double x, y;
  final double width, height;
  final double thermalPower; // кВт
  final RadiatorType type;

  const Radiator({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.thermalPower = 1.5,
    this.type = RadiatorType.sectional,
  });

  @override
  List<Object?> get props => [x, y, width, height, thermalPower, type];
}

enum RadiatorType {
  sectional('Секционный'),
  panel('Панельный'),
  tubular('Трубчатый'),
  convector('Конвектор');

  final String label;
  const RadiatorType(this.label);
}

class PlumbingFixture extends Equatable {
  final double x, y;
  final double width, height;
  final PlumbingFixtureType type;
  final double rotation;

  const PlumbingFixture({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    this.rotation = 0,
  });

  @override
  List<Object?> get props => [x, y, width, height, type, rotation];
}

enum PlumbingFixtureType {
  bathtub('Ванна'),
  shower('Душ'),
  sink('Раковина'),
  toilet('Унитаз'),
  bidet('Биде'),
  washingMachine('Стиральная машина'),
  dishwasher('Посудомоечная машина'),
  waterHeater('Водонагреватель');

  final String label;
  final String emoji;
  const PlumbingFixtureType(this.label, {this.emoji = '🔧'});
}

class ElectricalPoint extends Equatable {
  final double x, y;
  final ElectricalPointType type;
  final double height; // от пола

  const ElectricalPoint({
    required this.x,
    required this.y,
    required this.type,
    this.height = 0.3,
  });

  @override
  List<Object?> get props => [x, y, type, height];
}

enum ElectricalPointType {
  socket('Розетка', '🔌'),
  lightSwitch('Выключатель', '💡'),
  light('Светильник', '💡'),
  junctionBox('Распаячная коробка', '📦'),
  panel('Щиток', '⚡');

  final String label;
  final String emoji;
  const ElectricalPointType(this.label, this.emoji);
}

// ============================================================================
// РАСШИРЕННЫЙ FLOOR PLAN
// ============================================================================

class FloorPlan extends Equatable {
  final List<Room> rooms;
  final double totalWidth, totalHeight;
  final FloorPlanType objectType;

  /// Версия чертежа
  final String drawingVersion;

  /// Номер чертежа
  final String drawingNumber;

  /// Масштаб
  final double scale;

  /// Дата чертежа
  final DateTime drawingDate;

  /// Стены (общий список)
  final List<Wall> walls;

  /// Колонны
  final List<Column> columns;

  /// Осевые линии
  final List<AxisLine> axisLines;

  /// Размерные линии
  final List<DimensionLine> dimensionLines;

  /// Отметки уровней
  final List<LevelMark> levelMarks;

  /// Фундамент
  final Foundation? foundation;

  /// Перекрытия
  final List<Ceiling> ceilings;

  /// Кровля
  final Roof? roof;

  /// Инженерные системы
  final EngineeringSystems engineeringSystems;

  /// Площадь застройки
  final double buildingFootprint;

  /// Общая площадь
  final double totalArea;

  /// Жилая площадь
  final double livingArea;

  /// Высота этажа
  final double floorHeight;

  /// Отметка пола
  final double floorLevelMark;

  /// Отметка потолка
  final double ceilingLevelMark;

  /// Комментарии чертежа
  final List<String> notes;

  /// Экспликация помещений
  final List<RoomExposition> exposition;

  FloorPlan({
    required this.rooms,
    required this.totalWidth,
    required this.totalHeight,
    this.objectType = FloorPlanType.apartment,
    this.drawingVersion = '1.0',
    this.drawingNumber = '',
    this.scale = 100,
    DateTime? drawingDate,
    this.walls = const [],
    this.columns = const [],
    this.axisLines = const [],
    this.dimensionLines = const [],
    this.levelMarks = const [],
    this.foundation,
    this.ceilings = const [],
    this.roof,
    this.engineeringSystems = const EngineeringSystems(),
    this.buildingFootprint = 0,
    this.totalArea = 0,
    this.livingArea = 0,
    this.floorHeight = 2.7,
    this.floorLevelMark = 0,
    this.ceilingLevelMark = 2.7,
    this.notes = const [],
    this.exposition = const [],
  }) : drawingDate = drawingDate ?? DateTime.now();

  double get calculatedTotalArea => totalWidth * totalHeight;

  double get calculatedLivingArea => rooms
      .where(
        (r) =>
            r.type == RoomType.bedroom ||
            r.type == RoomType.livingRoom ||
            r.type == RoomType.childrenRoom ||
            r.type == RoomType.office,
      )
      .fold(0.0, (sum, r) => sum + r.area);

  double get complianceScore {
    if (rooms.isEmpty) return 0.0;
    return rooms.map((r) => r.complianceScore).reduce((a, b) => a + b) /
        rooms.length;
  }

  List<String> get allWarnings => rooms.expand((r) => r.warnings).toList();

  int get roomCount => rooms
      .where(
        (r) =>
            r.type == RoomType.bedroom ||
            r.type == RoomType.livingRoom ||
            r.type == RoomType.kitchen ||
            r.type == RoomType.childrenRoom ||
            r.type == RoomType.office ||
            r.type == RoomType.garage,
      )
      .length;

  List<Room> roomsByType(RoomType type) =>
      rooms.where((r) => r.type == type).toList();

  bool get isValid => allWarnings.isEmpty;

  /// Объём здания (м³)
  double get buildingVolume => totalWidth * totalHeight * floorHeight;

  /// Периметр наружных стен
  double get exteriorPerimeter {
    final extWalls = walls.where((w) => w.type == WallType.exterior);
    if (extWalls.isEmpty) return 2 * (totalWidth + totalHeight);
    return extWalls.fold(0.0, (sum, w) => sum + w.length);
  }

  /// Площадь наружных стен
  double get exteriorWallArea => walls
      .where((w) => w.type == WallType.exterior)
      .fold(0.0, (sum, w) => sum + w.area);

  /// Площадь проёмов (окна + двери)
  double get openingsArea {
    double total = 0;
    for (final room in rooms) {
      for (final w in room.windows) total += w.area;
      for (final d in room.doors) total += d.width * d.height;
    }
    return total;
  }

  /// Площадь стен за вычетом проёмов
  double get netWallArea => exteriorWallArea - openingsArea;

  /// Теплопотери через наружные стены (Вт)
  double get heatLoss {
    double loss = 0;
    final deltaT = 40; // разница температур (внутри - снаружи)
    for (final wall in walls.where((w) => w.type == WallType.exterior)) {
      final rValue =
          wall.material.calcRValue(wall.thickness) +
          wall.insulationThickness / 0.04; // утеплитель
      loss += wall.area / rValue * deltaT;
    }
    // Окна
    for (final room in rooms) {
      for (final w in room.windows) {
        loss += w.area / w.glassUnit.thermalResistance * deltaT;
      }
    }
    return loss;
  }

  FloorPlan copyWith({
    List<Room>? rooms,
    double? totalWidth,
    double? totalHeight,
    FloorPlanType? objectType,
    String? drawingVersion,
    String? drawingNumber,
    double? scale,
    DateTime? drawingDate,
    List<Wall>? walls,
    List<Column>? columns,
    List<AxisLine>? axisLines,
    List<DimensionLine>? dimensionLines,
    List<LevelMark>? levelMarks,
    Foundation? foundation,
    List<Ceiling>? ceilings,
    Roof? roof,
    EngineeringSystems? engineeringSystems,
    double? buildingFootprint,
    double? totalArea,
    double? livingArea,
    double? floorHeight,
    double? floorLevelMark,
    double? ceilingLevelMark,
    List<String>? notes,
    List<RoomExposition>? exposition,
  }) {
    return FloorPlan(
      rooms: rooms ?? this.rooms,
      totalWidth: totalWidth ?? this.totalWidth,
      totalHeight: totalHeight ?? this.totalHeight,
      objectType: objectType ?? this.objectType,
      drawingVersion: drawingVersion ?? this.drawingVersion,
      drawingNumber: drawingNumber ?? this.drawingNumber,
      scale: scale ?? this.scale,
      drawingDate: drawingDate ?? this.drawingDate,
      walls: walls ?? this.walls,
      columns: columns ?? this.columns,
      axisLines: axisLines ?? this.axisLines,
      dimensionLines: dimensionLines ?? this.dimensionLines,
      levelMarks: levelMarks ?? this.levelMarks,
      foundation: foundation ?? this.foundation,
      ceilings: ceilings ?? this.ceilings,
      roof: roof ?? this.roof,
      engineeringSystems: engineeringSystems ?? this.engineeringSystems,
      buildingFootprint: buildingFootprint ?? this.buildingFootprint,
      totalArea: totalArea ?? this.totalArea,
      livingArea: livingArea ?? this.livingArea,
      floorHeight: floorHeight ?? this.floorHeight,
      floorLevelMark: floorLevelMark ?? this.floorLevelMark,
      ceilingLevelMark: ceilingLevelMark ?? this.ceilingLevelMark,
      notes: notes ?? this.notes,
      exposition: exposition ?? this.exposition,
    );
  }

  @override
  List<Object?> get props => [
    rooms,
    totalWidth,
    totalHeight,
    objectType,
    drawingVersion,
    drawingNumber,
    scale,
    drawingDate,
    walls,
    columns,
    axisLines,
    dimensionLines,
    levelMarks,
    foundation,
    ceilings,
    roof,
    engineeringSystems,
    buildingFootprint,
    totalArea,
    livingArea,
    floorHeight,
    notes,
    exposition,
  ];
}

enum FloorPlanType {
  apartment('Квартира'),
  house('Частный дом'),
  office('Офис'),
  studio('Студия'),
  cottage('Коттедж'),
  duplex('Дуплекс'),
  townhouse('Таунхаус');

  final String label;
  const FloorPlanType(this.label);
}
