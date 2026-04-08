import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import '../../../../models/order.dart';
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
    _generatePlan();
  }

  Future<void> _initializeAI() async {
    await _aiOptimizer.initialize();
    if (mounted) setState(() {});
  }

  void _generatePlan() {
    setState(() => _isGenerating = true);

    final checklistData = widget.order.checklistData;
    final widthMm = (checklistData['width'] as num?)?.toDouble() ?? 0;
    final heightMm = (checklistData['height'] as num?)?.toDouble() ?? 0;

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

  /// Конвертировать FloorPlan в EditorState
  EditorState _planToEditorState(FloorPlan plan) {
    return EditorState(
      rooms: plan.rooms.map((room) => RoomState(
        id: room.type.toString(),
        type: room.type.name,
        x: room.x,
        y: room.y,
        width: room.width,
        height: room.height,
      )).toList(),
      totalWidth: plan.totalWidth,
      totalHeight: plan.totalHeight,
    );
  }

  /// Конвертировать EditorState обратно в FloorPlan
  FloorPlan _editorToPlan(EditorState editor) {
    return FloorPlan(
      rooms: editor.rooms.map((room) {
        final roomType = RoomType.values.firstWhere(
          (t) => t.name == room.type,
          orElse: () => RoomType.hallway,
        );
        return Room(
          type: roomType,
          x: room.x,
          y: room.y,
          width: room.width,
          height: room.height,
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
    return Scaffold(
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
  }

  void _resetPlan() {
    _undoRedo.clear();
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
