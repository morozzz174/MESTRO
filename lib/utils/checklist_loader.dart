import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/checklist_config.dart';

class ChecklistLoader {
  /// Загружает конфигурацию чек-листа из JSON-файла
  static Future<ChecklistConfig> load(String workType) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/checklists/$workType.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ChecklistConfig.fromJson(json);
    } catch (e) {
      // Если файл не найден, возвращаем пустой чек-лист
      return ChecklistConfig(workType: workType, title: workType, fields: []);
    }
  }
}
