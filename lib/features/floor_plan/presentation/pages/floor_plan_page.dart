import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../../../../models/order.dart';
import '../../../../services/ai_agent_service.dart';
import '../../../../services/subscription_service.dart';
import '../../../../services/construction_drawing_generator.dart';
import '../../../../utils/app_design.dart';
import '../../../../database/database_helper.dart';
import '../../../../utils/pdf_generator.dart';
import '../../models/floor_plan_models_extended.dart' hide Column;
import '../../models/editor_state.dart';
import '../../engine/floor_plan_rule_engine.dart';
import '../../engine/ai_floor_plan_optimizer.dart';
import '../../engine/editor_undo_redo.dart';
import '../../engine/floor_plan_validator.dart';
import '../widgets/floor_plan_painter.dart';
import '../widgets/floor_plan_editor.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/construction_panel.dart';

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
  final _aiAnalyzer = SmartChecklistAnalyzer();
  final _subscriptionService = SubscriptionService();

  FloorPlan? _plan;
  EditorState? _editorState;
  double _zoom = 1.0;
  bool _isGenerating = false;
  bool _isAIOptimized = false;
  bool _isAIFloorPlanGenerated = false;
  bool _isEditing = false;
  bool _isPanelExpanded = true;
  double _panelHeight = 380;
  final TransformationController _transformationController =
      TransformationController();

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

  /// AI-генерация Floor Plan из данных замера
  Future<void> _generateAIFloorPlan() async {
    // Проверяем премиум
    final isPremium = await _subscriptionService.isPremiumActive();
    if (!isPremium && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI-генерация плана доступна только для Премиум'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final aiPlan = _aiAnalyzer.generateFloorPlan(widget.order);

      setState(() {
        _plan = aiPlan;
        _editorState = EditorState.fromFloorPlan(aiPlan);
        _isAIFloorPlanGenerated = true;
        _isGenerating = false;
      });

      _undoRedo.clear();
      _undoRedo.push(_editorState!);
      _savePlanToOrder();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('AI-план сгенерирован из данных замера'),
                ),
                TextButton(
                  onPressed: () {
                    // Отмена AI — вернуться к обычному плану
                    _generatePlan();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppDesign.deepSteelBlue,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка AI-генерации: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generatePlan() {
    setState(() => _isGenerating = true);

    final checklistData = widget.order.checklistData;

    // Пробуем извлечь размеры помещения из чек-листа
    double widthMm = 0;
    double heightMm = 0;

    // 1. Размеры помещения (пол) — есть только в tiles.json
    final floorLength =
        (checklistData['floor_length'] as num?)?.toDouble() ?? 0;
    final floorWidth = (checklistData['floor_width'] as num?)?.toDouble() ?? 0;
    if (floorLength > 0 && floorWidth > 0) {
      widthMm = floorLength;
      heightMm = floorWidth;
    }

    // 2. Для кухни — отдельные поля (если есть)
    if (widthMm == 0 || heightMm == 0) {
      final kitchenLength =
          (checklistData['kitchen_length'] as num?)?.toDouble() ?? 0;
      final kitchenWidth =
          (checklistData['kitchen_width'] as num?)?.toDouble() ?? 0;
      if (kitchenLength > 0 && kitchenWidth > 0) {
        widthMm = kitchenLength;
        heightMm = kitchenWidth;
      }
    }

    // ВАЖНО: НЕ используем размеры отдельных элементов для генерации плана:
    // - width/height из windows.json — размер ОДНОГО окна, не помещения
    // - wall_length/wall_height из tiles.json — размер ОДНОЙ стены
    // Для этих типов работ используем дефолтные размеры

    if (widthMm == 0 || heightMm == 0) {
      // Нет размеров помещения — используем дефолтные 10×8м
      _plan = _ruleEngine.generateFromMeasurements(
        widthMm: 10000,
        heightMm: 8000,
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

    _editorState = _planToEditorState(_plan!);
    _undoRedo.push(_editorState!);
  }

  /// Конвертировать FloorPlan в EditorState (сохраняет все данные)
  EditorState _planToEditorState(FloorPlan plan) {
    final rooms = <RoomState>[];

    for (final room in plan.rooms) {
      final roomId = const Uuid().v4();

      final doors = room.doors
          .map(
            (door) => DoorState(
              id: const Uuid().v4(),
              x: door.x,
              y: door.y,
              width: door.width,
              type: door.type.name,
            ),
          )
          .toList();

      final windows = room.windows
          .map(
            (window) => WindowState(
              id: const Uuid().v4(),
              x: window.x,
              y: window.y,
              width: window.width,
              type: window.type.name,
            ),
          )
          .toList();

      rooms.add(
        RoomState(
          id: roomId,
          type: room.type.name,
          x: room.x,
          y: room.y,
          width: room.width,
          height: room.height,
          doors: doors,
          windows: windows,
        ),
      );
    }

    return EditorState(
      rooms: rooms,
      totalWidth: plan.totalWidth,
      totalHeight: plan.totalHeight,
      walls: plan.walls
          .map(
            (w) => WallState(
              id: const Uuid().v4(),
              x1: w.x1,
              y1: w.y1,
              x2: w.x2,
              y2: w.y2,
              thickness: w.thickness,
              type: w.type.name,
              material: w.material.name,
              height: w.height,
              isLoadBearing: w.isLoadBearing,
              insulationThickness: w.insulationThickness,
            ),
          )
          .toList(),
      foundation: plan.foundation != null
          ? FoundationState(
              id: 'foundation',
              type: plan.foundation!.type.name,
              width: plan.foundation!.width,
              depth: plan.foundation!.depth,
              height: plan.foundation!.height,
              embedmentDepth: plan.foundation!.embedmentDepth,
              concreteGrade: plan.foundation!.concreteGrade,
              concreteClass: plan.foundation!.concreteClass.name,
              mainBarDiameter: plan.foundation!.reinforcement.mainBarDiameter,
              mainBarsCount: plan.foundation!.reinforcement.mainBarsCount,
              stirrupDiameter: plan.foundation!.reinforcement.stirrupDiameter,
              stirrupSpacing: plan.foundation!.reinforcement.stirrupSpacing,
              rebarClass: plan.foundation!.reinforcement.rebarClass,
              hasWaterproofing: plan.foundation!.hasWaterproofing,
              hasInsulation: plan.foundation!.hasInsulation,
              hasDrainage: plan.foundation!.hasDrainage,
              sandCushionThickness: plan.foundation!.sandCushionThickness,
            )
          : null,
      roof: plan.roof != null
          ? RoofState(
              id: 'roof',
              type: plan.roof!.type.name,
              area: plan.roof!.area,
              slopeAngle: plan.roof!.slopeAngle,
              roofingMaterial: plan.roof!.roofingMaterial.name,
              rafterSpacing: plan.roof!.rafters.spacing,
              rafterSectionWidth: plan.roof!.rafters.sectionWidth,
              rafterSectionHeight: plan.roof!.rafters.sectionHeight,
              rafterLength: plan.roof!.rafters.length,
              rafterCount: plan.roof!.rafters.count,
              rafterMaterial: plan.roof!.rafters.material.name,
              insulationThickness: plan.roof!.insulation.thickness,
              insulationMaterial: plan.roof!.insulation.material.name,
              hasWaterproofingMembrane: plan.roof!.hasWaterproofingMembrane,
              hasVaporBarrier: plan.roof!.hasVaporBarrier,
              hasSnowRetention: plan.roof!.hasSnowRetention,
              snowRetentionCount: plan.roof!.snowRetentionCount,
            )
          : null,
      engineeringSystems: plan.engineeringSystems != null
          ? EngineeringSystemsState(
              heating: plan.engineeringSystems!.heating != null
                  ? HeatingSystemState(
                      type: plan.engineeringSystems!.heating!.type.name,
                      radiatorCount:
                          plan.engineeringSystems!.heating!.radiatorCount,
                      pipeLength: plan.engineeringSystems!.heating!.pipeLength,
                      boilerPower:
                          plan.engineeringSystems!.heating!.boilerPower,
                      hasWarmFloor:
                          plan.engineeringSystems!.heating!.hasWarmFloor,
                      warmFloorArea:
                          plan.engineeringSystems!.heating!.warmFloorArea,
                    )
                  : null,
              waterSupply: plan.engineeringSystems!.waterSupply != null
                  ? WaterSupplyState(
                      coldPipeLength:
                          plan.engineeringSystems!.waterSupply!.coldPipeLength,
                      hotPipeLength:
                          plan.engineeringSystems!.waterSupply!.hotPipeLength,
                      fixtureCount:
                          plan.engineeringSystems!.waterSupply!.fixtureCount,
                      hasWaterHeater:
                          plan.engineeringSystems!.waterSupply!.hasWaterHeater,
                      waterHeaterVolume: plan
                          .engineeringSystems!
                          .waterSupply!
                          .waterHeaterVolume,
                    )
                  : null,
              electrical: plan.engineeringSystems!.electrical != null
                  ? ElectricalState(
                      cableLength:
                          plan.engineeringSystems!.electrical!.cableLength,
                      socketCount:
                          plan.engineeringSystems!.electrical!.socketCount,
                      switchCount:
                          plan.engineeringSystems!.electrical!.switchCount,
                      lightPointCount:
                          plan.engineeringSystems!.electrical!.lightPointCount,
                      breakerCount:
                          plan.engineeringSystems!.electrical!.breakerCount,
                      hasRCD: plan.engineeringSystems!.electrical!.hasRCD,
                      hasGrounding:
                          plan.engineeringSystems!.electrical!.hasGrounding,
                      hasLightningProtection: plan
                          .engineeringSystems!
                          .electrical!
                          .hasLightningProtection,
                      hasSmartHome:
                          plan.engineeringSystems!.electrical!.hasSmartHome,
                    )
                  : null,
              ventilation: plan.engineeringSystems!.ventilation != null
                  ? VentilationState(
                      type: plan.engineeringSystems!.ventilation!.type.name,
                      exhaustPoints:
                          plan.engineeringSystems!.ventilation!.exhaustPoints,
                      supplyPoints:
                          plan.engineeringSystems!.ventilation!.supplyPoints,
                      ductLength:
                          plan.engineeringSystems!.ventilation!.ductLength,
                      hasRecuperator:
                          plan.engineeringSystems!.ventilation!.hasRecuperator,
                    )
                  : null,
              sewage: plan.engineeringSystems!.sewage != null
                  ? SewageState(
                      pipeLength: plan.engineeringSystems!.sewage!.pipeLength,
                      fixtureCount:
                          plan.engineeringSystems!.sewage!.fixtureCount,
                      hasSeptic: plan.engineeringSystems!.sewage!.hasSeptic,
                      septicType:
                          plan.engineeringSystems!.sewage!.septicType?.name,
                    )
                  : null,
            )
          : null,
      axisLines: plan.axisLines
          .map(
            (a) => AxisLineState(
              id: const Uuid().v4(),
              label: a.label,
              x1: a.x1,
              y1: a.y1,
              x2: a.x2,
              y2: a.y2,
            ),
          )
          .toList(),
      dimensionLines: plan.dimensionLines
          .map(
            (d) => DimensionLineState(
              id: const Uuid().v4(),
              x1: d.x1,
              y1: d.y1,
              x2: d.x2,
              y2: d.y2,
              value: d.value,
              offset: d.offset,
            ),
          )
          .toList(),
      levelMarks: plan.levelMarks
          .map(
            (l) => LevelMarkState(
              id: const Uuid().v4(),
              x: l.x,
              y: l.y,
              level: l.level,
              description: l.description,
            ),
          )
          .toList(),
      columns: plan.columns
          .map(
            (c) => ColumnState(
              id: const Uuid().v4(),
              x: c.x,
              y: c.y,
              width: c.width,
              height: c.height,
              material: c.material.name,
            ),
          )
          .toList(),
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
          return Door(x: door.x, y: door.y, width: door.width, type: doorType);
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
          hasVentilation:
              roomType == RoomType.kitchen ||
              roomType == RoomType.bathroom ||
              windows.isNotEmpty,
        );
      }).toList(),
      totalWidth: editor.totalWidth,
      totalHeight: editor.totalHeight,
      // === РАСШИРЕННЫЕ ДАННЫЕ ===
      walls: editor.walls.map((ws) => ws.toWall()).toList(),
      foundation: editor.foundation?.toFoundation(),
      roof: editor.roof?.toRoof(),
      ceilings: editor.ceilings.map((cs) => cs.toCeiling()).toList(),
      axisLines: editor.axisLines.map((a) => a.toAxis()).toList(),
      dimensionLines: editor.dimensionLines
          .map((d) => d.toDimension())
          .toList(),
      levelMarks: editor.levelMarks.map((l) => l.toLevelMark()).toList(),
      columns: editor.columns.map((c) => c.toColumn()).toList(),
      engineeringSystems:
          editor.engineeringSystems?.toSystems() ?? const EngineeringSystems(),
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
      'rooms': plan.rooms
          .map(
            (room) => {
              'type': room.type.name,
              'x': room.x,
              'y': room.y,
              'width': room.width,
              'height': room.height,
              'hasVentilation': room.hasVentilation,
              'hasBalconyAccess': room.hasBalconyAccess,
              'doors': room.doors
                  .map(
                    (door) => {
                      'x': door.x,
                      'y': door.y,
                      'width': door.width,
                      'type': door.type.name,
                      'clockwise': door.clockwise,
                    },
                  )
                  .toList(),
              'windows': room.windows
                  .map(
                    (window) => {
                      'x': window.x,
                      'y': window.y,
                      'width': window.width,
                      'type': window.type.name,
                      'sillHeight': window.sillHeight,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };

    // Добавляем свободные элементы из EditorState
    if (_editorState != null) {
      json['freeDoors'] = _editorState!.doors
          .map(
            (door) => {
              'id': door.id,
              'x': door.x,
              'y': door.y,
              'width': door.width,
              'type': door.type,
              'rotation': door.rotation,
            },
          )
          .toList();

      json['freeWindows'] = _editorState!.windows
          .map(
            (window) => {
              'id': window.id,
              'x': window.x,
              'y': window.y,
              'width': window.width,
              'type': window.type,
              'rotation': window.rotation,
            },
          )
          .toList();

      json['radiators'] = _editorState!.radiators
          .map(
            (radiator) => {
              'id': radiator.id,
              'x': radiator.x,
              'y': radiator.y,
              'length': radiator.length,
              'type': radiator.type,
            },
          )
          .toList();

      json['plumbingFixtures'] = _editorState!.plumbingFixtures
          .map(
            (fixture) => {
              'id': fixture.id,
              'x': fixture.x,
              'y': fixture.y,
              'type': fixture.type,
              'rotation': fixture.rotation,
            },
          )
          .toList();

      json['electricalPoints'] = _editorState!.electricalPoints
          .map(
            (point) => {
              'id': point.id,
              'x': point.x,
              'y': point.y,
              'type': point.type,
              'height': point.height,
            },
          )
          .toList();

      // === РАСШИРЕННЫЕ ДАННЫЕ ===
      json['walls'] = _editorState!.walls
          .map(
            (w) => {
              'id': w.id,
              'x1': w.x1,
              'y1': w.y1,
              'x2': w.x2,
              'y2': w.y2,
              'thickness': w.thickness,
              'type': w.type,
              'material': w.material,
              'height': w.height,
              'isLoadBearing': w.isLoadBearing,
              'insulationThickness': w.insulationThickness,
            },
          )
          .toList();

      if (_editorState!.foundation != null) {
        final f = _editorState!.foundation!;
        json['foundation'] = {
          'type': f.type,
          'width': f.width,
          'depth': f.depth,
          'height': f.height,
          'embedmentDepth': f.embedmentDepth,
          'concreteGrade': f.concreteGrade,
          'concreteClass': f.concreteClass,
          'mainBarDiameter': f.mainBarDiameter,
          'mainBarsCount': f.mainBarsCount,
          'stirrupDiameter': f.stirrupDiameter,
          'stirrupSpacing': f.stirrupSpacing,
          'rebarClass': f.rebarClass,
          'hasWaterproofing': f.hasWaterproofing,
          'hasInsulation': f.hasInsulation,
          'hasDrainage': f.hasDrainage,
          'sandCushionThickness': f.sandCushionThickness,
        };
      }

      if (_editorState!.roof != null) {
        final r = _editorState!.roof!;
        json['roof'] = {
          'type': r.type,
          'area': r.area,
          'slopeAngle': r.slopeAngle,
          'roofingMaterial': r.roofingMaterial,
          'rafterSpacing': r.rafterSpacing,
          'rafterSectionWidth': r.rafterSectionWidth,
          'rafterSectionHeight': r.rafterSectionHeight,
          'rafterLength': r.rafterLength,
          'rafterCount': r.rafterCount,
          'rafterMaterial': r.rafterMaterial,
          'insulationThickness': r.insulationThickness,
          'insulationMaterial': r.insulationMaterial,
          'hasWaterproofingMembrane': r.hasWaterproofingMembrane,
          'hasVaporBarrier': r.hasVaporBarrier,
          'hasSnowRetention': r.hasSnowRetention,
          'snowRetentionCount': r.snowRetentionCount,
        };
      }

      json['ceilings'] = _editorState!.ceilings
          .map(
            (c) => {
              'id': c.id,
              'type': c.type,
              'material': c.material,
              'thickness': c.thickness,
              'area': c.area,
              'hasSoundproofing': c.hasSoundproofing,
            },
          )
          .toList();

      json['axisLines'] = _editorState!.axisLines
          .map(
            (a) => {
              'id': a.id,
              'label': a.label,
              'x1': a.x1,
              'y1': a.y1,
              'x2': a.x2,
              'y2': a.y2,
            },
          )
          .toList();

      json['dimensionLines'] = _editorState!.dimensionLines
          .map(
            (d) => {
              'id': d.id,
              'x1': d.x1,
              'y1': d.y1,
              'x2': d.x2,
              'y2': d.y2,
              'value': d.value,
              'offset': d.offset,
            },
          )
          .toList();

      json['levelMarks'] = _editorState!.levelMarks
          .map(
            (l) => {
              'id': l.id,
              'x': l.x,
              'y': l.y,
              'level': l.level,
              'description': l.description,
            },
          )
          .toList();

      json['columns'] = _editorState!.columns
          .map(
            (c) => {
              'id': c.id,
              'x': c.x,
              'y': c.y,
              'width': c.width,
              'height': c.height,
              'material': c.material,
            },
          )
          .toList();

      if (_editorState!.engineeringSystems != null) {
        final es = _editorState!.engineeringSystems!;
        final esJson = <String, dynamic>{};
        if (es.heating != null) {
          final h = es.heating!;
          esJson['heating'] = {
            'type': h.type,
            'radiatorCount': h.radiatorCount,
            'pipeLength': h.pipeLength,
            'boilerPower': h.boilerPower,
            'hasWarmFloor': h.hasWarmFloor,
            'warmFloorArea': h.warmFloorArea,
          };
        }
        if (es.waterSupply != null) {
          final w = es.waterSupply!;
          esJson['waterSupply'] = {
            'coldPipeLength': w.coldPipeLength,
            'hotPipeLength': w.hotPipeLength,
            'fixtureCount': w.fixtureCount,
            'hasWaterHeater': w.hasWaterHeater,
            'waterHeaterVolume': w.waterHeaterVolume,
          };
        }
        if (es.electrical != null) {
          final e = es.electrical!;
          esJson['electrical'] = {
            'cableLength': e.cableLength,
            'socketCount': e.socketCount,
            'switchCount': e.switchCount,
            'lightPointCount': e.lightPointCount,
            'breakerCount': e.breakerCount,
            'hasRCD': e.hasRCD,
            'hasGrounding': e.hasGrounding,
            'hasLightningProtection': e.hasLightningProtection,
            'hasSmartHome': e.hasSmartHome,
          };
        }
        if (es.ventilation != null) {
          final v = es.ventilation!;
          esJson['ventilation'] = {
            'type': v.type,
            'exhaustPoints': v.exhaustPoints,
            'supplyPoints': v.supplyPoints,
            'ductLength': v.ductLength,
            'hasRecuperator': v.hasRecuperator,
          };
        }
        if (es.sewage != null) {
          final s = es.sewage!;
          esJson['sewage'] = {
            'pipeLength': s.pipeLength,
            'fixtureCount': s.fixtureCount,
            'hasSeptic': s.hasSeptic,
            'septicType': s.septicType,
          };
        }
        json['engineeringSystems'] = esJson;
      }

      json['outdoorElements'] = _editorState!.outdoorElements
          .map(
            (o) => {
              'id': o.id,
              'type': o.type,
              'x': o.x,
              'y': o.y,
              'width': o.width,
              'height': o.height,
              'material': o.material,
              'properties': o.properties,
            },
          )
          .toList();

      json['floors'] = _editorState!.floors
          .map(
            (f) => {
              'id': f.id,
              'name': f.name,
              'floorHeight': f.floorHeight,
              'floorLevel': f.floorLevel,
              'floorIndex': f.floorIndex,
            },
          )
          .toList();
      json['currentFloorIndex'] = _editorState!.currentFloorIndex;
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

        final doors =
            (roomJson['doors'] as List?)?.map((doorJson) {
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
            }).toList() ??
            [];

        final windows =
            (roomJson['windows'] as List?)?.map((windowJson) {
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
            }).toList() ??
            [];

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
        final freeDoors =
            (widget.order.floorPlanData!['freeDoors'] as List?)
                ?.map(
                  (doorJson) => DoorState(
                    id: doorJson['id'] ?? const Uuid().v4(),
                    x: doorJson['x'].toDouble(),
                    y: doorJson['y'].toDouble(),
                    width: doorJson['width'].toDouble(),
                    type: doorJson['type'] ?? 'internal',
                    rotation: doorJson['rotation']?.toDouble() ?? 0,
                  ),
                )
                .toList() ??
            [];

        final freeWindows =
            (widget.order.floorPlanData!['freeWindows'] as List?)
                ?.map(
                  (windowJson) => WindowState(
                    id: windowJson['id'] ?? const Uuid().v4(),
                    x: windowJson['x'].toDouble(),
                    y: windowJson['y'].toDouble(),
                    width: windowJson['width'].toDouble(),
                    type: windowJson['type'] ?? 'standard',
                    rotation: windowJson['rotation']?.toDouble() ?? 0,
                  ),
                )
                .toList() ??
            [];

        final radiators =
            (widget.order.floorPlanData!['radiators'] as List?)
                ?.map(
                  (radJson) => RadiatorState(
                    id: radJson['id'] ?? const Uuid().v4(),
                    x: radJson['x'].toDouble(),
                    y: radJson['y'].toDouble(),
                    length: radJson['length'].toDouble() ?? 1.0,
                    type: radJson['type'] ?? 'panel',
                  ),
                )
                .toList() ??
            [];

        final plumbingFixtures =
            (widget.order.floorPlanData!['plumbingFixtures'] as List?)
                ?.map(
                  (fixJson) => PlumbingFixtureState(
                    id: fixJson['id'] ?? const Uuid().v4(),
                    x: fixJson['x'].toDouble(),
                    y: fixJson['y'].toDouble(),
                    type: fixJson['type'] ?? 'sink',
                    rotation: fixJson['rotation']?.toDouble() ?? 0,
                  ),
                )
                .toList() ??
            [];

        final electricalPoints =
            (widget.order.floorPlanData!['electricalPoints'] as List?)
                ?.map(
                  (pointJson) => ElectricalPointState(
                    id: pointJson['id'] ?? const Uuid().v4(),
                    x: pointJson['x'].toDouble(),
                    y: pointJson['y'].toDouble(),
                    type: pointJson['type'] ?? 'socket',
                    height: pointJson['height']?.toDouble() ?? 0.3,
                  ),
                )
                .toList() ??
            [];

        // Обновляем EditorState свободными элементами
        var fullEditorState = editorState.copyWith(
          doors: freeDoors,
          windows: freeWindows,
          radiators: radiators,
          plumbingFixtures: plumbingFixtures,
          electricalPoints: electricalPoints,
        );

        // === ЗАГРУЗКА РАСШИРЕННЫХ ДАННЫХ ===
        final data = widget.order.floorPlanData!;

        if (data['walls'] != null) {
          fullEditorState = fullEditorState.copyWith(
            walls: (data['walls'] as List)
                .map(
                  (w) => WallState(
                    id: w['id'],
                    x1: w['x1'].toDouble(),
                    y1: w['y1'].toDouble(),
                    x2: w['x2'].toDouble(),
                    y2: w['y2'].toDouble(),
                    thickness: w['thickness']?.toDouble() ?? 0.2,
                    type: w['type'] ?? 'interior',
                    material: w['material'] ?? 'brick',
                    height: w['height']?.toDouble() ?? 2.7,
                    isLoadBearing: w['isLoadBearing'] ?? false,
                    insulationThickness:
                        w['insulationThickness']?.toDouble() ?? 0,
                  ),
                )
                .toList(),
          );
        }

        if (data['foundation'] != null) {
          final f = data['foundation'];
          fullEditorState = fullEditorState.copyWith(
            foundation: FoundationState(
              id: f['id'] ?? 'foundation',
              type: f['type'] ?? 'strip',
              width: f['width']?.toDouble() ?? 0.4,
              depth: f['depth']?.toDouble() ?? 1.2,
              height: f['height']?.toDouble() ?? 0.5,
              embedmentDepth: f['embedmentDepth']?.toDouble() ?? 1.2,
              concreteGrade: f['concreteGrade'] ?? 'М300',
              concreteClass: f['concreteClass'] ?? 'B22_5',
              mainBarDiameter: f['mainBarDiameter'] ?? 12,
              mainBarsCount: f['mainBarsCount'] ?? 4,
              stirrupDiameter: f['stirrupDiameter'] ?? 8,
              stirrupSpacing: f['stirrupSpacing'] ?? 200,
              rebarClass: f['rebarClass'] ?? 'A500C',
              hasWaterproofing: f['hasWaterproofing'] ?? false,
              hasInsulation: f['hasInsulation'] ?? false,
              hasDrainage: f['hasDrainage'] ?? false,
              sandCushionThickness:
                  f['sandCushionThickness']?.toDouble() ?? 0.2,
            ),
          );
        }

        if (data['roof'] != null) {
          final r = data['roof'];
          fullEditorState = fullEditorState.copyWith(
            roof: RoofState(
              id: r['id'] ?? 'roof',
              type: r['type'] ?? 'gable',
              area: r['area']?.toDouble() ?? 100,
              slopeAngle: r['slopeAngle']?.toDouble() ?? 30,
              roofingMaterial: r['roofingMaterial'] ?? 'metalTile',
              rafterSpacing: r['rafterSpacing'] ?? 600,
              rafterSectionWidth: r['rafterSectionWidth'] ?? 50,
              rafterSectionHeight: r['rafterSectionHeight'] ?? 200,
              rafterLength: r['rafterLength']?.toDouble() ?? 5,
              rafterCount: r['rafterCount'] ?? 10,
              rafterMaterial: r['rafterMaterial'] ?? 'pine',
              insulationThickness: r['insulationThickness']?.toDouble() ?? 0.2,
              insulationMaterial: r['insulationMaterial'] ?? 'mineralWool',
              hasWaterproofingMembrane: r['hasWaterproofingMembrane'] ?? false,
              hasVaporBarrier: r['hasVaporBarrier'] ?? false,
              hasSnowRetention: r['hasSnowRetention'] ?? false,
              snowRetentionCount: r['snowRetentionCount'] ?? 0,
            ),
          );
        }

        if (data['ceilings'] != null) {
          fullEditorState = fullEditorState.copyWith(
            ceilings: (data['ceilings'] as List)
                .map(
                  (c) => CeilingState(
                    id: c['id'],
                    type: c['type'] ?? 'monolithic',
                    material: c['material'] ?? 'concreteSlab',
                    thickness: c['thickness']?.toDouble() ?? 0.2,
                    area: c['area']?.toDouble() ?? 100,
                    hasSoundproofing: c['hasSoundproofing'] ?? false,
                  ),
                )
                .toList(),
          );
        }

        if (data['axisLines'] != null) {
          fullEditorState = fullEditorState.copyWith(
            axisLines: (data['axisLines'] as List)
                .map(
                  (a) => AxisLineState(
                    id: a['id'],
                    label: a['label'] ?? '',
                    x1: a['x1'].toDouble(),
                    y1: a['y1'].toDouble(),
                    x2: a['x2'].toDouble(),
                    y2: a['y2'].toDouble(),
                  ),
                )
                .toList(),
          );
        }

        if (data['dimensionLines'] != null) {
          fullEditorState = fullEditorState.copyWith(
            dimensionLines: (data['dimensionLines'] as List)
                .map(
                  (d) => DimensionLineState(
                    id: d['id'],
                    x1: d['x1'].toDouble(),
                    y1: d['y1'].toDouble(),
                    x2: d['x2'].toDouble(),
                    y2: d['y2'].toDouble(),
                    value: d['value'] ?? '',
                    offset: d['offset']?.toDouble() ?? 0.5,
                  ),
                )
                .toList(),
          );
        }

        if (data['levelMarks'] != null) {
          fullEditorState = fullEditorState.copyWith(
            levelMarks: (data['levelMarks'] as List)
                .map(
                  (l) => LevelMarkState(
                    id: l['id'],
                    x: l['x'].toDouble(),
                    y: l['y'].toDouble(),
                    level: l['level'].toDouble(),
                    description: l['description'],
                  ),
                )
                .toList(),
          );
        }

        if (data['columns'] != null) {
          fullEditorState = fullEditorState.copyWith(
            columns: (data['columns'] as List)
                .map(
                  (c) => ColumnState(
                    id: c['id'],
                    x: c['x'].toDouble(),
                    y: c['y'].toDouble(),
                    width: c['width'].toDouble(),
                    height: c['height'].toDouble(),
                    material: c['material'] ?? 'reinforcedConcrete',
                  ),
                )
                .toList(),
          );
        }

        if (data['engineeringSystems'] != null) {
          final esJson = data['engineeringSystems'];
          fullEditorState = fullEditorState.copyWith(
            engineeringSystems: EngineeringSystemsState(
              heating: esJson['heating'] != null
                  ? HeatingSystemState(
                      type: esJson['heating']['type'] ?? 'radiators',
                      radiatorCount: esJson['heating']['radiatorCount'] ?? 0,
                      pipeLength:
                          esJson['heating']['pipeLength']?.toDouble() ?? 0,
                      boilerPower:
                          esJson['heating']['boilerPower']?.toDouble() ?? 0,
                      hasWarmFloor: esJson['heating']['hasWarmFloor'] ?? false,
                      warmFloorArea:
                          esJson['heating']['warmFloorArea']?.toDouble() ?? 0,
                    )
                  : null,
              waterSupply: esJson['waterSupply'] != null
                  ? WaterSupplyState(
                      coldPipeLength:
                          esJson['waterSupply']['coldPipeLength']?.toDouble() ??
                          0,
                      hotPipeLength:
                          esJson['waterSupply']['hotPipeLength']?.toDouble() ??
                          0,
                      fixtureCount: esJson['waterSupply']['fixtureCount'] ?? 0,
                      hasWaterHeater:
                          esJson['waterSupply']['hasWaterHeater'] ?? false,
                      waterHeaterVolume:
                          esJson['waterSupply']['waterHeaterVolume']
                              ?.toDouble() ??
                          0,
                    )
                  : null,
              electrical: esJson['electrical'] != null
                  ? ElectricalState(
                      cableLength:
                          esJson['electrical']['cableLength']?.toDouble() ?? 0,
                      socketCount: esJson['electrical']['socketCount'] ?? 0,
                      switchCount: esJson['electrical']['switchCount'] ?? 0,
                      lightPointCount:
                          esJson['electrical']['lightPointCount'] ?? 0,
                      breakerCount: esJson['electrical']['breakerCount'] ?? 0,
                      hasRCD: esJson['electrical']['hasRCD'] ?? false,
                      hasGrounding:
                          esJson['electrical']['hasGrounding'] ?? false,
                      hasLightningProtection:
                          esJson['electrical']['hasLightningProtection'] ??
                          false,
                      hasSmartHome:
                          esJson['electrical']['hasSmartHome'] ?? false,
                    )
                  : null,
              ventilation: esJson['ventilation'] != null
                  ? VentilationState(
                      type: esJson['ventilation']['type'] ?? 'natural',
                      exhaustPoints:
                          esJson['ventilation']['exhaustPoints'] ?? 0,
                      supplyPoints: esJson['ventilation']['supplyPoints'] ?? 0,
                      ductLength:
                          esJson['ventilation']['ductLength']?.toDouble() ?? 0,
                      hasRecuperator:
                          esJson['ventilation']['hasRecuperator'] ?? false,
                    )
                  : null,
              sewage: esJson['sewage'] != null
                  ? SewageState(
                      pipeLength:
                          esJson['sewage']['pipeLength']?.toDouble() ?? 0,
                      fixtureCount: esJson['sewage']['fixtureCount'] ?? 0,
                      hasSeptic: esJson['sewage']['hasSeptic'] ?? false,
                      septicType: esJson['sewage']['septicType'],
                    )
                  : null,
            ),
          );
        }

        if (data['outdoorElements'] != null) {
          fullEditorState = fullEditorState.copyWith(
            outdoorElements: (data['outdoorElements'] as List)
                .map(
                  (o) => OutdoorElementState(
                    id: o['id'],
                    type: o['type'],
                    x: o['x'].toDouble(),
                    y: o['y'].toDouble(),
                    width: o['width']?.toDouble() ?? 0,
                    height: o['height']?.toDouble() ?? 0,
                    material: o['material'],
                    properties: Map<String, dynamic>.from(
                      o['properties'] ?? {},
                    ),
                  ),
                )
                .toList(),
          );
        }

        if (data['floors'] != null) {
          fullEditorState = fullEditorState.copyWith(
            floors: (data['floors'] as List)
                .map(
                  (f) => FloorState(
                    id: f['id'],
                    name: f['name'],
                    floorHeight: f['floorHeight'].toDouble(),
                    floorLevel: f['floorLevel'].toDouble(),
                    floorIndex: f['floorIndex'],
                  ),
                )
                .toList(),
            currentFloorIndex: data['currentFloorIndex'] ?? 0,
          );
        }

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
                    icon: Icon(
                      _isAIOptimized ? Icons.check_circle : Icons.auto_awesome,
                    ),
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
                IconButton(
                  icon: const Icon(Icons.engineering),
                  onPressed: _plan != null
                      ? () => _generateConstructionDrawing()
                      : null,
                  tooltip: 'Строительный чертёж',
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
            // Панель конструктива (перетаскиваемая)
            if (_editorState != null && _isEditing)
              _buildDraggableConstructionPanel(),
            // AI кнопка
            if (!_isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateAIFloorPlan,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                          _isAIFloorPlanGenerated
                              ? '🤖 AI-план готов (пересоздать)'
                              : '🤖 AI-генерация из замера',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesign.deepSteelBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
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
                    onPressed: () =>
                        setState(() => _zoom = (_zoom + 0.2).clamp(0.5, 5.0)),
                    backgroundColor: AppDesign.accentTeal,
                    child: const Icon(Icons.zoom_in, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'zoom_out',
                    onPressed: () =>
                        setState(() => _zoom = (_zoom - 0.2).clamp(0.5, 5.0)),
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
            Text(
              'Недостаточно данных для генерации',
              style: AppDesign.subtitleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Заполните размеры в чек-листе',
              style: AppDesign.captionStyle,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Compliance bar
        _buildComplianceBar(),

        // Warnings
        if (_plan!.allWarnings.isNotEmpty && !_isEditing)
          _buildWarningsBanner(),

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
    final color = score > 0.8
        ? Colors.green
        : score > 0.5
        ? Colors.orange
        : Colors.red;

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
          Text('${_plan!.roomCount} комн.', style: AppDesign.captionStyle),
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
            .map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(w, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            )
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

  /// Перетаскиваемая панель конструктива
  Widget _buildDraggableConstructionPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _isPanelExpanded ? _panelHeight : 50,
      decoration: BoxDecoration(
        color: AppDesign.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppDesign.deepSteelBlue.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Перетаскиваемая ручка
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _panelHeight = (_panelHeight - details.delta.dy).clamp(
                  50.0,
                  500.0,
                );
                if (_panelHeight < 100) {
                  _isPanelExpanded = false;
                } else {
                  _isPanelExpanded = true;
                }
              });
            },
            onDoubleTap: () {
              setState(() {
                _isPanelExpanded = !_isPanelExpanded;
                _panelHeight = _isPanelExpanded ? 380 : 50;
              });
            },
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppDesign.deepSteelBlue, AppDesign.accentTeal],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator, color: Colors.white70),
                  const SizedBox(width: 8),
                  const Icon(Icons.construction, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Конструктив',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  // Статистика элементов
                  _buildElementCountBadge(
                    Icons.wallpaper,
                    '${_editorState!.walls.length}',
                    'стен',
                  ),
                  const SizedBox(width: 8),
                  _buildElementCountBadge(
                    Icons.foundation,
                    _editorState!.foundation != null ? '1' : '0',
                    'фунд.',
                  ),
                  const SizedBox(width: 8),
                  _buildElementCountBadge(
                    Icons.roofing,
                    _editorState!.roof != null ? '1' : '0',
                    'кров.',
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      _isPanelExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPanelExpanded = !_isPanelExpanded;
                        _panelHeight = _isPanelExpanded ? 380 : 50;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // Контент панели
          if (_isPanelExpanded && _editorState != null)
            Expanded(
              child: ConstructionPanel(
                state: _editorState!,
                onChanged: _onEditorChanged,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildElementCountBadge(IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Поделиться планом (экспорт в PDF)
  Future<void> _sharePlan() async {
    if (_plan == null) return;

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Генерация PDF...')));

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
    }
  }

  /// Генерация полного строительного чертежа
  Future<void> _generateConstructionDrawing() async {
    if (_plan == null) return;

    // Проверяем премиум
    final isPremium = await _subscriptionService.isPremiumActive();
    if (!isPremium && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Строительный чертёж доступен только для Премиум'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Генерация полного комплекта чертежей...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final file =
          await ConstructionDrawingGenerator.generateFullDrawingPackage(
            plan: _plan!,
            order: widget.order,
            projectName: 'Проект — ${widget.order.clientName}',
          );

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Строительный чертёж — ${widget.order.clientName}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка генерации чертежа: $e')));
    }
  }

  /// AI оптимизация плана
  void _optimizeWithAI() {
    if (_plan == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('AI оптимизация...')));

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('План сброшен')));
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
