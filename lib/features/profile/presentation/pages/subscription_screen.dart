import 'package:flutter/material.dart';
import '../../../../services/subscription_service.dart';
import '../../../../utils/app_design.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  Map<String, dynamic>? _subscriptionInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    final info = await _subscriptionService.getSubscriptionInfo();
    setState(() {
      _subscriptionInfo = info;
      _isLoading = false;
    });
  }

  Future<void> _activatePremium(int? days) async {
    final success = await _subscriptionService.activatePremium(durationDays: days);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Премиум активирован!'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadSubscriptionInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Премиум подписка'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final isActive = _subscriptionInfo?['isActive'] as bool? ?? false;
    final message = _subscriptionInfo?['message'] as String? ?? '';
    final activatedAt = _subscriptionInfo?['activatedAt'] as String?;
    final until = _subscriptionInfo?['until'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Карточка статуса
          _buildStatusCard(isActive, message, activatedAt, until),
          const SizedBox(height: 24),

          // Что входит в премиум
          _buildFeaturesList(),
          const SizedBox(height: 24),

          // Кнопки активации
          _buildActivationButtons(isActive),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    bool isActive,
    String message,
    String? activatedAt,
    String? until,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
              : [const Color(0xFF78909C), const Color(0xFFB0BEC5)],
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
        children: [
          Icon(
            isActive ? Icons.workspace_premium : Icons.lock_outline,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isActive ? 'Премиум активен' : 'Премиум не активен',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          if (activatedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Активирован: $activatedAt',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
          if (until != null) ...[
            Text(
              'Действует до: $until',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    const features = [
      ('🤖', 'AI-ассистент замерщика', 'Автоматический анализ данных замера'),
      ('⚠️', 'Проверка ошибок', 'Поиск аномалий и пропущенных полей'),
      ('💡', 'Умные рекомендации', 'Советы по материалам и технологиям'),
      ('💰', 'Анализ стоимости', 'Проверка корректности расчётов'),
      ('🎙️', 'Расширенный голосовой ввод', 'AI-интерпретация диктовки'),
      ('📊', 'Авто-отчёты', 'Генерация резюме по замеру'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Возможности Премиум:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            f.$3,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActivationButtons(bool isActive) {
    if (isActive) {
      return Column(
        children: [
          _buildPlanOption(
            icon: Icons.calendar_today,
            title: 'Продлить на 30 дней',
            subtitle: 'Дополнительный месяц премиума',
            onTap: () => _activatePremium(30),
          ),
          const SizedBox(height: 12),
          _buildPlanOption(
            icon: Icons.star,
            title: 'Активировать бессрочно',
            subtitle: 'Премиум навсегда',
            onTap: () => _activatePremium(null),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildPlanOption(
          icon: Icons.calendar_today,
          title: 'Активировать на 30 дней',
          subtitle: 'Пробный период',
          onTap: () => _activatePremium(30),
        ),
        const SizedBox(height: 12),
        _buildPlanOption(
          icon: Icons.star,
          title: 'Активировать бессрочно',
          subtitle: 'Премиум навсегда',
          onTap: () => _activatePremium(null),
        ),
      ],
    );
  }

  Widget _buildPlanOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppDesign.deepSteelBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesign.deepSteelBlue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppDesign.deepSteelBlue, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
