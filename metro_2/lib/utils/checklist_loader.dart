import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/checklist_config.dart';

class ChecklistLoader {
  /// Загружает конфигурацию чек-листа из JSON-файла
  static Future<ChecklistConfig> load(String workType) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/checklists/$workType.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final config = ChecklistConfig.fromJson(json);

      debugPrint(
        '[ChecklistLoader] Loaded "$workType" with ${config.fields.length} fields',
      );

      if (config.fields.isEmpty) {
        throw Exception(
          'Чек-лист "$workType" не содержит полей. Проверьте файл assets/checklists/$workType.json',
        );
      }

      return config;
    } on FlutterError catch (e) {
      debugPrint(
        '[ChecklistLoader] File not found: assets/checklists/$workType.json',
      );
      throw Exception(
        'Файл чек-листа не найден: assets/checklists/$workType.json. Проверьте что файл существует в assets.',
      );
    } catch (e) {
      debugPrint('[ChecklistLoader] Error loading checklist: $e');
      rethrow;
    }
  }
}
