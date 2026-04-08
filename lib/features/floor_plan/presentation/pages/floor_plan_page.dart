import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../../../../models/order.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/app_design.dart';
import '../../../../utils/pdf_generator.dart';
import '../../models/floor_plan_models.dart';
import '../../models/editor_state.dart';
import '../../engine/floor_plan_rule_engine.dart';
import '../../engine/ai_floor_plan_optimizer.dart';
import '../../engine/editor_undo_redo.dart';
import '../../engine/floor_plan_validator.dart';
import '../widgets/floor_plan_painter.dart';
import '../widgets/floor_plan_editor.dart';
import '../widgets/editor_toolbar.dart';

/// Экран просмотра и редакти плана помещения
class FloorPlanPage extends StatefulWidget {
  final Order order;

  const FloorPlanPage({super.key, required this.order});

  @override
  State<FloorPlanPage> createState() => _FloorPlanPageState();
}

class _FloorPlanPageState extends State<FloorPlanPage> {
  late final FloorPlanRuleEngine _ruleEngine;
  late final AIFloorPlanOptimizer _aiOptimizer;
  late final EditorUndoRedoManager _undoRedo;

  FloorPlan? _plan;
  EditorState? _editorState;
  double _zoom = 1.0;
  bool _isGenerating = false;
  bool _isAIOptimized = false;
  bool _isEditing = false;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _aiOptimizer = AIFloorPlanOptimizer();
    _ruleEngine = FloorPlanRuleEngine(aiOptimizer: _aiOptimizer);
    _undoRedo = EditorUndoRedoManager();
    _initializeAI();
    // Загружаем сохранённый план или генерируем новый
    _loadPlanFromOrder();
  }

  Future<void> _initializeAI() async {
    await _aiOptimizer.initialize();
    if (mounted) setState(() {});
  }

  void _generatePlan() {
    setState(() => _isGenerating = true);

    final checklistData = widget.order.checklistData;
    
    // Пробуем извлечь размеры из разных полей чек-листа
    double widthMm = 0;
    double heightMm = 0;
    
    // Для окон и дверей
    widthMm = (checklistData['width'] as num?)?.toDouble() ?? 0;
    heightMm = (checklistData['height'] as num?)?.toDouble() ?? 0;
    
    // Для плитки и мебели (пол)
    if (widthMm == 0 || heightMm == 0) {
      final floorLength = (checklistData['floor_length'] as num?)?.toDouble() ?? 0;
      final floorWidth = (checklistData['floor_width'] as num?)?.toDouble() ?? 0;
      if (floorLength > 0 && floorWidth > 0) {
        widthMm = floorLength;
        heightMm = floorWidth;
      }
    }
    
    // Для кухни
    if (widthMm == 0 || heightMm == 0) {
      final kitchenLength = (checklistData['kitchen_length'] as num?)?.toDouble() ?? 0;
      if (kitchenLength > 0) {
        widthMm = kitchenLength;
        heightMm = 3000; // Дефолтная ширина кухни
      }
    }
    
    // Для плитки
    if (widthMm == 0 || heightMm == 0) {
      final wallLength = (checklistData['wall_length'] as num?)?.toDouble() ?? 0;
      final wallHeight = (checklistData['wall_height'] as num?)?.toDouble() ?? 0;
      if (wallLength > 0 && wallHeight > 0) {
        widthMm = wallLength;
        heightMm = wallHeight;
      }
    }

    if (widthMm == 0 || heightMm == 0) {
      // Если данных нет, используем дефолтные размеры
      _plan = _ruleEngine.generateFromMeasurements(
        widthMm: 10000, // 10м
        heightMm: 8000, // 8м
        objectType: _determineObjectType(widget.order),
      );
    } else {
      _plan = _ruleEngine.generateFromMeasurements(
        widthMm: widthMm,
        heightMm: heightMm,
        objectType: _determineObjectType(widget.order),
      );
    }

    setState(() => _isGenerating = false);

    // Создаём состояние редактора из плана
    _editorState = _planToEditorState(_plan!);
    _undoRedo.push(_editorState!);
  }

  /// Конвертировать FloorPlan в EditorState (сохраняет все данные)
  EditorState _planToEditorState(FloorPlan plan) {
    final rooms = <RoomState>[];
    
    for (final room in plan.rooms) {
      // Генерируем уникальный ID для комнаты
      final roomId = const Uuid().v4();
      
      // Конвертируем двери
      final doors = room.doors.map((door) => DoorState(
        id: const Uuid().v4(),
        x: door.x,
        y: door.y,
        width: door.width,
        type: door.type.name,
      )).toList();
      
      // Конвертируем окна
      final windows = room.windows.map((window) => WindowState(
        id: const Uuid().v4(),
        x: window.x,
        y: window.y,
        width: window.width,
        type: window.type.name,
      )).toList();
      
      rooms.add(RoomState(
        id: roomId,
        type: room.type.name,
        x: room.x,
        y: room.y,
        width: room.width,
        height: room.height,
        doors: doors,
        windows: windows,
      ));
    }
    
    return EditorState(
      rooms: rooms,
      totalWidth: plan.totalWidth,
      totalHeight: plan.totalHeight,
    );
  }

  /// Конвертировать EditorState обратно в FloorPlan (восстанавливает все данные)
  FloorPlan _editorToPlan(EditorState editor) {
    return FloorPlan(
      rooms: editor.rooms.map((room) {
        final roomType = RoomType.values.firstWhere(
          (t) => t.name == room.type,
          orElse: () => RoomType.hallway,
        );
        
        // Восстанавливаем двери
        final doors = room.doors.map((door) {
          final doorType = DoorType.values.firstWhere(
            (t) => t.name == door.type,
            orElse: () => DoorType.internal,
          );
          return Door(
            x: door.x,
            y: door.y,
            width: door.width,
            type: doorType,
          );
        }).toList();
        
        // Восстанавливаем окна
        final windows = room.windows.map((window) {
          final windowType = WindowType.values.firstWhere(
            (t) => t.name == window.type,
            orElse: () => WindowType.standard,
          );
          return Window(
            x: window.x,
            y: window.y,
            width: window.width,
            type: windowType,
          );
        }).toList();
        
        return Room(
          type: roomType,
          x: room.x,
          y: room.y,
          width: room.width,
          height: room.height,
          doors: doors,
          windows: windows,
          hasVentilation: roomType == RoomType.kitchen || 
                         roomType == RoomType.bathroom ||
                         windows.isNotEmpty,
        );
      }).toList(),
      totalWidth: editor.totalWidth,
      totalHeight: editor.totalHeight,
    );
  }

  void _onEditorChanged(EditorState newState) {
    setState(() {
      _editorState = newState;
      _plan = _editorToPlan(newState);
    });
    // Автосохранение при каждом изменении
    _savePlanToOrder();
  }

  /// Сохранить план в Order (в БД)
  Future<void> _savePlanToOrder() async {
    if (_plan == null) return;
    
    try {
      // Сериализуем план в JSON
      final planJson = _planToJson(_plan!);
      
      // Обновляем Order
      final updatedOrder = widget.order.copyWith(
        floorPlanData: planJson,
        updatedAt: DateTime.now(),
      );
      
      // Сохраняем в БД
      final db = DatabaseHelper();
      await db.updateOrder(updatedOrder);
      
      print('[FloorPlan] План сохранён в Order ${updatedOrder.id}');
    } catch (e) {
      print('[FloorPlan] Ошибка сохранения плана: $e');
    }
  }

  /// Конвертировать FloorPlan в JSON для сохранения
  Map<String, dynamic> _planToJson(FloorPlan plan) {
    final json = {
      'totalWidth': plan.totalWidth,
      'totalHeight': plan.totalHeight,
      'objectType': plan.objectType.name,
      'rooms': plan.rooms.map((room) => {
        'type': room.type.name,
        'x': room.x,
        'y': room.y,
        'width': room.width,
        'height': room.height,
        'hasVentilation': room.hasVentilation,
        'hasBalconyAccess': room.hasBalconyAccess,
        'doors': room.doors.map((door) => {
          'x': door.x,
          'y': door.y,
          'width': door.width,
          'type': door.type.name,
          'clockwise': door.clockwise,
        }).toList(),
        'windows': room.windows.map((window) => {
          'x': window.x,
          'y': window.y,
          'width': window.width,
          'type': window.type.name,
          'sillHeight': window.sillHeight,
        }).toList(),
      }).toList(),
    };

    // Добавляем свободные элементы из EditorState
    if (_editorState != null) {
      json['freeDoors'] = _editorState!.doors.map((door) => {
        'id': door.id,
        'x': door.x,
        'y': door.y,
        'width': door.width,
        'type': door.type,
        'rotation': door.rotation,
      }).toList();

      json['freeWindows'] = _editorState!.windows.map((window) => {
        'id': window.id,
        'x': window.x,
        'y': window.y,
        'width': window.width,
        'type': window.type,
        'rotation': window.rotation,
      }).toList();

      json['radiators'] = _editorState!.radiators.map((radiator) => {
        'id': radiator.id,
        'x': radiator.x,
        'y': radiator.y,
        'length': radiator.length,
        'type': radiator.type,
      }).toList();

      json['plumbingFixtures'] = _editorState!.plumbingFixtures.map((fixture) => {
        'id': fixture.id,
        'x': fixture.x,
        'y': fixture.y,
        'type': fixture.type,
        'rotation': fixture.rotation,
      }).toList();

      json['electricalPoints'] = _editorState!.electricalPoints.map((point) => {
        'id': point.id,
        'x': point.x,
        'y': point.y,
        'type': point.type,
        'height': point.height,
      }).toList();
    }

    return json;
  }

  /// Загрузить FloorPlan из JSON
  FloorPlan? _planFromJson(Map<String, dynamic> json) {
    try {
      final rooms = (json['rooms'] as List).map((roomJson) {
        final roomType = RoomType.values.firstWhere(
          (t) => t.name == roomJson['type'],
          orElse: () => RoomType.hallway,
        );
        
        final doors = (roomJson['doors'] as List?)?.map((doorJson) {
          final doorType = DoorType.values.firstWhere(
            (t) => t.name == doorJson['type'],
            orElse: () => DoorType.internal,
          );
          return Door(
            x: doorJson['x'].toDouble(),
            y: doorJson['y'].toDouble(),
            width: doorJson['width'].toDouble(),
            type: doorType,
            clockwise: doorJson['clockwise'] ?? true,
          );
        }).toList() ?? [];
        
        final windows = (roomJson['windows'] as List?)?.map((windowJson) {
          final windowType = WindowType.values.firstWhere(
            (t) => t.name == windowJson['type'],
            orElse: () => WindowType.standard,
          );
          return Window(
            x: windowJson['x'].toDouble(),
            y: windowJson['y'].toDouble(),
            width: windowJson['width'].toDouble(),
            type: windowType,
            sillHeight: windowJson['sillHeight']?.toDouble() ?? 0.9,
          );
        }).toList() ?? [];
        
        return Room(
          type: roomType,
          x: roomJson['x'].toDouble(),
          y: roomJson['y'].toDouble(),
          width: roomJson['width'].toDouble(),
          height: roomJson['height'].toDouble(),
          doors: doors,
          windows: windows,
          hasVentilation: roomJson['hasVentilation'] ?? true,
          hasBalconyAccess: roomJson['hasBalconyAccess'] ?? false,
        );
      }).toList();
      
      final objectType = FloorPlanType.values.firstWhere(
        (t) => t.name == json['objectType'],
        orElse: () => FloorPlanType.apartment,
      );
      
      return FloorPlan(
        rooms: rooms.cast<Room>(),
        totalWidth: json['totalWidth'].toDouble(),
        totalHeight: json['totalHeight'].toDouble(),
        objectType: objectType,
      );
    } catch (e) {
      print('[FloorPlan] Ошибка загрузки плана из JSON: $e');
      return null;
    }
  }

  /// Загрузить сохранённый план из Order
  void _loadPlanFromOrder() {
    if (widget.order.floorPlanData != null) {
      final savedPlan = _planFromJson(widget.order.floorPlanData!);
      if (savedPlan != null) {
        final editorState = _planToEditorState(savedPlan);
        
        // Загружаем свободные элементы из JSON
        final freeDoors = (widget.order.floorPlanData!['freeDoors'] as List?)?.map((doorJson) => DoorState(
          id: doorJson['id'] ?? const Uuid().v4(),
          x: doorJson['x'].toDouble(),
          y: doorJson['y'].toDouble(),
          width: doorJson['width'].toDouble(),
          type: doorJson['type'] ?? 'internal',
          rotation: doorJson['rotation']?.toDouble() ?? 0,
        )).toList() ?? [];

        final freeWindows = (widget.order.floorPlanData!['freeWindows'] as List?)?.map((windowJson) => WindowState(
          id: windowJson['id'] ?? const Uuid().v4(),
          x: windowJson['x'].toDouble(),
          y: windowJson['y'].toDouble(),
          width: windowJson['width'].toDouble(),
          type: windowJson['type'] ?? 'standard',
          rotation: windowJson['rotation']?.toDouble() ?? 0,
        )).toList() ?? [];

        final radiators = (widget.order.floorPlanData!['radiators'] as List?)?.map((radJson) => RadiatorState(
          id: radJson['id'] ?? const Uuid().v4(),
          x: radJson['x'].toDouble(),
          y: radJson['y'].toDouble(),
          length: radJson['length'].toDouble() ?? 1.0,
          type: radJson['type'] ?? 'panel',
        )).toList() ?? [];

        final plumbingFixtures = (widget.order.floorPlanData!['plumbingFixtures'] as List?)?.map((fixJson) => PlumbingFixtureState(
          id: fixJson['id'] ?? const Uuid().v4(),
          x: fixJson['x'].toDouble(),
          y: fixJson['y'].toDouble(),
          type: fixJson['type'] ?? 'sink',
          rotation: fixJson['rotation']?.toDouble() ?? 0,
        )).toList() ?? [];

        final electricalPoints = (widget.order.floorPlanData!['electricalPoints'] as List?)?.map((pointJson) => ElectricalPointState(
          id: pointJson['id'] ?? const Uuid().v4(),
          x: pointJson['x'].toDouble(),
          y: pointJson['y'].toDouble(),
          type: pointJson['type'] ?? 'socket',
          height: pointJson['height']?.toDouble() ?? 0.3,
        )).toList() ?? [];

        // Обновляем EditorState свободными элементами
        final fullEditorState = editorState.copyWith(
          doors: freeDoors,
          windows: freeWindows,
          radiators: radiators,
          plumbingFixtures: plumbingFixtures,
          electricalPoints: electricalPoints,
        );

        setState(() {
          _plan = savedPlan;
          _editorState = fullEditorState;
          _undoRedo.push(_editorState!);
        });
        print('[FloorPlan] Загружен сохранённый план из Order');
        return;
      }
    }

    // Если сохранённого плана нет - генерируем новый
    _generatePlan();
  }

  /// Определить тип объекта из заявки
  FloorPlanType _determineObjectType(Order order) {
    final notes = order.notes?.toLowerCase() ?? '';
    if (notes.contains('дом')) return FloorPlanType.house;
    if (notes.contains('офис')) return FloorPlanType.office;
    if (notes.contains('студия')) return FloorPlanType.studio;
    return FloorPlanType.apartment;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Автосохранение при выходе
        await _savePlanToOrder();
        return true;
      },
      child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(AppDesign.appBarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppDesign.appBarGradient,
            boxShadow: AppDesign.appBarShadow,
          ),
          child: AppBar(
            title: Text('План: ${widget.order.workType.title}'),
            actions: [
              if (_aiOptimizer.isAvailable)
                IconButton(
                  icon: Icon(_isAIOptimized ? Icons.check_circle : Icons.auto_awesome),
                  color: _isAIOptimized ? Colors.green : null,
                  onPressed: _optimizeWithAI,
                  tooltip: 'AI Оптимизация',
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _generatePlan,
                tooltip: 'Перегенерировать',
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _plan != null ? () => _sharePlan() : null,
                tooltip: 'Поделиться',
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Тулбар редактора
          if (_editorState != null)
            EditorToolbar(
              isEditing: _isEditing,
              canUndo: _undoRedo.canUndo,
              canRedo: _undoRedo.canRedo,
              isValid: _validateEditor().isValid,
              validation: _validateEditor(),
              onToggleEdit: _toggleEditMode,
              onUndo: _undo,
              onRedo: _redo,
              onAddRoom: _addRoom,
              onAddDoor: _addDoor,
              onAddWindow: _addWindow,
              onAddRadiator: _addRadiator,
              onAddPlumbing: _addPlumbing,
              onAddElectrical: _addElectrical,
              onReset: _resetPlan,
            ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _isEditing
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  onPressed: () => setState(() => _zoom = (_zoom + 0.2).clamp(0.5, 5.0)),
                  backgroundColor: AppDesign.accentTeal,
                  child: const Icon(Icons.zoom_in, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  onPressed: () => setState(() => _zoom = (_zoom - 0.2).clamp(0.5, 5.0)),
                  backgroundColor: AppDesign.accentTeal,
                  child: const Icon(Icons.zoom_out, color: Colors.white),
                ),
              ],
            ),
    ),
    );
  }

  Widget _buildBody() {
    if (_isGenerating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppDesign.midBlueGray),
            const SizedBox(height: 16),
            Text('Недостаточно данных для генерации', style: AppDesign.subtitleStyle),
            const SizedBox(height: 8),
            Text('Заполните размеры в чек-листе', style: AppDesign.captionStyle),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Compliance bar
        _buildComplianceBar(),

        // Warnings
        if (_plan!.allWarnings.isNotEmpty && !_isEditing) _buildWarningsBanner(),

        // План с зумом или редактор
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: _isEditing && _editorState != null
                ? FloorPlanEditor(
                    state: _editorState!,
                    onChanged: _onEditorChanged,
                    isEditable: true,
                  )
                : InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 5.0,
                    constrained: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: CustomPaint(
                          size: Size(
                            _plan!.totalWidth * 50 * _zoom,
                            _plan!.totalHeight * 50 * _zoom,
                          ),
                          painter: FloorPlanPainter(
                            _plan!,
                            50 * _zoom,
                            editorState: _editorState,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        // Инфо панель
        if (!_isEditing) _buildInfoPanel(),
      ],
    );
  }

  /// Полоса compliance
  Widget _buildComplianceBar() {
    final score = _plan!.complianceScore;
    final color = score > 0.8 ? Colors.green : score > 0.5 ? Colors.orange : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            score > 0.8 ? Icons.check_circle : Icons.warning,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Соответствие СНиП: ${(score * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                LinearProgressIndicator(
                  value: score,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_plan!.roomCount} комн.',
            style: AppDesign.captionStyle,
          ),
        ],
      ),
    );
  }

  /// Баннер предупреждений
  Widget _buildWarningsBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.amber.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _plan!.allWarnings
            .map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(w, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// Инфо панель внизу
  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppDesign.deepSteelBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoItem('Общая', '${_plan!.totalArea.toStringAsFixed(1)} м²'),
              _InfoItem('Жилая', '${_plan!.livingArea.toStringAsFixed(1)} м²'),
              _InfoItem('Комнат', '${_plan!.roomCount}'),
            ],
          ),
        ],
      ),
    );
  }

  /// Поделиться планом (экспорт в PDF)
  Future<void> _sharePlan() async {
    if (_plan == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Генерация PDF...')),
      );

      final file = await PdfGenerator.generateFloorPlanPdf(widget.order);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'План помещения — ${widget.order.clientName}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }

  /// AI оптимизация плана
  void _optimizeWithAI() {
    if (_plan == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI оптимизация...')),
    );

    final optimizedPlan = _ruleEngine.optimize(_plan!);

    setState(() {
      _plan = optimizedPlan;
      _isAIOptimized = true;
      _editorState = _planToEditorState(optimizedPlan);
      _undoRedo.push(_editorState!);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Compliance: ${(optimizedPlan.complianceScore * 100).toInt()}%',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===== Редактор =====

  ValidationResult _validateEditor() {
    if (_editorState == null) return const ValidationResult(isValid: true);
    return FloorPlanValidator.validate(_editorState!);
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditing) {
        // Сохраняем изменения
        _undoRedo.push(_editorState!);
      }
      _isEditing = !_isEditing;
    });
  }

  void _undo() {
    final previous = _undoRedo.undo(_editorState!);
    if (previous != null) {
      setState(() {
        _editorState = previous;
        _plan = _editorToPlan(previous);
      });
    }
  }

  void _redo() {
    final next = _undoRedo.redo(_editorState!);
    if (next != null) {
      setState(() {
        _editorState = next;
        _plan = _editorToPlan(next);
      });
    }
  }

  Future<void> _addRoom() async {
    if (_editorState == null) return;

    final room = await showAddRoomDialog(context, _editorState!);
    if (room == null || !mounted) return;

    _undoRedo.push(_editorState!);
    setState(() {
      _editorState = _editorState!.copyWith(
        rooms: [..._editorState!.rooms, room],
      );
      _plan = _editorToPlan(_editorState!);
    });
    _savePlanToOrder();
  }

  Future<void> _addDoor() async {
    if (_editorState == null) return;

    final door = await showAddDoorDialog(context);
    if (door == null || !mounted) return;

    _undoRedo.push(_editorState!);
    setState(() {
      _editorState = _editorState!.copyWith(
        doors: [..._editorState!.doors, door],
      );
      _plan = _editorToPlan(_editorState!);
    });
    _savePlanToOrder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Дверь добавлена'),
          backgroundColor: Colors.brown,
        ),
      );
    }
  }

  Future<void> _addWindow() async {
    if (_editorState == null) return;

    final window = await showAddWindowDialog(context);
    if (window == null || !mounted) return;

    _undoRedo.push(_editorState!);
    setState(() {
      _editorState = _editorState!.copyWith(
        windows: [..._editorState!.windows, window],
      );
      _plan = _editorToPlan(_editorState!);
    });
    _savePlanToOrder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Окно добавлено'),
          backgroundColor: Colors.cyan,
        ),
      );
    }
  }

  Future<void> _addRadiator() async {
    if (_editorState == null) return;

    final radiator = await showAddRadiatorDialog(context);
    if (radiator == null || !mounted) return;

    _undoRedo.push(_editorState!);
    setState(() {
      _editorState = _editorState!.copyWith(
        radiators: [..._editorState!.radiators, radiator],
      );
      _plan = _editorToPlan(_editorState!);
    });
    _savePlanToOrder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Радиатор добавлен'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addPlumbing() async {
    if (_editorState == null) return;

    final fixture = await showAddPlumbingDialog(context);
    if (fixture == null || !mounted) return;

    _undoRedo.push(_editorState!);
    setState(() {
      _editorState = _editorState!.copyWith(
        plumbingFixtures: [..._editorState!.plumbingFixtures, fixture],
      );
      _plan = _editorToPlan(_editorState!);
    });
    _savePlanToOrder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Сантехника добавлена'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Future<void> _addElectrical() async {
    if (_editorState == null) return;

    final point = await showAddElectricalDialog(context);
    if (point == null || !mounted) return;

    _undoRedo.push(_editorState!);
    setState(() {
      _editorState = _editorState!.copyWith(
        electricalPoints: [..._editorState!.electricalPoints, point],
      );
      _plan = _editorToPlan(_editorState!);
    });
    _savePlanToOrder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Электрика добавлена'),
          backgroundColor: Colors.amber.shade700,
        ),
      );
    }
  }

  void _resetPlan() {
    _undoRedo.clear();
    // Очищаем сохранённый план из Order
    _savePlanToOrder(); // сохраняем пустой/сброшенный
    _generatePlan();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('План сброшен')),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppDesign.deepSteelBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppDesign.captionStyle),
      ],
    );
  }
}
