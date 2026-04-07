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
        errors.add('$label: площадь ${room.area.toStringAsFixed(1)}м² < мин. ${minArea}м²');
      }

      // Проверка размеров
      if (room.width < 1.5) {
        errors.add('$label: ширина ${room.width.toStringAsFixed(1)}м < мин. 1.5м');
      }
      if (room.height < 1.5) {
        errors.add('$label: высота ${room.height.toStringAsFixed(1)}м < мин. 1.5м');
      }

      // Предупреждения
      if (room.type == 'kitchen' && room.doors.isEmpty) {
        warnings.add('$label: нет двери');
      }
      if (room.type != 'bathroom' && room.type != 'toilet' && room.type != 'hallway') {
        if (room.windows.isEmpty) {
          warnings.add('$label: нет окна');
        }
      }

      // Проверка выхода за границы
      if (room.x < 0) {
        errors.add('$label: выходит за левую границу');
      }
      if (room.y < 0) {
        errors.add('$label: выходит за верхнюю границу');
      }
      if (room.x + room.width > state.totalWidth) {
        warnings.add('$label: выходит за правую границу');
      }
      if (room.y + room.height > state.totalHeight) {
        warnings.add('$label: выходит за нижнюю границу');
      }
    }

    // Проверка пересечений комнат
    for (int i = 0; i < state.rooms.length; i++) {
      for (int j = i + 1; j < state.rooms.length; j++) {
        final a = state.rooms[i];
        final b = state.rooms[j];
        if (_intersects(a, b)) {
          final labelA = roomLabels[a.type] ?? a.type;
          final labelB = roomLabels[b.type] ?? b.type;
          errors.add('$labelA и $labelB: пересечение');
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Рассчитать compliance score (0.0 - 1.0)
  static double calculateCompliance(EditorState state) {
    final result = validate(state);
    if (result.isValid && result.warnings.isEmpty) return 1.0;

    double score = 1.0;
    score -= result.errors.length * 0.15;
    score -= result.warnings.length * 0.05;
    return score.clamp(0.0, 1.0);
  }

  /// Проверка пересечения двух комнат
  static bool _intersects(RoomState a, RoomState b) {
    return !(a.x + a.width <= b.x ||
        b.x + b.width <= a.x ||
        a.y + a.height <= b.y ||
        b.y + b.height <= a.y);
  }
}
