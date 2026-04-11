/// Тип AI-инсайта
enum AIInsightType {
  warning,       // Предупреждение (пропущенные данные, аномалии)
  recommendation,// Рекомендация по улучшению
  correction,    // Автоматическая коррекция данных
  costAdvice,    // Совет по стоимости
  missingData,   // Недостающие данные
  tip,           // Полезный совет
  error,         // Критическая ошибка в данных
}

/// Уровень важности
enum AIInsightPriority {
  low,
  medium,
  high,
  critical,
}

/// Результат анализа AI-агента
class AIInsight {
  final String id;
  final AIInsightType type;
  final AIInsightPriority priority;
  final String title;
  final String description;
  final String? suggestion; // Что сделать для исправления
  final String? affectedField; // Какое поле затронуто
  final Map<String, dynamic>? metadata; // Дополнительные данные

  const AIInsight({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    this.suggestion,
    this.affectedField,
    this.metadata,
  });

  /// Иконка для типа инсайта
  String get icon {
    switch (type) {
      case AIInsightType.warning:
        return '⚠️';
      case AIInsightType.recommendation:
        return '💡';
      case AIInsightType.correction:
        return '🔧';
      case AIInsightType.costAdvice:
        return '💰';
      case AIInsightType.missingData:
        return '📋';
      case AIInsightType.tip:
        return '✨';
      case AIInsightType.error:
        return '❌';
    }
  }

  /// Цвет для типа инсайта
  String get colorHex {
    switch (type) {
      case AIInsightType.warning:
        return 'FF9800'; // оранжевый
      case AIInsightType.recommendation:
        return '2196F3'; // синий
      case AIInsightType.correction:
        return '9C27B0'; // фиолетовый
      case AIInsightType.costAdvice:
        return '4CAF50'; // зелёный
      case AIInsightType.missingData:
        return 'FF5722'; // красно-оранжевый
      case AIInsightType.tip:
        return '00BCD4'; // голубой
      case AIInsightType.error:
        return 'F44336'; // красный
    }
  }
}

/// Полный отчёт AI-агента
class AIAnalysisReport {
  final List<AIInsight> insights;
  final String summary; // Общее резюме
  final double? estimatedCost; // Пересчитанная стоимость
  final double? confidenceScore; // Уверенность анализа (0.0 - 1.0)
  final DateTime analyzedAt;

  const AIAnalysisReport({
    required this.insights,
    required this.summary,
    this.estimatedCost,
    this.confidenceScore,
    required this.analyzedAt,
  });

  /// Количество инсайтов по типам
  int get criticalCount =>
      insights.where((i) => i.priority == AIInsightPriority.critical).length;
  int get highCount =>
      insights.where((i) => i.priority == AIInsightPriority.high).length;
  int get warningCount =>
      insights.where((i) => i.priority == AIInsightPriority.medium).length;
  int get tipCount =>
      insights.where((i) => i.priority == AIInsightPriority.low).length;

  /// Есть ли критические проблемы
  bool get hasCriticalIssues => criticalCount > 0 || highCount > 0;

  /// Сортировка по приоритету
  List<AIInsight> get sortedInsights {
    final priorityOrder = {
      AIInsightPriority.critical: 0,
      AIInsightPriority.high: 1,
      AIInsightPriority.medium: 2,
      AIInsightPriority.low: 3,
    };
    final sorted = List<AIInsight>.from(insights);
    sorted.sort((a, b) =>
        priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!));
    return sorted;
  }
}
