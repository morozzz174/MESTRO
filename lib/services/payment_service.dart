/// Сервис оплаты через YooKassa
/// Работает через YooKassa Payments API (HTTP)
/// Документация: https://yookassa.ru/developers/api
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'subscription_service.dart';
import 'app_logger.dart';

/// Тарифный план премиум-подписки
class PricingPlan {
  final String id;
  final String title;
  final String description;
  final int priceRubles;
  final int? durationDays; // null = бессрочно
  final String badge; // "Хит", "Выгодно" и т.д.
  final bool isPopular;

  const PricingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.priceRubles,
    this.durationDays,
    this.badge = '',
    this.isPopular = false,
  });

  String get formattedPrice => '${priceRubles.toString()} ₽';

  String get durationLabel {
    if (durationDays == null) return 'Навсегда';
    if (durationDays == 7) return '7 дней';
    if (durationDays == 30) return '1 месяц';
    if (durationDays == 90) return '3 месяца';
    if (durationDays == 365) return '1 год';
    return '$durationDays дней';
  }

  double get pricePerDay {
    final days = durationDays;
    if (days == null) return 0;
    return priceRubles / days;
  }

  static const List<PricingPlan> available = [
    PricingPlan(
      id: 'trial_7d',
      title: 'Пробный',
      description: '7 дней полного доступа',
      priceRubles: 149,
      durationDays: 7,
    ),
    PricingPlan(
      id: 'monthly',
      title: 'Месяц',
      description: '30 дней AI-ассистента и чертежей',
      priceRubles: 299,
      durationDays: 30,
    ),
    PricingPlan(
      id: 'quarterly',
      title: 'Квартал',
      description: '90 дней со скидкой 25%',
      priceRubles: 699,
      durationDays: 90,
      badge: '-25%',
      isPopular: true,
    ),
    PricingPlan(
      id: 'yearly',
      title: 'Год',
      description: '365 дней максимальной выгоды',
      priceRubles: 1990,
      durationDays: 365,
      badge: '-45%',
    ),
    PricingPlan(
      id: 'lifetime',
      title: 'Навсегда',
      description: 'Одна оплата — вечный премиум',
      priceRubles: 4990,
      durationDays: null,
      badge: 'ХИТ',
      isPopular: true,
    ),
  ];
}

/// Статус платежа
enum PaymentStatus {
  pending('Ожидает оплаты'),
  waitingForCapture('Ожидает подтверждения'),
  succeeded('Оплачен'),
  canceled('Отменён');

  final String label;
  const PaymentStatus(this.label);
}

/// Результат платежа
class PaymentResult {
  final String paymentId;
  final PaymentStatus status;
  final int amount;
  final String? description;
  final DateTime? createdAt;
  final DateTime? capturedAt;
  final String? error;

  const PaymentResult({
    required this.paymentId,
    required this.status,
    required this.amount,
    this.description,
    this.createdAt,
    this.capturedAt,
    this.error,
  });

  bool get isSuccess => status == PaymentStatus.succeeded;
}

/// Сервис оплаты через YooKassa
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  static const _baseUrl = 'https://api.yookassa.ru/v3';
  final _uuid = const Uuid();
  final _subscriptionService = SubscriptionService();

  String get _shopId => dotenv.env['YOOKASSA_SHOP_ID'] ?? '';
  String get _secretKey => dotenv.env['YOOKASSA_SECRET_KEY'] ?? '';

  bool get isConfigured => _shopId.isNotEmpty && _secretKey.isNotEmpty;

  /// Создание платежа
  Future<PaymentResult?> createPayment({
    required PricingPlan plan,
    required String userEmail,
    required String returnUrl, // URL возврата в приложение
  }) async {
    if (!isConfigured) {
      AppLogger.error('PaymentService', 'YooKassa не настроена. Проверьте .env');
      return null;
    }

    try {
      final idempotenceKey = _uuid.v4();
      final body = {
        'amount': {
          'value': '${plan.priceRubles.toString()}.00',
          'currency': 'RUB',
        },
        'confirmation': {
          'type': 'redirect',
          'return_url': returnUrl,
        },
        'capture': true, // Автоматическое списание
        'description': 'Премиум-подписка MESTRO — ${plan.title} (${plan.durationLabel})',
        'metadata': {
          'plan_id': plan.id,
          'duration_days': plan.durationDays?.toString() ?? '0',
          'app_version': '1.2.0',
        },
        'receipt': {
          'customer': {
            'email': userEmail,
          },
          'items': [
            {
              'description': 'Премиум-подписка MESTRO — ${plan.title}',
              'quantity': '1.0',
              'amount': {
                'value': '${plan.priceRubles.toString()}.00',
                'currency': 'RUB',
              },
              'vat_code': '1', // Без НДС (для ИП на УСН)
              'payment_mode': 'full_payment',
              'payment_subject': 'service',
            },
          ],
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Idempotence-Key': idempotenceKey,
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentUrl = data['confirmation']['confirmation_url'] as String;

        AppLogger.info('PaymentService', 'Платёж создан: ${data['id']}, URL: $paymentUrl');

        return PaymentResult(
          paymentId: data['id'] as String,
          status: _parsePaymentStatus(data['status'] as String),
          amount: plan.priceRubles,
          description: data['description'] as String?,
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'] as String)
              : null,
        );
      } else {
        AppLogger.error('PaymentService', 'Ошибка создания платежа: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e, st) {
      AppLogger.error('PaymentService', 'Исключение при создании платежа: $e\n$st');
      return null;
    }
  }

  /// Проверка статуса платежа
  Future<PaymentResult?> checkPaymentStatus(String paymentId) async {
    if (!isConfigured) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$paymentId'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = PaymentResult(
          paymentId: data['id'] as String,
          status: _parsePaymentStatus(data['status'] as String),
          amount: int.parse((data['amount']['value'] as String).split('.')[0]),
          description: data['description'] as String?,
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'] as String)
              : null,
          capturedAt: data['captured_at'] != null
              ? DateTime.parse(data['captured_at'] as String)
              : null,
        );

        // Если платёж успешен — активируем премиум
        if (result.isSuccess) {
          final planId = (data['metadata']?['plan_id'] as String?) ?? '';
          final durationDays = int.tryParse(
            (data['metadata']?['duration_days'] as String?) ?? '0',
          );

          if (planId.isNotEmpty) {
            await _subscriptionService.activatePremium(
              durationDays: durationDays,
            );
            AppLogger.info('PaymentService', 'Премиум активирован после оплаты: $paymentId');
          }
        }

        return result;
      } else {
        return null;
      }
    } catch (e) {
      AppLogger.error('PaymentService', 'Ошибка проверки статуса: $e');
      return null;
    }
  }

  /// Получение URL для оплаты
  Future<String?> getPaymentUrl(String paymentId) async {
    final result = await checkPaymentStatus(paymentId);
    // URL уже был получен при создании платежа, но можно запросить заново
    return null;
  }

  PaymentStatus _parsePaymentStatus(String status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'waiting_for_capture':
        return PaymentStatus.waitingForCapture;
      case 'succeeded':
        return PaymentStatus.succeeded;
      case 'canceled':
        return PaymentStatus.canceled;
      default:
        return PaymentStatus.pending;
    }
  }

  /// Демо-активация (для тестирования без реальной оплаты)
  Future<bool> activateDemoPremium({int? durationDays}) async {
    return _subscriptionService.activatePremium(durationDays: durationDays);
  }

  /// Проверка: нужна ли оплата
  Future<bool> needsPayment() async {
    return !(await _subscriptionService.isPremiumActive());
  }
}
