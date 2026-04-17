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
      'glass_energy': 3000.0, // энергосберегающий стеклопакет за м²
      'hardware': 2000.0, // базовая фурнитура
      'hardware_turn': 800.0, // доп. наценка за поворотно-откидное
      'hardware_slide': 3000.0, // фурнитура раздвижная
      'sill': 800.0, // подоконник за м.п.
      'drip_cap': 600.0, // отлив за м.п.
      'slope_plastic': 1200.0, // откос пластиковый за м.п.
      'slope_sandwich': 1500.0, // откос сэндвич за м.п.
      'slope_plaster': 900.0, // откос штукатурка за м.п.
      'installation': 2500.0, // монтаж за м²
      'geometry_correction': 1500.0, // наценка за сложную геометрию
      'high_floor_delivery': 500.0, // доплата за этаж без лифта
    },
    'doors': {
      'door_entrance': 15000.0, // входная дверь комплект
      'door_interior': 8000.0, // межкомнатная дверь комплект
      'door_technical': 5000.0, // техническая дверь комплект
      'door_frame': 3000.0, // коробка
      'lock_cylinder': 2500.0, // замок цилиндровый
      'lock_mortise': 3500.0, // замок сувальдный
      'lock_electronic': 8000.0, // замок электронный
      'door_handle': 800.0, // ручка
      'door_installation': 5000.0, // монтаж
      'door_floor_leveling': 2000.0, // подгонка по перепаду пола
      'door_geometry_correction': 1500.0, // наценка за неровный проём
      'threshold': 1500.0, // порог
      'peephole': 500.0, // глазок
      'finish_mdf': 0.0, // МДФ (базовая цена включена)
      'finish_veneer': 3000.0, // шпон (доплата)
      'finish_eco': 1500.0, // экошпон (доплата)
      'finish_solid': 8000.0, // массив (доплата)
      'finish_lamination': 0.0, // ламинация (базовая)
    },
    'air_conditioners': {
      'ac_install_basic': 15000.0, // базовый монтаж
      'ac_install_complex': 25000.0, // сложный монтаж
      'ac_mount': 3000.0, // кронштейны
      'ac_copper_pipe': 800.0, // медная труба за м.п.
      'ac_drain': 500.0, // дренаж за м.п.
      'ac_drain_pump': 5000.0, // дренажный насос
      'ac_wifi': 3000.0, // Wi-Fi модуль
      'ac_route_chase': 1200.0, // штроба за м.п.
      'ac_route_box': 400.0, // короб за м.п.
      'ac_alpine': 5000.0, // промальпинизм
      'ac_scaffolding': 3000.0, // леса
      'ac_power_cable': 800.0, // кабель питания за м.п.
      'ac_wall_drill': 2000.0, // бурение стены (бетон/кирпич)
    },
    'kitchens': {
      'kitchen_lm_meter': 15000.0, // базовая кухня за пог.м
      'kitchen_corner': 5000.0, // угловой модуль (доплата)
      'kitchen_island': 20000.0, // островной модуль
      'countertop_ldsp': 8000.0, // столешница ЛДСП за м.п.
      'countertop_mdf': 12000.0, // столешница МДФ за м.п.
      'countertop_artificial_stone': 25000.0, // иск. камень за м.п.
      'countertop_natural_stone': 50000.0, // натур. камень за м.п.
      'facade_film': 0.0, // плёнка (базовая)
      'facade_enamel': 5000.0, // эмаль (доплата за м.п.)
      'facade_solid': 12000.0, // массив (доплата за м.п.)
      'facade_veneer': 8000.0, // шпон (доплата за м.п.)
      'facade_plastic': 4000.0, // пластик (доплата за м.п.)
      'kitchen_appliance_install': 3000.0, // установка техники за шт.
      'kitchen_sink': 5000.0, // мойка
      'sink_undermount': 3000.0, // доплата за подстольную мойку
      'backsplash_tile': 2000.0, // фартук плитка за м²
      'backsplash_glass': 4000.0, // фартук стекло за м²
      'backsplash_mdf': 1500.0, // фартук МДФ за м²
      'backsplash_mosaic': 5000.0, // фартук мозаика за м²
    },
    'tiles': {
      'tile_per_m2': 800.0, // плитка (материал) за м²
      'tile_install_simple': 1200.0, // укладка простая за м²
      'tile_install_diagonal': 1600.0, // укладка диагональная за м²
      'tile_install_offset': 1400.0, // укладка со смещением за м²
      'tile_install_modular': 1800.0, // укладка модульная за м²
      'tile_install_pattern': 2200.0, // укладка узор за м²
      'tile_grout': 150.0, // затирка за м²
      'tile_glue': 200.0, // клей за м²
      'tile_warm_floor': 800.0, // тёплый пол за м²
      'tile_leveling': 500.0, // выравнивание основания за м²
      'tile_glue_standard': 200.0, // стандартный клей
      'tile_glue_porcelain': 350.0, // клей для керамогранита
      'tile_glue_mosaic': 500.0, // клей для мозаики
      'tile_material_ceramic': 800.0, // керамика за м²
      'tile_material_porcelain': 1500.0, // керамогранит за м²
      'tile_material_mosaic': 3000.0, // мозаика за м²
      'tile_material_stone': 5000.0, // натур. камень за м²
      'tile_material_clinker': 2000.0, // клинкер за м²
      'socket_cutout': 500.0, // вырез под розетку за шт.
      'decorative_insert': 1500.0, // декоративная вставка за шт.
      'reserve_surcharge': 0.0, // наценка за запас (%, вычисляется)
    },
    'furniture': {
      'ldsp_per_m2': 2500.0, // ЛДСП за м²
      'mdf_per_m2': 3500.0, // МДФ за м²
      'solid_per_m2': 6000.0, // массив за м²
      'facade_per_m2': 4000.0, // фасады за м²
      'drawer_mechanism': 1500.0, // механизм выдвижной за шт.
      'furniture_assembly': 3000.0, // сборка за м.п.
      'niche_custom_work': 5000.0, // индивидуальная работа для ниши
      'wall_curvature_compensation': 3000.0, // компенсация кривизны стен
      'door_hinged': 0.0, // распашные (базовая)
      'door_sliding': 5000.0, // раздвижные (доплата за комплект)
      'builtin_surcharge': 2000.0, // встроенная (доплата за м²)
      'edge_pvc': 0.0, // ПВХ (базовая)
      'edge_abs': 200.0, // АБС (доплата за м.п.)
      'edge_thin': 0.0, // 0.4 мм (базовая)
      'edge_medium': 300.0, // 1 мм (доплата за м.п.)
      'edge_thick': 600.0, // 2 мм (доплата за м.п.)
      'pantograph': 4000.0, // пантограф за шт.
      'rod': 1500.0, // штанга за шт.
      'mezzanine': 3000.0, // антресоль
      'open_shelf': 1000.0, // открытая полка
      'socket_cutout': 500.0, // вырез под розетку
      'pipe_cutout': 2000.0, // обход трубы
      'skewed_corner': 3000.0, // скошенный угол
      'column_cutout': 2000.0, // обход колонны
    },
    'engineering': {
      'boiler_gas': 35000.0, // газовый котёл
      'boiler_electric': 20000.0, // электрический котёл
      'boiler_solid': 25000.0, // твёрдотопливный котёл
      'boiler_liquid': 30000.0, // жидкотопливный котёл
      'boiler_power_kw': 500.0, // доплата за кВт мощности
      'boiler_wall_mount': 2000.0, // настенный монтаж
      'boiler_floor_mount': 5000.0, // напольный монтаж
      'chimney_install': 3000.0, // монтаж дымохода за м
      'radiator_section_bimetal': 6000.0, // биметалл за секцию
      'radiator_section_aluminum': 4500.0, // алюминий за секцию
      'radiator_section_castiron': 5000.0, // чугун за секцию
      'radiator_section': 5000.0, // секция радиатора (базовая)
      'pipe_pp_per_m': 200.0, // труба ПП за м
      'pipe_pex_per_m': 350.0, // труба PEX за м
      'pipe_concealed': 300.0, // скрытая прокладка (доплата за м)
      'warm_floor_water_per_m2': 1500.0, // водяной тёплый пол за м²
      'warm_floor_electric_per_m2': 2000.0, // электрический тёплый пол за м²
      'warm_floor_cable_per_m2': 1800.0, // кабельный тёплый пол за м²
      'warm_floor_mat_per_m2': 2200.0, // нагревательный мат за м²
      'sewage_pipe_per_m': 500.0, // канализационная труба за м
      'ventilation_install': 3000.0, // вентиляция за точку
      'ventilation_forced': 5000.0, // принудительная вентиляция за точку
      'insulation_per_m2': 800.0, // утепление за м²
      'heat_loss_calculation': 5000.0, // расчёт теплопотерь
      'filter': 3000.0, // фильтр
      'water_meter': 2500.0, // счётчик воды
      'recuperator': 25000.0, // рекуператор
      'collector': 8000.0, // коллекторный шкаф
      'floor_drain': 3000.0, // трап канализационный
    },
    'electrical': {
      'cable_vvg_per_m': 80.0, // кабель ВВГнг за м
      'cable_nym_per_m': 100.0, // кабель NYM за м
      'socket': 400.0, // розетка за шт.
      'socket_waterproof': 600.0, // влагозащищённая розетка
      'switch': 350.0, // выключатель за шт.
      'switch_pass': 800.0, // проходной выключатель
      'switch_dimmer': 1500.0, // диммер
      'light_point': 800.0, // точка освещения
      'panel_assembly': 5000.0, // сборка щитка
      'panel_3phase': 5000.0, // доплата за 3-фазный щит
      'cable_routing_per_m': 300.0, // прокладка кабеля за м
      'cable_concealed': 200.0, // скрытая прокладка (доплата за м)
      'circuit_breaker': 500.0, // автомат за шт.
      'rcd_single': 2000.0, // УЗО за шт.
      'rcd_leakage_10': 500.0, // доплата за ток утечки 10мА
      'rcd_leakage_30': 0.0, // 30мА (базовая)
      'rcd_leakage_100': 1000.0, // доплата за ток утечки 100мА
      'lightning_protection': 15000.0, // молниезащита
      'grounding_circuit': 10000.0, // контур заземления
      'internet_socket': 800.0, // розетка интернет/ТВ
      'cctv_point': 5000.0, // точка видеонаблюдения
      'smart_home_point': 3000.0, // точка умного дома
    },
    // ===== Строительство ИЖС =====
    'foundations': {
      'concrete_work': 5500.0, // бетонные работы за м³
      'formwork': 800.0, // опалубка за м²
      'reinforcement': 95.0, // арматура за кг
      'sand_cushion': 1200.0, // песчаная подушка за м³
      'waterproofing': 450.0, // гидроизоляция за м²
      'excavation': 2500.0, // земляные работы за м³
      'drainage': 1800.0, // дренаж за пог.м
      'geotextile': 180.0, // геотекстиль за м²
      'delivery_concrete': 500.0, // доставка бетона за м³
      'labor_foundation': 15000.0, // работа за компл.
    },
    'house_construction': {
      'wall_construction': 3500.0, // возведение стен за м²
      'ceiling_installation': 1200.0, // перекрытия за м²
      'partition_install': 900.0, // перегородки за м²
      'roof_installation': 2800.0, // кровля за м²
      'window_installation': 8500.0, // установка окон за шт
      'door_installation': 6500.0, // установка дверей за шт
      'rough_finish': 1800.0, // черновая отделка за м²
      'garage_construction': 4200.0, // гараж за м²
      'basement_construction': 5500.0, // подвал за м²
      'project_management': 85000.0, // управление проектом
      'site_preparation': 45000.0, // подготовка площадки
    },
    'walls_box': {
      'wall_block': 2800.0, // кладка блока за м²
      'insulation': 650.0, // утепление за м²
      'armo_poyas': 1800.0, // армопояс за пог.м
      'window_openings': 3500.0, // оформление оконных проёмов за шт
      'door_openings': 4200.0, // оформление дверных проёмов за шт
      'internal_walls': 2400.0, // внутренние стены за м²
      'floor_slab_install': 2200.0, // монтаж плит за м²
      'scaffolding': 25000.0, // леса за компл.
      'labor_box': 35000.0, // работа за компл.
    },
    'facades': {
      'facade_plaster': 1800.0, // штукатурка за м²
      'facade_siding_vinyl': 1200.0, // виниловый сайдинг за м²
      'facade_siding_metal': 1500.0, // металлический сайдинг за м²
      'facade_clinker': 2800.0, // клинкер за м²
      'facade_composite': 3200.0, // композит за м²
      'facade_porcelain': 3500.0, // керамогранит за м²
      'facade_stone': 4200.0, // декор. камень за м²
      'insulation_facade': 850.0, // утепление фасада за м²
      'decorative_elements': 1200.0, // декор элементы за пог.м
      'scaffolding_facade': 18000.0, // леса за компл.
      'window_trims': 2500.0, // откосы/отливы за шт
      'base_finish': 2200.0, // отделка цоколя за пог.м
      'labor_facade': 25000.0, // работа за компл.
    },
    'roofing': {
      'roof_metal_tile': 950.0, // металлочерепица за м²
      'roof_soft': 1200.0, // мягкая кровля за м²
      'roof_prof': 750.0, // профнастил за м²
      'roof_seam': 1400.0, // фальцевая за м²
      'roof_ondulin': 650.0, // ондулин за м²
      'roof_ceramic': 2200.0, // керамическая за м²
      'rafter_system': 1500.0, // стропильная система за м²
      'roof_insulation': 750.0, // утепление кровли за м²
      'waterproofing_membrane': 350.0, // гидро-мембрана за м²
      'vapor_barrier': 250.0, // пароизоляция за м²
      'gutter_system': 850.0, // водосток за пог.м
      'ridge': 650.0, // конёк за пог.м
      'snow_retention': 3500.0, // снегозадержатели за шт
      'labor_roofing': 30000.0, // работа за компл.
    },
    'metal_structures': {
      'metal_fabrication': 180.0, // изготовление за кг
      'metal_installation': 120.0, // монтаж за кг
      'antikorrosion': 65.0, // антикоррозийная за кг
      'bolt_connections': 5500.0, // болтовые соединения компл.
      'welding_work': 1500.0, // сварка за пог.м
      'concrete_foundation_metal': 6500.0, // фундамент под конструкцию за м³
      'delivery_metal': 12000.0, // доставка металла
      'crane_work': 4500.0, // крановые работы за час
      'scaffolding_metal': 15000.0, // леса за компл.
      'labor_metal': 20000.0, // работа за компл.
    },
    'external_networks': {
      'trench_excavation': 1800.0, // земляные работы за м³
      'pipe_installation': 850.0, // прокладка трубы за пог.м
      'pipe_pnd': 350.0, // труба ПНД за пог.м
      'pipe_pvc': 280.0, // труба ПВХ за пог.м
      'pipe_steel': 950.0, // труба стальная за пог.м
      'pipe_cast_iron': 1200.0, // труба чугунная за пог.м
      'pipe_copper': 2500.0, // труба медная за пог.м
      'well_installation': 28000.0, // монтаж колодца за шт
      'horizontal_boring': 4500.0, // ГНБ за пог.м
      'road_crossing': 35000.0, // пересечение дороги
      'water_crossing': 85000.0, // пересечение воды
      'backfill': 650.0, // обратная засыпка за м³
      'restoration_work': 25000.0, // восстановление покрытия
      'labor_networks': 18000.0, // работа за компл.
    },
  };

  /// Текущие цены (могут быть переопределены из UI)
  static Map<String, Map<String, double>> _currentPrices = _deepCopy(
    basePrices,
  );

  static Map<String, Map<String, double>> _deepCopy(
    Map<String, Map<String, double>> source,
  ) {
    return Map.fromEntries(
      source.entries.map((e) => MapEntry(e.key, Map.from(e.value))),
    );
  }

  /// Обновить цену для конкретного типа работ
  static void updatePrice(String workType, String itemId, double newPrice) {
    if (!_currentPrices.containsKey(workType)) {
      _currentPrices[workType] = Map.from(basePrices[workType] ?? {});
    }
    _currentPrices[workType]![itemId] = newPrice;
  }

  /// Сбросить все цены к дефолтным
  static void resetToDefaults() {
    _currentPrices = _deepCopy(basePrices);
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
      case WorkType.foundations:
        total = _calculateFoundations(data, prices);
        break;
      case WorkType.houseConstruction:
        total = _calculateHouseConstruction(data, prices);
        break;
      case WorkType.wallsBox:
        total = _calculateWallsBox(data, prices);
        break;
      case WorkType.facades:
        total = _calculateFacades(data, prices);
        break;
      case WorkType.roofing:
        total = _calculateRoofing(data, prices);
        break;
      case WorkType.metalStructures:
        total = _calculateMetalStructures(data, prices);
        break;
      case WorkType.externalNetworks:
        total = _calculateExternalNetworks(data, prices);
        break;
      case WorkType.fences:
        total = _calculateFences(data, prices);
        break;
      case WorkType.canopies:
        total = _calculateCanopies(data, prices);
        break;
      case WorkType.saunas:
        total = _calculateSaunas(data, prices);
        break;
      case WorkType.pools:
        total = _calculatePools(data, prices);
        break;
      case WorkType.garages:
        total = _calculateGarages(data, prices);
        break;
      case WorkType.ventilation:
        total = _calculateVentilation(data, prices);
        break;
      case WorkType.ventilatedFacades:
        total = _calculateVentilatedFacades(data, prices);
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

    // Используем минимальную ширину из замеров (если есть 3 точки)
    double width = (data['width'] as num?)?.toDouble() ?? 0;
    final widthTop = (data['width_top'] as num?)?.toDouble();
    final widthMiddle = (data['width_middle'] as num?)?.toDouble();
    final widthBottom = (data['width_bottom'] as num?)?.toDouble();
    if (widthTop != null && widthMiddle != null && widthBottom != null) {
      width = [
        widthTop,
        widthMiddle,
        widthBottom,
      ].reduce((a, b) => a < b ? a : b);
    }

    // Используем минимальную высоту из замеров (если есть 3 точки)
    double height = (data['height'] as num?)?.toDouble() ?? 0;
    final heightLeft = (data['height_left'] as num?)?.toDouble();
    final heightMiddle = (data['height_middle'] as num?)?.toDouble();
    final heightRight = (data['height_right'] as num?)?.toDouble();
    if (heightLeft != null && heightMiddle != null && heightRight != null) {
      height = [
        heightLeft,
        heightMiddle,
        heightRight,
      ].reduce((a, b) => a < b ? a : b);
    }

    final area = (width / 1000) * (height / 1000);
    total += area * (prices['frame_per_m2'] ?? 0);

    final glassType = data['glass_type'] as String?;
    if (glassType == 'double') {
      total += area * (prices['glass_double'] ?? 0);
    } else if (glassType == 'energy') {
      total += area * (prices['glass_energy'] ?? 0);
    } else {
      total += area * (prices['glass_single'] ?? 0);
    }

    // Фурнитура с учётом типа открывания
    total += prices['hardware'] ?? 0;
    final openingType = data['opening_type'] as String?;
    if (openingType == 'поворотно-откидное') {
      total += prices['hardware_turn'] ?? 0;
    } else if (openingType == 'раздвижное') {
      total += prices['hardware_slide'] ?? 0;
    }

    // Подоконник — ТОЛЬКО если выбран (ИСПРАВЛЕН БАГ)
    if (data['has_sill'] == true) {
      final sillWidth =
          (data['sill_width'] as num?)?.toDouble() ?? (width / 1000 * 1000);
      total += (sillWidth / 1000) * (prices['sill'] ?? 0);
    }

    // Откосы с учётом типа
    if (data['has_slopes'] == true) {
      final perimeter = 2 * (width / 1000) + (height / 1000);
      final slopeType = data['slope_type'] as String?;
      if (slopeType == 'sandwich') {
        total += perimeter * (prices['slope_sandwich'] ?? 0);
      } else if (slopeType == 'plaster') {
        total += perimeter * (prices['slope_plaster'] ?? 0);
      } else {
        total += perimeter * (prices['slope_plastic'] ?? 0);
      }
    }

    // Отлив
    if (data['has_drip_cap'] == true) {
      final dripCapWidth =
          (data['drip_cap_width'] as num?)?.toDouble() ?? width;
      total += (dripCapWidth / 1000) * (prices['drip_cap'] ?? 0);
    }

    // Проверка геометрии по диагоналям
    final diag1 = (data['diagonal_1'] as num?)?.toDouble();
    final diag2 = (data['diagonal_2'] as num?)?.toDouble();
    if (diag1 != null && diag2 != null) {
      final diff = (diag1 - diag2).abs();
      if (diff > 2.0) {
        total += prices['geometry_correction'] ?? 0;
      }
    }

    // Доставка на высокий этаж (если нет лифта — этаж > 5)
    final floor = (data['floor_number'] as num?)?.toDouble() ?? 0;
    if (floor > 5) {
      total += prices['high_floor_delivery'] ?? 0;
    }

    total += area * (prices['installation'] ?? 0);
    return total;
  }

  static double _calculateDoors(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;

    // Тип двери — разная базовая цена
    final doorType = data['door_type'] as String?;
    if (doorType == 'входная') {
      total += prices['door_entrance'] ?? 0;
    } else if (doorType == 'техническая') {
      total += prices['door_technical'] ?? 0;
    } else {
      total += prices['door_interior'] ?? 0;
    }

    total += prices['door_frame'] ?? 0;

    // Замок с учётом типа
    if (data['has_lock'] == true) {
      final lockType = data['lock_type'] as String?;
      if (lockType == 'сувальдный') {
        total += prices['lock_mortise'] ?? 0;
      } else if (lockType == 'электронный') {
        total += prices['lock_electronic'] ?? 0;
      } else {
        total += prices['lock_cylinder'] ?? 0;
      }
    }

    total += prices['door_handle'] ?? 0;

    // Порог
    if (data['has_threshold'] == true) {
      total += prices['threshold'] ?? 0;
    }

    // Глазок
    if (data['has_peephole'] == true) {
      total += prices['peephole'] ?? 0;
    }

    // Материал отделки — доплата к базовой
    final finishMaterial = data['finish_material'] as String?;
    if (finishMaterial == 'шпон') {
      total += prices['finish_veneer'] ?? 0;
    } else if (finishMaterial == 'экошпон') {
      total += prices['finish_eco'] ?? 0;
    } else if (finishMaterial == 'массив') {
      total += prices['finish_solid'] ?? 0;
    }

    total += prices['door_installation'] ?? 0;

    // Перепад высот в проёме — подгонка полотна
    final floorDiff = (data['floor_level_difference'] as num?)?.toDouble() ?? 0;
    if (floorDiff > 5) {
      total += prices['door_floor_leveling'] ?? 0;
    }

    // Проверка геометрии по 3 точкам ширины
    final widthTop = (data['width_top'] as num?)?.toDouble();
    final widthMiddle = (data['width_middle'] as num?)?.toDouble();
    final widthBottom = (data['width_bottom'] as num?)?.toDouble();
    if (widthTop != null && widthMiddle != null && widthBottom != null) {
      final maxDiff =
          [widthTop, widthMiddle, widthBottom].reduce((a, b) => a > b ? a : b) -
          [widthTop, widthMiddle, widthBottom].reduce((a, b) => a < b ? a : b);
      if (maxDiff > 10) {
        total += prices['door_geometry_correction'] ?? 0;
      }
    }

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

    // Дренажный насос
    if (data['has_drain_pump'] == true) {
      total += prices['ac_drain_pump'] ?? 0;
    }

    // Wi-Fi модуль
    if (data['has_wifi_module'] == true) {
      total += prices['ac_wifi'] ?? 0;
    }

    // Способ прокладки трассы
    final routeMethod = data['route_method'] as String?;
    if (routeMethod == 'В штробе') {
      total += pipeLength * (prices['ac_route_chase'] ?? 0);
    } else if (routeMethod == 'В коробе') {
      total += pipeLength * (prices['ac_route_box'] ?? 0);
    }

    // Доступ к наружному блоку
    final access = data['outdoor_unit_access'] as String?;
    if (access == 'Промышленный альпин') {
      total += prices['ac_alpine'] ?? 0;
    } else if (access == 'Нужны леса') {
      total += prices['ac_scaffolding'] ?? 0;
    }

    // Электроснабжение
    final powerSupply = data['power_supply'] as String?;
    if (powerSupply == 'Нужно проложить кабель до щитка' ||
        powerSupply == 'Отдельная линия от щитка') {
      total += 10 * (prices['ac_power_cable'] ?? 0); // ~10 м кабеля
    }

    // Бурение стены (бетон/кирпич)
    final wallMaterial = data['wall_material'] as String?;
    if (wallMaterial == 'бетон' || wallMaterial == 'кирпич') {
      total += prices['ac_wall_drill'] ?? 0;
    }

    return total;
  }

  static double _calculateKitchen(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final length = (data['kitchen_length'] as num?)?.toDouble() ?? 0;
    final lengthM = length / 1000;

    // Базовая цена за погонный метр
    total += lengthM * (prices['kitchen_lm_meter'] ?? 0);

    // Тип планировки — угловая/П-образная = доп. угловой модуль
    final kitchenType = data['kitchen_type'] as String?;
    if (kitchenType == 'угловая' || kitchenType == 'П-образная') {
      total += prices['kitchen_corner'] ?? 0;
    }
    if (kitchenType == 'с островом') {
      total += prices['kitchen_corner'] ?? 0;
      total += prices['kitchen_island'] ?? 0;
    }

    // Столешница — материал
    final countertopMaterial = data['countertop_material'] as String?;
    if (countertopMaterial == 'МДФ') {
      total += lengthM * (prices['countertop_mdf'] ?? 0);
    } else if (countertopMaterial == 'искусственный камень') {
      total += lengthM * (prices['countertop_artificial_stone'] ?? 0);
    } else if (countertopMaterial == 'натуральный камень') {
      total += lengthM * (prices['countertop_natural_stone'] ?? 0);
    } else {
      total += lengthM * (prices['countertop_ldsp'] ?? 0);
    }

    // Фасады — материал (доплата к базовой)
    final facadeMaterial = data['facade_material'] as String?;
    if (facadeMaterial == 'МДФ эмаль') {
      total += lengthM * (prices['facade_enamel'] ?? 0);
    } else if (facadeMaterial == 'массив') {
      total += lengthM * (prices['facade_solid'] ?? 0);
    } else if (facadeMaterial == 'шпон') {
      total += lengthM * (prices['facade_veneer'] ?? 0);
    } else if (facadeMaterial == 'пластик') {
      total += lengthM * (prices['facade_plastic'] ?? 0);
    }

    // Установка техники
    if (data['has_appliance_install'] == true) {
      final applianceCount = (data['appliance_count'] as num?)?.toDouble() ?? 0;
      total += applianceCount * (prices['kitchen_appliance_install'] ?? 0);
    }

    // Фартук с учётом материала
    if (data['has_backsplash'] == true) {
      final backsplashArea =
          ((data['backsplash_length'] as num?)?.toDouble() ?? 0) / 1000 * 0.6;
      final backsplashMaterial = data['backsplash_material'] as String?;
      if (backsplashMaterial == 'стекло') {
        total += backsplashArea * (prices['backsplash_glass'] ?? 0);
      } else if (backsplashMaterial == 'МДФ') {
        total += backsplashArea * (prices['backsplash_mdf'] ?? 0);
      } else if (backsplashMaterial == 'мозаика') {
        total += backsplashArea * (prices['backsplash_mosaic'] ?? 0);
      } else {
        total += backsplashArea * (prices['backsplash_tile'] ?? 0);
      }
    }

    // Мойка — тип
    final sinkType = data['sink_type'] as String?;
    if (sinkType == 'подстольная') {
      total += (prices['kitchen_sink'] ?? 0) + (prices['sink_undermount'] ?? 0);
    } else {
      total += prices['kitchen_sink'] ?? 0;
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
      // Материал плитки
      final tileMaterial = data['tile_material'] as String?;
      if (tileMaterial == 'Керамогранит') {
        total += area * (prices['tile_material_porcelain'] ?? 0);
      } else if (tileMaterial == 'Мозаика') {
        total += area * (prices['tile_material_mosaic'] ?? 0);
      } else if (tileMaterial == 'Натуральный камень') {
        total += area * (prices['tile_material_stone'] ?? 0);
      } else if (tileMaterial == 'Клинкерная') {
        total += area * (prices['tile_material_clinker'] ?? 0);
      } else {
        total += area * (prices['tile_material_ceramic'] ?? 0);
      }

      // Выбор клея по типу основания
      final baseType = data['base_type'] as String?;
      if (baseType == 'Старая плитка' || baseType == 'Кирпич') {
        total += area * (prices['tile_glue_porcelain'] ?? 0);
      } else if (baseType == 'Мозаика') {
        total += area * (prices['tile_glue_mosaic'] ?? 0);
      } else {
        total +=
            area * (prices['tile_glue_standard'] ?? prices['tile_glue'] ?? 0);
      }

      // Способ укладки
      final layingMethod = data['laying_method'] as String?;
      if (layingMethod == 'Диагональная') {
        total += area * (prices['tile_install_diagonal'] ?? 0);
      } else if (layingMethod == 'Со смещением (кирпич)') {
        total += area * (prices['tile_install_offset'] ?? 0);
      } else if (layingMethod == 'Модульная') {
        total += area * (prices['tile_install_modular'] ?? 0);
      } else if (layingMethod == 'Узор (пэчворк, ёлочка)') {
        total += area * (prices['tile_install_pattern'] ?? 0);
      } else {
        total += area * (prices['tile_install_simple'] ?? 0);
      }

      total += area * (prices['tile_grout'] ?? 0);

      // Выравнивание основания
      const unevenOptions = [
        'Неровное (5–10 мм)',
        'Требует выравнивания (>10 мм)',
      ];
      if (unevenOptions.contains(data['surface_evenness'])) {
        total += area * (prices['tile_leveling'] ?? 0);
      }

      // Запас материала (коэффициент)
      final reserveStr = data['reserve_coefficient'] as String?;
      if (reserveStr != null) {
        final reserve = double.tryParse(reserveStr) ?? 1.0;
        if (reserve > 1.0) {
          total *= reserve;
        }
      }
    }

    // Вырезы под розетки
    if (data['has_sockets'] == true) {
      final socketsCount = (data['sockets_count'] as num?)?.toDouble() ?? 0;
      total += socketsCount * (prices['socket_cutout'] ?? 0);
    }

    // Декоративные вставки
    if (data['has_decorative_inserts'] == true) {
      final insertsCount =
          (data['decorative_inserts_count'] as num?)?.toDouble() ?? 0;
      total += insertsCount * (prices['decorative_insert'] ?? 0);
    }

    // Тёплый пол
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

    // Используем минимальную длину стены из замеров (если есть 3 точки)
    double wallLength = (data['wall_length'] as num?)?.toDouble() ?? 0;
    final wallTop = (data['wall_length_top'] as num?)?.toDouble();
    final wallMiddle = (data['wall_length_middle'] as num?)?.toDouble();
    final wallBottom = (data['wall_length_bottom'] as num?)?.toDouble();
    if (wallTop != null && wallMiddle != null && wallBottom != null) {
      wallLength = [
        wallTop,
        wallMiddle,
        wallBottom,
      ].reduce((a, b) => a < b ? a : b);
    }

    // Используем минимальную высоту потолка (если есть 3 точки)
    double ceilingHeight = (data['ceiling_height'] as num?)?.toDouble() ?? 0;
    final ceilLeft = (data['ceiling_height_left'] as num?)?.toDouble();
    final ceilMiddle = (data['ceiling_height_middle'] as num?)?.toDouble();
    final ceilRight = (data['ceiling_height_right'] as num?)?.toDouble();
    if (ceilLeft != null && ceilMiddle != null && ceilRight != null) {
      ceilingHeight = [
        ceilLeft,
        ceilMiddle,
        ceilRight,
      ].reduce((a, b) => a < b ? a : b);
    }

    final area = (wallLength / 1000) * (ceilingHeight / 1000);

    // Материал корпуса
    if (bodyMaterial == 'ЛДСП') {
      total += area * (prices['ldsp_per_m2'] ?? 0);
    } else if (bodyMaterial == 'МДФ') {
      total += area * (prices['mdf_per_m2'] ?? 0);
    } else if (bodyMaterial == 'Массив') {
      total += area * (prices['solid_per_m2'] ?? 0);
    }

    total += area * (prices['facade_per_m2'] ?? 0);

    // Тип мебели — встроенная = доплата
    final furnitureType = data['furniture_type'] as String?;
    if (furnitureType == 'Встроенный') {
      total += area * (prices['builtin_surcharge'] ?? 0);
    }

    // Тип дверей — раздвижные = доплата
    final doorType = data['door_type'] as String?;
    if (doorType == 'Раздвижные (купе)') {
      total += prices['door_sliding'] ?? 0;
    }

    // Выдвижные ящики
    if (data['has_drawers'] == true) {
      final drawersCount = (data['drawers_count'] as num?)?.toDouble() ?? 0;
      total += drawersCount * (prices['drawer_mechanism'] ?? 0);
    }

    // Антресоль
    if (data['has_mezzanine'] == true) {
      total += prices['mezzanine'] ?? 0;
    }

    // Открытые полки
    if (data['has_open_shelves'] == true) {
      total += prices['open_shelf'] ?? 0;
    }

    // Штанги
    if (data['has_rods'] == true) {
      total += prices['rod'] ?? 0;
    }

    // Пантограф
    if (data['has_pantograph'] == true) {
      total += prices['pantograph'] ?? 0;
    }

    // Кромка — тип и толщина
    final edgeType = data['edge_type'] as String?;
    if (edgeType == 'АБС') {
      total += wallLength / 1000 * (prices['edge_abs'] ?? 0);
    }
    final edgeThickness = data['edge_thickness'] as String?;
    if (edgeThickness == '1') {
      total += prices['edge_medium'] ?? 0;
    } else if (edgeThickness == '2') {
      total += prices['edge_thick'] ?? 0;
    }

    total += (wallLength / 1000) * (prices['furniture_assembly'] ?? 0);

    // Ниши — индивидуальная работа
    if (data['has_niches'] == true) {
      total += prices['niche_custom_work'] ?? 0;
    }

    // Скошенные углы
    if (data['has_skewed_corners'] == true) {
      total += prices['skewed_corner'] ?? 0;
    }

    // Колонны
    if (data['has_columns'] == true) {
      total += prices['column_cutout'] ?? 0;
    }

    // Обход трубы
    if (data['has_heating_pipe'] == true) {
      total += prices['pipe_cutout'] ?? 0;
    }

    // Розетки/выключатели — вырезы
    if (data['has_sockets_switches'] == true) {
      total += prices['socket_cutout'] ?? 0;
    }

    // Кривизна стен — компенсация зазора
    final curvature = (data['wall_curvature'] as num?)?.toDouble() ?? 0;
    if (curvature > 5) {
      total += prices['wall_curvature_compensation'] ?? 0;
    }

    return total;
  }

  static double _calculateEngineering(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final systemType = data['system_type'] as String?;

    // Утепление (общее для всех систем)
    if (data['has_insulation'] == true) {
      final roomArea = (data['room_area'] as num?)?.toDouble() ?? 0;
      if (roomArea > 0) {
        total += roomArea * (prices['insulation_per_m2'] ?? 0);
      }
    }

    // Утепление пола
    if (data['has_floor_insulation'] == true) {
      final roomArea = (data['room_area'] as num?)?.toDouble() ?? 0;
      if (roomArea > 0) {
        total += roomArea * (prices['insulation_per_m2'] ?? 0);
      }
    }

    if (systemType == 'Котельная') {
      final boilerType = data['boiler_type'] as String?;
      if (boilerType == 'Газовый') {
        total += prices['boiler_gas'] ?? 0;
      } else if (boilerType == 'Электрический') {
        total += prices['boiler_electric'] ?? 0;
      } else if (boilerType == 'Твёрдотопливный') {
        total += prices['boiler_solid'] ?? 0;
      } else if (boilerType == 'Жидкотопливный') {
        total += prices['boiler_liquid'] ?? 0;
      }

      // Доплата за мощность (свыше 10 кВт)
      final boilerPower = (data['boiler_power'] as num?)?.toDouble() ?? 0;
      if (boilerPower > 10) {
        total += (boilerPower - 10) * (prices['boiler_power_kw'] ?? 0);
      }

      // Монтаж котла
      final boilerPosition = data['boiler_position'] as String?;
      if (boilerPosition == 'Напольный') {
        total += prices['boiler_floor_mount'] ?? 0;
      } else {
        total += prices['boiler_wall_mount'] ?? 0;
      }

      // Дымоход
      final chimneyHeight = (data['chimney_height'] as num?)?.toDouble() ?? 0;
      if (chimneyHeight > 0) {
        total += chimneyHeight * (prices['chimney_install'] ?? 0);
      }
    }

    if (systemType == 'Отопление') {
      // Тип радиаторов
      final radiatorType = data['radiator_type'] as String?;
      final sectionsCount =
          (data['radiator_sections_count'] as num?)?.toDouble() ?? 0;
      if (radiatorType == 'Биметалл') {
        total += sectionsCount * (prices['radiator_section_bimetal'] ?? 0);
      } else if (radiatorType == 'Алюминий') {
        total += sectionsCount * (prices['radiator_section_aluminum'] ?? 0);
      } else if (radiatorType == 'Чугун') {
        total += sectionsCount * (prices['radiator_section_castiron'] ?? 0);
      } else {
        total += sectionsCount * (prices['radiator_section'] ?? 0);
      }

      // Тип системы отопления
      final heatingSystemType = data['heating_system_type'] as String?;
      if (heatingSystemType == 'Тёплый пол (водяной)') {
        final roomArea = (data['room_area'] as num?)?.toDouble() ?? 0;
        total += roomArea * (prices['warm_floor_water_per_m2'] ?? 0);
      } else if (heatingSystemType == 'Тёплый пол (электрический)') {
        final roomArea = (data['room_area'] as num?)?.toDouble() ?? 0;
        total += roomArea * (prices['warm_floor_electric_per_m2'] ?? 0);
      }

      // Материал труб
      final pipesMaterial = data['pipes_material'] as String?;
      final pipesLength = (data['room_area'] as num?)?.toDouble() ?? 0;
      if (pipesMaterial == 'Сшитый полиэтилен' || pipesMaterial == 'PEX') {
        total += pipesLength * (prices['pipe_pex_per_m'] ?? 0);
      } else {
        total += pipesLength * (prices['pipe_pp_per_m'] ?? 0);
      }

      // Скрытая прокладка
      final pipesInstallation = data['pipes_installation'] as String?;
      if (pipesInstallation == 'Скрытая') {
        total += pipesLength * (prices['pipe_concealed'] ?? 0);
      }

      // Тёплый пол — контуры
      final floorContours =
          (data['floor_heating_contours'] as num?)?.toDouble() ?? 0;
      if (floorContours > 0) {
        total += floorContours * (prices['collector'] ?? 0);
        final contourLength =
            (data['floor_heating_contour_length'] as num?)?.toDouble() ?? 0;
        total +=
            floorContours * contourLength * (prices['pipe_pex_per_m'] ?? 0);
      }
    }

    if (systemType == 'Водоснабжение') {
      // Фильтры
      if (data['has_filters'] == true) {
        total += prices['filter'] ?? 0;
      }

      // Счётчик воды
      if (data['has_water_meter'] == true) {
        total += prices['water_meter'] ?? 0;
      }

      // Трубы
      final pipeDiameter =
          (data['input_pipe_diameter'] as num?)?.toDouble() ?? 0;
      final roomArea = (data['room_area'] as num?)?.toDouble() ?? 0;
      if (pipeDiameter > 32) {
        total += roomArea * (prices['pipe_pex_per_m'] ?? 0);
      } else {
        total += roomArea * (prices['pipe_pp_per_m'] ?? 0);
      }
    }

    if (systemType == 'Канализация') {
      final roomArea = (data['room_area'] as num?)?.toDouble() ?? 0;
      total += roomArea * (prices['sewage_pipe_per_m'] ?? 0);

      // Трапы
      if (data['has_floor_drains'] == true) {
        total += prices['floor_drain'] ?? 0;
      }
    }

    if (systemType == 'Вентиляция') {
      final valvesCount =
          (data['intake_valves_count'] as num?)?.toDouble() ?? 0;
      final ventilationType = data['ventilation_type'] as String?;
      if (ventilationType == 'Принудительная') {
        total += valvesCount * (prices['ventilation_forced'] ?? 0);
      } else {
        total += valvesCount * (prices['ventilation_install'] ?? 0);
      }

      // Рекуператор
      if (data['has_recuperator'] == true) {
        total += prices['recuperator'] ?? 0;
      }
    }

    // Расчёт теплопотерь (если есть данные для расчёта)
    if (data['wall_material'] != null && data['room_area'] != null) {
      total += prices['heat_loss_calculation'] ?? 0;
    }

    return total;
  }

  static double _calculateElectrical(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;

    // Розетки
    final socketsCount = (data['sockets_count'] as num?)?.toDouble() ?? 0;
    total += socketsCount * (prices['socket'] ?? 0);

    // Освещение
    final lightingCount = (data['lighting_count'] as num?)?.toDouble() ?? 0;
    total += lightingCount * (prices['light_point'] ?? 0);

    // Тип выключателей
    final switchesType = data['switches_type'] as String?;
    if (switchesType != null && switchesType.contains('проходной')) {
      total += lightingCount * (prices['switch_pass'] ?? 0);
    } else if (switchesType != null && switchesType.contains('диммер')) {
      total += lightingCount * (prices['switch_dimmer'] ?? 0);
    } else {
      total += socketsCount * (prices['switch'] ?? 0);
    }

    // Трассы кабеля
    final wallRoutes = (data['wall_routes_length'] as num?)?.toDouble() ?? 0;
    final floorRoutes = (data['floor_routes_length'] as num?)?.toDouble() ?? 0;
    final ceilingRoutes =
        (data['ceiling_routes_length'] as num?)?.toDouble() ?? 0;
    final totalRouteLength = wallRoutes + floorRoutes + ceilingRoutes;
    total += totalRouteLength * (prices['cable_routing_per_m'] ?? 0);

    // Марка кабеля
    final cableBrand = data['cable_brand'] as String?;
    if (cableBrand == 'NYM') {
      total += totalRouteLength * (prices['cable_nym_per_m'] ?? 0);
    } else {
      total += totalRouteLength * (prices['cable_vvg_per_m'] ?? 0);
    }

    // Скрытая прокладка
    final cableRouting = data['cable_routing'] as String?;
    if (cableRouting == 'Скрытая' || cableRouting == 'В штробе') {
      total += totalRouteLength * (prices['cable_concealed'] ?? 0);
    }

    // Щиток
    total += prices['panel_assembly'] ?? 0;

    // 3-фазный ввод
    final inputVoltage = data['input_voltage'] as String?;
    if (inputVoltage == 'Трёхфазный 380В') {
      total += prices['panel_3phase'] ?? 0;
    }

    // Автоматы (кол-во отходящих линий)
    final circuitsCount = (data['circuits_count'] as num?)?.toDouble() ?? 0;
    if (circuitsCount > 0) {
      total += circuitsCount * (prices['circuit_breaker'] ?? 0);
    }

    // УЗО
    if (data['has_rcd'] == true) {
      total += prices['rcd_single'] ?? 0;
      final rcdLeakage = data['rcd_leakage_current'] as String?;
      if (rcdLeakage == '10') {
        total += prices['rcd_leakage_10'] ?? 0;
      } else if (rcdLeakage == '100') {
        total += prices['rcd_leakage_100'] ?? 0;
      }
    }

    // Молниезащита
    if (data['has_lightning_protection'] == true) {
      total += prices['lightning_protection'] ?? 0;
    }

    // Заземление
    if (data['has_grounding_circuit'] == true) {
      total += prices['grounding_circuit'] ?? 0;
    }

    // Интернет/ТВ
    if (data['has_internet_tv'] == true) {
      final internetSockets =
          (data['internet_tv_sockets_count'] as num?)?.toDouble() ?? 0;
      total += internetSockets * (prices['internet_socket'] ?? 0);
    }

    // Видеонаблюдение
    if (data['has_cctv'] == true) {
      total += prices['cctv_point'] ?? 0;
    }

    // Умный дом
    if (data['has_smart_home'] == true) {
      total += prices['smart_home_point'] ?? 0;
    }

    return total;
  }

  // ===== Расчёты для строительства ИЖС =====

  static double _calculateFoundations(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final length = (data['foundation_length'] as num?)?.toDouble() ?? 0;
    final width = (data['foundation_width'] as num?)?.toDouble() ?? 0;
    final depth = (data['foundation_depth'] as num?)?.toDouble() ?? 0;
    final height = (data['foundation_height'] as num?)?.toDouble() ?? 500;

    // Объём бетона (м³)
    final concreteVolume = length / 1000 * width / 1000 * depth / 1000;
    total += concreteVolume * (prices['concrete_work'] ?? 0);

    // Опалубка (м²) — периметр * высота
    final formworkArea = (length + width) / 1000 * (depth + height) / 1000 * 2;
    total += formworkArea * (prices['formwork'] ?? 0);

    // Арматура (приблизительно: 4 продольных стержня * длина)
    if (data['has_reinforcement'] == true) {
      final reinfLength =
          (length + width) / 1000 * 4 * 1.5; // 4 прутка + перехлёст
      total += reinfLength * (prices['reinforcement'] ?? 0);
    }

    // Песчаная подушка
    if (data['has_sand_cushion'] == true) {
      final sandVolume = length / 1000 * width / 1000 * 0.3;
      total += sandVolume * (prices['sand_cushion'] ?? 0);
    }

    // Гидроизоляция
    if (data['has_waterproofing'] == true) {
      final waterproofArea = length / 1000 * width / 1000;
      total += waterproofArea * (prices['waterproofing'] ?? 0);
    }

    // Земляные работы
    total += concreteVolume * (prices['excavation'] ?? 0);

    // Дренаж
    if (data['has_drainage'] == true) {
      total += length / 1000 * (prices['drainage'] ?? 0);
    }

    // Геотекстиль
    total += length / 1000 * width / 1000 * (prices['geotextile'] ?? 0);

    // Доставка бетона
    total += concreteVolume * (prices['delivery_concrete'] ?? 0);

    // Работа
    total += prices['labor_foundation'] ?? 0;

    return total;
  }

  static double _calculateHouseConstruction(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final houseArea = (data['house_area'] as num?)?.toDouble() ?? 0;
    final floorsCount = _parseSelectCount(data['floors_count']);

    // Стены (площадь стен ≈ 40% площади этажа * этажность)
    final wallArea = houseArea * 0.4 * floorsCount;
    total += wallArea * (prices['wall_construction'] ?? 0);

    // Перекрытия
    total += houseArea * (prices['ceiling_installation'] ?? 0);

    // Перегородки (≈ 15% площади этажа)
    total += houseArea * 0.15 * (prices['partition_install'] ?? 0);

    // Кровля (площадь кровли ≈ 60% площади дома)
    total += houseArea * 0.6 * (prices['roof_installation'] ?? 0);

    // Окна
    final windowCount = (data['window_count'] as num?)?.toDouble() ?? 0;
    total += windowCount * (prices['window_installation'] ?? 0);

    // Двери
    final doorCount = (data['door_count'] as num?)?.toDouble() ?? 0;
    total += doorCount * (prices['door_installation'] ?? 0);

    // Черновая отделка
    if (data['rough_finish'] == true) {
      total += houseArea * floorsCount * (prices['rough_finish'] ?? 0);
    }

    // Гараж
    if (data['has_garage'] == true) {
      final garageArea = (data['garage_area'] as num?)?.toDouble() ?? 0;
      total += garageArea * (prices['garage_construction'] ?? 0);
    }

    // Подвал
    if (data['has_basement'] == true) {
      total += houseArea * 0.3 * (prices['basement_construction'] ?? 0);
    }

    // Управление проектом и подготовка площадки
    total += prices['project_management'] ?? 0;
    total += prices['site_preparation'] ?? 0;

    return total;
  }

  static double _calculateWallsBox(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final perimeter = (data['perimeter'] as num?)?.toDouble() ?? 0;
    final wallHeight = (data['wall_height'] as num?)?.toDouble() ?? 0;
    final wallArea = perimeter * wallHeight;

    // Вычет проёмов
    final windowCount = (data['window_count'] as num?)?.toDouble() ?? 0;
    final windowAvgW = (data['window_avg_width'] as num?)?.toDouble() ?? 1200;
    final windowAvgH = (data['window_avg_height'] as num?)?.toDouble() ?? 1400;
    final windowArea = windowCount * windowAvgW / 1000 * windowAvgH / 1000;

    final doorCount = (data['door_ext_count'] as num?)?.toDouble() ?? 0;
    final doorArea = doorCount * 1.0 * 2.1;

    final netWallArea = wallArea - windowArea - doorArea;
    total += netWallArea * (prices['wall_block'] ?? 0);

    // Утепление
    total += wallArea * 0.8 * (prices['insulation'] ?? 0);

    // Армопояс
    if (data['has_armo_poyas'] == true) {
      total += perimeter * (prices['armo_poyas'] ?? 0);
    }

    // Оформление проёмов
    total += windowCount * (prices['window_openings'] ?? 0);
    total += doorCount * (prices['door_openings'] ?? 0);

    // Внутренние несущие стены
    if (data['has_internal_walls'] == true) {
      final intWallLength =
          (data['internal_wall_length'] as num?)?.toDouble() ?? 0;
      total += intWallLength * wallHeight * (prices['internal_walls'] ?? 0);
    }

    // Плиты перекрытия (приблизительная площадь = периметр²/4)
    final floorArea = perimeter * perimeter / 4 / 100;
    total += floorArea * (prices['floor_slab_install'] ?? 0);

    // Леса
    total += prices['scaffolding'] ?? 0;

    // Работа
    total += prices['labor_box'] ?? 0;

    return total;
  }

  static double _calculateFacades(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final facadeArea = (data['facade_area'] as num?)?.toDouble() ?? 0;

    // Отделка фасада — выбираем по типу
    final facadeType = data['facade_type'] as String?;
    switch (facadeType) {
      case 'Штукатурка (мокрый)':
        total += facadeArea * (prices['facade_plaster'] ?? 0);
        break;
      case 'Сайдинг виниловый':
        total += facadeArea * (prices['facade_siding_vinyl'] ?? 0);
        break;
      case 'Сайдинг металлический':
        total += facadeArea * (prices['facade_siding_metal'] ?? 0);
        break;
      case 'Клинкерная плитка':
        total += facadeArea * (prices['facade_clinker'] ?? 0);
        break;
      case 'Композитные панели':
        total += facadeArea * (prices['facade_composite'] ?? 0);
        break;
      case 'Керамогранит':
        total += facadeArea * (prices['facade_porcelain'] ?? 0);
        break;
      case 'Декоративный камень':
        total += facadeArea * (prices['facade_stone'] ?? 0);
        break;
      default:
        total += facadeArea * (prices['facade_plaster'] ?? 0);
    }

    // Утепление
    if (data['has_insulation'] == true) {
      total += facadeArea * (prices['insulation_facade'] ?? 0);
    }

    // Декоративные элементы
    if (data['has_decor_elements'] == true) {
      total += facadeArea * 0.1 * (prices['decorative_elements'] ?? 0);
    }

    // Леса
    if (data['needs_scaffolding'] == true) {
      total += prices['scaffolding_facade'] ?? 0;
    }

    // Откосы и отливы
    if (data['window_trim'] == true) {
      total += facadeArea * 0.05 * (prices['window_trims'] ?? 0);
    }

    // Цоколь
    final baseFinish = data['base_finish'] as String?;
    if (baseFinish != null && baseFinish != 'Не отделывается') {
      total += facadeArea * 0.15 * (prices['base_finish'] ?? 0);
    }

    // Работа
    total += prices['labor_facade'] ?? 0;

    return total;
  }

  static double _calculateRoofing(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final roofArea = (data['roof_area'] as num?)?.toDouble() ?? 0;
    final buildingWidth = (data['building_width'] as num?)?.toDouble() ?? 0;
    final buildingLength = (data['building_length'] as num?)?.toDouble() ?? 0;

    // Кровельный материал
    final roofMaterial = data['roof_material'] as String?;
    switch (roofMaterial) {
      case 'Металлочерепица':
        total += roofArea * (prices['roof_metal_tile'] ?? 0);
        break;
      case 'Мягкая кровля (гибкая)':
        total += roofArea * (prices['roof_soft'] ?? 0);
        break;
      case 'Профнастил':
        total += roofArea * (prices['roof_prof'] ?? 0);
        break;
      case 'Фальцевая':
        total += roofArea * (prices['roof_seam'] ?? 0);
        break;
      case 'Ондулин':
        total += roofArea * (prices['roof_ondulin'] ?? 0);
        break;
      case 'Керамическая черепица':
        total += roofArea * (prices['roof_ceramic'] ?? 0);
        break;
      default:
        total += roofArea * (prices['roof_metal_tile'] ?? 0);
    }

    // Стропильная система
    total += roofArea * (prices['rafter_system'] ?? 0);

    // Утепление
    if (data['has_insulation'] == true) {
      total += roofArea * (prices['roof_insulation'] ?? 0);
    }

    // Гидро-мембрана
    if (data['has_waterproofing_membrane'] == true) {
      total += roofArea * (prices['waterproofing_membrane'] ?? 0);
    }

    // Пароизоляция
    if (data['has_vapor_barrier'] == true) {
      total += roofArea * (prices['vapor_barrier'] ?? 0);
    }

    // Водосток
    if (data['has_gutter'] == true) {
      final gutterLength = (buildingWidth + buildingLength) / 1000 * 2;
      total += gutterLength * (prices['gutter_system'] ?? 0);
    }

    // Конёк
    total += buildingLength / 1000 * (prices['ridge'] ?? 0);

    // Снегозадержатели
    if (data['has_snow_retention'] == true) {
      total += (roofArea / 20).ceil() * (prices['snow_retention'] ?? 0);
    }

    // Работа
    total += prices['labor_roofing'] ?? 0;

    return total;
  }

  static double _calculateMetalStructures(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final metalWeight = (data['metal_weight'] as num?)?.toDouble() ?? 0;
    final structLength = (data['structure_length'] as num?)?.toDouble() ?? 0;
    final structHeight = (data['structure_height'] as num?)?.toDouble() ?? 0;

    // Изготовление металлоконструкций
    total += metalWeight * (prices['metal_fabrication'] ?? 0);

    // Монтаж
    total += metalWeight * (prices['metal_installation'] ?? 0);

    // Антикоррозийная обработка
    if (data['has_antikorrosion'] == true) {
      total += metalWeight * (prices['antikorrosion'] ?? 0);
    }

    // Сварка
    total += structLength / 1000 * 3 * (prices['welding_work'] ?? 0);

    // Болтовые соединения
    total += prices['bolt_connections'] ?? 0;

    // Фундамент под конструкцию
    if (data['has_concrete_foundation'] == true) {
      final structWidth = (data['structure_width'] as num?)?.toDouble() ?? 0;
      final foundationVolume = structLength / 1000 * structWidth / 1000 * 0.5;
      total += foundationVolume * (prices['concrete_foundation_metal'] ?? 0);
    }

    // Доставка
    if (data['has_delivery'] == true) {
      total += prices['delivery_metal'] ?? 0;
    }

    // Крановые работы (зависит от высоты)
    total += structHeight * 2 * (prices['crane_work'] ?? 0);

    // Леса (если высота > 3м)
    if (structHeight > 3000) {
      total += prices['scaffolding_metal'] ?? 0;
    }

    // Работа
    total += prices['labor_metal'] ?? 0;

    return total;
  }

  static double _calculateExternalNetworks(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;
    final trenchLength = (data['trench_length'] as num?)?.toDouble() ?? 0;
    final trenchDepth = (data['trench_depth'] as num?)?.toDouble() ?? 0;
    final trenchWidth = (data['trench_width'] as num?)?.toDouble() ?? 600;

    // Земляные работы (м³)
    final trenchVolume = trenchLength * trenchDepth * trenchWidth / 1000;
    total += trenchVolume * (prices['trench_excavation'] ?? 0);

    // Прокладка трубы (пог.м)
    total += trenchLength * (prices['pipe_installation'] ?? 0);

    // Материал трубы
    final pipeMaterial = data['pipe_material'] as String?;
    switch (pipeMaterial) {
      case 'ПНД':
        total += trenchLength * (prices['pipe_pnd'] ?? 0);
        break;
      case 'ПВХ':
        total += trenchLength * (prices['pipe_pvc'] ?? 0);
        break;
      case 'Сталь':
        total += trenchLength * (prices['pipe_steel'] ?? 0);
        break;
      case 'Чугун':
        total += trenchLength * (prices['pipe_cast_iron'] ?? 0);
        break;
      case 'Медь':
        total += trenchLength * (prices['pipe_copper'] ?? 0);
        break;
      case 'Полипропилен':
      case 'Стеклопластик':
        total += trenchLength * (prices['pipe_pnd'] ?? 0);
        break;
    }

    // Колодцы
    if (data['has_wells'] == true) {
      final wellsCount = (data['wells_count'] as num?)?.toDouble() ?? 0;
      total += wellsCount * (prices['well_installation'] ?? 0);
    }

    // Горизонтальное бурение
    if (data['has_horizontal_boring'] == true) {
      final boringLength = (data['boring_length'] as num?)?.toDouble() ?? 0;
      total += boringLength * (prices['horizontal_boring'] ?? 0);
    }

    // Пересечение дорог
    if (data['has_road_crossing'] == true) {
      total += prices['road_crossing'] ?? 0;
    }

    // Пересечение воды
    if (data['has_water_crossing'] == true) {
      total += prices['water_crossing'] ?? 0;
    }

    // Обратная засыпка
    total += trenchVolume * (prices['backfill'] ?? 0);

    // Восстановление покрытия
    if (data['restoration_work'] == true) {
      total += prices['restoration_work'] ?? 0;
    }

    // Работа
    total += prices['labor_networks'] ?? 0;

    return total;
  }

  /// Парсинг select-значения с количеством этажей
  static int _parseSelectCount(dynamic value) {
    if (value == null) return 1;
    final str = value.toString();
    if (str.contains('1.5')) return 2;
    if (str.contains('2')) return 2;
    if (str.contains('3')) return 3;
    return 1;
  }

  /// Расчёт стоимости заборов
  static double _calculateFences(
    Map<String, dynamic> data,
    Map<String, double> prices,
  ) {
    double total = 0;

    final length = (data['fence_length'] as num?)?.toDouble() ?? 0;
    final height = (data['fence_height'] as num?)?.toDouble() ?? 0;
    final fenceType = data['fence_type'] as String?;
    final sectionCount = (data['section_count'] as num?)?.toDouble() ?? 0;
    final gateCount = (data['gate_count'] as num?)?.toDouble() ?? 0;
    final walkGateCount = (data['walk_gate_count'] as num?)?.toDouble() ?? 0;

    // Основное полотно забора (за м²)
    if (length > 0 && height > 0 && fenceType != null) {
      double area = length * height;
      double pricePerArea = 0;

      switch (fenceType) {
        case 'профнастил':
          pricePerArea = prices['profnastil_per_m2'] ?? 0;
          break;
        case 'штакетник_металлический':
          pricePerArea = prices['metal_shtaketnik_per_m2'] ?? 0;
          break;
        case 'штакетник_деревянный':
          pricePerArea = prices['wood_shtaketnik_per_m2'] ?? 0;
          break;
        case 'деревянный_сплошной':
          pricePerArea = prices['wood_solid_per_m2'] ?? 0;
          break;
        case 'сетка_рабица':
          pricePerArea = prices['rabitz_per_m2'] ?? 0;
          break;
        case 'секционный':
          pricePerArea = prices['section_fence_per_m2'] ?? 0;
          break;
        case 'кирпичный':
          pricePerArea = prices['brick_fence_per_m2'] ?? 0;
          break;
        case 'бетонный':
          pricePerArea = prices['concrete_fence_per_m2'] ?? 0;
          break;
        case 'кованый':
          pricePerArea = prices['forged_fence_per_m2'] ?? 0;
          break;
      }

      total += area * pricePerArea;
    }

    // Секции
    if (sectionCount > 0) {
      total += sectionCount * (prices['section_installation'] ?? 0);
    }

    // Ворота
    if (gateCount > 0) {
      total += gateCount * (prices['gate_installation'] ?? 0);

      final gateWidth = (data['gate_width'] as num?)?.toDouble() ?? 0;
      if (gateWidth > 0) {
        total += gateWidth * (prices['gate_per_meter'] ?? 0);
      }

      if (data['gate_automat'] == true) {
        total += gateCount * (prices['gate_automation'] ?? 0);
      }

      if (data['gate_opening'] == true) {
        total += gateCount * (prices['walk_gate_separate'] ?? 0);
      }
    }

    // Калитки
    if (walkGateCount > 0) {
      total += walkGateCount * (prices['walk_gate_installation'] ?? 0);

      final walkGateWidth = (data['walk_gate_width'] as num?)?.toDouble() ?? 0;
      if (walkGateWidth > 0) {
        total += walkGateWidth * (prices['walk_gate_per_meter'] ?? 0);
      }
    }

    // Столбы
    final postMaterial = data['post_material'] as String?;
    final postDistance = (data['post_distance'] as num?)?.toDouble() ?? 0;
    if (length > 0 && postDistance > 0) {
      final postCount = (length / postDistance).ceil();
      double postPrice = 0;

      switch (postMaterial) {
        case 'металлические':
          postPrice = prices['metal_post'] ?? 0;
          break;
        case 'кирпичные':
          postPrice = prices['brick_post'] ?? 0;
          break;
        case 'бетонные':
          postPrice = prices['concrete_post'] ?? 0;
          break;
        case 'деревянные':
          postPrice = prices['wood_post'] ?? 0;
          break;
      }

      total += postCount * postPrice;
    }

    // Фундамент
    final foundationType = data['foundation_type'] as String?;
    if (foundationType != null && foundationType != 'нет') {
      double foundationPrice = 0;

      switch (foundationType) {
        case 'ленточный':
          foundationPrice = prices['strip_foundation_per_m'] ?? 0;
          break;
        case 'столбчатый':
          foundationPrice = prices['column_foundation_per_unit'] ?? 0;
          break;
        case 'бетонные площадки':
          foundationPrice = prices['concrete_pad_installation'] ?? 0;
          break;
      }

      total += length * foundationPrice;
    }

    // Колпаки на столбы
    if (data['has_capstones'] == true) {
      final postDistance = (data['post_distance'] as num?)?.toDouble() ?? 0;
      if (length > 0 && postDistance > 0) {
        final postCount = (length / postDistance).ceil();
        total += postCount * (prices['capstone'] ?? 0);
      }
    }

    // Лаги
    if (data['has_lags'] == true) {
      final lagsCount = (data['lags_count'] as num?)?.toDouble() ?? 2;
      total += length * lagsCount * (prices['lag_per_meter'] ?? 0);
    }

    // Заземление
    if (data['has_grounding'] == true) {
      total += prices['grounding_installation'] ?? 0;
    }

    // Демонтаж старого забора
    if (data['existing_fence'] == true) {
      total += length * (prices['fence_dismantling_per_m'] ?? 0);
    }

    // Работа
    total += prices['fence_labor'] ?? 0;

    return total;
  }
}
