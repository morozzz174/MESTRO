import 'package:uuid/uuid.dart';
import '../models/ai_insight.dart';
import '../models/order.dart';
import '../models/checklist_config.dart';
import '../features/floor_plan/models/floor_plan_models.dart';
import 'ai_floor_plan_generator.dart';

/// Офлайн AI-агент для анализа данных замеров
/// Работает полностью без сети — rule-based + эвристики
class SmartChecklistAnalyzer {
  static const _uuid = Uuid();
  final _floorPlanGenerator = AIFloorPlanGenerator();

  /// Генерация Floor Plan из данных замера
  FloorPlan generateFloorPlan(Order order) {
    return _floorPlanGenerator.generateFromOrder(order);
  }

  /// Полный анализ данных замера
  AIAnalysisReport analyze(Order order, ChecklistConfig checklistConfig) {
    final insights = <AIInsight>[];

    // 1. Проверка заполненности обязательных полей
    insights.addAll(_checkRequiredFields(order, checklistConfig));

    // 2. Валидация значений (аномалии, выходы за диапазоны)
    insights.addAll(_checkDataAnomalies(order));

    // 3. Согласованность данных (cross-field validation)
    insights.addAll(_checkDataConsistency(order));

    // 4. Анализ стоимости
    insights.addAll(_analyzeCost(order));

    // 5. Рекомендации по типу работ
    insights.addAll(_generateWorkTypeRecommendations(order));

    // 6. Общие советы
    insights.addAll(_generateGeneralTips(order));

    // Формируем резюме
    final summary = _buildSummary(insights);

    return AIAnalysisReport(
      insights: insights,
      summary: summary,
      estimatedCost: order.estimatedCost,
      confidenceScore: _calculateConfidence(insights),
      analyzedAt: DateTime.now(),
    );
  }

  // ===== 1. Проверка обязательных полей =====
  List<AIInsight> _checkRequiredFields(
    Order order,
    ChecklistConfig config,
  ) {
    final insights = <AIInsight>[];
    final data = order.checklistData;

    for (final field in config.fields) {
      if (field.required && !data.containsKey(field.id)) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.missingData,
          priority: AIInsightPriority.high,
          title: 'Не заполнено обязательное поле',
          description: 'Поле "${field.label}" обязательно для заполнения',
          suggestion: 'Заполните поле "${field.label}" для корректного расчёта',
          affectedField: field.id,
        ));
      }
    }

    return insights;
  }

  // ===== 2. Проверка аномалий =====
  List<AIInsight> _checkDataAnomalies(Order order) {
    final insights = <AIInsight>[];
    final data = order.checklistData;
    final workType = order.workType.checklistFile;

    // Проверка размеров на реалистичность
    for (final entry in data.entries) {
      if (entry.value is num) {
        final value = (entry.value as num).toDouble();
        final anomaly = _checkSizeAnomaly(entry.key, value, workType);
        if (anomaly != null) insights.add(anomaly);
      }
    }

    return insights;
  }

  AIInsight? _checkSizeAnomaly(String key, double value, String workType) {
    // Диапазоны реалистичных значений по типам полей
    final ranges = <String, (double min, double max, String unit)>{
      // Общие размеры (мм)
      'width': (200, 15000, 'мм'),
      'height': (200, 8000, 'мм'),
      'length': (500, 50000, 'мм'),
      'depth': (100, 5000, 'мм'),
      'perimeter': (2000, 200000, 'мм'),
      // Площади (м²)
      'area': (1, 500, 'м²'),
      'facade_area': (5, 2000, 'м²'),
      'roof_area': (10, 1000, 'м²'),
      'house_area': (20, 500, 'м²'),
      // Количество
      'count': (1, 200, 'шт'),
      'window_count': (1, 100, 'шт'),
      'door_count': (1, 50, 'шт'),
      'floors_count': (1, 5, 'эт'),
      // Углы
      'angle': (5, 85, '°'),
      'roof_slope_angle': (5, 75, '°'),
      // Вес (кг)
      'weight': (10, 50000, 'кг'),
      'metal_weight': (50, 100000, 'кг'),
      // Длины (м)
      'trench_length': (1, 5000, 'м'),
      'trench_depth': (0.3, 10, 'м'),
    };

    // Проверяем по ключу
    for (final pattern in ranges.entries) {
      if (key.contains(pattern.key)) {
        final (min, max, unit) = pattern.value;
        if (value < min) {
          return AIInsight(
            id: _uuid.v4(),
            type: AIInsightType.warning,
            priority: AIInsightPriority.medium,
            title: 'Подозрительно малое значение',
            description:
                'Значение "$key": $value $unit — возможно, ошибка ввода '
                '(норма: от $min $unit)',
            suggestion: 'Проверьте корректность значения',
            affectedField: key,
          );
        }
        if (value > max) {
          return AIInsight(
            id: _uuid.v4(),
            type: AIInsightType.warning,
            priority: AIInsightPriority.high,
            title: 'Подозрительно большое значение',
            description:
                'Значение "$key": $value $unit — превышает типичные значения '
                '(макс: $max $unit)',
            suggestion: 'Проверьте единицы измерения (мм vs м)',
            affectedField: key,
          );
        }
        return null;
      }
    }

    return null;
  }

  // ===== 3. Согласованность данных =====
  List<AIInsight> _checkDataConsistency(Order order) {
    final insights = <AIInsight>[];
    final data = order.checklistData;

    // Окна: ширина > высоты (типично)
    final width = (data['width'] as num?)?.toDouble();
    final height = (data['height'] as num?)?.toDouble();
    if (width != null && height != null) {
      if (width > height * 3) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.warning,
          priority: AIInsightPriority.medium,
          title: 'Несоответствие размеров',
          description:
              'Ширина ($width мм) более чем в 3 раза превышает высоту '
              '($height мм). Убедитесь, что поля не перепутаны.',
          suggestion: 'Проверьте: ширина и высота не перепутаны местами?',
        ));
      }
    }

    // Периметр и площадь дома
    final perimeter = (data['perimeter'] as num?)?.toDouble();
    final houseArea = (data['house_area'] as num?)?.toDouble();
    if (perimeter != null && houseArea != null) {
      final expectedArea = (perimeter / 1000) * (perimeter / 1000) / 4;
      final ratio = houseArea / expectedArea;
      if (ratio < 0.3 || ratio > 3) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.warning,
          priority: AIInsightPriority.medium,
          title: 'Площадь не соответствует периметру',
          description:
              'Площадь дома ($houseArea м²) сильно отличается от ожидаемой '
              'по периметру (${expectedArea.toStringAsFixed(1)} м²). '
              'Это нормально для сложных форм, но стоит проверить.',
        ));
      }
    }

    // Фундамент: глубина > ширины (нетипично)
    final foundDepth = (data['foundation_depth'] as num?)?.toDouble();
    final foundWidth = (data['foundation_width'] as num?)?.toDouble();
    if (foundDepth != null && foundWidth != null) {
      if (foundDepth > foundWidth * 2) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.warning,
          priority: AIInsightPriority.high,
          title: 'Глубина фундамента превышает ширину',
          description:
              'Глубина заложения ($foundDepth мм) значительно больше ширины '
              '($foundWidth мм). Это возможно для свайных фундаментов, но '
              'стоит проверить.',
          suggestion: 'Убедитесь, что значения указаны в мм, а не в см/м',
        ));
      }
    }

    // Кровля: площадь > площади дома (нормально, но проверяем)
    final roofArea = (data['roof_area'] as num?)?.toDouble();
    if (roofArea != null && houseArea != null) {
      if (roofArea > houseArea * 2.5) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.warning,
          priority: AIInsightPriority.medium,
          title: 'Площадь кровли значительно больше площади дома',
          description:
              'Площадь кровли ($roofArea м²) более чем в 2.5 раза превышает '
              'площадь дома ($houseArea м²). Проверьте данные.',
        ));
      }
    }

    // Траншея: глубина > ширины (нормально, но экстремальные значения)
    final trenchDepth = (data['trench_depth'] as num?)?.toDouble();
    final trenchWidth = (data['trench_width'] as num?)?.toDouble();
    if (trenchDepth != null && trenchWidth != null) {
      final depthM = trenchWidth < 100
          ? trenchDepth
          : trenchDepth; // если в мм
      final widthM =
          trenchWidth > 100 ? trenchWidth / 1000 : trenchWidth; // нормализация
      if (depthM > widthM * 5) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.warning,
          priority: AIInsightPriority.high,
          title: 'Траншея очень глубокая и узкая',
          description:
              'Глубина траншеи ($trenchDepth м) в ${depthM ~/ widthM} раз '
              'больше ширины (${trenchWidth} мм). Требуется укрепление стен.',
          suggestion: 'Убедитесь в безопасности котлована такой глубины',
        ));
      }
    }

    return insights;
  }

  // ===== 4. Анализ стоимости =====
  List<AIInsight> _analyzeCost(Order order) {
    final insights = <AIInsight>[];
    final cost = order.estimatedCost;

    if (cost == null) return insights;

    // Пороговые значения стоимости по типам работ (в рублях)
    final costRanges = <String, (double low, double high)>{
      'windows': (15000, 500000),
      'doors': (8000, 200000),
      'air_conditioners': (15000, 150000),
      'kitchens': (50000, 800000),
      'tiles': (20000, 500000),
      'furniture': (30000, 600000),
      'engineering': (30000, 400000),
      'electrical': (15000, 300000),
      'foundations': (100000, 1500000),
      'house_construction': (500000, 15000000),
      'walls_box': (200000, 3000000),
      'facades': (100000, 2000000),
      'roofing': (100000, 1500000),
      'metal_structures': (50000, 2000000),
      'external_networks': (50000, 1000000),
    };

    final workType = order.workType.checklistFile;
    final range = costRanges[workType];

    if (range != null) {
      if (cost < range.$1) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.costAdvice,
          priority: AIInsightPriority.low,
          title: 'Стоимость ниже типовой',
          description:
              'Расчётная стоимость ${cost.toStringAsFixed(0)} ₽ ниже '
              'типичного минимума для этого типа работ (${range.$1.toStringAsFixed(0)} ₽)',
          suggestion:
              'Возможно, не все позиции учтены. Проверьте полноту замера.',
        ));
      } else if (cost > range.$2) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.costAdvice,
          priority: AIInsightPriority.medium,
          title: 'Стоимость выше типовой',
          description:
              'Расчётная стоимость ${cost.toStringAsFixed(0)} ₽ превышает '
              'типовой максимум (${range.$2.toStringAsFixed(0)} ₽)',
          suggestion:
              'Проверьте количество позиций и цены. Возможно, стоит '
              'предложить клиенту альтернативные материалы.',
        ));
      }
    }

    // Проверка: стоимость 0 при заполненных данных
    if (cost == 0 && order.checklistData.isNotEmpty) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.error,
        priority: AIInsightPriority.critical,
        title: 'Стоимость не рассчитана',
        description:
            'Данные замера заполнены, но стоимость равна 0 ₽. '
            'Возможно, прайс-лист не загружен или формулы не настроены.',
        suggestion: 'Проверьте прайс-лист и формулы расчёта',
      ));
    }

    return insights;
  }

  // ===== 5. Рекомендации по типу работ =====
  List<AIInsight> _generateWorkTypeRecommendations(Order order) {
    final insights = <AIInsight>[];
    final data = order.checklistData;

    switch (order.workType.checklistFile) {
      case 'foundations':
        insights.addAll(_analyzeFoundation(data));
        break;
      case 'house_construction':
        insights.addAll(_analyzeHouseConstruction(data));
        break;
      case 'walls_box':
        insights.addAll(_analyzeWallsBox(data));
        break;
      case 'facades':
        insights.addAll(_analyzeFacades(data));
        break;
      case 'roofing':
        insights.addAll(_analyzeRoofing(data));
        break;
      case 'metal_structures':
        insights.addAll(_analyzeMetalStructures(data));
        break;
      case 'external_networks':
        insights.addAll(_analyzeExternalNetworks(data));
        break;
    }

    return insights;
  }

  List<AIInsight> _analyzeFoundation(Map<String, dynamic> data) {
    final insights = <AIInsight>[];
    final depth = (data['foundation_depth'] as num?)?.toDouble() ?? 0;

    if (depth > 1500) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.recommendation,
        priority: AIInsightPriority.medium,
        title: 'Глубокий фундамент',
        description:
            'Глубина заложения ${depth} мм — это ниже глубины промерзания '
            'для большинства регионов. Убедитесь, что тип фундамента выбран верно.',
        suggestion:
            'Для глубин > 1.5м рассмотрите свайный фундамент вместо ленточного',
      ));
    }

    if (data['has_reinforcement'] == false && depth > 500) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.warning,
        priority: AIInsightPriority.high,
        title: 'Фундамент без армирования',
        description:
            'Глубина фундамента ${depth} мм, но армирование не указано. '
            'Для глубин > 500 мм армирование обязательно по СНиП.',
        suggestion: 'Добавьте армирование для обеспечения прочности',
      ));
    }

    if (data['has_waterproofing'] == false) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.recommendation,
        priority: AIInsightPriority.low,
        title: 'Рекомендуется гидроизоляция',
        description:
            'Гидроизоляция фундамента не указана. Она защищает от грунтовых '
            'вод и продлевает срок службы.',
        suggestion: 'Добавьте гидроизоляцию — это 5-10% стоимости фундамента',
      ));
    }

    return insights;
  }

  List<AIInsight> _analyzeHouseConstruction(Map<String, dynamic> data) {
    final insights = <AIInsight>[];

    if (data['has_basement'] == true &&
        data['foundation_type'] == null) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.missingData,
        priority: AIInsightPriority.high,
        title: 'Подвал без типа фундамента',
        description:
            'Указан подвал, но не выбран тип фундамента. Для подвала '
            'необходим ленточный фундамент глубокого заложения.',
        suggestion: 'Укажите тип фундамента с учётом подвала',
      ));
    }

    if (data['has_garage'] == true) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.tip,
        priority: AIInsightPriority.low,
        title: 'Гараж в проекте',
        description:
            'Наличие гаража увеличивает площадь фундамента и нагрузку '
            'на несущие конструкции. Убедитесь, что фундамент рассчитан.',
      ));
    }

    return insights;
  }

  List<AIInsight> _analyzeWallsBox(Map<String, dynamic> data) {
    final insights = <AIInsight>[];

    if (data['has_armo_poyas'] == false) {
      final material = data['wall_material'] as String?;
      if (material != null && material.contains('Газоблок')) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.warning,
          priority: AIInsightPriority.high,
          title: 'Армопояс обязателен для газоблока',
          description:
              'Для стен из газобетона армопояс обязателен по СНиП. '
              'Он распределяет нагрузку от перекрытий.',
          suggestion: 'Добавьте армопояс над каждым этажом',
        ));
      }
    }

    return insights;
  }

  List<AIInsight> _analyzeFacades(Map<String, dynamic> data) {
    final insights = <AIInsight>[];

    if (data['has_insulation'] == false) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.recommendation,
        priority: AIInsightPriority.medium,
        title: 'Рекомендуется утепление фасада',
        description:
            'Утепление фасада снижает теплопотери на 30-40% и повышает '
            'комфорт проживания. Окупается за 3-5 лет.',
        suggestion:
            'Добавьте утепление — минвата 100мм или пенополистирол 80мм',
      ));
    }

    return insights;
  }

  List<AIInsight> _analyzeRoofing(Map<String, dynamic> data) {
    final insights = <AIInsight>[];

    if (data['has_insulation'] == false) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.warning,
        priority: AIInsightPriority.high,
        title: 'Кровля без утепления',
        description:
            'Утепление кровли критически важно для жилого дома. '
            'Без него теплопотери через крышу составляют до 25%.',
        suggestion: 'Добавьте утепление минватой 200мм',
      ));
    }

    if (data['has_waterproofing_membrane'] == false) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.warning,
        priority: AIInsightPriority.high,
        title: 'Нет гидроизоляционной мембраны',
        description:
            'Гидроизоляционная мембрана защищает утеплитель и стропила '
            'от конденсата и протечек.',
        suggestion: 'Добавьте гидро-ветрозащитную мембрану',
      ));
    }

    if (data['has_gutter'] == false) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.recommendation,
        priority: AIInsightPriority.medium,
        title: 'Рекомендуется водосточная система',
        description:
            'Водосток защищает фундамент и фасад от размывания. '
            'Особенно важен при отмостке менее 1м.',
      ));
    }

    return insights;
  }

  List<AIInsight> _analyzeMetalStructures(Map<String, dynamic> data) {
    final insights = <AIInsight>[];

    if (data['has_antikorrosion'] == false) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.warning,
        priority: AIInsightPriority.high,
        title: 'Нет антикоррозийной обработки',
        description:
            'Металлоконструкции без антикоррозийной защиты быстро ржавеют. '
            'Срок службы снижается в 3-5 раз.',
        suggestion:
            'Добавьте грунтовку + покраску или горячее цинкование',
      ));
    }

    return insights;
  }

  List<AIInsight> _analyzeExternalNetworks(Map<String, dynamic> data) {
    final insights = <AIInsight>[];

    final depth = (data['trench_depth'] as num?)?.toDouble() ?? 0;
    final networkType = data['network_type'] as String?;

    // Минимальные глубины заложения по СНиП
    final minDepths = <String, double>{
      'Водоснабжение': 1.5,
      'Канализация': 0.7,
      'Газоснабжение': 0.8,
      'Теплоснабжение': 1.2,
    };

    if (networkType != null && depth > 0) {
      final minDepth = minDepths[networkType];
      if (minDepth != null && depth < minDepth) {
        insights.add(AIInsight(
          id: _uuid.v4(),
          type: AIInsightType.warning,
          priority: AIInsightPriority.high,
          title: 'Траншея слишком мелкая',
          description:
              'Глубина $depth м для $networkType ниже нормы ($minDepth м). '
              'Риск промерзания/повреждения.',
          suggestion: 'Увеличьте глубину до $minDepth м минимум',
        ));
      }
    }

    if (data['has_wells'] == false && depth > 1.5) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.recommendation,
        priority: AIInsightPriority.medium,
        title: 'Рекомендуются смотровые колодцы',
        description:
            'При глубине заложения > 1.5м и длине > 50м необходимы '
            'смотровые колодцы для обслуживания.',
      ));
    }

    return insights;
  }

  // ===== 6. Общие советы =====
  List<AIInsight> _generateGeneralTips(Order order) {
    final insights = <AIInsight>[];
    final data = order.checklistData;

    // Если есть фото — похвалить
    final photoFields =
        data.entries.where((e) => e.value.toString().contains('photo'));
    if (photoFields.isEmpty && data.isNotEmpty) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.tip,
        priority: AIInsightPriority.low,
        title: 'Добавьте фотографии',
        description:
            'Фотофиксация объекта поможет при составлении коммерческого '
            'предложения и защитит от споров с клиентом.',
      ));
    }

    // Заметки
    if (order.notes == null || order.notes!.isEmpty) {
      insights.add(AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.tip,
        priority: AIInsightPriority.low,
        title: 'Добавьте заметки',
        description:
            'Заметки к замеру помогут вспомнить детали объекта при '
            'составлении предложения.',
      ));
    }

    return insights;
  }

  // ===== Утилиты =====
  String _buildSummary(List<AIInsight> insights) {
    if (insights.isEmpty) {
      return 'Данные замера заполнены корректно. Критических проблем не обнаружено.';
    }

    final critical =
        insights.where((i) => i.priority == AIInsightPriority.critical).length;
    final high =
        insights.where((i) => i.priority == AIInsightPriority.high).length;
    final medium =
        insights.where((i) => i.priority == AIInsightPriority.medium).length;

    final parts = <String>[];
    if (critical > 0) parts.add('$critical критических');
    if (high > 0) parts.add('$high важных');
    if (medium > 0) parts.add('$medium предупреждений');

    return
        'Найдено ${insights.length} замечаний: ${parts.join(', ')}. '
        'Рекомендуем исправить критические и важные проблемы перед отправкой.';
  }

  double _calculateConfidence(List<AIInsight> insights) {
    if (insights.isEmpty) return 1.0;

    double score = 1.0;
    for (final insight in insights) {
      switch (insight.priority) {
        case AIInsightPriority.critical:
          score -= 0.3;
          break;
        case AIInsightPriority.high:
          score -= 0.15;
          break;
        case AIInsightPriority.medium:
          score -= 0.05;
          break;
        case AIInsightPriority.low:
          score -= 0.02;
          break;
      }
    }

    return score.clamp(0.0, 1.0);
  }
}
