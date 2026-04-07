import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/editor_state.dart';
import '../engine/floor_plan_validator.dart';
import '../../../utils/app_design.dart';

/// Интерактивный редактор плана с drag & drop, resize
class FloorPlanEditor extends StatefulWidget {
  final EditorState state;
  final ValueChanged<EditorState> onChanged;
  final bool isEditable;

  const FloorPlanEditor({
    super.key,
    required this.state,
    required this.onChanged,
    this.isEditable = true,
  });

  @override
  State<FloorPlanEditor> createState() => _FloorPlanEditorState();
}

class _FloorPlanEditorState extends State<FloorPlanEditor> {
  String? _selectedRoomId;
  String? _draggingRoomId;
  Offset? _dragOffset;
  final TransformationController _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final ppm = _calculateScale(width, height);

        return InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 3.0,
          child: GestureDetector(
            onTap: () => setState(() => _selectedRoomId = null),
            child: Stack(
              children: [
                // Фон и сетка
                CustomPaint(
                  size: Size(
                    widget.state.totalWidth * ppm,
                    widget.state.totalHeight * ppm,
                  ),
                  painter: EditorGridPainter(
                    state: widget.state,
                    pixelsPerMeter: ppm,
                  ),
                ),
                // Комнаты
                ...widget.state.rooms.map((room) => _buildRoom(room, ppm)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoom(RoomState room, double ppm) {
    final isSelected = _selectedRoomId == room.id;
    final isDragging = _draggingRoomId == room.id;

    return Positioned(
      left: room.x * ppm,
      top: room.y * ppm,
      width: room.width * ppm,
      height: room.height * ppm,
      child: GestureDetector(
        onTap: widget.isEditable
            ? () => setState(() => _selectedRoomId = room.id)
            : null,
        onPanStart: widget.isEditable ? _onPanStart : null,
        onPanUpdate: widget.isEditable
            ? (d) => _onPanUpdate(d, room)
            : null,
        onPanEnd: widget.isEditable ? _onPanEnd : null,
        child: _RoomWidget(
          room: room,
          pixelsPerMeter: ppm,
          isSelected: isSelected && !isDragging,
          isDragging: isDragging,
          isValid: _isRoomValid(room),
          onResize: widget.isEditable
              ? (dx, dy) => _onResize(room, dx, dy)
              : null,
          onDelete: widget.isEditable
              ? () => _deleteRoom(room)
              : null,
        ),
      ),
    );
  }

  double _calculateScale(double width, double height) {
    final scaleX = (width - 40) / widget.state.totalWidth;
    final scaleY = (height - 40) / widget.state.totalHeight;
    return math.min(scaleX, scaleY).clamp(30.0, 80.0);
  }

  bool _isRoomValid(RoomState room) {
    final minArea = FloorPlanValidator.minAreas[room.type];
    return minArea == null || room.area >= minArea;
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _draggingRoomId = _selectedRoomId;
      _dragOffset = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, RoomState room) {
    if (_draggingRoomId == null) return;

    final delta = details.localPosition - _dragOffset!;
    final ppm = _calculateScale(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final dx = delta.dx / ppm;
    final dy = delta.dy / ppm;

    final newX = (room.x + dx).clamp(0.0, widget.state.totalWidth - room.width);
    final newY = (room.y + dy).clamp(0.0, widget.state.totalHeight - room.height);

    widget.onChanged(widget.state.copyWith(
      rooms: widget.state.rooms.map((r) {
        if (r.id == room.id) {
          return r.copyWith(x: newX, y: newY);
        }
        return r;
      }).toList(),
    ));

    setState(() => _dragOffset = details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _draggingRoomId = null;
      _dragOffset = null;
    });
  }

  void _onResize(RoomState room, double dx, double dy) {
    final ppm = _calculateScale(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final newWidth = (room.width + dx / ppm).clamp(1.5, 10.0);
    final newHeight = (room.height + dy / ppm).clamp(1.5, 10.0);

    widget.onChanged(widget.state.copyWith(
      rooms: widget.state.rooms.map((r) {
        if (r.id == room.id) {
          return r.copyWith(width: newWidth, height: newHeight);
        }
        return r;
      }).toList(),
    ));
  }

  void _deleteRoom(RoomState room) {
    if (widget.state.rooms.length <= 1) return;

    widget.onChanged(widget.state.copyWith(
      rooms: widget.state.rooms.where((r) => r.id != room.id).toList(),
    ));
    setState(() => _selectedRoomId = null);
  }
}

class _RoomWidget extends StatelessWidget {
  final RoomState room;
  final double pixelsPerMeter;
  final bool isSelected;
  final bool isDragging;
  final bool isValid;
  final ValueChanged<double>? onResize;
  final VoidCallback? onDelete;

  const _RoomWidget({
    required this.room,
    required this.pixelsPerMeter,
    required this.isSelected,
    required this.isDragging,
    required this.isValid,
    this.onResize,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getRoomColor(room.type).withOpacity(isDragging ? 0.4 : (isSelected ? 0.25 : 0.1)),
        border: Border.all(
          color: isSelected
              ? AppDesign.accentTeal
              : (isValid ? AppDesign.midBlueGrayBorder : AppDesign.statusCancelled),
          width: isSelected ? 2.5 : 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Контент комнаты
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getRoomIcon(room.type),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  _getRoomLabel(room.type),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppDesign.primaryDark.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${room.area.toStringAsFixed(1)} м²',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppDesign.primaryDark.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Resize handle
          if (isSelected && onResize != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (d) => onResize!(d.delta.dx, d.delta.dy),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppDesign.accentTeal,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: const Icon(Icons.zoom_out_map, color: Colors.white, size: 14),
                ),
              ),
            ),
          // Delete button
          if (isSelected && onDelete != null)
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppDesign.statusCancelled,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRoomColor(String type) {
    switch (type) {
      case 'kitchen': return Colors.orange.shade100;
      case 'livingRoom': return Colors.blue.shade100;
      case 'bedroom': return Colors.purple.shade100;
      case 'childrenRoom': return Colors.green.shade100;
      case 'bathroom': return Colors.teal.shade100;
      case 'toilet': return Colors.cyan.shade100;
      case 'hallway': return Colors.grey.shade200;
      case 'balcony': return Colors.lightGreen.shade100;
      case 'storage': return Colors.brown.shade100;
      case 'office': return Colors.indigo.shade100;
      default: return Colors.grey.shade100;
    }
  }

  String _getRoomIcon(String type) {
    switch (type) {
      case 'kitchen': return '🍳';
      case 'livingRoom': return '🛋️';
      case 'bedroom': return '🛏️';
      case 'childrenRoom': return '🧸';
      case 'bathroom': return '🚿';
      case 'toilet': return '🚽';
      case 'hallway': return '🚶';
      case 'balcony': return '🌿';
      case 'storage': return '📦';
      case 'office': return '💼';
      default: return '🏠';
    }
  }

  String _getRoomLabel(String type) {
    switch (type) {
      case 'kitchen': return 'Кухня';
      case 'livingRoom': return 'Гостиная';
      case 'bedroom': return 'Спальня';
      case 'childrenRoom': return 'Детская';
      case 'bathroom': return 'Ванная';
      case 'toilet': return 'Туалет';
      case 'hallway': return 'Коридор';
      case 'balcony': return 'Балкон';
      case 'storage': return 'Кладовая';
      case 'office': return 'Кабинет';
      default: return type;
    }
  }
}

class EditorGridPainter extends CustomPainter {
  final EditorState state;
  final double pixelsPerMeter;

  EditorGridPainter({required this.state, required this.pixelsPerMeter});

  @override
  void paint(Canvas canvas, Size size) {
    // Фон
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);

    // Сетка 1м
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= state.totalWidth * pixelsPerMeter; x += pixelsPerMeter) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, state.totalHeight * pixelsPerMeter),
        gridPaint,
      );
    }
    for (double y = 0; y <= state.totalHeight * pixelsPerMeter; y += pixelsPerMeter) {
      canvas.drawLine(
        Offset(0, y),
        Offset(state.totalWidth * pixelsPerMeter, y),
        gridPaint,
      );
    }

    // Граница плана
    canvas.drawRect(
      Rect.fromLTWH(0, 0, state.totalWidth * pixelsPerMeter, state.totalHeight * pixelsPerMeter),
      Paint()
        ..color = AppDesign.primaryDark
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant EditorGridPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.pixelsPerMeter != pixelsPerMeter;
  }
}
