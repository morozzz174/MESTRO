import 'package:flutter/material.dart';
import '../../../../services/subscription_service.dart';
import '../../../../services/payment_service.dart';
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

  Future<void> _activateDemoPremium(int? days) async {
    final success = await _subscriptionService.activatePremium(
      durationDays: days,
    );
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
        backgroundColor: AppDesign.primaryDark,
        foregroundColor: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(isActive, message, activatedAt, until),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFeaturesList(),
          ),
          const SizedBox(height: 24),
          if (!isActive) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Выберите тариф:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPricingCards(),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildActiveUserActions(),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(
    bool isActive,
    String message,
    String? activatedAt,
    String? until,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
              : [
                  AppDesign.primaryDark,
                  AppDesign.primaryDark.withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Icon(
              isActive ? Icons.workspace_premium : Icons.star_rounded,
              size: 72,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'Премиум активен' : 'MESTRO Премиум',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? message
                  : 'Разблокируйте все возможности AI-ассистента',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      until != null ? 'До $until' : 'Бессрочно',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Возможности Премиум:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.smart_toy,
            'AI-ассистент замерщика',
            'Автоматический анализ данных и поиск ошибок',
            Colors.purple,
          ),
          _buildFeatureItem(
            Icons.mic,
            'Голосовой ввод для 15 специализаций',
            'Диктуйте замеры — AI заполнит все поля',
            Colors.blue,
          ),
          _buildFeatureItem(
            Icons.fact_check,
            'AI-валидация КП',
            'Проверка коммерческого предложения перед отправкой',
            Colors.green,
          ),
          _buildFeatureItem(
            Icons.note_add,
            'Авто-заметки замерщика',
            'AI генерирует структурированные заметки',
            Colors.orange,
          ),
          _buildFeatureItem(
            Icons.architecture,
            'Строительные чертежи и планы',
            'Генерация полного комплекта чертежей',
            Colors.teal,
          ),
          _buildFeatureItem(
            Icons.table_chart,
            'Экспорт в Excel',
            'Выгрузка заявок и прайс-листов',
            Colors.indigo,
          ),
          _buildFeatureItem(
            Icons.cloud_upload,
            'Резервная копия',
            'Экспорт и импорт базы данных',
            Colors.brown,
          ),
          _buildFeatureItem(
            Icons.notifications_active,
            'Уведомления о замерах',
            'Напоминания за 1 час, 30 мин, SMS клиенту',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards() {
    final plans = PricingPlan.available;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildPricingCard(plans[0], false)),
              const SizedBox(width: 8),
              Expanded(child: _buildPricingCard(plans[1], false)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildPricingCard(plans[2], true),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildPricingCard(plans[3], false)),
              const SizedBox(width: 8),
              Expanded(child: _buildPricingCard(plans[4], false)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '* Демо-активация для тестирования',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(PricingPlan plan, bool isWide) {
    return InkWell(
      onTap: () => _activateDemoPremium(plan.durationDays),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: plan.isPopular
              ? LinearGradient(
                  colors: [
                    AppDesign.accentTeal.withValues(alpha: 0.1),
                    AppDesign.primaryDark.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: plan.isPopular ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: plan.isPopular
                ? AppDesign.accentTeal.withValues(alpha: 0.3)
                : Colors.grey[300]!,
            width: plan.isPopular ? 2 : 1,
          ),
          boxShadow: plan.isPopular
              ? [
                  BoxShadow(
                    color: AppDesign.accentTeal.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.badge.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppDesign.accentTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (plan.badge.isNotEmpty) const SizedBox(height: 8),
            Text(
              plan.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              plan.description,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.formattedPrice,
                  style: TextStyle(
                    fontSize: isWide ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: plan.isPopular
                        ? AppDesign.accentTeal
                        : AppDesign.primaryDark,
                  ),
                ),
                if (plan.durationDays != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '/ ${plan.durationLabel}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ],
            ),
            if (plan.pricePerDay > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${plan.pricePerDay.toStringAsFixed(1)} ₽/день',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUserActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Продлить подписку:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildExtendButton(
                'Месяц',
                '299 ₽',
                () => _activateDemoPremium(30),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildExtendButton(
                'Квартал',
                '699 ₽',
                () => _activateDemoPremium(90),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildExtendButton(
                'Год',
                '1990 ₽',
                () => _activateDemoPremium(365),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildExtendButton(
                'Навсегда',
                '4990 ₽',
                () => _activateDemoPremium(null),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExtendButton(String title, String price, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppDesign.accentTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppDesign.accentTeal.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppDesign.accentTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
