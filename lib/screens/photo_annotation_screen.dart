import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../models/order.dart';

class PhotoAnnotationScreen extends StatefulWidget {
  final PhotoAnnotation photo;

  const PhotoAnnotationScreen({super.key, required this.photo});

  @override
  State<PhotoAnnotationScreen> createState() => _PhotoAnnotationScreenState();
}

class _PhotoAnnotationScreenState extends State<PhotoAnnotationScreen> {
  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _undoStack = [];
  DrawingStroke? _currentStroke;
  DrawMode _mode = DrawMode.pen;
  final GlobalKey<_CanvasImageState> _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аннотации'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAndExit,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Область изображения с рисованием
          Expanded(
            child: _CanvasImage(
              key: _canvasKey,
              imagePath: widget.photo.filePath,
              strokes: _strokes,
              currentStroke: _currentStroke,
              mode: _mode,
              onStrokeStart: _onStrokeStart,
              onStrokeMove: _onStrokeMove,
              onStrokeEnd: _onStrokeEnd,
            ),
          ),

          // Панель инструментов
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  icon: Icons.edit,
                  label: 'Кисть',
                  isSelected: _mode == DrawMode.pen,
                  onTap: () => setState(() => _mode = DrawMode.pen),
                ),
                _ToolButton(
                  icon: Icons.circle,
                  label: 'Круг',
                  isSelected: _mode == DrawMode.circle,
                  onTap: () => setState(() => _mode = DrawMode.circle),
                ),
                _ToolButton(
                  icon: Icons.arrow_forward,
                  label: 'Стрелка',
                  isSelected: _mode == DrawMode.arrow,
                  onTap: () => setState(() => _mode = DrawMode.arrow),
                ),
                _ToolButton(
                  icon: Icons.text_fields,
                  label: 'Текст',
                  onTap: _addText,
                ),
                _ToolButton(
                  icon: Icons.color_lens,
                  label: 'Цвет',
                  onTap: _changeColor,
                ),
                _ToolButton(icon: Icons.undo, label: 'Отмена', onTap: _undo),
                _ToolButton(
                  icon: Icons.delete_sweep,
                  label: 'Очистить',
                  onTap: _clear,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onStrokeStart(Offset position) {
    setState(() {
      _currentStroke = DrawingStroke(
        points: [position],
        color: _mode == DrawMode.text ? Colors.yellow : Colors.red,
        mode: _mode,
        width: _mode == DrawMode.pen ? 4.0 : 2.0,
      );
    });
  }

  void _onStrokeMove(Offset position) {
    if (_currentStroke != null) {
      setState(() {
        _currentStroke = _currentStroke!.copyWith(
          points: [..._currentStroke!.points, position],
        );
      });
    }
  }

  void _onStrokeEnd() {
    if (_currentStroke != null && _currentStroke!.points.isNotEmpty) {
      setState(() {
        _strokes.add(_currentStroke!);
        _undoStack.clear();
        _currentStroke = null;
      });
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _undoStack.add(_strokes.removeLast());
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _undoStack.clear();
    });
  }

  Future<void> _addText() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить текст'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введите текст аннотации',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (text != null && text.isNotEmpty) {
      setState(() {
        _strokes.add(
          DrawingStroke(
            points: [const Offset(100, 100)],
            color: Colors.yellow,
            mode: DrawMode.text,
            text: text,
            width: 0,
          ),
        );
      });
    }
  }

  Future<void> _changeColor() async {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.white,
    ];

    final color = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите цвет'),
        content: Wrap(
          spacing: 8,
          children: colors
              .map(
                (c) => GestureDetector(
                  onTap: () => Navigator.of(context).pop(c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (color != null && _strokes.isNotEmpty) {
      setState(() {
        _strokes[_strokes.length - 1] = _strokes.last.copyWith(color: color);
      });
    }
  }

  Future<void> _saveAndExit() async {
    try {
      final image = await _canvasKey.currentState?.getImageWithAnnotations();

      String? savedPath;
      if (image != null) {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          final tempDir = Directory.systemTemp;
          final filePath = '${tempDir.path}/annotated_${widget.photo.id}.png';
          final file = File(filePath);
          await file.writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
          savedPath = filePath;
        }
      }

      if (mounted) {
        Navigator.of(context).pop(
          PhotoAnnotation(
            id: widget.photo.id,
            orderId: widget.photo.orderId,
            filePath: widget.photo.filePath,
            annotatedPath: savedPath ?? widget.photo.filePath,
            checklistFieldId: widget.photo.checklistFieldId,
            latitude: widget.photo.latitude,
            longitude: widget.photo.longitude,
            timestamp: widget.photo.timestamp,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    }
  }
}

// ===== Режимы рисования =====
enum DrawMode { pen, circle, arrow, text }

// ===== Штрих =====
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final DrawMode mode;
  final double width;
  final String? text;

  const DrawingStroke({
    required this.points,
    required this.color,
    required this.mode,
    required this.width,
    this.text,
  });

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    DrawMode? mode,
    double? width,
    String? text,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      mode: mode ?? this.mode,
      width: width ?? this.width,
      text: text ?? this.text,
    );
  }
}

// ===== Виджет canvas с изображением =====
class _CanvasImage extends StatefulWidget {
  final String imagePath;
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final DrawMode mode;
  final ValueChanged<Offset> onStrokeStart;
  final ValueChanged<Offset> onStrokeMove;
  final VoidCallback onStrokeEnd;

  const _CanvasImage({
    super.key,
    required this.imagePath,
    required this.strokes,
    required this.currentStroke,
    required this.mode,
    required this.onStrokeStart,
    required this.onStrokeMove,
    required this.onStrokeEnd,
  });

  @override
  State<_CanvasImage> createState() => _CanvasImageState();
}

class _CanvasImageState extends State<_CanvasImage> {
  Size _imageSize = Size.zero;
  final List<Offset> _currentPoints = [];

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = File(widget.imagePath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      if (mounted) {
        setState(() {
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        });
      }
    }
  }

  Future<ui.Image?> getImageWithAnnotations() async {
    if (_imageSize == Size.zero) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final bgImage = frame.image;

    canvas.drawImage(bgImage, Offset.zero, Paint());

    // Рисуем аннотации
    final painter = _AnnotationPainter(
      strokes: widget.strokes,
      currentStroke: widget.currentStroke,
      imageSize: _imageSize,
      canvasSize: _imageSize,
    );
    painter.paint(canvas, _imageSize);

    final picture = recorder.endRecording();
    return picture.toImage(_imageSize.width.toInt(), _imageSize.height.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            final position = details.localPosition;
            _currentPoints.clear();
            _currentPoints.add(position);
            widget.onStrokeStart(position);
          },
          onPanUpdate: (details) {
            final position = details.localPosition;
            _currentPoints.add(position);
            widget.onStrokeMove(position);
          },
          onPanEnd: (details) {
            _currentPoints.clear();
            widget.onStrokeEnd();
          },
          child: Container(
            color: Colors.black,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _imageSize.width,
                  height: _imageSize.height,
                  child: CustomPaint(
                    painter: _AnnotationPainter(
                      strokes: widget.strokes,
                      currentStroke: widget.currentStroke,
                      imageSize: _imageSize,
                      canvasSize: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    ),
                    child: _imageSize.width > 0
                        ? Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===== Рисование аннотаций =====
class _AnnotationPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final Size imageSize;
  final Size canvasSize;

  _AnnotationPainter({
    required this.strokes,
    required this.currentStroke,
    required this.imageSize,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = imageSize.width > 0
        ? imageSize.width / canvasSize.width
        : 1.0;
    final scaleY = imageSize.height > 0
        ? imageSize.height / canvasSize.height
        : 1.0;

    final allStrokes = [...strokes, if (currentStroke != null) currentStroke!];
    for (final stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      switch (stroke.mode) {
        case DrawMode.pen:
          final path = Path();
          final start = stroke.points.first;
          path.moveTo(start.dx * scaleX, start.dy * scaleY);
          for (int i = 1; i < stroke.points.length; i++) {
            final p = stroke.points[i];
            path.lineTo(p.dx * scaleX, p.dy * scaleY);
          }
          canvas.drawPath(path, paint..style = PaintingStyle.stroke);
          break;

        case DrawMode.circle:
          if (stroke.points.length >= 2) {
            final start = stroke.points.first;
            final end = stroke.points.last;
            final radius = (end - start).distance * scaleX;
            canvas.drawCircle(
              Offset(start.dx * scaleX, start.dy * scaleY),
              radius,
              paint,
            );
          }
          break;

        case DrawMode.arrow:
          if (stroke.points.length >= 2) {
            final start = stroke.points.first;
            final end = stroke.points.last;
            _drawArrow(
              canvas,
              Offset(start.dx * scaleX, start.dy * scaleY),
              Offset(end.dx * scaleX, end.dy * scaleY),
              paint,
            );
          }
          break;

        case DrawMode.text:
          if (stroke.text != null && stroke.points.isNotEmpty) {
            final span = TextSpan(
              text: stroke.text,
              style: TextStyle(
                color: stroke.color,
                fontSize: 24 * scaleX,
                fontWeight: FontWeight.bold,
                shadows: [
                  const Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            );
            final tp = TextPainter(
              text: span,
              textDirection: TextDirection.ltr,
            );
            tp.layout();
            tp.paint(
              canvas,
              Offset(
                stroke.points.first.dx * scaleX,
                stroke.points.first.dy * scaleY,
              ),
            );
          }
          break;
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Линия
    canvas.drawLine(start, end, paint);

    // Наконечник
    final angle = (end - start).direction;
    const arrowSize = 15.0;
    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * math.cos(angle - 0.4),
      end.dy - arrowSize * math.sin(angle - 0.4),
    );
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * math.cos(angle + 0.4),
      end.dy - arrowSize * math.sin(angle + 0.4),
    );
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}

// ===== Кнопка инструмента =====
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey.shade700),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.blue : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
