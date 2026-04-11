import 'package:flutter/material.dart';
import '../../../../models/ai_insight.dart';
import '../../../../models/order.dart';
import '../../../../models/checklist_config.dart';
import '../../../../services/ai_agent_service.dart';
import '../../../../services/subscription_service.dart';
import '../../../../utils/app_design.dart';
import '../pages/ai_analysis_screen.dart';
import '../pages/subscription_screen.dart';

/// Виджет кнопки AI-анализа на экране заявки
class AIAgentButton extends StatefulWidget {
  final Order order;
  final ChecklistConfig checklistConfig;

  const AIAgentButton({
    super.key,
    required this.order,
    required this.checklistConfig,
  });

  @override
  State<AIAgentButton> createState() => _AIAgentButtonState();
}

class _AIAgentButtonState extends State<AIAgentButton>
    with SingleTickerProviderStateMixin {
  final _aiService = SmartChecklistAnalyzer();
  final _subscriptionService = SubscriptionService();
  late AnimationController _pulseController;
  bool _isPremium = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkPremium();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkPremium() async {
    final isActive = await _subscriptionService.isPremiumActive();
    setState(() => _isPremium = isActive);
  }

  Future<void> _runAnalysis() async {
    if (!_isPremium) {
      // Показать экран подписки
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SubscriptionScreen(),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // Анализируем в фоне
    final report = _aiService.analyze(widget.order, widget.checklistConfig);

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AIAnalysisScreen(report: report),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isPremium ? _buildPremiumButton() : _buildLockedButton();
  }

  Widget _buildPremiumButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + _pulseController.value * 0.05;
        return Transform.scale(
          scale: scale,
          child: FloatingActionButton(
            heroTag: 'ai_agent_fab',
            onPressed: _isLoading ? null : _runAnalysis,
            backgroundColor: AppDesign.deepSteelBlue,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.auto_awesome, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildLockedButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + _pulseController.value * 0.03;
        return Transform.scale(
          scale: scale,
          child: FloatingActionButton(
            heroTag: 'ai_agent_locked_fab',
            onPressed: _runAnalysis,
            backgroundColor: Colors.grey[400],
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white54),
                Positioned(
                  bottom: 4,
                  child: Icon(Icons.lock, size: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
