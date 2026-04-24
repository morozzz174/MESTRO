import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/editor_state.dart';
import '../../../../utils/app_design.dart';

/// Интерактивный редактор плана с drag & drop для всех элементов
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
  String? _selectedDoorId;
  String? _selectedWindowId;
  String? _selectedRadiatorId;
  String? _selectedPlumbingId;
  String? _selectedElectricalId;
  String? _selectedWallId;
  String? _selectedColumnId;

  final TransformationController _transformController =
      TransformationController();

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
          maxScale: 5.0,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedRoomId = null;
              _selectedDoorId = null;
              _selectedWindowId = null;
              _selectedRadiatorId = null;
              _selectedPlumbingId = null;
              _selectedElectricalId = null;
              _selectedWallId = null;
              _selectedColumnId = null;
            }),
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
                // Двери
                if (widget.isEditable)
                  ...widget.state.doors.map(
                    (door) => _buildDraggableElement(
                      door,
                      ppm,
                      isDoor: true,
                      isSelected: _selectedDoorId == door.id,
                      onTap: () => setState(() {
                        _selectedDoorId = door.id;
                        _clearOtherSelections(isDoor: true);
                      }),
                      onDelete: () => _deleteDoor(door),
                    ),
                  ),
                // Окна
                if (widget.isEditable)
                  ...widget.state.windows.map(
                    (window) => _buildDraggableElement(
                      window,
                      ppm,
                      isWindow: true,
                      isSelected: _selectedWindowId == window.id,
                      onTap: () => setState(() {
                        _selectedWindowId = window.id;
                        _clearOtherSelections(isWindow: true);
                      }),
                      onDelete: () => _deleteWindow(window),
                    ),
                  ),
                // Радиаторы
                if (widget.isEditable)
                  ...widget.state.radiators.map(
                    (radiator) => _buildDraggableElement(
                      radiator,
                      ppm,
                      isRadiator: true,
                      isSelected: _selectedRadiatorId == radiator.id,
                      onTap: () => setState(() {
                        _selectedRadiatorId = radiator.id;
                        _clearOtherSelections(isRadiator: true);
                      }),
                      onDelete: () => _deleteRadiator(radiator),
                    ),
                  ),
                // Сантехника
                if (widget.isEditable)
                  ...widget.state.plumbingFixtures.map(
                    (fixture) => _buildDraggableElement(
                      fixture,
                      ppm,
                      isPlumbing: true,
                      isSelected: _selectedPlumbingId == fixture.id,
                      onTap: () => setState(() {
                        _selectedPlumbingId = fixture.id;
                        _clearOtherSelections(isPlumbing: true);
                      }),
                      onDelete: () => _deletePlumbing(fixture),
                    ),
                  ),
                // Электрика
                if (widget.isEditable)
                  ...widget.state.electricalPoints.map(
                    (point) => _buildDraggableElement(
                      point,
                      ppm,
                      isElectrical: true,
                      isSelected: _selectedElectricalId == point.id,
                      onTap: () => setState(() {
                        _selectedElectricalId = point.id;
                        _clearOtherSelections(isElectrical: true);
                      }),
                      onDelete: () => _deleteElectrical(point),
                    ),
                  ),
                // Стены
                if (widget.isEditable)
                  ...widget.state.walls.map(
                    (wall) => _buildWallDraggableElement(wall, ppm),
                  ),
                // Колонны
                if (widget.isEditable)
                  ...widget.state.columns.map(
                    (col) => _buildColumnDraggableElement(col, ppm),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearOtherSelections({
    bool isDoor = false,
    bool isWindow = false,
    bool isRadiator = false,
    bool isPlumbing = false,
    bool isElectrical = false,
    bool isWall = false,
    bool isColumn = false,
  }) {
    if (!isDoor) _selectedDoorId = null;
    if (!isWindow) _selectedWindowId = null;
    if (!isRadiator) _selectedRadiatorId = null;
    if (!isPlumbing) _selectedPlumbingId = null;
    if (!isElectrical) _selectedElectricalId = null;
    if (!isWall) _selectedWallId = null;
    if (!isColumn) _selectedColumnId = null;
  }

  Widget _buildRoom(RoomState room, double ppm) {
    final isSelected = _selectedRoomId == room.id;

    return Positioned(
      left: room.x * ppm,
      top: room.y * ppm,
      width: room.width * ppm,
      height: room.height * ppm,
      child: GestureDetector(
        onTap: widget.isEditable
            ? () => setState(() {
                _selectedRoomId = room.id;
                _clearOtherSelections();
              })
            : null,
        onPanStart: widget.isEditable ? (d) => _startDragRoom(room) : null,
        onPanUpdate: widget.isEditable
            ? (d) => _updateDragRoom(room, d.delta)
            : null,
        onPanEnd: widget.isEditable ? (_) => _endDragRoom(room) : null,
        child: _RoomWidget(
          room: room,
          pixelsPerMeter: ppm,
          isSelected: isSelected,
          onResize: widget.isEditable
              ? (dx, dy) => _onResize(room, dx, dy, ppm)
              : null,
          onDelete: widget.isEditable ? () => _deleteRoom(room) : null,
        ),
      ),
    );
  }

  // ===== Drag & Drop для элементов =====

  Offset? _dragStartPos;
  String? _draggingElementId;
  dynamic _draggingElement;

  void _startDragElement(dynamic element, String id) {
    setState(() {
      _draggingElementId = id;
      _draggingElement = element;
    });
  }

  void _updateDragElement(DragUpdateDetails details, String id, double ppm) {
    if (_draggingElementId != id) return;

    final dx = details.delta.dx / ppm;
    final dy = details.delta.dy / ppm;

    if (_draggingElement is DoorState) {
      final door = _draggingElement as DoorState;
      final newX = (door.x + dx).clamp(0.0, widget.state.totalWidth);
      final newY = (door.y + dy).clamp(0.0, widget.state.totalHeight);
      _updateDoor(door.copyWith(x: newX, y: newY));
    } else if (_draggingElement is WindowState) {
      final window = _draggingElement as WindowState;
      final newX = (window.x + dx).clamp(0.0, widget.state.totalWidth);
      final newY = (window.y + dy).clamp(0.0, widget.state.totalHeight);
      _updateWindow(window.copyWith(x: newX, y: newY));
    } else if (_draggingElement is RadiatorState) {
      final radiator = _draggingElement as RadiatorState;
      final newX = (radiator.x + dx).clamp(0.0, widget.state.totalWidth);
      final newY = (radiator.y + dy).clamp(0.0, widget.state.totalHeight);
      _updateRadiator(radiator.copyWith(x: newX, y: newY));
    } else if (_draggingElement is PlumbingFixtureState) {
      final fixture = _draggingElement as PlumbingFixtureState;
      final newX = (fixture.x + dx).clamp(0.0, widget.state.totalWidth);
      final newY = (fixture.y + dy).clamp(0.0, widget.state.totalHeight);
      _updatePlumbing(fixture.copyWith(x: newX, y: newY));
    } else if (_draggingElement is ElectricalPointState) {
      final point = _draggingElement as ElectricalPointState;
      final newX = (point.x + dx).clamp(0.0, widget.state.totalWidth);
      final newY = (point.y + dy).clamp(0.0, widget.state.totalHeight);
      _updateElectrical(point.copyWith(x: newX, y: newY));
    }
  }

  void _endDragElement() {
    setState(() {
      _draggingElementId = null;
      _draggingElement = null;
    });
  }

  Widget _buildDraggableElement(
    dynamic element,
    double ppm, {
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onDelete,
    bool isDoor = false,
    bool isWindow = false,
    bool isRadiator = false,
    bool isPlumbing = false,
    bool isElectrical = false,
  }) {
    double x = 0, y = 0;
    String label = '';
    String icon = '';
    Color color = Colors.grey;

    if (isDoor) {
      final door = element as DoorState;
      x = door.x;
      y = door.y;
      label = 'Дверь';
      icon = '🚪';
      color = Colors.brown;
    } else if (isWindow) {
      final window = element as WindowState;
      x = window.x;
      y = window.y;
      label = 'Окно';
      icon = '🪟';
      color = Colors.cyan;
    } else if (isRadiator) {
      final radiator = element as RadiatorState;
      x = radiator.x;
      y = radiator.y;
      label = 'Радиатор';
      icon = '🔥';
      color = Colors.red;
    } else if (isPlumbing) {
      final fixture = element as PlumbingFixtureState;
      x = fixture.x;
      y = fixture.y;
      label = _getPlumbingLabel(fixture.type);
      icon = _getPlumbingIcon(fixture.type);
      color = Colors.teal;
    } else if (isElectrical) {
      final point = element as ElectricalPointState;
      x = point.x;
      y = point.y;
      label = _getElectricalLabel(point.type);
      icon = _getElectricalIcon(point.type);
      color = Colors.amber;
    }

    return Positioned(
      left: x * ppm,
      top: y * ppm,
      child: GestureDetector(
        onTap: onTap,
        onPanStart: (d) => _startDragElement(element, element.id),
        onPanUpdate: (d) => _updateDragElement(d, element.id, ppm),
        onPanEnd: (_) => _endDragElement(),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.3)
                : color.withOpacity(0.15),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  right: -4,
                  top: -4,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateScale(double width, double height) {
    final scaleX = (width - 40) / widget.state.totalWidth;
    final scaleY = (height - 40) / widget.state.totalHeight;
    return math.min(scaleX, scaleY).clamp(30.0, 80.0);
  }

  // ===== Room drag & drop =====

  void _startDragRoom(RoomState room) {
    _selectedRoomId = room.id;
  }

  void _updateDragRoom(RoomState room, Offset delta) {
    final ppm = _calculateScale(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final dx = delta.dx / ppm;
    final dy = delta.dy / ppm;

    final newX = (room.x + dx).clamp(0.0, widget.state.totalWidth - room.width);
    final newY = (room.y + dy).clamp(
      0.0,
      widget.state.totalHeight - room.height,
    );

    widget.onChanged(
      widget.state.copyWith(
        rooms: widget.state.rooms.map((r) {
          if (r.id == room.id) {
            return r.copyWith(x: newX, y: newY);
          }
          return r;
        }).toList(),
      ),
    );
  }

  void _endDragRoom(RoomState room) {
    // Сохранение уже произошло в _updateDragRoom
  }

  void _onResize(RoomState room, double dx, double dy, double ppm) {
    final newWidth = (room.width + dx / ppm).clamp(1.5, 15.0);
    final newHeight = (room.height + dy / ppm).clamp(1.5, 15.0);

    widget.onChanged(
      widget.state.copyWith(
        rooms: widget.state.rooms.map((r) {
          if (r.id == room.id) {
            return r.copyWith(width: newWidth, height: newHeight);
          }
          return r;
        }).toList(),
      ),
    );
  }

  void _deleteRoom(RoomState room) {
    if (widget.state.rooms.length <= 1) return;

    widget.onChanged(
      widget.state.copyWith(
        rooms: widget.state.rooms.where((r) => r.id != room.id).toList(),
      ),
    );
    setState(() => _selectedRoomId = null);
  }

  // ===== Door CRUD =====

  void _updateDoor(DoorState door) {
    widget.onChanged(
      widget.state.copyWith(
        doors: widget.state.doors
            .map((d) => d.id == door.id ? door : d)
            .toList(),
      ),
    );
  }

  void _deleteDoor(DoorState door) {
    widget.onChanged(
      widget.state.copyWith(
        doors: widget.state.doors.where((d) => d.id != door.id).toList(),
      ),
    );
    setState(() => _selectedDoorId = null);
  }

  // ===== Window CRUD =====

  void _updateWindow(WindowState window) {
    widget.onChanged(
      widget.state.copyWith(
        windows: widget.state.windows
            .map((w) => w.id == window.id ? window : w)
            .toList(),
      ),
    );
  }

  void _deleteWindow(WindowState window) {
    widget.onChanged(
      widget.state.copyWith(
        windows: widget.state.windows.where((w) => w.id != window.id).toList(),
      ),
    );
    setState(() => _selectedWindowId = null);
  }

  // ===== Radiator CRUD =====

  void _updateRadiator(RadiatorState radiator) {
    widget.onChanged(
      widget.state.copyWith(
        radiators: widget.state.radiators
            .map((r) => r.id == radiator.id ? radiator : r)
            .toList(),
      ),
    );
  }

  void _deleteRadiator(RadiatorState radiator) {
    widget.onChanged(
      widget.state.copyWith(
        radiators: widget.state.radiators
            .where((r) => r.id != radiator.id)
            .toList(),
      ),
    );
    setState(() => _selectedRadiatorId = null);
  }

  // ===== Plumbing CRUD =====

  void _updatePlumbing(PlumbingFixtureState fixture) {
    widget.onChanged(
      widget.state.copyWith(
        plumbingFixtures: widget.state.plumbingFixtures
            .map((f) => f.id == fixture.id ? fixture : f)
            .toList(),
      ),
    );
  }

  void _deletePlumbing(PlumbingFixtureState fixture) {
    widget.onChanged(
      widget.state.copyWith(
        plumbingFixtures: widget.state.plumbingFixtures
            .where((f) => f.id != fixture.id)
            .toList(),
      ),
    );
    setState(() => _selectedPlumbingId = null);
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

  // ===== Electrical CRUD =====

  void _updateElectrical(ElectricalPointState point) {
    widget.onChanged(
      widget.state.copyWith(
        electricalPoints: widget.state.electricalPoints
            .map((p) => p.id == point.id ? point : p)
            .toList(),
      ),
    );
  }

  void _deleteElectrical(ElectricalPointState point) {
    widget.onChanged(
      widget.state.copyWith(
        electricalPoints: widget.state.electricalPoints
            .where((p) => p.id != point.id)
            .toList(),
      ),
    );
    setState(() => _selectedElectricalId = null);
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

  // ===== Wall CRUD =====

  Widget _buildWallDraggableElement(WallState wall, double ppm) {
    final isSelected = _selectedWallId == wall.id;
    final midX = ((wall.x1 + wall.x2) / 2) * ppm;
    final midY = ((wall.y1 + wall.y2) / 2) * ppm;

    return Positioned(
      left: midX - 30,
      top: midY - 15,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedWallId = wall.id;
          _clearOtherSelections(isWall: true);
        }),
        onPanStart: (_) => _startDragWall(wall),
        onPanUpdate: (d) => _updateDragWall(wall, d.delta, ppm),
        onPanEnd: (_) => _endDragWall(),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.red.withOpacity(0.3)
                : Colors.red.withOpacity(0.1),
            border: Border.all(
              color: isSelected ? Colors.red : Colors.red.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _wallTypeShortLabel(wall.type),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 2),
              if (isSelected)
                GestureDetector(
                  onTap: () => _deleteWall(wall),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startDragWall(WallState wall) {
    _dragWallStartPos = Offset(wall.x1, wall.y1);
    _dragWallEndPos = Offset(wall.x2, wall.y2);
    _draggingWallId = wall.id;
  }

  Offset? _dragWallStartPos;
  Offset? _dragWallEndPos;
  String? _draggingWallId;

  void _updateDragWall(WallState wall, Offset delta, double ppm) {
    if (_draggingWallId != wall.id) return;
    final dx = delta.dx / ppm;
    final dy = delta.dy / ppm;

    _dragWallStartPos = Offset(
      _dragWallStartPos!.dx + dx,
      _dragWallStartPos!.dy + dy,
    );
    _dragWallEndPos = Offset(
      _dragWallEndPos!.dx + dx,
      _dragWallEndPos!.dy + dy,
    );

    widget.onChanged(
      widget.state.copyWith(
        walls: widget.state.walls.map((w) {
          if (w.id == wall.id) {
            return w.copyWith(
              x1: _dragWallStartPos!.dx.clamp(0.0, widget.state.totalWidth),
              y1: _dragWallStartPos!.dy.clamp(0.0, widget.state.totalHeight),
              x2: _dragWallEndPos!.dx.clamp(0.0, widget.state.totalWidth),
              y2: _dragWallEndPos!.dy.clamp(0.0, widget.state.totalHeight),
            );
          }
          return w;
        }).toList(),
      ),
    );
  }

  void _endDragWall() {
    _draggingWallId = null;
    _dragWallStartPos = null;
    _dragWallEndPos = null;
  }

  void _deleteWall(WallState wall) {
    widget.onChanged(
      widget.state.copyWith(
        walls: widget.state.walls.where((w) => w.id != wall.id).toList(),
      ),
    );
    setState(() => _selectedWallId = null);
  }

  String _wallTypeShortLabel(String type) {
    switch (type) {
      case 'exterior':
        return '🧱 Наружная';
      case 'interior':
        return '🧱 Внутр';
      case 'partition':
        return '│ Перегор';
      case 'foundation':
        return '▣ Фундам';
      case 'retaining':
        return '◧ Подпорн';
      default:
        return '🧱 $type';
    }
  }

  // ===== Column CRUD =====

  Widget _buildColumnDraggableElement(ColumnState col, double ppm) {
    final isSelected = _selectedColumnId == col.id;
    final cx = col.x * ppm;
    final cy = col.y * ppm;

    return Positioned(
      left: cx - 15,
      top: cy - 15,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedColumnId = col.id;
          _clearOtherSelections(isColumn: true);
        }),
        onPanStart: (_) => _startDragColumn(col),
        onPanUpdate: (d) => _updateDragColumn(col, d.delta, ppm),
        onPanEnd: (_) => _endDragColumn(),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey.shade600 : Colors.grey.shade500,
            border: Border.all(color: Colors.black, width: isSelected ? 2 : 1),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '✕',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: -2,
                  top: -2,
                  child: GestureDetector(
                    onTap: () => _deleteColumn(col),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startDragColumn(ColumnState col) {
    _draggingColumnId = col.id;
  }

  String? _draggingColumnId;

  void _updateDragColumn(ColumnState col, Offset delta, double ppm) {
    if (_draggingColumnId != col.id) return;
    final dx = delta.dx / ppm;
    final dy = delta.dy / ppm;

    widget.onChanged(
      widget.state.copyWith(
        columns: widget.state.columns.map((c) {
          if (c.id == col.id) {
            return ColumnState(
              id: c.id,
              x: (c.x + dx).clamp(0.0, widget.state.totalWidth),
              y: (c.y + dy).clamp(0.0, widget.state.totalHeight),
              width: c.width,
              height: c.height,
              material: c.material,
            );
          }
          return c;
        }).toList(),
      ),
    );
  }

  void _endDragColumn() {
    _draggingColumnId = null;
  }

  void _deleteColumn(ColumnState col) {
    widget.onChanged(
      widget.state.copyWith(
        columns: widget.state.columns.where((c) => c.id != col.id).toList(),
      ),
    );
    setState(() => _selectedColumnId = null);
  }
}

class _RoomWidget extends StatelessWidget {
  final RoomState room;
  final double pixelsPerMeter;
  final bool isSelected;
  final Function(double dx, double dy)? onResize;
  final VoidCallback? onDelete;

  const _RoomWidget({
    required this.room,
    required this.pixelsPerMeter,
    required this.isSelected,
    this.onResize,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getRoomColor(room.type).withOpacity(isSelected ? 0.25 : 0.1),
        border: Border.all(
          color: isSelected
              ? AppDesign.accentTeal
              : AppDesign.midBlueGrayBorder,
          width: isSelected ? 2.5 : 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
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
                  child: const Icon(
                    Icons.zoom_out_map,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
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
      case 'kitchen':
        return Colors.orange.shade100;
      case 'livingRoom':
        return Colors.blue.shade100;
      case 'bedroom':
        return Colors.purple.shade100;
      case 'childrenRoom':
        return Colors.green.shade100;
      case 'bathroom':
        return Colors.teal.shade100;
      case 'toilet':
        return Colors.cyan.shade100;
      case 'hallway':
        return Colors.grey.shade200;
      case 'balcony':
        return Colors.lightGreen.shade100;
      case 'storage':
        return Colors.brown.shade100;
      case 'office':
        return Colors.indigo.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  String _getRoomIcon(String type) {
    switch (type) {
      case 'kitchen':
        return '🍳';
      case 'livingRoom':
        return '🛋️';
      case 'bedroom':
        return '🛏️';
      case 'childrenRoom':
        return '🧸';
      case 'bathroom':
        return '🚿';
      case 'toilet':
        return '🚽';
      case 'hallway':
        return '🚶';
      case 'balcony':
        return '🌿';
      case 'storage':
        return '📦';
      case 'office':
        return '💼';
      default:
        return '🏠';
    }
  }

  String _getRoomLabel(String type) {
    switch (type) {
      case 'kitchen':
        return 'Кухня';
      case 'livingRoom':
        return 'Гостиная';
      case 'bedroom':
        return 'Спальня';
      case 'childrenRoom':
        return 'Детская';
      case 'bathroom':
        return 'Ванная';
      case 'toilet':
        return 'Туалет';
      case 'hallway':
        return 'Коридор';
      case 'balcony':
        return 'Балкон';
      case 'storage':
        return 'Кладовая';
      case 'office':
        return 'Кабинет';
      default:
        return type;
    }
  }
}

class EditorGridPainter extends CustomPainter {
  final EditorState state;
  final double pixelsPerMeter;

  EditorGridPainter({required this.state, required this.pixelsPerMeter});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 0.5;

    for (
      double x = 0;
      x <= state.totalWidth * pixelsPerMeter;
      x += pixelsPerMeter
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, state.totalHeight * pixelsPerMeter),
        gridPaint,
      );
    }
    for (
      double y = 0;
      y <= state.totalHeight * pixelsPerMeter;
      y += pixelsPerMeter
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(state.totalWidth * pixelsPerMeter, y),
        gridPaint,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        state.totalWidth * pixelsPerMeter,
        state.totalHeight * pixelsPerMeter,
      ),
      Paint()
        ..color = AppDesign.primaryDark
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant EditorGridPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.pixelsPerMeter != pixelsPerMeter;
  }
}
