import '../models/order.dart';
import '../models/checklist_config.dart';

/// Калькулятор стоимости на основе прайс-листов
/// Цены берутся из дефолтных значений + могут быть переопределены через PriceListService
class CostCalculator {
  /// Базовые цены на материалы/работы по типам
  /// Эти значения можно переопределить через UI прайс-листа
  static const Map<String, Map<String, double>> basePrices = {
    'windows': {
      'frame_per_m2': 3500.0, // цена за м² рамы
      'glass_single': 1500.0, // однокамерный стеклопакет за м²
      'glass_double': 2500.0, // двухкамерный стеклопакет за м²
      'hardware': 2000.0, // фурнитура
      'sill': 800.0, // подоконник за м.п.
      'slope': 1200.0, // откос за м.п.
      'installation': 2500.0, // монтаж за м²
    },
    'doors': {
      'door_leaf': 8000.0, // полотно
      'door_frame': 3000.0, // коробка
      'door_lock': 2500.0, // замок
      'door_handle': 800.0, // ручка
      'door_installation': 5000.0, // монтаж
    },
    'air_conditioners': {
      'ac_install_basic': 15000.0, // базовый монтаж
      'ac_install_complex': 25000.0, // сложный монтаж
      'ac_mount': 3000.0, // кронштейны
      'ac_copper_pipe': 800.0, // медная труба за м.п.
      'ac_drain': 500.0, // дренаж за м.п.
    },
    'kitchens': {
      'kitchen_lm_meter': 15000.0, // цена за погонный метр
      'kitchen_countertop': 8000.0, // столешница за м.п.
      'kitchen_appliance_install': 3000.0, // установка техники за шт.
      'kitchen_sink': 5000.0, // мойка
      'kitchen_backsplash': 2000.0, // фартук за м²
    },
    'tiles': {
      'tile_per_m2': 800.0, // плитка за м²
      'tile_install_simple': 1200.0, // укладка простая за м²
      'tile_install_diagonal': 1600.0, // укладка диагональная за м²
      'tile_grout': 150.0, // затирка за м²
      'tile_glue': 200.0, // клей за м²
      'tile_warm_floor': 800.0, // тёплый пол за м²
    },
    'furniture': {
      'ldsp_per_m2': 2500.0, // ЛДСП за м²
      'mdf_per_m2': 3500.0, // МДФ за м²
      'solid_per_m2': 6000.0, // массив за м²
      'facade_per_m2': 4000.0, // фасады за м²
      'drawer_mechanism': 1500.0, // механизм выдвижной за шт.
      'furniture_assembly': 3000.0, // сборка за м.п.
    },
    'engineering': {
      'boiler_gas': 35000.0, // газовый котёл
      'boiler_electric': 20000.0, // электрический котёл
      'radiator_section': 5000.0, // секция радиатора
      'pipe_pp_per_m': 200.0, // труба ПП за м
      'pipe_pex_per_m': 350.0, // труба PEX за м
      'warm_floor_water_per_m2': 1500.0, // водяной тёплый пол за м²
      'warm_floor_electric_per_m2': 2000.0, // электрический тёплый пол за м²
      'sewage_pipe_per_m': 500.0, // канализационная труба за м
      'ventilation_install': 3000.0, // вентиляция за точку
    },
    'electrical': {
      'cable_vvg_per_m': 80.0, // кабель ВВГнг за м
      'cable_nym_per_m': 100.0, // кабель NYM за м
      'socket': 400.0, // розетка за шт.
      'switch': 350.0, // выключатель за шт.
      'light_point': 800.0, // точка освещения
      'panel_assembly': 5000.0, // сборка щитка
      'cable_routing_per_m': 300.0, // прокладка кабеля за м
      'smart_home_point': 3000.0, // точка умного дома
    },
  };

  /// Текущие цены (могут быть переопределены из UI)
  static Map<String, Map<String, double>> _currentPrices = Map.from(basePrices);

  /// Обновить цену для конкретного типа работ
  static void updatePrice(String workType, String itemId, double newPrice) {
    if (!_currentPrices.containsKey(workType)) {
      _currentPrices[workType] = Map.from(basePrices[workType] ?? {});
    }
    _currentPrices[workType]![itemId] = newPrice;
  }

  /// Сбросить все цены к дефолтным
  static void resetToDefaults() {
    _currentPrices = Map.from(basePrices);
  }

  /// Получить текущую цену
  static double getPrice(String workType, String itemId) {
    return _currentPrices[workType]?[itemId] ??
        basePrices[workType]?[itemId] ??
        0;
  }

  /// Получить все цены для типа работ
  static Map<String, double> getPricesForType(String workType) {
    return _currentPrices[workType] ?? basePrices[workType] ?? {};
  }

  /// Расчёт стоимости на основе данных чек-листа
  static double calculate(Order order, ChecklistConfig config) {
    final data = order.checklistData;
    final prices = getPricesForType(order.workType.checklistFile);
    double total = 0;

    switch (order.workType) {
      case WorkType.windows:
        total = _calculateWindows(data, prices);
        break;
      case WorkType.doors:
        total = _calculateDoors(data, prices);
        break;
      case WorkType.airConditioners:
        total = _calculateAC(data, prices);
        break;
      case WorkType.kitchens:
        total = _calculateKitchen(data, prices);
        break;
      case WorkType.tiles:
        total = _calculateTiles(data, prices);
        break;
      case WorkType.furniture:
        total = _calculateFurniture(data, prices);
        break;
      case WorkType.engineering:
        total = _calculateEngineering(data, prices);
        break;
      case WorkType.electrical:
        total = _calculateElectrical(data, prices);
        break;
    }

    return total.roundToDouble();
  }

  // ===== Методы расчёта =====

  static double _calculateWindows(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final width = (data['width'] as num?)?.toDouble() ?? 0;
    final height = (data['height'] as num?)?.toDouble() ?? 0;
    final area = (width / 1000) * (height / 1000);

    total += area * (prices['frame_per_m2'] ?? 0);

    final glassType = data['glass_type'] as String?;
    if (glassType == 'double') {
      total += area * (prices['glass_double'] ?? 0);
    } else {
      total += area * (prices['glass_single'] ?? 0);
    }

    total += prices['hardware'] ?? 0;
    total += (width / 1000) * (prices['sill'] ?? 0);

    if (data['has_slopes'] == true) {
      final perimeter = 2 * (width / 1000) + (height / 1000);
      total += perimeter * (prices['slope'] ?? 0);
    }

    total += area * (prices['installation'] ?? 0);
    return total;
  }

  static double _calculateDoors(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    total += prices['door_leaf'] ?? 0;
    total += prices['door_frame'] ?? 0;
    if (data['has_lock'] == true) total += prices['door_lock'] ?? 0;
    total += prices['door_handle'] ?? 0;
    total += prices['door_installation'] ?? 0;
    return total;
  }

  static double _calculateAC(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final installType = data['install_type'] as String?;
    if (installType == 'complex') {
      total += prices['ac_install_complex'] ?? 0;
    } else {
      total += prices['ac_install_basic'] ?? 0;
    }
    total += prices['ac_mount'] ?? 0;
    final pipeLength = (data['pipe_length'] as num?)?.toDouble() ?? 0;
    total += pipeLength * (prices['ac_copper_pipe'] ?? 0);
    final drainLength = (data['drain_length'] as num?)?.toDouble() ?? 0;
    total += drainLength * (prices['ac_drain'] ?? 0);
    return total;
  }

  static double _calculateKitchen(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final length = (data['kitchen_length'] as num?)?.toDouble() ?? 0;
    total += (length / 1000) * (prices['kitchen_lm_meter'] ?? 0);
    total += (length / 1000) * (prices['kitchen_countertop'] ?? 0);
    if (data['has_appliance_install'] == true) {
      final applianceCount = (data['appliance_count'] as num?)?.toDouble() ?? 0;
      total += applianceCount * (prices['kitchen_appliance_install'] ?? 0);
    }
    if (data['has_backsplash'] == true) {
      final backsplashArea =
          ((data['backsplash_length'] as num?)?.toDouble() ?? 0) / 1000 * 0.6;
      total += backsplashArea * (prices['kitchen_backsplash'] ?? 0);
    }
    return total;
  }

  static double _calculateTiles(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final surfaceType = data['surface_type'] as String?;
    double area = 0;

    if (surfaceType == 'Стены') {
      final wallHeight = (data['wall_height'] as num?)?.toDouble() ?? 0;
      final wallLength = (data['wall_length'] as num?)?.toDouble() ?? 0;
      area = (wallHeight / 1000) * (wallLength / 1000);
      if (data['has_windows_doors'] == true) {
        final windowsArea =
            (data['windows_doors_area'] as num?)?.toDouble() ?? 0;
        area -= windowsArea;
      }
    } else if (surfaceType == 'Пол') {
      final floorLength = (data['floor_length'] as num?)?.toDouble() ?? 0;
      final floorWidth = (data['floor_width'] as num?)?.toDouble() ?? 0;
      area = (floorLength / 1000) * (floorWidth / 1000);
    } else if (surfaceType == 'Фартук (кухня/ванна)') {
      final apronHeight = (data['apron_height'] as num?)?.toDouble() ?? 0;
      final apronLength = (data['apron_length'] as num?)?.toDouble() ?? 0;
      area = (apronHeight / 1000) * (apronLength / 1000);
    }

    if (area > 0) {
      total += area * (prices['tile_per_m2'] ?? 0);
      final layingMethod = data['laying_method'] as String?;
      if (layingMethod == 'Диагональная') {
        total += area * (prices['tile_install_diagonal'] ?? 0);
      } else {
        total += area * (prices['tile_install_simple'] ?? 0);
      }
      total += area * (prices['tile_grout'] ?? 0);
      total += area * (prices['tile_glue'] ?? 0);
    }

    if (data['has_underfloor_heating'] == true) {
      final heatingArea = (data['heating_area'] as num?)?.toDouble() ?? 0;
      total += heatingArea * (prices['tile_warm_floor'] ?? 0);
    }
    return total;
  }

  static double _calculateFurniture(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final bodyMaterial = data['body_material'] as String?;
    final wallLength = (data['wall_length'] as num?)?.toDouble() ?? 0;
    final ceilingHeight = (data['ceiling_height'] as num?)?.toDouble() ?? 0;
    final area = (wallLength / 1000) * (ceilingHeight / 1000);

    if (bodyMaterial == 'ЛДСП') {
      total += area * (prices['ldsp_per_m2'] ?? 0);
    } else if (bodyMaterial == 'МДФ') {
      total += area * (prices['mdf_per_m2'] ?? 0);
    } else if (bodyMaterial == 'Массив') {
      total += area * (prices['solid_per_m2'] ?? 0);
    }

    total += area * (prices['facade_per_m2'] ?? 0);

    if (data['has_drawers'] == true) {
      final drawersCount = (data['drawers_count'] as num?)?.toDouble() ?? 0;
      total += drawersCount * (prices['drawer_mechanism'] ?? 0);
    }

    total += (wallLength / 1000) * (prices['furniture_assembly'] ?? 0);
    return total;
  }

  static double _calculateEngineering(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final systemType = data['system_type'] as String?;

    if (systemType == 'Котельная') {
      final boilerType = data['boiler_type'] as String?;
      if (boilerType == 'Газовый') {
        total += prices['boiler_gas'] ?? 0;
      } else if (boilerType == 'Электрический') {
        total += prices['boiler_electric'] ?? 0;
      }
    }

    if (systemType == 'Отопление') {
      final sectionsCount =
          (data['radiator_sections_count'] as num?)?.toDouble() ?? 0;
      total += sectionsCount * (prices['radiator_section'] ?? 0);
    }

    if (systemType == 'Вентиляция') {
      final valvesCount =
          (data['intake_valves_count'] as num?)?.toDouble() ?? 0;
      total += valvesCount * (prices['ventilation_install'] ?? 0);
    }
    return total;
  }

  static double _calculateElectrical(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final socketsCount = (data['sockets_count'] as num?)?.toDouble() ?? 0;
    total += socketsCount * (prices['socket'] ?? 0);
    final lightingCount = (data['lighting_count'] as num?)?.toDouble() ?? 0;
    total += lightingCount * (prices['light_point'] ?? 0);
    final wallRoutes = (data['wall_routes_length'] as num?)?.toDouble() ?? 0;
    final floorRoutes = (data['floor_routes_length'] as num?)?.toDouble() ?? 0;
    final ceilingRoutes =
        (data['ceiling_routes_length'] as num?)?.toDouble() ?? 0;
    final totalRouteLength = wallRoutes + floorRoutes + ceilingRoutes;
    total += totalRouteLength * (prices['cable_routing_per_m'] ?? 0);
    total += prices['panel_assembly'] ?? 0;
    if (data['has_smart_home'] == true) {
      total += prices['smart_home_point'] ?? 0;
    }
    return total;
  }
}
