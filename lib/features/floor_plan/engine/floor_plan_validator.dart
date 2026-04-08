import 'dart:math' as math;
import '../models/editor_state.dart';

/// Валидатор плана в реальном времени
class FloorPlanValidator {
  /// Минимальные площади по СНиП (м²)
  static const Map<String, double> minAreas = {
    'kitchen': 8.0,
    'livingRoom': 16.0,
    'bedroom': 12.0,
    'bathroom': 3.5,
    'toilet': 1.2,
    'storage': 2.0,
    'childrenRoom': 12.0,
    'office': 9.0,
  };

  static const Map<String, String> roomLabels = {
    'kitchen': 'Кухня',
    'livingRoom': 'Гостиная',
    'bedroom': 'Спальня',
    'bathroom': 'Ванная',
    'toilet': 'Туалет',
    'storage': 'Кладовая',
    'childrenRoom': 'Детская',
    'office': 'Кабинет',
    'hallway': 'Коридор',
    'balcony': 'Балкон',
  };

  /// Валидировать план
  static ValidationResult validate(EditorState state) {
    final errors = <String>[];
    final warnings = <String>[];

    for (final room in state.rooms) {
      final label = roomLabels[room.type] ?? room.type;
      final minArea = minAreas[room.type];

      // Проверка площади
      if (minArea != null && room.area < minArea) {
        errors.add(
          '$label: площадь ${room.area.toStringAsFixed(1)}м² < мин. ${minArea}м²',
        );
      }

      // Проверка на пересечение
      for (final other in state.rooms) {
        if (other.id != room.id && _intersects(room, other)) {
          errors.add(
            '$label: пересечение с ${roomLabels[other.type] ?? other.type}',
          );
          break;
        }
      }
    }

    // Предупреждение о пустом плане
    if (state.rooms.isEmpty) {
      warnings.add('План пустой — добавьте комнаты');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Проверка пересечения двух комнат
  static bool _intersects(RoomState a, RoomState b) {
    return a.x < b.x + b.width &&
        a.x + a.width > b.x &&
        a.y < b.y + b.height &&
        a.y + a.height > b.y;
  }

  /// Рассчитать compliance score (0.0 - 1.0)
  static double calculateCompliance(EditorState state) {
    if (state.rooms.isEmpty) return 0.0;

    int passedChecks = 0;
    int totalChecks = 0;

    for (final room in state.rooms) {
      final minArea = minAreas[room.type];
      if (minArea != null) {
        totalChecks++;
        if (room.area >= minArea) passedChecks++;
      }
    }

    // Штраф за пересечения
    int intersections = 0;
    for (int i = 0; i < state.rooms.length; i++) {
      for (int j = i + 1; j < state.rooms.length; j++) {
        if (_intersects(state.rooms[i], state.rooms[j])) {
          intersections++;
          totalChecks++;
        }
      }
    }

    if (totalChecks == 0) return 1.0;
    final score = math.max(0.0, (passedChecks - intersections) / totalChecks);
    return score.clamp(0.0, 1.0);
  }
}

/// Результат валидации
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}
