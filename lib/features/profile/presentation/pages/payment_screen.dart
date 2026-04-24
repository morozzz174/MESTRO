import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../services/payment_service.dart';
import '../../../../services/subscription_service.dart';
import '../../../../utils/app_design.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _paymentService = PaymentService();
  final _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  bool _isPremiumActive = false;
  String? _currentPaymentId;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isActive = await _subscriptionService.isPremiumActive();
    if (mounted) {
      setState(() {
        _isPremiumActive = isActive;
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePlan(PricingPlan plan) async {
    setState(() => _isProcessingPayment = true);

    // Демо-режим: если YooKassa не настроена — активируем напрямую
    if (!_paymentService.isConfigured) {
      await _paymentService.activateDemoPremium(durationDays: plan.durationDays);
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _isPremiumActive = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${plan.title} активирован (демо-режим)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Реальная оплата через YooKassa
    try {
      final result = await _paymentService.createPayment(
        plan: plan,
        userEmail: 'user@example.com', // TODO: взять из профиля
        returnUrl: 'mestro://payment-success', // Deep link для возврата
      );

      if (result == null && mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка создания платежа'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Открываем страницу оплаты
      final confirmationUrl = result; // TODO: получить URL из result
      // Пока не реализовано — используем демо-активацию
      await _paymentService.activateDemoPremium(durationDays: plan.durationDays);

      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _isPremiumActive = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${plan.title} активирован!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка оплаты: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Премиум подписка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isPremiumActive) {
      return _buildActiveStatus();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Баннер демо-режима
          _buildDemoBanner(),
          const SizedBox(height: 16),

          // Заголовок
          _buildHeader(),
          const SizedBox(height: 24),

          // Тарифные планы
          ...PricingPlan.available.map((plan) => _buildPlanCard(plan)),

          const SizedBox(height: 24),

          // Возможности
          _buildFeaturesList(),
          const SizedBox(height: 16),

          // Оферта
          _buildLegalNotice(),
        ],
      ),
    );
  }

  Widget _buildDemoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎉 Временно бесплатно!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Оплата пока не подключена — премиум доступен бесплатно. '
                  'В будущем обновлении будет подключена ЮKassa.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDemo = !_paymentService.isConfigured;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDemo
              ? [const Color(0xFFFF9800), const Color(0xFFFFB74D)]
              : [const Color(0xFF4CAF50), const Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isDemo ? Icons.emoji_events : Icons.workspace_premium,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isDemo ? 'Премиум — временно бесплатно!' : 'Разблокировать Премиум',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isDemo
                ? 'Оплата будет подключена в будущем обновлении\nВсе функции уже доступны бесплатно 🎉'
                : 'AI-ассистент • Строительные чертежи\nУмные рекомендации • Анализ стоимости',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PricingPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: plan.isPopular
            ? AppDesign.deepSteelBlue.withOpacity(0.08)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.isPopular
              ? AppDesign.deepSteelBlue.withOpacity(0.3)
              : Colors.grey[200]!,
          width: plan.isPopular ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessingPayment ? null : () => _purchasePlan(plan),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Иконка и информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: plan.isPopular
                                    ? AppDesign.deepSteelBlue
                                    : null,
                              ),
                            ),
                          ),
                          if (plan.badge.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: plan.isPopular
                                    ? AppDesign.deepSteelBlue
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                plan.badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.durationLabel,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Цена и кнопка
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.formattedPrice,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: plan.isPopular
                            ? AppDesign.deepSteelBlue
                            : null,
                      ),
                    ),
                    if (plan.durationDays != null)
                      Text(
                        '${plan.pricePerDay.toStringAsFixed(1)} ₽/день',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 8),
                    _isProcessingPayment
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ElevatedButton(
                            onPressed: () => _purchasePlan(plan),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: plan.isPopular
                                  ? AppDesign.deepSteelBlue
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              _paymentService.isConfigured
                                  ? 'Купить'
                                  : 'Бесплатно',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    const features = [
      ('🤖', 'AI-ассистент замерщика', 'Автоматический анализ данных замера'),
      ('⚠️', 'Проверка ошибок', 'Поиск аномалий и пропущенных полей'),
      ('💡', 'Умные рекомендации', 'Советы по материалам и технологиям'),
      ('💰', 'Анализ стоимости', 'Проверка корректности расчётов'),
      ('📐', 'Строительные чертежи', 'Полный комплект PDF документации'),
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

  Widget _buildLegalNotice() {
    return Column(
      children: [
        const Divider(),
        TextButton(
          onPressed: () => _showDocumentDialog('Публичная оферта', 'assets/offer.md'),
          child: const Text('Публичная оферта'),
        ),
        TextButton(
          onPressed: () => _showDocumentDialog('Политика конфиденциальности', 'assets/privacy_policy.md'),
          child: const Text('Политика конфиденциальности'),
        ),
        TextButton(
          onPressed: () => _showDocumentDialog('Политика возврата', 'assets/refund_policy.md'),
          child: const Text('Политика возврата'),
        ),
        const SizedBox(height: 8),
        Text(
          'ИП Морозов М.И. | ИНН 745013371800 | ОГРНИП 326745600046657',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _showDocumentDialog(String title, String assetPath) async {
    try {
      final text = await rootBundle.loadString(assetPath);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    text,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки документа: $e')),
      );
    }
  }

  Widget _buildActiveStatus() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Премиум активен!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Все функции доступны',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('О подписке'),
        content: const SingleChildScrollView(
          child: Text(
            'Премиум-подписка открывает доступ к:\n\n'
            '• AI-ассистенту замерщика\n'
            '• Строительным чертежам в PDF\n'
            '• Умным рекомендациям\n'
            '• Анализу стоимости\n\n'
            'Оплата через YooKassa (ЮKassa).\n'
            'Для возврата обратитесь на CHIK174@YANDEX.RU',
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
