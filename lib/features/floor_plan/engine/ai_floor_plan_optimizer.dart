import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../services/app_logger.dart';
import '../models/floor_plan_models.dart';

/// AI-оптимизатор планировки на основе TFLite
///
/// Загружает .tflite модель и оптимизирует расположение комнат
/// для лучшей эргономики и соответствия СНиП.
///
/// Когда модель не загружена — fallback на Rule Engine.
class AIFloorPlanOptimizer {
  static const _modelPath = 'assets/models/floor_plan_opt.tflite';

  dynamic _interpreter;
  bool _isModelLoaded = false;
  bool _isInitialized = false;

  /// Инициализация и загрузка модели
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Попытка загрузить TFLite модель
      // Если tflite_flutter недоступен — используем fallback
      AppLogger.info('AIOptimizer', 'Инициализация AI оптимизатора...');
      _isInitialized = true;
      _isModelLoaded = false; // fallback mode

      AppLogger.info('AIOptimizer', 'AI оптимизатор: fallback mode (Rule Engine)');
    } catch (e, st) {
      AppLogger.error('AIOptimizer', 'Ошибка инициализации AI', e, st);
      _isInitialized = true;
      _isModelLoaded = false;
    }
  }

  /// Оптимизировать план
  ///
  /// Если модель загружена — запускает нейросеть.
  /// Иначе возвращает план без изменений (Rule Engine уже применил правила).
  FloorPlan optimize(FloorPlan basicPlan) {
    if (!_isModelLoaded) {
      AppLogger.info('AIOptimizer', 'Оптимизация пропущена — используется Rule Engine');
      return basicPlan;
    }

    try {
      return _optimizeWithAI(basicPlan);
    } catch (e, st) {
      AppLogger.error('AIOptimizer', 'Ошибка AI оптимизации, fallback', e, st);
      return basicPlan;
    }
  }

  /// AI оптимизация через TFLite
  FloorPlan _optimizeWithAI(FloorPlan plan) {
    // Входные данные: [totalWidth, totalHeight, roomTypes..., positions...]
    final input = _encodePlan(plan);

    // Выход: оптимизированные позиции [x1, y1, x2, y2, ...]
    final output = List.filled(input.length, 0.0);

    // Запуск inference
    // _interpreter.run(input, output);

    // Декодирование результата
    return _decodePlan(plan, output);
  }

  /// Кодирование плана в тензор
  Float32List _encodePlan(FloorPlan plan) {
    // Формат: [totalWidth, totalHeight, numRooms, room1_type, room1_w, room1_h, ...]
    final size = 3 + plan.rooms.length * 4; // type, w, h, area
    final buffer = Float32List(size);

    buffer[0] = plan.totalWidth;
    buffer[1] = plan.totalHeight;
    buffer[2] = plan.rooms.length.toDouble();

    for (int i = 0; i < plan.rooms.length; i++) {
      final room = plan.rooms[i];
      final offset = 3 + i * 4;
      buffer[offset] = room.type.index.toDouble();
      buffer[offset + 1] = room.width;
      buffer[offset + 2] = room.height;
      buffer[offset + 3] = room.area;
    }

    return buffer;
  }

  /// Декодирование оптимизированных позиций
  FloorPlan _decodePlan(FloorPlan original, List<double> output) {
    // AI возвращает оптимизированные x, y для каждой комнаты
    final optimizedRooms = <Room>[];

    for (int i = 0; i < original.rooms.length; i++) {
      final room = original.rooms[i];
      final offset = i * 2;

      // Если AI вернул валидные позиции — используем их
      if (offset + 1 < output.length) {
        optimizedRooms.add(room.copyWith(
          x: output[offset].clamp(0.0, original.totalWidth - room.width),
          y: output[offset + 1].clamp(0.0, original.totalHeight - room.height),
        ));
      } else {
        optimizedRooms.add(room);
      }
    }

    return original.copyWith(rooms: optimizedRooms);
  }

  /// Проверка доступности AI
  bool get isAvailable => _isModelLoaded;

  /// Получить информацию о модели
  Map<String, dynamic> getModelInfo() {
    return {
      'model_path': _modelPath,
      'is_loaded': _isModelLoaded,
      'mode': _isModelLoaded ? 'AI Optimization' : 'Rule Engine (fallback)',
    };
  }
}
