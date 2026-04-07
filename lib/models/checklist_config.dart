/// Модель поля чек-листа
class ChecklistField {
  final String id;
  final String type; // text, number, select, boolean, date, photo
  final String label;
  final bool required;
  final List<String>? options; // для типа select
  final ChecklistCondition? condition;
  final String? hint;

  const ChecklistField({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    this.options,
    this.condition,
    this.hint,
  });

  factory ChecklistField.fromJson(Map<String, dynamic> json) {
    return ChecklistField(
      id: json['id'] as String,
      type: json['type'] as String,
      label: json['label'] as String,
      required: json['required'] as bool? ?? false,
      options: json['options'] != null
          ? (json['options'] as List).map((e) => e as String).toList()
          : null,
      condition: json['condition'] != null
          ? ChecklistCondition.fromJson(
              json['condition'] as Map<String, dynamic>,
            )
          : null,
      hint: json['hint'] as String?,
    );
  }
}

/// Условие видимости поля
class ChecklistCondition {
  final String field;
  final String operator; // equals, not_equals, greater_than, less_than
  final dynamic value;

  const ChecklistCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory ChecklistCondition.fromJson(Map<String, dynamic> json) {
    return ChecklistCondition(
      field: json['field'] as String,
      operator: json['operator'] as String,
      value: json['value'],
    );
  }

  /// Проверка выполнения условия
  bool evaluate(Map<String, dynamic> formData) {
    final fieldValue = formData[field];

    switch (operator) {
      case 'equals':
        return _valuesEqual(fieldValue, value);
      case 'not_equals':
        return !_valuesEqual(fieldValue, value);
      case 'greater_than':
        if (fieldValue is num && value is num) {
          return fieldValue > value;
        }
        return false;
      case 'less_than':
        if (fieldValue is num && value is num) {
          return fieldValue < value;
        }
        return false;
      default:
        return false;
    }
  }

  bool _valuesEqual(dynamic a, dynamic b) {
    if (a is bool) {
      // JSON парсит true/false как bool, но может и как строку
      if (b is bool) return a == b;
      if (b is String) return a == (b.toLowerCase() == 'true');
      if (b is int) return a == (b == 1);
    }
    if (a is num && b is num) return a == b;
    return a.toString() == b.toString();
  }
}

/// Модель чек-листа
class ChecklistConfig {
  final String workType;
  final String title;
  final List<ChecklistField> fields;

  const ChecklistConfig({
    required this.workType,
    required this.title,
    required this.fields,
  });

  factory ChecklistConfig.fromJson(Map<String, dynamic> json) {
    return ChecklistConfig(
      workType: json['work_type'] as String,
      title: json['title'] as String,
      fields: (json['fields'] as List)
          .map((f) => ChecklistField.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}
