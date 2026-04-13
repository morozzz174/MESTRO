import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/checklist_config.dart';
import '../models/ai_insight.dart';
import '../utils/cost_calculator.dart';
import 'ai_agent_service.dart';

/// AI-агент для премиум-функций:
/// - Автозаполнение чеклиста из голосового ввода
/// - AI-валидация финального коммерческого предложения
/// - Генерация заметок замерщика
class AIPremiumAgent {
  final SmartChecklistAnalyzer _analyzer = SmartChecklistAnalyzer();

  /// ===== AUTO-FILL: Применить распознанные данные к чеклисту =====
  /// Берёт Map<String, dynamic> из VoiceInputService и сливает с checklistData заказа
  /// Возвращает обновлённый Order + список применённых полей
  Map<String, dynamic> applyVoiceDataToOrder(
    Order order,
    Map<String, dynamic> voiceData,
  ) {
    if (voiceData.isEmpty) {
      return {'order': order, 'appliedFields': <String>[]};
    }

    final existingData = Map<String, dynamic>.from(order.checklistData);
    final appliedFields = <String>[];

    for (final entry in voiceData.entries) {
      // Не перезаписываем существующие ненулевые значения
      if (existingData.containsKey(entry.key) &&
          existingData[entry.key] != null &&
          existingData[entry.key] != false) {
        continue;
      }

      if (entry.value != null) {
        existingData[entry.key] = entry.value;
        appliedFields.add(entry.key);
      }
    }

    final updatedOrder = order.copyWith(
      checklistData: existingData,
      updatedAt: DateTime.now(),
    );

    return {'order': updatedOrder, 'appliedFields': appliedFields};
  }

  /// ===== AUTO-FILL: Сгенерировать заметки из голосового текста =====
  /// Извлекает контекстные заметки из полного текста голосового ввода
  String generateSurveyorNotes(String voiceText, Order order) {
    final lower = voiceText.toLowerCase();
    final notes = <String>[];

    // Существующие заметки
    if (order.notes != null && order.notes!.isNotEmpty) {
      notes.add(order.notes!);
    }

    // Общие примечания
    if (lower.contains('примечание') || lower.contains('примеч') ||
        lower.contains('заметк')) {
      final noteMatch = RegExp(
        r'(?:примечание|примеч|заметк)[,:]?\s*(.+)',
        caseSensitive: false,
      ).firstMatch(lower);
      if (noteMatch != null) {
        notes.add(noteMatch.group(1)!.trim());
      }
    }

    // Доступ к объекту
    if (lower.contains('доступ') || lower.contains('въезд') ||
        lower.contains('подъезд')) {
      if (lower.contains('сложн') || lower.contains('огранич')) {
        notes.add('⚠️ Сложный доступ к объекту');
      }
      if (lower.contains('шлагбаум') || lower.contains('пропуск')) {
        notes.add('🔑 Требуется пропуск/шлагбаум');
      }
      if (lower.contains('парковк')) {
        notes.add('🚗 Есть парковка рядом');
      }
    }

    // Время/сроки
    if (lower.contains('срок') || lower.contains('дедлайн') ||
        lower.contains('когда нужен')) {
      final deadlineMatch = RegExp(
        r'(?:срок|дедлайн|нужн).*?[:=]?\s*(.+?)(?:\.|$)',
        caseSensitive: false,
      ).firstMatch(lower);
      if (deadlineMatch != null) {
        notes.add('📅 Срок: ${deadlineMatch.group(1)!.trim()}');
      }
    }

    // Бюджет клиента
    if (lower.contains('бюджет') || lower.contains('сколько готов') ||
        lower.contains('максимальн')) {
      final budgetMatch = RegExp(
        r'(?:бюджет|готов|максимальн).*?[:=]?\s*([0-9]+[,.]?[0-9]*)\s*(?:тыс|руб|р)',
        caseSensitive: false,
      ).firstMatch(lower);
      if (budgetMatch != null) {
        notes.add('💰 Бюджет: ~${budgetMatch.group(1)} тыс.руб');
      }
    }

    // Особенности объекта
    if (lower.contains('сложн') && lower.contains('геометр')) {
      notes.add('📐 Сложная геометрия помещения');
    }
    if (lower.contains('демонтаж') || lower.contains('снести') ||
        lower.contains('убрать')) {
      notes.add('🔨 Требуется демонтаж старой конструкции');
    }
    if (lower.contains('мусор') || lower.contains('вывоз')) {
      notes.add('🗑️ Нужен вывоз мусора');
    }

    // Контакты
    if (lower.contains('контакт') || lower.contains('телефон') ||
        lower.contains('позвонить')) {
      final phoneMatch = RegExp(
        r'(\+?[0-9][0-9\s\-\(\)]{9,})',
        caseSensitive: false,
      ).firstMatch(lower);
      if (phoneMatch != null) {
        notes.add('📞 Контакт: ${phoneMatch.group(1)!.trim()}');
      }
    }

    return notes.join('\n');
  }

  /// ===== AI-ВАЛИДАЦИЯ КП: Полная проверка перед отправкой клиенту =====
  AIValidationReport validateCommercialProposal(
    Order order,
    ChecklistConfig config,
  ) {
    final issues = <AIIssue>[];
    double completenessScore = 100.0;

    // 1. Базовый анализ через AI-агента
    final analysisReport = _analyzer.analyze(order, config);
    for (final insight in analysisReport.insights) {
      if (insight.priority == AIInsightPriority.critical ||
          insight.priority == AIInsightPriority.high) {
        issues.add(
          AIIssue(
            type: AIIssueType.error,
            field: insight.affectedField ?? 'general',
            message: '${insight.title}: ${insight.description}',
            suggestion: insight.suggestion,
          ),
        );
        completenessScore -= insight.priority == AIInsightPriority.critical
            ? 10
            : 5;
      }
    }

    // 2. Проверка заполненности ключевых измерений
    final keyFields = _getKeyFieldsForWorkType(order.workType.checklistFile);
    for (final field in keyFields) {
      if (!order.checklistData.containsKey(field) ||
          order.checklistData[field] == null) {
        issues.add(
          AIIssue(
            type: AIIssueType.warning,
            field: field,
            message: 'Не заполнено ключевое поле: $field',
            suggestion: 'Заполните это поле для точного расчёта',
          ),
        );
        completenessScore -= 3;
      }
    }

    // 3. Проверка расчёта стоимости
    final calculatedCost = CostCalculator.calculate(order, config);
    if (calculatedCost <= 0 && order.checklistData.isNotEmpty) {
      issues.add(
        AIIssue(
          type: AIIssueType.error,
          field: 'cost',
          message: 'Стоимость равна 0 при заполненных данных',
          suggestion: 'Проверьте формулы расчёта и значения полей',
        ),
      );
      completenessScore -= 15;
    }

    // 4. Проверка фотографий
    if (order.photos.isEmpty && order.checklistData.isNotEmpty) {
      issues.add(
        AIIssue(
          type: AIIssueType.info,
          field: 'photos',
          message: 'Нет фотографий объекта',
          suggestion: 'Добавьте фото для защиты от споров с клиентом',
        ),
      );
      completenessScore -= 2;
    }

    // 5. Проверка заметок
    if (order.notes == null || order.notes!.isEmpty) {
      issues.add(
        AIIssue(
          type: AIIssueType.info,
          field: 'notes',
          message: 'Нет заметок к замеру',
          suggestion: 'Добавьте заметки о специфике объекта',
        ),
      );
      completenessScore -= 1;
    }

    // 6. Проверка на аномально высокую/низкую стоимость
    final costRanges = _getCostRangesForWorkType(order.workType.checklistFile);
    if (calculatedCost > 0 && costRanges != null) {
      if (calculatedCost > costRanges['max']!) {
        issues.add(
          AIIssue(
            type: AIIssueType.warning,
            field: 'cost',
            message:
                'Стоимость ${calculatedCost.toStringAsFixed(0)} ₽ значительно '
                'выше типичной для этого типа работ (макс: ${costRanges['max']} ₽)',
            suggestion: 'Проверьте размеры и количество позиций',
          ),
        );
      } else if (calculatedCost < costRanges['min']! && calculatedCost > 0) {
        issues.add(
          AIIssue(
            type: AIIssueType.warning,
            field: 'cost',
            message:
                'Стоимость ${calculatedCost.toStringAsFixed(0)} ₽ ниже '
                'типичной для этого типа работ (мин: ${costRanges['min']} ₽)',
            suggestion: 'Возможно, не все позиции учтены',
          ),
        );
      }
    }

    // 7. Проверка контактных данных клиента
    if (order.clientPhone == null || order.clientPhone!.isEmpty) {
      issues.add(
        AIIssue(
          type: AIIssueType.info,
          field: 'client_phone',
          message: 'Не указан телефон клиента',
          suggestion: 'Добавьте телефон для связи с клиентом',
        ),
      );
    }

    completenessScore = completenessScore.clamp(0.0, 100.0);

    return AIValidationReport(
      isValid: issues.where((i) => i.type == AIIssueType.error).isEmpty,
      completenessScore: completenessScore,
      issues: issues,
      estimatedCost: calculatedCost,
      confidenceScore: analysisReport.confidenceScore ?? 0.0,
      validatedAt: DateTime.now(),
    );
  }

  /// ===== Ключевые поля для каждого типа работ =====
  List<String> _getKeyFieldsForWorkType(String workTypeKey) {
    switch (workTypeKey) {
      case 'windows':
        return ['width', 'height', 'glass_type'];
      case 'doors':
        return ['door_type', 'width', 'height'];
      case 'air_conditioners':
        return ['install_type', 'pipe_length'];
      case 'kitchens':
        return ['kitchen_length', 'countertop_material'];
      case 'tiles':
        return ['surface_type', 'floor_length', 'floor_width'];
      case 'furniture':
        return ['body_material', 'wall_length', 'ceiling_height'];
      case 'engineering':
        return ['system_type'];
      case 'electrical':
        return ['sockets_count', 'lighting_count'];
      case 'foundations':
        return ['foundation_type', 'trench_length', 'trench_depth'];
      case 'house_construction':
        return ['house_area', 'floors_count', 'wall_material'];
      case 'walls_box':
        return ['wall_block_type', 'perimeter'];
      case 'facades':
        return ['facade_type', 'facade_area'];
      case 'roofing':
        return ['roof_type', 'roof_area'];
      case 'metal_structures':
        return ['metal_structure_type', 'metal_weight'];
      case 'external_networks':
        return ['network_type', 'trench_length'];
      default:
        return [];
    }
  }

  /// Диапазоны типичных стоимостей
  Map<String, double>? _getCostRangesForWorkType(String workTypeKey) {
    const ranges = {
      'windows': {'min': 15000.0, 'max': 500000.0},
      'doors': {'min': 8000.0, 'max': 200000.0},
      'air_conditioners': {'min': 15000.0, 'max': 80000.0},
      'kitchens': {'min': 50000.0, 'max': 800000.0},
      'tiles': {'min': 10000.0, 'max': 300000.0},
      'furniture': {'min': 30000.0, 'max': 500000.0},
      'engineering': {'min': 20000.0, 'max': 500000.0},
      'electrical': {'min': 10000.0, 'max': 400000.0},
      'foundations': {'min': 100000.0, 'max': 2000000.0},
      'house_construction': {'min': 500000.0, 'max': 15000000.0},
      'walls_box': {'min': 200000.0, 'max': 5000000.0},
      'facades': {'min': 100000.0, 'max': 3000000.0},
      'roofing': {'min': 80000.0, 'max': 2000000.0},
      'metal_structures': {'min': 50000.0, 'max': 1500000.0},
      'external_networks': {'min': 50000.0, 'max': 2000000.0},
    };
    return ranges[workTypeKey];
  }
}

/// Отчёт AI-валидации КП
class AIValidationReport {
  final bool isValid;
  final double completenessScore; // 0-100
  final List<AIIssue> issues;
  final double estimatedCost;
  final double confidenceScore;
  final DateTime validatedAt;

  const AIValidationReport({
    required this.isValid,
    required this.completenessScore,
    required this.issues,
    required this.estimatedCost,
    required this.confidenceScore,
    required this.validatedAt,
  });

  int get errorCount =>
      issues.where((i) => i.type == AIIssueType.error).length;
  int get warningCount =>
      issues.where((i) => i.type == AIIssueType.warning).length;
  int get infoCount => issues.where((i) => i.type == AIIssueType.info).length;

  String get summary {
    final parts = <String>[];
    if (errorCount > 0) parts.add('❌ $errorCount ошибок');
    if (warningCount > 0) parts.add('⚠️ $warningCount предупреждений');
    if (infoCount > 0) parts.add('ℹ️ $infoCount замечаний');
    return parts.isEmpty
        ? '✅ КП готово к отправке!'
        : 'Найдено: ${parts.join(', ')}. Заполненность: ${completenessScore.toStringAsFixed(0)}%';
  }
}

enum AIIssueType { error, warning, info }

class AIIssue {
  final AIIssueType type;
  final String field;
  final String message;
  final String? suggestion;

  const AIIssue({
    required this.type,
    required this.field,
    required this.message,
    this.suggestion,
  });
}
