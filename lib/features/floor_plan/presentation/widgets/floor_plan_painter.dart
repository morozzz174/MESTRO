import 'package:flutter/material.dart';
import '../../../../utils/app_design.dart';
import '../../models/floor_plan_models.dart';
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

    // Комнаты
    for (final room in plan.rooms) {
      _drawRoom(canvas, room);
    }

    // Свободные элементы (из EditorState)
    if (editorState != null) {
      _drawFreeElements(canvas, editorState!);
    }

    // Размеры
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
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, heightInPixels),
        gridPaint,
      );
    }

    // Горизонтальные линии
    for (double y = 0; y <= heightInPixels; y += pixelsPerMeter) {
      canvas.drawLine(
        Offset(0, y),
        Offset(widthInPixels, y),
        gridPaint,
      );
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
      canvas.drawRect(rect, Paint()..color = AppDesign.statusCancelled.withOpacity(0.15));
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
    }
  }

  /// Дверь
  void _drawDoor(Canvas canvas, Room room, Door door) {
    final doorX = (room.x + door.x) * pixelsPerMeter;
    final doorY = (room.y + door.y) * pixelsPerMeter;
    final doorW = door.width * pixelsPerMeter;

    final doorPaint = Paint()
      ..color = door.type == DoorType.entrance ? AppDesign.deepSteelBlue : AppDesign.accentTeal
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
    if (window.type == WindowType.standard || window.type == WindowType.balcony) {
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
      ..color = door.type == 'entrance' ? AppDesign.deepSteelBlue : AppDesign.accentTeal
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
    _drawLabel(canvas, doorX, doorY + 15, _getDoorLabel(door.type), 9, doorPaint.color);
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
      canvas.drawLine(Offset(x, ry - rh / 2), Offset(x, ry + rh / 2), sectionPaint);
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
    _drawLabel(canvas, fx - 10, fy + 25, _getPlumbingLabel(fixture.type), 9, Colors.teal.shade700);
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
    _drawLabel(canvas, px - 5, py + 16, _getElectricalLabel(point.type), 8, Colors.amber.shade700);
  }

  String _getDoorLabel(String type) {
    switch (type) {
      case 'entrance': return 'Вход';
      case 'balcony': return 'Балкон';
      default: return 'Дверь';
    }
  }

  String _getPlumbingIcon(String type) {
    switch (type) {
      case 'sink': return '🚰';
      case 'toilet': return '🚽';
      case 'bathtub': return '🛁';
      case 'shower': return '🚿';
      case 'washingMachine': return '🧺';
      default: return '🔧';
    }
  }

  String _getPlumbingLabel(String type) {
    switch (type) {
      case 'sink': return 'Раковина';
      case 'toilet': return 'Унитаз';
      case 'bathtub': return 'Ванна';
      case 'shower': return 'Душ';
      case 'washingMachine': return 'Стиралка';
      default: return type;
    }
  }

  String _getElectricalIcon(String type) {
    switch (type) {
      case 'socket': return '🔌';
      case 'switch': return '🔘';
      case 'lightPoint': return '💡';
      case 'internetSocket': return '🌐';
      default: return '⚡';
    }
  }

  String _getElectricalLabel(String type) {
    switch (type) {
      case 'socket': return 'Розетка';
      case 'switch': return 'Выключатель';
      case 'lightPoint': return 'Свет';
      case 'internetSocket': return 'Интернет';
      default: return type;
    }
  }

  /// Подпись элемента
  void _drawLabel(Canvas canvas, double x, double y, String text, double fontSize, Color color) {
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
    widthLabel.paint(canvas, Offset((widthInPixels - widthLabel.width) / 2, heightInPixels + 25));

    // Высота (справа)
    canvas.drawLine(
      Offset(widthInPixels + 20, 0),
      Offset(widthInPixels + 20, heightInPixels),
      dimPaint,
    );

    _drawArrow(canvas, widthInPixels + 20, 0, true, vertical: true);
    _drawArrow(canvas, widthInPixels + 20, heightInPixels, false, vertical: true);

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
    canvas.translate(widthInPixels + 35, (heightInPixels - heightLabel.width) / 2);
    canvas.rotate(3.14159 / 2);
    heightLabel.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// Стрелка размера
  void _drawArrow(Canvas canvas, double x, double y, bool left, {bool vertical = false}) {
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
      text: TextSpan(text: icon, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - size / 2, y - size / 2));
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.plan != plan || 
        oldDelegate.pixelsPerMeter != pixelsPerMeter ||
        oldDelegate.editorState != editorState;
  }
}
