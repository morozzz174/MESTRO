import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/order.dart';
import '../../../utils/app_design.dart';
import '../../../utils/pdf_generator.dart';
import '../models/floor_plan_models.dart';
import '../engine/floor_plan_rule_engine.dart';
import '../engine/ai_floor_plan_optimizer.dart';
import '../widgets/floor_plan_painter.dart';

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
  FloorPlan? _plan;
  double _zoom = 1.0;
  bool _isGenerating = false;
  bool _isAIOptimized = false;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _aiOptimizer = AIFloorPlanOptimizer();
    _ruleEngine = FloorPlanRuleEngine(aiOptimizer: _aiOptimizer);
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
      body: _buildBody(),
      floatingActionButton: Column(
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
        if (_plan!.allWarnings.isNotEmpty) _buildWarningsBanner(),

        // План с зумом
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: InteractiveViewer(
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
        _buildInfoPanel(),
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
