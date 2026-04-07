import '../models/checklist_config.dart';

/// Утилитарные функции для проверки условий чек-листа
class ConditionEvaluator {
  /// Определяет, должно ли поле быть видимым
  static bool isFieldVisible(
    ChecklistField field,
    Map<String, dynamic> formData,
  ) {
    if (field.condition == null) return true;
    return field.condition!.evaluate(formData);
  }

  /// Проверяет, все ли обязательные видимые поля заполнены
  static List<String> validateRequiredFields(
    List<ChecklistField> fields,
    Map<String, dynamic> formData,
  ) {
    final errors = <String>[];

    for (final field in fields) {
      if (!isFieldVisible(field, formData)) continue;
      if (!field.required) continue;

      final value = formData[field.id];
      if (value == null ||
          (value is String && value.isEmpty) ||
          (value is num && value == 0)) {
        errors.add(field.label);
      }
    }

    return errors;
  }
}
