import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Результат голосового распознавания
class VoiceInputResult {
  final String recognizedText;
  final bool isFinal;
  final double confidence;

  const VoiceInputResult({
    required this.recognizedText,
    this.isFinal = false,
    this.confidence = 0.0,
  });
}

/// Сервис голосового ввода для замеров
/// Распознаёт речь и извлекает структурированные данные для ВСЕХ 15 специализаций
class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _currentText = '';

  // Callback для обновления UI в реальном времени
  Function(VoiceInputResult)? onResult;

  bool get isListening => _isListening;
  bool get isAvailable => _speech.isAvailable;
  String get currentText => _currentText;

  /// Инициализация сервиса
  Future<bool> initialize() async {
    try {
      final available = await _speech.initialize(
        onError: (error) {
          _isListening = false;
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return available;
    } catch (e) {
      return false;
    }
  }

  /// Запрос разрешения на запись микрофона
  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Начать распознавание речи
  Future<bool> startListening({String? localeId}) async {
    if (_isListening) return false;

    try {
      final hasPermission = await _requestMicPermission();
      if (!hasPermission) return false;

      if (!_speech.isAvailable) {
        final available = await initialize();
        if (!available) return false;
      }

      _currentText = '';

      final started = await _speech.listen(
        onResult: (result) {
          _currentText = result.recognizedWords;
          onResult?.call(
            VoiceInputResult(
              recognizedText: _currentText,
              isFinal: result.finalResult,
              confidence: result.confidence,
            ),
          );
        },
        localeId: localeId ?? 'ru_RU',
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );

      if (started) _isListening = true;
      return started;
    } catch (e) {
      _isListening = false;
      return false;
    }
  }

  /// Остановить распознавание
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  /// Отменить распознавание
  Future<void> cancelListening() async {
    await stopListening();
    _currentText = '';
  }

  /// Извлечь структурированные данные из распознанного текста
  /// Для окон — использует extractDataForWindows
  /// Для дверей — extractDataForDoors и т.д.
  Map<String, dynamic> extractDataForWorkType(String text, String workTypeKey) {
    switch (workTypeKey) {
      case 'windows':
        return extractDataForWindows(text);
      case 'doors':
        return extractDataForDoors(text);
      case 'air_conditioners':
        return extractDataForAirConditioners(text);
      case 'kitchens':
        return extractDataForKitchens(text);
      case 'tiles':
        return extractDataForTiles(text);
      case 'furniture':
        return extractDataForFurniture(text);
      case 'engineering':
        return extractDataForEngineering(text);
      case 'electrical':
        return extractDataForElectrical(text);
      case 'foundations':
        return extractDataForFoundations(text);
      case 'house_construction':
        return extractDataForHouseConstruction(text);
      case 'walls_box':
        return extractDataForWallsBox(text);
      case 'facades':
        return extractDataForFacades(text);
      case 'roofing':
        return extractDataForRoofing(text);
      case 'metal_structures':
        return extractDataForMetalStructures(text);
      case 'external_networks':
        return extractDataForExternalNetworks(text);
      case 'fences':
        return extractDataForFences(text);
      case 'canopies':
        return extractDataForCanopies(text);
      case 'saunas':
        return extractDataForSaunas(text);
      case 'pools':
        return extractDataForPools(text);
      case 'garages':
        return extractDataForGarages(text);
      case 'ventilation':
        return extractDataForVentilation(text);
      case 'ventilated_facades':
        return extractDataForVentilatedFacades(text);
      default:
        return extractDataForWindows(text);
    }
  }

  // ===== ОКНА =====
  Map<String, dynamic> extractDataForWindows(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Ширина окна (мм)
    final width = _extractDouble(lower, [
      r'ширин[аоы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:мм|мм\.?)?',
      r'([0-9]{3,4})\s*(?:ширин|ш)\b',
      r'ширин[аоы]?\s+([0-9]{3,4})',
    ]);
    if (width != null) data['width'] = width;

    // Высота окна (мм)
    final height = _extractDouble(lower, [
      r'высот[аоы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:мм|мм\.?)?',
      r'([0-9]{3,4})\s*(?:высот|выс|в)\b',
      r'высот[аоы]?\s+([0-9]{3,4})',
    ]);
    if (height != null) data['height'] = height;

    // Тип стеклопакета
    if (lower.contains('однокамерн')) {
      data['glass_type'] = 'single';
    } else if (lower.contains('двухкамерн')) {
      data['glass_type'] = 'double';
    } else if (lower.contains('энергосберегающ') ||
        lower.contains('энергетич') ||
        lower.contains('энерг')) {
      data['glass_type'] = 'energy';
    }

    // Открывание
    if (lower.contains('поворотн.*?откидн') ||
        (lower.contains('поворотн') && lower.contains('откидн'))) {
      data['opening_type'] = 'поворотно-откидное';
    } else if (lower.contains('раздвижн') ||
        lower.contains('сдвижн') ||
        lower.contains('слайд')) {
      data['opening_type'] = 'раздвижное';
    } else if (lower.contains('глух') || lower.contains('не открыв')) {
      data['opening_type'] = 'глухое';
    }

    // Подоконник
    if (lower.contains('подоконник') || lower.contains('подоконн')) {
      data['has_sill'] = true;
      final sillW = _extractDouble(lower, [
        r'подоконник\s*(?:ширин[аоы]?)?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
        r'([0-9]+[,.]?[0-9]*)\s*(?:см|мм|м)\s*(?:подоконник|подок)',
        r'подоконник\s+([0-9]{2,4})',
      ]);
      if (sillW != null) data['sill_width'] = sillW;
    }

    // Откосы
    if (lower.contains('откос')) {
      data['has_slopes'] = true;
      if (lower.contains('сэндвич') || lower.contains('sandwich')) {
        data['slope_type'] = 'sandwich';
      } else if (lower.contains('штукатур')) {
        data['slope_type'] = 'plaster';
      } else {
        data['slope_type'] = 'plastic';
      }
    }

    // Отлив
    if (lower.contains('отлив')) {
      data['has_drip_cap'] = true;
    }

    // Москитная сетка
    if (lower.contains('москитн') || lower.contains('сетк')) {
      data['has_mosquito_net'] = true;
    }

    // Диагонали (проверка геометрии)
    final diag1 = _extractDouble(lower, [
      r'диагональ\s*1\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'диаг\s*1\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (diag1 != null) data['diagonal_1'] = diag1;

    final diag2 = _extractDouble(lower, [
      r'диагональ\s*2\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'диаг\s*2\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (diag2 != null) data['diagonal_2'] = diag2;

    // Этаж
    final floorMatch = RegExp(
      r'этаж\s*[:=]?\s*([0-9]+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (floorMatch != null) {
      data['floor_number'] = int.tryParse(floorMatch.group(1)!);
    }

    // Заметки
    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== ДВЕРИ =====
  Map<String, dynamic> extractDataForDoors(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Тип двери
    if (lower.contains('входн') || lower.contains('наружн')) {
      data['door_type'] = 'входная';
    } else if (lower.contains('межкомнатн') || lower.contains('внутренн')) {
      data['door_type'] = 'межкомнатная';
    } else if (lower.contains('технич') || lower.contains('подъездн')) {
      data['door_type'] = 'техническая';
    }

    // Ширина проёма (мм)
    final width = _extractDouble(lower, [
      r'ширин[аоы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'проём\s*(?:ширин[аоы]?)?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (width != null) data['width'] = width;

    // Высота проёма (мм)
    final height = _extractDouble(lower, [
      r'высот[аоы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'проём\s*(?:высот[аоы]?)?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (height != null) data['height'] = height;

    // Замок
    if (lower.contains('замок')) {
      data['has_lock'] = true;
      if (lower.contains('цилиндр') || lower.contains('ключ')) {
        data['lock_type'] = 'цилиндровый';
      } else if (lower.contains('сувальд')) {
        data['lock_type'] = 'сувальдный';
      } else if (lower.contains('электрон') || lower.contains('кодов')) {
        data['lock_type'] = 'электронный';
      }
    }

    // Порог
    if (lower.contains('порог')) {
      data['has_threshold'] = true;
    }

    // Глазок
    if (lower.contains('глазок')) {
      data['has_peephole'] = true;
    }

    // Материал отделки
    if (lower.contains('шпон')) {
      data['finish_material'] = 'шпон';
    } else if (lower.contains('массив') || lower.contains('дерево')) {
      data['finish_material'] = 'массив';
    } else if (lower.contains('экошпон')) {
      data['finish_material'] = 'экошпон';
    } else if (lower.contains('ламинат') || lower.contains('ламинац')) {
      data['finish_material'] = 'ламинация';
    }

    // Перепад пола
    final floorDiff = _extractDouble(lower, [
      r'(?:перепад|разниц[аы])\s*(?:пола|уровн)?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (floorDiff != null) data['floor_level_difference'] = floorDiff;

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== КОНДИЦИОНЕРЫ =====
  Map<String, dynamic> extractDataForAirConditioners(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Тип монтажа
    if (lower.contains('сложн') ||
        lower.contains('альпин') ||
        lower.contains('леса')) {
      data['install_type'] = 'complex';
    } else {
      data['install_type'] = 'basic';
    }

    // Длина трассы (м)
    final pipeLen = _extractDouble(lower, [
      r'(?:трасс|труб|медн).*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*)',
      r'длин[аы]?\s*(?:трасс|труб)\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (pipeLen != null) data['pipe_length'] = pipeLen;

    // Дренаж (м)
    final drainLen = _extractDouble(lower, [
      r'(?:дренаж|дрен).*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*)',
      r'длин[аы]?\s*дрен\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (drainLen != null) data['drain_length'] = drainLen;

    // Дренажный насос
    if (lower.contains('дренаж.*?насос') || lower.contains('насос.*?дренаж')) {
      data['has_drain_pump'] = true;
    }

    // Wi-Fi модуль
    if (lower.contains('wi-?fi') ||
        lower.contains('вай.*?фай') ||
        lower.contains('вайфай') ||
        lower.contains('модуль')) {
      data['has_wifi_module'] = true;
    }

    // Способ прокладки
    if (lower.contains('штроб') || lower.contains('скрыт')) {
      data['route_method'] = 'В штробе';
    } else if (lower.contains('короб')) {
      data['route_method'] = 'В коробе';
    }

    // Доступ к наружному блоку
    if (lower.contains('альпин') || lower.contains('высот')) {
      data['outdoor_unit_access'] = 'Промышленный альпин';
    } else if (lower.contains('леса')) {
      data['outdoor_unit_access'] = 'Нужны леса';
    }

    // Стена
    if (lower.contains('бетон')) {
      data['wall_material'] = 'бетон';
    } else if (lower.contains('кирпич')) {
      data['wall_material'] = 'кирпич';
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== КУХНИ =====
  Map<String, dynamic> extractDataForKitchens(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Длина кухни (мм)
    final length = _extractDouble(lower, [
      r'длин[аы]?\s*(?:кухн)?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'кухн[яию]?\s*(?:длин[аы]?)?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'([0-9]+)\s*(?:погонн?|пог\.?\s*м)',
    ]);
    if (length != null) data['kitchen_length'] = length;

    // Тип планировки
    if (lower.contains('углов')) {
      data['kitchen_type'] = 'угловая';
    } else if (lower.contains('п-образн') || lower.contains('подков')) {
      data['kitchen_type'] = 'П-образная';
    } else if (lower.contains('остров')) {
      data['kitchen_type'] = 'с островом';
    }

    // Столешница
    if (lower.contains('иск.*?камен') || lower.contains('камен.*?иск')) {
      data['countertop_material'] = 'искусственный камень';
    } else if (lower.contains('натуральн.*?камен') ||
        lower.contains('камен.*?натур')) {
      data['countertop_material'] = 'натуральный камень';
    } else if (lower.contains('мдф')) {
      data['countertop_material'] = 'МДФ';
    } else {
      data['countertop_material'] = 'ЛДСП';
    }

    // Фасады
    if (lower.contains('эмал')) {
      data['facade_material'] = 'МДФ эмаль';
    } else if (lower.contains('массив') || lower.contains('дерево')) {
      data['facade_material'] = 'массив';
    } else if (lower.contains('шпон')) {
      data['facade_material'] = 'шпон';
    } else if (lower.contains('пластик')) {
      data['facade_material'] = 'пластик';
    }

    // Установка техники
    if (lower.contains('техник') && lower.contains('установ')) {
      data['has_appliance_install'] = true;
      final count = _extractInt(lower, [
        r'(?:кол-?во|количеств|штук|шт).*?техник\s*[:=]?\s*([0-9]+)',
        r'техник[ауы].*?([0-9]+)\s*(?:шт|штук)',
      ]);
      if (count != null) data['appliance_count'] = count;
    }

    // Фартук
    if (lower.contains('фартук')) {
      data['has_backsplash'] = true;
      final backsplashLen = _extractDouble(lower, [
        r'фартук.*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
        r'фартук\s*(?:длин[аы]?)?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      ]);
      if (backsplashLen != null) data['backsplash_length'] = backsplashLen;

      if (lower.contains('стекл') && lower.contains('фартук')) {
        data['backsplash_material'] = 'стекло';
      } else if (lower.contains('мозаик')) {
        data['backsplash_material'] = 'мозаика';
      } else if (lower.contains('мдф') && lower.contains('фартук')) {
        data['backsplash_material'] = 'МДФ';
      }
    }

    // Мойка
    if (lower.contains('мойк')) {
      data['has_sink'] = true;
      if (lower.contains('подстольн')) {
        data['sink_type'] = 'подстольная';
      }
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== ПЛИТКА =====
  Map<String, dynamic> extractDataForTiles(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Поверхность
    if (lower.contains('пол')) {
      data['surface_type'] = 'Пол';
    } else if (lower.contains('стен')) {
      data['surface_type'] = 'Стены';
    }

    // Размеры помещения
    final floorLen = _extractDouble(lower, [
      r'длин[аы]?\s*(?:помещен|комнат|пол)\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (floorLen != null) data['floor_length'] = floorLen;

    final floorWidth = _extractDouble(lower, [
      r'ширин[аы]?\s*(?:помещен|комнат|пол)\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (floorWidth != null) data['floor_width'] = floorWidth;

    // Площадь
    final area = _extractDouble(lower, [
      r'площад[ьы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (area != null) data['area'] = area;

    // Способ укладки
    if (lower.contains('диагон') || lower.contains('ромб')) {
      data['laying_method'] = 'Диагональная';
    } else if (lower.contains('смещен') || lower.contains('разбежк')) {
      data['laying_method'] = 'Со смещением';
    } else if (lower.contains('модульн') || lower.contains('узор')) {
      data['laying_method'] = 'Модульная';
    } else {
      data['laying_method'] = 'Прямая';
    }

    // Тёплый пол
    if (lower.contains('тёпл.*?пол') ||
        lower.contains('тепл.*?пол') ||
        lower.contains('подогрев')) {
      data['has_underfloor_heating'] = true;
      final heatingArea = _extractDouble(lower, [
        r'(?:тёпл|тепл).*?пол.*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*кв|кв\.?\s*м)',
      ]);
      if (heatingArea != null) data['heating_area'] = heatingArea;
    }

    // Материал плитки
    if (lower.contains('керамогранит') || lower.contains('гранит')) {
      data['tile_material'] = 'керамогранит';
    } else if (lower.contains('мозаик')) {
      data['tile_material'] = 'мозаика';
    } else if (lower.contains('камен') && lower.contains('натур')) {
      data['tile_material'] = 'натуральный камень';
    } else {
      data['tile_material'] = 'керамика';
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== МЕБЕЛЬ =====
  Map<String, dynamic> extractDataForFurniture(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Материал корпуса
    if (lower.contains('лдсп') || lower.contains('ламинир')) {
      data['body_material'] = 'ЛДСП';
    } else if (lower.contains('мдф')) {
      data['body_material'] = 'МДФ';
    } else if (lower.contains('массив') || lower.contains('дерево')) {
      data['body_material'] = 'массив';
    }

    // Ширина стены (мм)
    final wallLen = _extractDouble(lower, [
      r'(?:длин[аы]|ширин[аы])\s*(?:стен|помещен|комнат)\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'стен[аы]\s*(?:длин[аы])?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (wallLen != null) data['wall_length'] = wallLen;

    // Высота потолка (мм)
    final ceilingH = _extractDouble(lower, [
      r'(?:высот[аы]|потолок)\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'потолок.*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (ceilingH != null) data['ceiling_height'] = ceilingH;

    // Ящики
    if (lower.contains('ящик') || lower.contains('выдвижн')) {
      data['has_drawers'] = true;
      final drawerCount = _extractInt(lower, [
        r'(?:кол-?во|количеств).*?ящик\s*[:=]?\s*([0-9]+)',
        r'ящик\s*[:=]?\s*([0-9]+)\s*(?:шт|штук)',
      ]);
      if (drawerCount != null) data['drawers_count'] = drawerCount;
    }

    // Двери
    if (lower.contains('раздвижн') ||
        lower.contains('слайд') ||
        lower.contains('купе')) {
      data['door_type'] = 'раздвижные';
    } else {
      data['door_type'] = 'распашные';
    }

    // Кромка
    if (lower.contains('абс') || lower.contains('abs')) {
      data['edge_type'] = 'АБС';
    } else if (lower.contains('2 мм') || lower.contains('2мм')) {
      data['edge_type'] = '2 мм';
    } else if (lower.contains('1 мм') || lower.contains('1мм')) {
      data['edge_type'] = '1 мм';
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== ИНЖЕНЕРНЫЕ СИСТЕМЫ =====
  Map<String, dynamic> extractDataForEngineering(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Система
    if (lower.contains('котельн') || lower.contains('котел')) {
      data['system_type'] = 'Котельная';
      if (lower.contains('газов') || lower.contains('газ')) {
        data['boiler_type'] = 'Газовый';
      } else if (lower.contains('электр')) {
        data['boiler_type'] = 'Электрический';
      } else if (lower.contains('твёрд') ||
          lower.contains('тверд') ||
          lower.contains('пеллет')) {
        data['boiler_type'] = 'Твёрдотопливный';
      }
      // Мощность
      final power = _extractDouble(lower, [
        r'мощност[ьы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:квт|кВт)',
      ]);
      if (power != null) data['boiler_power'] = power;
      // Позиция
      if (lower.contains('напольн')) {
        data['boiler_position'] = 'Напольный';
      } else if (lower.contains('настенн')) {
        data['boiler_position'] = 'Настенный';
      }
    } else if (lower.contains('отоплен') ||
        lower.contains('радиатор') ||
        lower.contains('батаре')) {
      data['system_type'] = 'Отопление';
      final sections = _extractInt(lower, [
        r'(?:кол-?во|количеств).*?секц\s*[:=]?\s*([0-9]+)',
        r'секц(?:ий|ии|ия)\s*[:=]?\s*([0-9]+)',
      ]);
      if (sections != null) data['radiator_sections_count'] = sections;
      if (lower.contains('биметалл')) {
        data['radiator_type'] = 'биметалл';
      } else if (lower.contains('алюмин')) {
        data['radiator_type'] = 'алюминий';
      } else if (lower.contains('чугун')) {
        data['radiator_type'] = 'чугун';
      }
    } else if (lower.contains('водоснабжен') ||
        lower.contains('водопровод') ||
        lower.contains('вод')) {
      data['system_type'] = 'Водоснабжение';
    } else if (lower.contains('канализац') || lower.contains('сточн')) {
      data['system_type'] = 'Канализация';
    } else if (lower.contains('вентиляц') || lower.contains('вент')) {
      data['system_type'] = 'Вентиляция';
    }

    // Утепление
    if (lower.contains('утеплен') ||
        lower.contains('утепл') ||
        lower.contains('изоляц')) {
      data['has_insulation'] = true;
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== ЭЛЕКТРИКА =====
  Map<String, dynamic> extractDataForElectrical(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Розетки
    final sockets = _extractInt(lower, [
      r'(?:кол-?во|количеств).*?розетк\s*[:=]?\s*([0-9]+)',
      r'розет(?:ок|ки|ку)\s*[:=]?\s*([0-9]+)',
    ]);
    if (sockets != null) data['sockets_count'] = sockets;

    // Освещение
    final lighting = _extractInt(lower, [
      r'(?:кол-?во|количеств).*?(?:свет|точек|точк)\s*[:=]?\s*([0-9]+)',
    ]);
    if (lighting != null) data['lighting_count'] = lighting;

    // Трассы (м)
    final wallRoutes = _extractDouble(lower, [
      r'(?:по стен|стен[аы]).*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*)',
    ]);
    if (wallRoutes != null) data['wall_routes_length'] = wallRoutes;

    final floorRoutes = _extractDouble(lower, [
      r'(?:по пол|пол[ауы]|стяжк).*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*)',
    ]);
    if (floorRoutes != null) data['floor_routes_length'] = floorRoutes;

    final ceilingRoutes = _extractDouble(lower, [
      r'(?:по потол|потолок).*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*)',
    ]);
    if (ceilingRoutes != null) data['ceiling_routes_length'] = ceilingRoutes;

    // Кабель
    if (lower.contains('nym') || lower.contains('нум')) {
      data['cable_brand'] = 'NYM';
    } else {
      data['cable_brand'] = 'ВВГнг';
    }

    // Скрытая прокладка
    if (lower.contains('штроб') || lower.contains('скрыт')) {
      data['cable_routing'] = 'Скрытая';
    }

    // Выключатели
    if (lower.contains('проходн') || lower.contains('переключ')) {
      data['switches_type'] = 'проходной';
    } else if (lower.contains('диммер') || lower.contains('светорегул')) {
      data['switches_type'] = 'диммер';
    }

    // Щиток
    if (lower.contains('трёхфазн') ||
        lower.contains('380') ||
        lower.contains('три фаз')) {
      data['input_voltage'] = 'Трёхфазный 380В';
    } else {
      data['input_voltage'] = 'Однофазный 220В';
    }

    // Автоматы
    final circuits = _extractInt(lower, [
      r'(?:кол-?во|количеств).*?(?:автомат|лин|групп)\s*[:=]?\s*([0-9]+)',
    ]);
    if (circuits != null) data['circuits_count'] = circuits;

    // УЗО
    if (lower.contains('узо') || lower.contains('диф.*?защит')) {
      data['has_rcd'] = true;
      if (lower.contains('10\s*ма')) {
        data['rcd_leakage_current'] = '10';
      } else if (lower.contains('100\s*ма')) {
        data['rcd_leakage_current'] = '100';
      } else {
        data['rcd_leakage_current'] = '30';
      }
    }

    // Умный дом
    if (lower.contains('умн.*?дом') ||
        lower.contains('smart.*?home') ||
        lower.contains('умный дом')) {
      data['has_smart_home'] = true;
    }

    // Заземление
    if (lower.contains('заземлен')) {
      data['has_grounding_circuit'] = true;
    }

    // Молниезащита
    if (lower.contains('молни') || lower.contains('грозов')) {
      data['has_lightning_protection'] = true;
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== ФУНДАМЕНТЫ =====
  Map<String, dynamic> extractDataForFoundations(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Тип фундамента
    if (lower.contains('ленточн')) {
      data['foundation_type'] = 'ленточный';
    } else if (lower.contains('плитн') || lower.contains('плит')) {
      data['foundation_type'] = 'плитный';
    } else if (lower.contains('свайн') || lower.contains('свай')) {
      data['foundation_type'] = 'свайный';
    } else if (lower.contains('столбчат')) {
      data['foundation_type'] = 'столбчатый';
    }

    // Размеры (мм)
    final length = _extractDouble(lower, [
      r'(?:длин[аы]|периметр).*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (length != null) data['trench_length'] = length;

    final width = _extractDouble(lower, [
      r'ширин[аы]?\s*(?:фундамент|транше|лент).*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (width != null) data['trench_width'] = width;

    final depth = _extractDouble(lower, [
      r'глубин[аы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'глуб.*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (depth != null) data['trench_depth'] = depth;

    // Армирование
    if (lower.contains('арматур') || lower.contains('армирован')) {
      data['has_reinforcement'] = true;
      final rebarWeight = _extractDouble(lower, [
        r'арматур[аы].*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:кг|тонн)',
      ]);
      if (rebarWeight != null) data['rebar_weight'] = rebarWeight;
    }

    // Бетон
    final concreteVolume = _extractDouble(lower, [
      r'бетон.*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:куб|м³|м3)',
      r'объём.*?бетон.*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (concreteVolume != null) data['concrete_volume'] = concreteVolume;

    // Гидроизоляция
    if (lower.contains('гидроизоляц') || lower.contains('гидроизол')) {
      data['has_waterproofing'] = true;
    }

    // Грунт
    if (lower.contains('песчан') || lower.contains('песок')) {
      data['soil_type'] = 'песчаный';
    } else if (lower.contains('глин')) {
      data['soil_type'] = 'глинистый';
    } else if (lower.contains('скальн')) {
      data['soil_type'] = 'скальный';
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== СТРОИТЕЛЬСТВО ИЖС =====
  Map<String, dynamic> extractDataForHouseConstruction(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Площадь дома
    final area = _extractDouble(lower, [
      r'площад[ьы]?\s*(?:дом[аы])?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*кв|кв\.?\s*м)',
    ]);
    if (area != null) data['house_area'] = area;

    // Этажность
    final floors = _extractInt(lower, [
      r'(?:кол-?во|количеств).*?этаж\s*[:=]?\s*([0-9]+)',
      r'([0-9])\s*этаж',
    ]);
    if (floors != null) data['floors_count'] = floors;

    // Материал стен
    if (lower.contains('кирпич') || lower.contains('керамич')) {
      data['wall_material'] = 'кирпич';
    } else if (lower.contains('газоблок') ||
        lower.contains('газобетон') ||
        lower.contains('блок')) {
      data['wall_material'] = 'газоблок';
    } else if (lower.contains('дерев') ||
        lower.contains('брус') ||
        lower.contains('бревен')) {
      data['wall_material'] = 'дерево';
    } else if (lower.contains('каркасн')) {
      data['wall_material'] = 'каркасный';
    }

    // Перекрытия
    if (lower.contains('деревянн') && lower.contains('перекрыт')) {
      data['ceiling_type'] = 'деревянные';
    } else if (lower.contains('жб') ||
        lower.contains('железобетон') ||
        lower.contains('плит')) {
      data['ceiling_type'] = 'ж/б плиты';
    }

    // Кровля
    if (lower.contains('кровл')) {
      if (lower.contains('металлочерепиц') || lower.contains('металл')) {
        data['roof_type'] = 'металлочерепица';
      } else if (lower.contains('мягк') || lower.contains('гибк')) {
        data['roof_type'] = 'мягкая кровля';
      } else if (lower.contains('профнастил') || lower.contains('профлист')) {
        data['roof_type'] = 'профнастил';
      }
    }

    // Гараж
    if (lower.contains('гараж')) {
      data['has_garage'] = true;
    }

    // Подвал
    if (lower.contains('подвал') || lower.contains('цокольн')) {
      data['has_basement'] = true;
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== КОРОБКА (СТЕНЫ) =====
  Map<String, dynamic> extractDataForWallsBox(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Материал стен
    if (lower.contains('газоблок') || lower.contains('газобетон')) {
      data['wall_block_type'] = 'газоблок';
    } else if (lower.contains('кирпич')) {
      data['wall_block_type'] = 'кирпич';
    } else if (lower.contains('керамоблок') || lower.contains('керамич')) {
      data['wall_block_type'] = 'керамоблок';
    }

    // Периметр
    final perimeter = _extractDouble(lower, [
      r'периметр\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (perimeter != null) data['perimeter'] = perimeter;

    // Высота стен
    final wallHeight = _extractDouble(lower, [
      r'высот[аы]?\s*(?:стен[аы])?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (wallHeight != null) data['wall_height'] = wallHeight;

    // Толщина стен
    final wallThickness = _extractDouble(lower, [
      r'толщин[аы]?\s*(?:стен[аы])?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (wallThickness != null) data['wall_thickness'] = wallThickness;

    // Армопояс
    if (lower.contains('армопояс') || lower.contains('армирован.*?пояс')) {
      data['has_armpoyas'] = true;
    }

    // Утепление
    if (lower.contains('утеплен')) {
      data['has_insulation'] = true;
      final insulationThickness = _extractDouble(lower, [
        r'утеплен.*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:мм|см)',
      ]);
      if (insulationThickness != null)
        data['insulation_thickness'] = insulationThickness;
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== ФАСАДЫ =====
  Map<String, dynamic> extractDataForFacades(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Тип отделки
    if (lower.contains('штукатур') || lower.contains('мокр')) {
      data['facade_type'] = 'штукатурка';
    } else if (lower.contains('сайдинг') || lower.contains('панел')) {
      data['facade_type'] = 'сайдинг';
    } else if (lower.contains('клинкер') || lower.contains('облицовочн')) {
      data['facade_type'] = 'клинкер';
    } else if (lower.contains('керамогранит')) {
      data['facade_type'] = 'керамогранит';
    } else if (lower.contains('композит') || lower.contains('алюкобонд')) {
      data['facade_type'] = 'композит';
    }

    // Площадь фасада
    final facadeArea = _extractDouble(lower, [
      r'площад[ьы]?\s*(?:фасад).*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (facadeArea != null) data['facade_area'] = facadeArea;

    // Утепление
    if (lower.contains('утеплен.*?фасад') ||
        lower.contains('фасад.*?утеплен') ||
        (lower.contains('фасад') && lower.contains('утепл'))) {
      data['has_facade_insulation'] = true;
    }

    // Декоративные элементы
    if (lower.contains('декор') ||
        lower.contains('карниз') ||
        lower.contains('пилястр')) {
      data['has_decorative_elements'] = true;
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== КРОВЛЯ =====
  Map<String, dynamic> extractDataForRoofing(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Тип кровли
    if (lower.contains('металлочерепиц') || lower.contains('металл')) {
      data['roof_type'] = 'металлочерепица';
    } else if (lower.contains('мягк') ||
        lower.contains('гибк') ||
        lower.contains('черепиц')) {
      data['roof_type'] = 'мягкая кровля';
    } else if (lower.contains('профнастил') || lower.contains('профлист')) {
      data['roof_type'] = 'профнастил';
    } else if (lower.contains('фальц')) {
      data['roof_type'] = 'фальцевая';
    } else if (lower.contains('керамик') || lower.contains('натуральн')) {
      data['roof_type'] = 'керамическая';
    } else if (lower.contains('ондулин')) {
      data['roof_type'] = 'ондулин';
    }

    // Площадь кровли
    final roofArea = _extractDouble(lower, [
      r'площад[ьы]?\s*(?:кровл).*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (roofArea != null) data['roof_area'] = roofArea;

    // Угол наклона
    final angle = _extractDouble(lower, [
      r'угол\s*(?:наклон[аы])?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:градус)?',
    ]);
    if (angle != null) data['roof_slope_angle'] = angle;

    // Утепление кровли
    if (lower.contains('утеплен.*?кровл') ||
        lower.contains('кровл.*?утеплен') ||
        lower.contains('утепленн.*?крыш')) {
      data['has_roof_insulation'] = true;
    }

    // Водосток
    if (lower.contains('водосток') || lower.contains('желоб')) {
      data['has_gutter_system'] = true;
    }

    // Снегозадержание
    if (lower.contains('снегозадерж') || lower.contains('снегозадержат')) {
      data['has_snow_retention'] = true;
      final snowCount = _extractInt(lower, [
        r'снегозадержат.*?[:=]?\s*([0-9]+)',
      ]);
      if (snowCount != null) data['snow_retention_count'] = snowCount;
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== МЕТАЛЛОКОНСТРУКЦИИ =====
  Map<String, dynamic> extractDataForMetalStructures(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Тип конструкции
    if (lower.contains('навес') ||
        lower.contains('козырек') ||
        lower.contains('козырёк')) {
      data['metal_structure_type'] = 'навес';
    } else if (lower.contains('ангар') ||
        lower.contains('склад') ||
        lower.contains('ангарн')) {
      data['metal_structure_type'] = 'ангар';
    } else if (lower.contains('лестниц')) {
      data['metal_structure_type'] = 'лестница';
    } else if (lower.contains('ферм')) {
      data['metal_structure_type'] = 'ферма';
    }

    // Вес металла (кг)
    final weight = _extractDouble(lower, [
      r'вес\s*(?:металл|конструкц).*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:кг|тонн)',
      r'([0-9]+[,.]?[0-9]*)\s*(?:кг|тонн)\s*(?:металл)',
    ]);
    if (weight != null) data['metal_weight'] = weight;

    // Антикоррозийная обработка
    if (lower.contains('антикорроз') ||
        lower.contains('грунтовк') ||
        lower.contains('покраск')) {
      data['has_antikorrosion'] = true;
    }

    // Фундамент под конструкцию
    if (lower.contains('фундамент')) {
      data['has_foundation'] = true;
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== ИНЖЕНЕРНЫЕ СЕТИ НАРУЖНЫЕ =====
  Map<String, dynamic> extractDataForExternalNetworks(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();

    // Тип сети
    if (lower.contains('водоснабжен') || lower.contains('водопровод')) {
      data['network_type'] = 'водоснабжение';
    } else if (lower.contains('канализац') || lower.contains('сточн')) {
      data['network_type'] = 'канализация';
    } else if (lower.contains('газ') || lower.contains('газоснабжен')) {
      data['network_type'] = 'газоснабжение';
    } else if (lower.contains('тепл') || lower.contains('теплоснабжен')) {
      data['network_type'] = 'теплоснабжение';
    } else if (lower.contains('электроснабжен') || lower.contains('электрич')) {
      data['network_type'] = 'электроснабжение';
    }

    // Длина траншеи (м)
    final trenchLen = _extractDouble(lower, [
      r'длин[аы]?\s*(?:транше|трасс).*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'транше.*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*)',
    ]);
    if (trenchLen != null) data['trench_length'] = trenchLen;

    // Глубина траншеи (м)
    final trenchDepth = _extractDouble(lower, [
      r'глубин[аы]?\s*(?:транше).*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'глуб.*?транше.*?[:=]?\s*([0-9]+[,.]?[0-9]*)',
    ]);
    if (trenchDepth != null) data['trench_depth'] = trenchDepth;

    // Тип трубы
    if (lower.contains('пнд') || lower.contains('полиэтилен')) {
      data['pipe_type'] = 'ПНД';
    } else if (lower.contains('пвх') || lower.contains('полимер')) {
      data['pipe_type'] = 'ПВХ';
    } else if (lower.contains('стальн') || lower.contains('сталь')) {
      data['pipe_type'] = 'стальная';
    } else if (lower.contains('чугун')) {
      data['pipe_type'] = 'чугунная';
    }

    // Диаметр трубы (мм)
    final pipeDiameter = _extractDouble(lower, [
      r'диаметр.*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:мм|мм\.?)',
    ]);
    if (pipeDiameter != null) data['pipe_diameter'] = pipeDiameter;

    // Колодец
    if (lower.contains('колодец') || lower.contains('колод')) {
      data['has_well'] = true;
    }

    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');

    return data;
  }

  // ===== ЗАБОРЫ =====
  Map<String, dynamic> extractDataForFences(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();
    final length = _extractDouble(lower, [r'длин[аы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (length != null) data['length'] = length;
    final height = _extractDouble(lower, [r'высот[аы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (height != null) data['height'] = height;
    if (lower.contains('профнастил')) data['fence_material'] = 'профнастил';
    else if (lower.contains('дерев') || lower.contains('штакет')) data['fence_material'] = 'дерево';
    else if (lower.contains('кирпич')) data['fence_material'] = 'кирпич';
    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');
    return data;
  }

  // ===== НАВЕСЫ =====
  Map<String, dynamic> extractDataForCanopies(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();
    final length = _extractDouble(lower, [r'длин[аы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (length != null) data['length'] = length;
    final width = _extractDouble(lower, [r'ширин[аы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (width != null) data['width'] = width;
    if (lower.contains('опор') || lower.contains('стойк')) data['has_legs'] = true;
    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');
    return data;
  }

  // ===== БАНИ =====
  Map<String, dynamic> extractDataForSaunas(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();
    final area = _extractDouble(lower, [r'площад[ьы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (area != null) data['area'] = area;
    if (lower.contains('печ') || lower.contains('камин')) data['has_stove'] = true;
    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');
    return data;
  }

  // ===== БАССЕЙНЫ =====
  Map<String, dynamic> extractDataForPools(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();
    final area = _extractDouble(lower, [r'площад[ьы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (area != null) data['area'] = area;
    final depth = _extractDouble(lower, [r'глубин[аы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (depth != null) data['depth'] = depth;
    if (lower.contains('фильтрац') || lower.contains('фильтр')) data['has_filtration'] = true;
    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');
    return data;
  }

  // ===== ГАРАЖИ =====
  Map<String, dynamic> extractDataForGarages(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();
    final area = _extractDouble(lower, [r'площад[ьы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (area != null) data['area'] = area;
    final height = _extractDouble(lower, [r'высот[аы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (height != null) data['height'] = height;
    if (lower.contains('автоматик') || lower.contains('привод')) data['has_automation'] = true;
    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');
    return data;
  }

  // ===== ВЕНТИЛЯЦИЯ =====
  Map<String, dynamic> extractDataForVentilation(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();
    final area = _extractDouble(lower, [r'площад[ьы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (area != null) data['room_area'] = area;
    if (lower.contains('рекуперац') || lower.contains('рекупер')) data['has_recovery'] = true;
    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');
    return data;
  }

  // ===== ВЕНТИЛИРУЕМЫЕ ФАСАДЫ =====
  Map<String, dynamic> extractDataForVentilatedFacades(String text) {
    final data = <String, dynamic>{};
    final lower = text.toLowerCase();
    final area = _extractDouble(lower, [r'площад[ьы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)']);
    if (area != null) data['area'] = area;
    if (lower.contains('утеплен')) data['has_insulation'] = true;
    final notes = _extractNotes(text);
    if (notes.isNotEmpty) data['notes'] = notes.join('; ');
    return data;
  }

  // ===== УТИЛИТЫ =====

  /// Извлечь заметки из текста
  List<String> _extractNotes(String text) {
    final lowerText = text.toLowerCase();
    final notes = <String>[];

    // Цвет
    if (lowerText.contains('белый') || lowerText.contains('бел')) {
      notes.add('Цвет: белый');
    } else if (lowerText.contains('коричнев') ||
        lowerText.contains('ламинат')) {
      notes.add('Цвет: коричневый/ламинат');
    } else if (lowerText.contains('серый') || lowerText.contains('графит')) {
      notes.add('Цвет: серый/графит');
    } else if (lowerText.contains('антрацит') || lowerText.contains('чёрн')) {
      notes.add('Цвет: антрацит/чёрный');
    }

    // Этажность / доступ
    final floorMatch = RegExp(
      r'этаж\s*[:=]?\s*([0-9]+)\s*(?:из|\/)\s*([0-9]+)',
      caseSensitive: false,
    ).firstMatch(lowerText);
    if (floorMatch != null) {
      notes.add('Этаж: ${floorMatch.group(1)}/${floorMatch.group(2)}');
    }

    // Ключи / доступ
    if (lowerText.contains('ключ') || lowerText.contains('пропуск')) {
      notes.add('Нужен ключ/пропуск');
    }

    // Сложный доступ
    if (lowerText.contains('сложн.*?доступ') ||
        lowerText.contains('огранич.*?доступ')) {
      notes.add('Сложный/ограниченный доступ');
    }

    // Срочность
    if (lowerText.contains('срочн') || lowerText.contains('быстр')) {
      notes.add('Срочный заказ');
    }

    return notes;
  }

  double? _extractDouble(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final valueStr = match
            .group(1)!
            .replaceAll(',', '.')
            .replaceAll(' ', '');
        final value = double.tryParse(valueStr);
        if (value != null) return value;
      }
    }
    return null;
  }

  int? _extractInt(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final valueStr = match.group(1)!.replaceAll(' ', '');
        final value = int.tryParse(valueStr);
        if (value != null) return value;
      }
    }
    return null;
  }

  /// Старый метод для обратной совместимости (окна)
  VoiceExtractedData extractData(String text) {
    final data = extractDataForWindows(text);
    return VoiceExtractedData._fromMap(data);
  }
}

/// Структурированные данные, извлечённые из голосового ввода
/// (оставлен для обратной совместимости)
class VoiceExtractedData {
  double? windowWidth;
  double? windowHeight;
  double? area;
  int? windowCount;
  String? windowType;
  bool hasSill = false;
  double? sillWidth;
  bool hasSlopes = false;
  bool hasSillOutside = false;
  bool hasMosquitoNet = false;
  String? notes;

  VoiceExtractedData();

  bool get hasData =>
      windowWidth != null ||
      windowHeight != null ||
      area != null ||
      windowCount != null ||
      windowType != null ||
      notes != null;

  factory VoiceExtractedData._fromMap(Map<String, dynamic> data) {
    final result = VoiceExtractedData();
    result.windowWidth = (data['width'] as num?)?.toDouble();
    result.windowHeight = (data['height'] as num?)?.toDouble();
    result.area = (data['area'] as num?)?.toDouble();
    result.windowCount = data['window_count'] as int?;
    result.windowType = data['window_type'] as String?;
    result.hasSill = data['has_sill'] == true;
    result.sillWidth = (data['sill_width'] as num?)?.toDouble();
    result.hasSlopes = data['has_slopes'] == true;
    result.hasSillOutside = data['has_drip_cap'] == true;
    result.hasMosquitoNet = data['has_mosquito_net'] == true;
    result.notes = data['notes'] as String?;
    return result;
  }

  @override
  String toString() {
    final parts = <String>[];
    if (windowWidth != null) parts.add('Ширина: ${windowWidth}мм');
    if (windowHeight != null) parts.add('Высота: ${windowHeight}мм');
    if (area != null) parts.add('Площадь: $area м²');
    if (windowCount != null) parts.add('Окон: $windowCount');
    if (windowType != null) parts.add('Тип: $windowType');
    if (hasSill) parts.add('Подоконник: да');
    if (hasSlopes) parts.add('Откосы: да');
    if (hasSillOutside) parts.add('Отлив: да');
    if (hasMosquitoNet) parts.add('Москитная сетка: да');
    if (notes != null && notes!.isNotEmpty) parts.add('Заметки: $notes');
    return parts.join(', ');
  }
}
