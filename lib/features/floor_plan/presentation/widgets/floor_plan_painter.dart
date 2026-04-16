import 'package:flutter/material.dart';
import '../../../../utils/app_design.dart';
import '../../models/floor_plan_models_extended.dart' hide Column;
import '../../models/editor_state.dart';

/// CustomPainter для отрисовки плана помещения
class FloorPlanPainter extends CustomPainter {
  final FloorPlan plan;
  final double pixelsPerMeter;
  final EditorState? editorState; // Для отрисовки дополнительных элементов

  FloorPlanPainter(this.plan, this.pixelsPerMeter, {this.editorState});

  @override
  void paint(Canvas canvas, Size size) {
    // Фон
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Сетка
    _drawGrid(canvas, size);

    // === КОНСТРУКТИВНЫЕ ЭЛЕМЕНТЫ (рисуем ПОД комнатами) ===
    if (editorState != null) {
      // Фундамент (контур)
      _drawFoundation(canvas, editorState!);
      // Наружные стены
      _drawWalls(canvas, editorState!);
      // Осевые линии
      _drawAxisLines(canvas, editorState!);
      // Колонны
      _drawColumns(canvas, editorState!);
      // Отметки уровней
      _drawLevelMarks(canvas, editorState!);
    }

    // Комнаты
    for (final room in plan.rooms) {
      _drawRoom(canvas, room);
    }

    // Свободные элементы (из EditorState)
    if (editorState != null) {
      _drawFreeElements(canvas, editorState!);
      // Размерные линии
      _drawDimensionLines(canvas, editorState!);
    }

    // Размеры общие
    _drawDimensions(canvas, size);

    // Легенда
    _drawLegend(canvas, size);
  }

  /// Сетка (1 клетка = 1 метр)
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 0.5;

    final widthInPixels = plan.totalWidth * pixelsPerMeter;
    final heightInPixels = plan.totalHeight * pixelsPerMeter;

    // Вертикальные линии
    for (double x = 0; x <= widthInPixels; x += pixelsPerMeter) {
      canvas.drawLine(Offset(x, 0), Offset(x, heightInPixels), gridPaint);
    }

    // Горизонтальные линии
    for (double y = 0; y <= heightInPixels; y += pixelsPerMeter) {
      canvas.drawLine(Offset(0, y), Offset(widthInPixels, y), gridPaint);
    }
  }

  /// Отрисовка комнаты
  void _drawRoom(Canvas canvas, Room room) {
    final rect = Rect.fromLTWH(
      room.x * pixelsPerMeter,
      room.y * pixelsPerMeter,
      room.width * pixelsPerMeter,
      room.height * pixelsPerMeter,
    );

    // Фон комнаты
    canvas.drawRect(rect, Paint()..color = _getRoomColor(room.type));

    // Подсветка ошибок compliance
    if (room.complianceScore < 1.0) {
      canvas.drawRect(
        rect,
        Paint()..color = AppDesign.statusCancelled.withOpacity(0.15),
      );
    }

    // Стены
    final wallPaint = Paint()
      ..color = AppDesign.primaryDark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, wallPaint);

    // Двери
    for (final door in room.doors) {
      _drawDoor(canvas, room, door);
    }

    // Окна
    for (final window in room.windows) {
      _drawWindow(canvas, room, window);
    }

    // Название комнаты
    _drawRoomLabel(canvas, room, rect);

    // Площадь
    _drawRoomArea(canvas, room, rect);
  }

  /// Цвет комнаты по типу
  Color _getRoomColor(RoomType type) {
    switch (type) {
      case RoomType.kitchen:
        return Colors.orange.shade50;
      case RoomType.livingRoom:
        return Colors.blue.shade50;
      case RoomType.bedroom:
        return Colors.purple.shade50;
      case RoomType.childrenRoom:
        return Colors.green.shade50;
      case RoomType.bathroom:
        return Colors.teal.shade50;
      case RoomType.toilet:
        return Colors.cyan.shade50;
      case RoomType.hallway:
        return Colors.grey.shade100;
      case RoomType.balcony:
        return Colors.lightGreen.shade50;
      case RoomType.storage:
        return Colors.brown.shade50;
      case RoomType.office:
        return Colors.indigo.shade50;
      case RoomType.garage:
        return Colors.blueGrey.shade50;
      case RoomType.boilerRoom:
        return Colors.red.shade50;
      case RoomType.terrace:
        return Colors.lightGreen.shade100;
      case RoomType.attic:
        return Colors.purple.shade50;
      case RoomType.basement:
        return Colors.grey.shade200;
      case RoomType.wardrobe:
        return Colors.amber.shade50;
      case RoomType.laundry:
        return Colors.cyan.shade50;
      case RoomType.pantry:
        return Colors.brown.shade100;
      case RoomType.workshop:
        return Colors.orange.shade100;
      case RoomType.sauna:
        return Colors.deepOrange.shade50;
      case RoomType.pool:
        return Colors.blue.shade100;
      case RoomType.gym:
        return Colors.red.shade50;
      case RoomType.cinema:
        return Colors.indigo.shade100;
      case RoomType.elevator:
        return Colors.grey.shade100;
    }
  }

  /// Дверь
  void _drawDoor(Canvas canvas, Room room, Door door) {
    final doorX = (room.x + door.x) * pixelsPerMeter;
    final doorY = (room.y + door.y) * pixelsPerMeter;
    final doorW = door.width * pixelsPerMeter;

    final doorPaint = Paint()
      ..color = door.type == DoorType.entrance
          ? AppDesign.deepSteelBlue
          : AppDesign.accentTeal
      ..strokeWidth = 2;

    // Линия двери
    canvas.drawLine(
      Offset(doorX, doorY),
      Offset(doorX + doorW, doorY),
      doorPaint,
    );

    // Дуга открывания
    final arcRect = Rect.fromLTWH(doorX, doorY, doorW, doorW);
    canvas.drawArc(
      arcRect,
      -3.14159 / 2,
      door.clockwise ? 3.14159 / 2 : -3.14159 / 2,
      false,
      doorPaint..style = PaintingStyle.stroke,
    );

    // Иконка типа двери
    if (door.type == DoorType.entrance) {
      _drawIcon(canvas, doorX + doorW / 2, doorY - 12, '🚪', 14);
    }
  }

  /// Окно
  void _drawWindow(Canvas canvas, Room room, Window window) {
    final windowX = (room.x + window.x) * pixelsPerMeter;
    final windowY = (room.y + window.y) * pixelsPerMeter;
    final windowW = window.width * pixelsPerMeter;

    final windowPaint = Paint()
      ..color = Colors.blue.shade300
      ..strokeWidth = 2;

    // Линия окна
    canvas.drawLine(
      Offset(windowX, windowY),
      Offset(windowX + windowW, windowY),
      windowPaint,
    );

    // Двойная линия для обычных окон
    if (window.type == WindowType.standard ||
        window.type == WindowType.balcony) {
      canvas.drawLine(
        Offset(windowX, windowY + 3),
        Offset(windowX + windowW, windowY + 3),
        windowPaint..strokeWidth = 1,
      );
    }

    // Иконка окна
    _drawIcon(canvas, windowX + windowW / 2, windowY - 10, '🪟', 12);
  }

  /// Название комнаты
  void _drawRoomLabel(Canvas canvas, Room room, Rect rect) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: room.type.icon,
        style: const TextStyle(fontSize: 18),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();

    final labelX = rect.left + (rect.width - labelPainter.width) / 2;
    final labelY = rect.top + 4;

    labelPainter.paint(canvas, Offset(labelX, labelY));
  }

  /// Площадь комнаты
  void _drawRoomArea(Canvas canvas, Room room, Rect rect) {
    final areaText = '${room.area.toStringAsFixed(1)} м²';
    final areaPainter = TextPainter(
      text: TextSpan(
        text: areaText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppDesign.primaryDark.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    areaPainter.layout();

    final areaX = rect.left + (rect.width - areaPainter.width) / 2;
    final areaY = rect.bottom - areaPainter.height - 4;

    areaPainter.paint(canvas, Offset(areaX, areaY));
  }

  /// Отрисовка свободных элементов (не привязанных к комнатам)
  void _drawFreeElements(Canvas canvas, EditorState state) {
    // Двери
    for (final door in state.doors) {
      _drawFreeDoor(canvas, door);
    }

    // Окна
    for (final window in state.windows) {
      _drawFreeWindow(canvas, window);
    }

    // Радиаторы
    for (final radiator in state.radiators) {
      _drawRadiator(canvas, radiator);
    }

    // Сантехника
    for (final fixture in state.plumbingFixtures) {
      _drawPlumbingFixture(canvas, fixture);
    }

    // Электрика
    for (final point in state.electricalPoints) {
      _drawElectricalPoint(canvas, point);
    }
  }

  /// Свободная дверь
  void _drawFreeDoor(Canvas canvas, DoorState door) {
    final doorX = door.x * pixelsPerMeter;
    final doorY = door.y * pixelsPerMeter;
    final doorW = door.width * pixelsPerMeter;

    final doorPaint = Paint()
      ..color = door.type == 'entrance'
          ? AppDesign.deepSteelBlue
          : AppDesign.accentTeal
      ..strokeWidth = 2;

    // Линия двери
    canvas.drawLine(
      Offset(doorX, doorY),
      Offset(doorX + doorW, doorY),
      doorPaint,
    );

    // Иконка
    final icon = door.type == 'entrance' ? '🚪' : '🚪';
    _drawIcon(canvas, doorX + doorW / 2, doorY - 10, icon, 14);

    // Подпись
    _drawLabel(
      canvas,
      doorX,
      doorY + 15,
      _getDoorLabel(door.type),
      9,
      doorPaint.color,
    );
  }

  /// Свободное окно
  void _drawFreeWindow(Canvas canvas, WindowState window) {
    final windowX = window.x * pixelsPerMeter;
    final windowY = window.y * pixelsPerMeter;
    final windowW = window.width * pixelsPerMeter;

    final windowPaint = Paint()
      ..color = Colors.blue.shade300
      ..strokeWidth = 2;

    // Линия окна
    canvas.drawLine(
      Offset(windowX, windowY),
      Offset(windowX + windowW, windowY),
      windowPaint,
    );

    // Двойная линия
    canvas.drawLine(
      Offset(windowX, windowY + 3),
      Offset(windowX + windowW, windowY + 3),
      windowPaint..strokeWidth = 1,
    );

    // Иконка
    _drawIcon(canvas, windowX + windowW / 2, windowY - 10, '🪟', 12);

    // Подпись
    _drawLabel(canvas, windowX, windowY + 15, 'Окно', 9, Colors.blue.shade300);
  }

  /// Радиатор
  void _drawRadiator(Canvas canvas, RadiatorState radiator) {
    final rx = radiator.x * pixelsPerMeter;
    final ry = radiator.y * pixelsPerMeter;
    final rw = radiator.length * pixelsPerMeter;
    const rh = 10.0;

    final radiatorPaint = Paint()
      ..color = Colors.red.shade300
      ..style = PaintingStyle.fill;

    // Корпус радиатора
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rx, ry - rh / 2, rw, rh),
        const Radius.circular(2),
      ),
      radiatorPaint,
    );

    // Секции (линии)
    final sectionPaint = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 1;
    final sectionWidth = 20.0;
    for (double x = rx + sectionWidth; x < rx + rw; x += sectionWidth) {
      canvas.drawLine(
        Offset(x, ry - rh / 2),
        Offset(x, ry + rh / 2),
        sectionPaint,
      );
    }

    // Иконка
    _drawIcon(canvas, rx + rw / 2, ry - 12, '🔥', 12);

    // Подпись
    _drawLabel(canvas, rx, ry + 12, 'Радиатор', 9, Colors.red.shade700);
  }

  /// Сантехнический прибор
  void _drawPlumbingFixture(Canvas canvas, PlumbingFixtureState fixture) {
    final fx = fixture.x * pixelsPerMeter;
    final fy = fixture.y * pixelsPerMeter;

    // Иконка
    final icon = _getPlumbingIcon(fixture.type);
    _drawIcon(canvas, fx + 10, fy + 10, icon, 20);

    // Подпись
    _drawLabel(
      canvas,
      fx - 10,
      fy + 25,
      _getPlumbingLabel(fixture.type),
      9,
      Colors.teal.shade700,
    );
  }

  /// Электрическая точка
  void _drawElectricalPoint(Canvas canvas, ElectricalPointState point) {
    final px = point.x * pixelsPerMeter;
    final py = point.y * pixelsPerMeter;

    // Кружок
    final circlePaint = Paint()
      ..color = Colors.amber.shade300
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(px + 6, py + 6), 6, circlePaint);

    // Обводка
    final borderPaint = Paint()
      ..color = Colors.amber.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(px + 6, py + 6), 6, borderPaint);

    // Иконка
    final icon = _getElectricalIcon(point.type);
    _drawIcon(canvas, px + 2, py + 2, icon, 10);

    // Подпись
    _drawLabel(
      canvas,
      px - 5,
      py + 16,
      _getElectricalLabel(point.type),
      8,
      Colors.amber.shade700,
    );
  }

  String _getDoorLabel(String type) {
    switch (type) {
      case 'entrance':
        return 'Вход';
      case 'balcony':
        return 'Балкон';
      default:
        return 'Дверь';
    }
  }

  String _getPlumbingIcon(String type) {
    switch (type) {
      case 'sink':
        return '🚰';
      case 'toilet':
        return '🚽';
      case 'bathtub':
        return '🛁';
      case 'shower':
        return '🚿';
      case 'washingMachine':
        return '🧺';
      default:
        return '🔧';
    }
  }

  String _getPlumbingLabel(String type) {
    switch (type) {
      case 'sink':
        return 'Раковина';
      case 'toilet':
        return 'Унитаз';
      case 'bathtub':
        return 'Ванна';
      case 'shower':
        return 'Душ';
      case 'washingMachine':
        return 'Стиралка';
      default:
        return type;
    }
  }

  String _getElectricalIcon(String type) {
    switch (type) {
      case 'socket':
        return '🔌';
      case 'switch':
        return '🔘';
      case 'lightPoint':
        return '💡';
      case 'internetSocket':
        return '🌐';
      default:
        return '⚡';
    }
  }

  String _getElectricalLabel(String type) {
    switch (type) {
      case 'socket':
        return 'Розетка';
      case 'switch':
        return 'Выключатель';
      case 'lightPoint':
        return 'Свет';
      case 'internetSocket':
        return 'Интернет';
      default:
        return type;
    }
  }

  /// Подпись элемента
  void _drawLabel(
    Canvas canvas,
    double x,
    double y,
    String text,
    double fontSize,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  /// Размеры плана
  void _drawDimensions(Canvas canvas, Size size) {
    final widthInPixels = plan.totalWidth * pixelsPerMeter;
    final heightInPixels = plan.totalHeight * pixelsPerMeter;

    final dimPaint = Paint()
      ..color = AppDesign.primaryDark
      ..strokeWidth = 1.5;

    // Ширина (внизу)
    canvas.drawLine(
      Offset(0, heightInPixels + 20),
      Offset(widthInPixels, heightInPixels + 20),
      dimPaint,
    );

    // Стрелки
    _drawArrow(canvas, 0, heightInPixels + 20, true);
    _drawArrow(canvas, widthInPixels, heightInPixels + 20, false);

    // Текст ширины
    final widthLabel = TextPainter(
      text: TextSpan(
        text: '${plan.totalWidth.toStringAsFixed(1)} м',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppDesign.primaryDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    widthLabel.layout();
    widthLabel.paint(
      canvas,
      Offset((widthInPixels - widthLabel.width) / 2, heightInPixels + 25),
    );

    // Высота (справа)
    canvas.drawLine(
      Offset(widthInPixels + 20, 0),
      Offset(widthInPixels + 20, heightInPixels),
      dimPaint,
    );

    _drawArrow(canvas, widthInPixels + 20, 0, true, vertical: true);
    _drawArrow(
      canvas,
      widthInPixels + 20,
      heightInPixels,
      false,
      vertical: true,
    );

    final heightLabel = TextPainter(
      text: TextSpan(
        text: '${plan.totalHeight.toStringAsFixed(1)} м',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppDesign.primaryDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    heightLabel.layout();

    canvas.save();
    canvas.translate(
      widthInPixels + 35,
      (heightInPixels - heightLabel.width) / 2,
    );
    canvas.rotate(3.14159 / 2);
    heightLabel.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// Стрелка размера
  void _drawArrow(
    Canvas canvas,
    double x,
    double y,
    bool left, {
    bool vertical = false,
  }) {
    final path = Path();
    if (vertical) {
      path.moveTo(x, y);
      path.lineTo(x - 5, y + (left ? 8 : -8));
      path.lineTo(x + 5, y + (left ? 8 : -8));
    } else {
      path.moveTo(x, y);
      path.lineTo(x + (left ? 8 : -8), y - 5);
      path.lineTo(x + (left ? 8 : -8), y + 5);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = AppDesign.primaryDark);
  }

  /// Легенда
  void _drawLegend(Canvas canvas, Size size) {
    final legendY = plan.totalHeight * pixelsPerMeter + 60;

    final items = [
      ('🚪 Входная', AppDesign.deepSteelBlue),
      ('🚪 Межкомнатная', AppDesign.accentTeal),
      ('🪟 Окно', Colors.blue.shade300),
    ];

    double currentX = 10;
    for (final (label, color) in items) {
      // Кружок цвета
      canvas.drawCircle(
        Offset(currentX + 8, legendY),
        6,
        Paint()..color = color,
      );

      // Текст
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(currentX + 18, legendY - 6));

      currentX += textPainter.width + 30;
    }
  }

  /// Иконка (эмодзи)
  void _drawIcon(Canvas canvas, double x, double y, String icon, double size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: TextStyle(fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - size / 2, y - size / 2));
  }

  // ========================================================================
  // КОНСТРУКТИВНЫЕ ЭЛЕМЕНТЫ
  // ========================================================================

  /// Фундамент — контур
  void _drawFoundation(Canvas canvas, EditorState state) {
    final f = state.foundation;
    if (f == null) return;

    final ppm = pixelsPerMeter;
    final rect = Rect.fromLTWH(
      (state.totalWidth / 2 - f.width / 2) * ppm,
      (state.totalHeight / 2 - f.depth / 2) * ppm,
      f.width * ppm,
      f.depth * ppm,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.brown.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.brown.shade700
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Подпись
    _drawLabel(
      canvas,
      rect.left,
      rect.top - 14,
      'Фундамент: ${_foundationTypeLabel(f.type)}',
      10,
      Colors.brown.shade700,
    );
  }

  /// Стены
  void _drawWalls(Canvas canvas, EditorState state) {
    for (final wall in state.walls) {
      final ppm = pixelsPerMeter;
      final x1 = wall.x1 * ppm;
      final y1 = wall.y1 * ppm;
      final x2 = wall.x2 * ppm;
      final y2 = wall.y2 * ppm;

      // Толщина стены в пикселях
      final thickness = (wall.thickness * ppm).clamp(2.0, 20.0);

      // Цвет по типу
      Color wallColor;
      if (wall.type == 'exterior') {
        wallColor = Colors.red.shade700;
      } else if (wall.type == 'foundation') {
        wallColor = Colors.brown.shade600;
      } else if (wall.isLoadBearing) {
        wallColor = Colors.orange.shade800;
      } else {
        wallColor = Colors.blueGrey.shade400;
      }

      final wallPaint = Paint()
        ..color = wallColor
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), wallPaint);

      // Подпись материала для наружных стен
      if (wall.type == 'exterior') {
        final mx = (x1 + x2) / 2;
        final my = (y1 + y2) / 2;
        _drawLabel(
          canvas,
          mx,
          my - thickness - 6,
          _materialShortLabel(wall.material),
          8,
          wallColor,
        );
      }
    }
  }

  /// Осевые линии
  void _drawAxisLines(Canvas canvas, EditorState state) {
    for (final axis in state.axisLines) {
      final ppm = pixelsPerMeter;
      final x1 = axis.x1 * ppm;
      final y1 = axis.y1 * ppm;
      final x2 = axis.x2 * ppm;
      final y2 = axis.y2 * ppm;

      // Штрих-пунктир
      final dashPaint = Paint()
        ..color = Colors.red.shade700
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      _drawDashedLine(canvas, Offset(x1, y1), Offset(x2, y2), dashPaint, 8, 4);

      // Кружок с обозначением оси
      final circlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x1, y1), 10, circlePaint);
      canvas.drawCircle(
        Offset(x1, y1),
        10,
        Paint()
          ..color = Colors.red.shade700
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: axis.label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x1 - textPainter.width / 2, y1 - textPainter.height / 2),
      );
    }
  }

  /// Колонны
  void _drawColumns(Canvas canvas, EditorState state) {
    for (final col in state.columns) {
      final ppm = pixelsPerMeter;
      final cx = col.x * ppm;
      final cy = col.y * ppm;
      final cw = col.width * ppm;
      final ch = col.height * ppm;

      final colRect = Rect.fromLTWH(cx - cw / 2, cy - ch / 2, cw, ch);

      // Заливка
      canvas.drawRect(
        colRect,
        Paint()
          ..color = Colors.grey.shade600
          ..style = PaintingStyle.fill,
      );

      // Обводка
      canvas.drawRect(
        colRect,
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );

      // Штриховка (крест)
      canvas.drawLine(
        Offset(colRect.left, colRect.top),
        Offset(colRect.right, colRect.bottom),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 0.5,
      );
      canvas.drawLine(
        Offset(colRect.right, colRect.top),
        Offset(colRect.left, colRect.bottom),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 0.5,
      );
    }
  }

  /// Отметки уровней
  void _drawLevelMarks(Canvas canvas, EditorState state) {
    for (final level in state.levelMarks) {
      final ppm = pixelsPerMeter;
      final lx = level.x * ppm;
      final ly = level.y * ppm;

      // Стрелка вниз
      final arrowPaint = Paint()
        ..color = Colors.blue.shade700
        ..strokeWidth = 1.5;

      canvas.drawLine(Offset(lx, ly - 20), Offset(lx, ly), arrowPaint);
      // Треугольник
      final triangle = Path()
        ..moveTo(lx, ly)
        ..lineTo(lx - 5, ly - 8)
        ..lineTo(lx + 5, ly - 8)
        ..close();
      canvas.drawPath(triangle, Paint()..color = Colors.blue.shade700);

      // Подпись
      final levelText = level.level > 0
          ? '+${level.level.toStringAsFixed(3)}'
          : level.level.toStringAsFixed(3);
      final desc = level.description != null ? ' ${level.description}' : '';
      _drawLabel(
        canvas,
        lx + 8,
        ly - 4,
        '$levelText$desc',
        10,
        Colors.blue.shade700,
      );
    }
  }

  /// Размерные линии (из EditorState)
  void _drawDimensionLines(Canvas canvas, EditorState state) {
    for (final dim in state.dimensionLines) {
      final ppm = pixelsPerMeter;
      final x1 = dim.x1 * ppm;
      final y1 = dim.y1 * ppm;
      final x2 = dim.x2 * ppm;
      final y2 = dim.y2 * ppm;

      final dimPaint = Paint()
        ..color = Colors.green.shade700
        ..strokeWidth = 1.5;

      // Линия
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dimPaint);

      // Засечки
      _drawTick(canvas, Offset(x1, y1), dimPaint);
      _drawTick(canvas, Offset(x2, y2), dimPaint);

      // Текст
      final mx = (x1 + x2) / 2;
      final my = (y1 + y2) / 2;
      _drawLabel(canvas, mx, my - 10, dim.value, 11, Colors.green.shade700);
    }
  }

  /// Штриховая линия
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    double distance = 0;

    while (distance < totalLength) {
      final dashEnd = distance + dashLength;
      final p1 = start + direction * distance;
      final p2 = start + direction * dashEnd.clamp(0, totalLength);
      canvas.drawLine(p1, p2, paint);
      distance += dashLength + gapLength;
    }
  }

  /// Засечка для размерной линии
  void _drawTick(Canvas canvas, Offset point, Paint paint) {
    canvas.drawLine(
      Offset(point.dx - 4, point.dy - 4),
      Offset(point.dx + 4, point.dy + 4),
      paint,
    );
  }

  String _foundationTypeLabel(String t) {
    switch (t) {
      case 'strip':
        return 'Ленточный';
      case 'slab':
        return 'Плитный';
      case 'pile':
        return 'Свайный';
      case 'column':
        return 'Столбчатый';
      case 'screw':
        return 'Винтовые сваи';
      default:
        return t;
    }
  }

  String _materialShortLabel(String m) {
    switch (m) {
      case 'brick':
        return 'КИР';
      case 'gasBlockD400':
      case 'gasBlockD500':
      case 'gasBlockD600':
        return 'ГБ';
      case 'concrete':
        return 'ЖБ';
      case 'timber':
        return 'ДЕР';
      case 'keramoblock':
        return 'КБ';
      case 'foamBlock':
        return 'ПБ';
      case 'sipPanel':
        return 'СИП';
      default:
        return m.substring(0, m.length > 3 ? 3 : m.length).toUpperCase();
    }
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.pixelsPerMeter != pixelsPerMeter ||
        oldDelegate.editorState != editorState;
  }
}

/// 2.5D Изометрический Painter для плана этажа
class IsoPlanPainter extends CustomPainter {
  final FloorPlan plan;
  final double pixelsPerMeter;
  final EditorState? editorState;
  final double wallHeight; // Высота стен для 3D эффекта (в метрах)

  IsoPlanPainter(
    this.plan,
    this.pixelsPerMeter, {
    this.editorState,
    this.wallHeight = 2.7,
  });

  // Изометрические константы (30° угол)
  static const double isoAngle = 0.5236; // 30° в радианах
  static const double cosAngle = 0.866; // cos(30°)
  static const double sinAngle = 0.5; // sin(30°)

  @override
  void paint(Canvas canvas, Size size) {
    // Фон
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey.shade100,
    );

    // Центрируем план
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 50;

    // Рисуем в порядке: от дальних к ближним (z-sorting)
    _drawFloor(canvas, centerX, centerY);

    if (editorState != null) {
      _drawWalls3D(canvas, centerX, centerY);
      _drawFoundation3D(canvas, centerX, centerY);
    }

    // Рисуем комнаты
    for (final room in plan.rooms) {
      _drawRoom3D(canvas, room, centerX, centerY);
    }

    // Рисуем свободные элементы
    if (editorState != null) {
      _drawFreeElements3D(canvas, centerX, centerY);
    }

    // Легенда
    _drawIsoLegend(canvas, size);
  }

  /// Конвертация 2D координат в изометрические
  Offset isoTransform(
    double x,
    double y,
    double z,
    double centerX,
    double centerY,
  ) {
    final px = (x - y) * cosAngle * pixelsPerMeter;
    final py = (x + y) * sinAngle * pixelsPerMeter - z * pixelsPerMeter;
    return Offset(centerX + px, centerY + py);
  }

  void _drawFloor(Canvas canvas, double centerX, double centerY) {
    final p = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Вершины пола в 2D
    final p1 = isoTransform(0, 0, 0, centerX, centerY);
    final p2 = isoTransform(plan.totalWidth, 0, 0, centerX, centerY);
    final p3 = isoTransform(
      plan.totalWidth,
      plan.totalHeight,
      0,
      centerX,
      centerY,
    );
    final p4 = isoTransform(0, plan.totalHeight, 0, centerX, centerY);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(path, p);
    canvas.drawPath(path, outlinePaint);

    // Сетка на полу
    _drawIsoGrid(canvas, centerX, centerY);
  }

  void _drawIsoGrid(Canvas canvas, double centerX, double centerY) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    // Вертикальные линии
    for (double x = 0; x <= plan.totalWidth; x += 1) {
      final p1 = isoTransform(x, 0, 0, centerX, centerY);
      final p2 = isoTransform(x, plan.totalHeight, 0, centerX, centerY);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // Горизонтальные линии
    for (double y = 0; y <= plan.totalHeight; y += 1) {
      final p1 = isoTransform(0, y, 0, centerX, centerY);
      final p2 = isoTransform(plan.totalWidth, y, 0, centerX, centerY);
      canvas.drawLine(p1, p2, gridPaint);
    }
  }

  void _drawRoom3D(Canvas canvas, Room room, double centerX, double centerY) {
    // Рисуем только название комнаты на полу
    final center = isoTransform(
      room.x + room.width / 2,
      room.y + room.height / 2,
      0,
      centerX,
      centerY,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: _getRoomLabel(room.type),
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Рисуем тень под текстом
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Рисуем двери
    for (final door in room.doors) {
      _drawDoor3D(canvas, room, door, centerX, centerY);
    }

    // Рисуем окна
    for (final window in room.windows) {
      _drawWindow3D(canvas, room, window, centerX, centerY);
    }
  }

  void _drawDoor3D(
    Canvas canvas,
    Room room,
    Door door,
    double centerX,
    double centerY,
  ) {
    final doorPaint = Paint()
      ..color = Colors.brown.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Проём двери на полу
    final x = room.x + door.x;
    final y = room.y + door.y;
    final p1 = isoTransform(x, y, 0, centerX, centerY);
    final p2 = isoTransform(x + door.width, y, 0, centerX, centerY);

    canvas.drawLine(p1, p2, doorPaint);
  }

  void _drawWindow3D(
    Canvas canvas,
    Room room,
    Window window,
    double centerX,
    double centerY,
  ) {
    final windowPaint = Paint()
      ..color = Colors.cyan.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final x = room.x + window.x;
    final y = room.y + window.y;
    final p1 = isoTransform(x, y, 0, centerX, centerY);
    final p2 = isoTransform(x + window.width, y, 0, centerX, centerY);

    canvas.drawLine(p1, p2, windowPaint);
  }

  void _drawWalls3D(Canvas canvas, double centerX, double centerY) {
    if (editorState == null) return;

    for (final wall in editorState!.walls) {
      final h = wall.height > 0 ? wall.height : wallHeight;

      // Определяем цвет стены
      Color wallColor;
      if (wall.type == 'exterior') {
        wallColor = Colors.grey.shade400;
      } else if (wall.type == 'foundation') {
        wallColor = Colors.brown.shade400;
      } else if (wall.isLoadBearing) {
        wallColor = Colors.grey.shade500;
      } else {
        wallColor = Colors.grey.shade300;
      }

      final lightColor = wallColor.withValues(alpha: 0.7);
      final darkColor = wallColor.withValues(alpha: 0.9);

      // Верхняя грань стены
      final topLeft = isoTransform(wall.x1, wall.y1, h, centerX, centerY);
      final topRight = isoTransform(wall.x2, wall.y2, h, centerX, centerY);

      // Нижняя грань стены
      final bottomLeft = isoTransform(wall.x1, wall.y1, 0, centerX, centerY);
      final bottomRight = isoTransform(wall.x2, wall.y2, 0, centerX, centerY);

      // Толщина стены
      final thickness = (wall.thickness * pixelsPerMeter).clamp(4.0, 15.0);

      // Определяем направление стены
      final dx = wall.x2 - wall.x1;
      final dy = wall.y2 - wall.y1;
      final isHorizontal = dx.abs() > dy.abs();

      // Рисуем боковые грани
      final sidePaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.fill;

      final path = Path();
      if (isHorizontal) {
        // Ближняя грань (к зрителю)
        path.moveTo(topRight.dx, topRight.dy);
        path.lineTo(bottomRight.dx, bottomRight.dy);
        path.lineTo(
          bottomRight.dx - thickness,
          bottomRight.dy + thickness * 0.5,
        );
        path.lineTo(topRight.dx - thickness, topRight.dy + thickness * 0.5);
        path.close();
      } else {
        // Ближняя грань
        path.moveTo(topRight.dx, topRight.dy);
        path.lineTo(bottomRight.dx, bottomRight.dy);
        path.lineTo(
          bottomRight.dx + thickness,
          bottomRight.dy + thickness * 0.5,
        );
        path.lineTo(topRight.dx + thickness, topRight.dy + thickness * 0.5);
        path.close();
      }
      canvas.drawPath(path, sidePaint);

      // Рисуем верхнюю грань
      final topPaint = Paint()
        ..color = lightColor
        ..style = PaintingStyle.fill;

      final topPath = Path()
        ..moveTo(topLeft.dx, topLeft.dy)
        ..lineTo(topRight.dx, topRight.dy)
        ..lineTo(topRight.dx - thickness, topRight.dy + thickness * 0.5)
        ..lineTo(topLeft.dx - thickness, topLeft.dy + thickness * 0.5)
        ..close();

      canvas.drawPath(topPath, topPaint);

      // Контур стены
      final outlinePaint = Paint()
        ..color = wallColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawLine(topLeft, topRight, outlinePaint);
      canvas.drawLine(bottomLeft, bottomRight, outlinePaint);
    }
  }

  void _drawFoundation3D(Canvas canvas, double centerX, double centerY) {
    if (editorState?.foundation == null) return;

    final f = editorState!.foundation!;
    final h = 0.3; // Фиксированная высота фундамента

    final centerDx = (plan.totalWidth - f.width) / 2;
    final centerDy = (plan.totalHeight - f.depth) / 2;

    final p1 = isoTransform(centerDx, centerDy, -h, centerX, centerY);
    final p2 = isoTransform(centerDx + f.width, centerDy, -h, centerX, centerY);
    final p3 = isoTransform(
      centerDx + f.width,
      centerDy + f.depth,
      -h,
      centerX,
      centerY,
    );
    final p4 = isoTransform(centerDx, centerDy + f.depth, -h, centerX, centerY);

    final p5 = isoTransform(centerDx, centerDy, 0, centerX, centerY);
    final p6 = isoTransform(centerDx + f.width, centerDy, 0, centerX, centerY);
    final p7 = isoTransform(
      centerDx + f.width,
      centerDy + f.depth,
      0,
      centerX,
      centerY,
    );
    final p8 = isoTransform(centerDx, centerDy + f.depth, 0, centerX, centerY);

    final fillPaint = Paint()
      ..color = Colors.brown.shade300.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.brown.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Верхняя грань
    final topPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();
    canvas.drawPath(topPath, fillPaint);
    canvas.drawPath(topPath, outlinePaint);

    // Боковые грани
    _drawIsoSide(canvas, p1, p2, p6, p5, Colors.brown.shade400, outlinePaint);
    _drawIsoSide(canvas, p2, p3, p7, p6, Colors.brown.shade300, outlinePaint);
  }

  void _drawIsoSide(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Offset p3,
    Offset p4,
    Color color,
    Paint outline,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, outline);
  }

  void _drawFreeElements3D(Canvas canvas, double centerX, double centerY) {
    // Рисуем радиаторы
    for (final radiator in editorState!.radiators) {
      _drawRadiator3D(canvas, radiator, centerX, centerY);
    }

    // Рисуем сантехнику
    for (final fixture in editorState!.plumbingFixtures) {
      _drawPlumbing3D(canvas, fixture, centerX, centerY);
    }

    // Рисуем электрику
    for (final point in editorState!.electricalPoints) {
      _drawElectrical3D(canvas, point, centerX, centerY);
    }
  }

  void _drawRadiator3D(Canvas canvas, RadiatorState r, double cx, double cy) {
    final pos = isoTransform(r.x, r.y, 0, cx, cy);
    final h = 0.6;

    final topPoint = isoTransform(r.x, r.y, h, cx, cy);

    final paint = Paint()
      ..color = Colors.red.shade300
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = Colors.red.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(topPoint.dx, topPoint.dy);

    // Рисуем несколько секций
    for (int i = 0; i < 6; i++) {
      final offset = i * 3.0;
      path.lineTo(pos.dx + offset, pos.dy - h * 0.3);
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, outline);
  }

  void _drawPlumbing3D(
    Canvas canvas,
    PlumbingFixtureState f,
    double cx,
    double cy,
  ) {
    final pos = isoTransform(f.x, f.y, 0, cx, cy);
    final paint = Paint()
      ..color = Colors.teal.shade300
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, 8, paint);
  }

  void _drawElectrical3D(
    Canvas canvas,
    ElectricalPointState p,
    double cx,
    double cy,
  ) {
    final pos = isoTransform(p.x, p.y, 0, cx, cy);
    final paint = Paint()
      ..color = Colors.amber.shade600
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, 4, paint);
  }

  String _getRoomLabel(RoomType type) {
    switch (type) {
      case RoomType.kitchen:
        return 'Кухня';
      case RoomType.livingRoom:
        return 'Гостиная';
      case RoomType.bedroom:
        return 'Спальня';
      case RoomType.childrenRoom:
        return 'Детская';
      case RoomType.bathroom:
        return 'Ванная';
      case RoomType.toilet:
        return 'Туалет';
      case RoomType.hallway:
        return 'Коридор';
      case RoomType.balcony:
        return 'Балкон';
      case RoomType.storage:
        return 'Кладовая';
      case RoomType.office:
        return 'Кабинет';
      default:
        return 'Комната';
    }
  }

  void _drawIsoLegend(Canvas canvas, Size size) {
    final legendPaint = TextPainter(
      text: const TextSpan(
        text: '2.5D Вид',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    legendPaint.paint(canvas, Offset(10, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant IsoPlanPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.pixelsPerMeter != pixelsPerMeter ||
        oldDelegate.editorState != editorState ||
        oldDelegate.wallHeight != wallHeight;
  }
}
