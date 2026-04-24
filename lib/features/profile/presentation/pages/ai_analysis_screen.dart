import 'package:flutter/material.dart';
import '../../../../models/ai_insight.dart';

class AIAnalysisScreen extends StatelessWidget {
  final AIAnalysisReport report;

  const AIAnalysisScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI-анализ замера'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Сводка
            _buildSummaryCard(),
            const SizedBox(height: 16),

            // Статистика
            _buildStatsRow(),
            const SizedBox(height: 16),

            // Инсайты
            if (report.insights.isEmpty)
              _buildEmptyState()
            else
              ...report.sortedInsights
                  .map((insight) => _buildInsightCard(insight))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final confidence = report.confidenceScore ?? 0;
    final confidencePercent = (confidence * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: report.hasCriticalIssues
              ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
              : [const Color(0xFF4CAF50), const Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                report.hasCriticalIssues
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Результат анализа',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.summary,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Уверенность
          Row(
            children: [
              const Text(
                'Уверенность:',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$confidencePercent%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatChip(
          '❌',
          report.criticalCount.toString(),
          'Критических',
          const Color(0xFFF44336),
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          '⚠️',
          report.highCount.toString(),
          'Важных',
          const Color(0xFFFF9800),
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          '💡',
          report.tipCount.toString(),
          'Советов',
          const Color(0xFF00BCD4),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    String emoji,
    String count,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Всё отлично!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            report.summary,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(AIInsight insight) {
    final color = Color(int.parse('FF${insight.colorHex}'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(insight.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _priorityLabel(insight.priority),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.description,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if (insight.suggestion != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.suggestion!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (insight.affectedField != null) ...[
            const SizedBox(height: 8),
            Text(
              'Поле: ${insight.affectedField}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  String _priorityLabel(AIInsightPriority priority) {
    switch (priority) {
      case AIInsightPriority.critical:
        return 'КРИТ';
      case AIInsightPriority.high:
        return 'ВАЖНО';
      case AIInsightPriority.medium:
        return 'ВНИМАНИЕ';
      case AIInsightPriority.low:
        return 'СОВЕТ';
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('О AI-анализе'),
        content: const SingleChildScrollView(
          child: Text(
            'AI-ассистент анализирует данные замера и находит:\n\n'
            '• Пропущенные обязательные поля\n'
            '• Аномалии в значениях (слишком большие/маленькие)\n'
            '• Несогласованность между полями\n'
            '• Проблемы со стоимостью\n'
            '• Рекомендации по типу работ\n'
            '• Общие советы по улучшению\n\n'
            'Анализ выполняется полностью офлайн — без отправки данных на сервер.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}
