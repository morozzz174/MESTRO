import '../../../database/database_helper.dart';
import '../../../models/order.dart';
import '../services/notification_service.dart';
import '../../../services/sms_gateways/sms_gateway_provider.dart';

/// Сервис планирования и отправки уведомлений
class AppointmentNotificationScheduler {
  final NotificationService _notificationService = NotificationService();
  final SmsGatewayProvider? _smsGateway;

  AppointmentNotificationScheduler({SmsGatewayProvider? smsGateway})
      : _smsGateway = smsGateway;

  /// Планировать все уведомления при создании/изменении замера
  Future<void> scheduleForAppointment(Order order) async {
    if (order.appointmentDate == null) return;

    final apptDate = order.appointmentDate!;
    final now = DateTime.now();

    // === Уведомления МАСТЕРУ (локальные) ===

    // За 1 час до замера
    final oneHourBefore = apptDate.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _notificationService.schedule(
        id: _generateId(order, 'master_1h'),
        title: '⏰ Напоминание о замере',
        body: NotificationTemplates.masterReminder(
          order.clientName,
          order.address,
          order.workType.title,
          _formatTime(apptDate),
        ),
        scheduledDate: oneHourBefore,
        payload: 'order:${order.id}',
      );

      // Сохраняем в БД
      await _saveNotification(order, 'master_1h', oneHourBefore,
          NotificationTemplates.masterReminder(
            order.clientName,
            order.address,
            order.workType.title,
            _formatTime(apptDate),
          ),
          'local');
    }

    // За 30 минут до замера
    final thirtyMinBefore = apptDate.subtract(const Duration(minutes: 30));
    if (thirtyMinBefore.isAfter(now)) {
      await _notificationService.schedule(
        id: _generateId(order, 'master_30m'),
        title: '🚗 Скоро замер',
        body: NotificationTemplates.masterSoonReminder(
          order.clientName,
          _formatTime(apptDate),
        ),
        scheduledDate: thirtyMinBefore,
        payload: 'order:${order.id}',
      );

      await _saveNotification(order, 'master_30m', thirtyMinBefore,
          NotificationTemplates.masterSoonReminder(
            order.clientName,
            _formatTime(apptDate),
          ),
          'local');
    }

    // === Уведомления КЛИЕНТУ (SMS) ===
    if (order.clientPhone == null || _smsGateway == null) return;

    // За 24 часа до замера
    final twentyFourHBefore = apptDate.subtract(const Duration(hours: 24));
    if (twentyFourHBefore.isAfter(now)) {
      await _sendClientSMS(
        order: order,
        message: _buildClientSMS24h(order, apptDate),
        templateId: 'client_24h',
        scheduledAt: twentyFourHBefore,
      );
    }

    // За 2 часа до замера
    final twoHBefore = apptDate.subtract(const Duration(hours: 2));
    if (twoHBefore.isAfter(now)) {
      await _sendClientSMS(
        order: order,
        message: _buildClientSMS2h(order, apptDate),
        templateId: 'client_2h',
        scheduledAt: twoHBefore,
      );
    }
  }

  /// Отправить SMS клиенту (немедленно или запланировать)
  Future<void> _sendClientSMS({
    required Order order,
    required String message,
    required String templateId,
    required DateTime scheduledAt,
  }) async {
    final phone = order.clientPhone;
    if (phone == null || _smsGateway == null) return;

    // Сохраняем в БД
    await _saveNotification(order, templateId, scheduledAt, message, 'sms');

    // Если время уже — отправить немедленно
    if (scheduledAt.isBefore(DateTime.now()) ||
        scheduledAt.difference(DateTime.now()).inMinutes < 5) {
      final result = await _smsGateway!.sendSMS(
        phone: phone,
        message: message,
      );

      await DatabaseHelper().updateNotificationStatus(
        _buildNotifId(order.id, templateId),
        result.success ? 'sent' : 'failed',
        sentAt: DateTime.now(),
      );
    }
    // Иначе — планировщик обработает позже
  }

  String _buildClientSMS24h(Order order, DateTime apptDate) {
    return 'Здравствуйте! Напоминаем, что завтра ${_formatDate(apptDate)} '
        'в ${_formatTime(apptDate)} запланирован замер (${order.workType.title}). '
        'Мастер: ${order.clientName}. Тел: свяжемся с вами.';
  }

  String _buildClientSMS2h(Order order, DateTime apptDate) {
    return 'Замер через 2 часа в ${_formatTime(apptDate)}. '
        'Мастер уже в пути! Адрес: ${order.address}';
  }

  Future<void> _saveNotification(
    Order order,
    String templateId,
    DateTime scheduledAt,
    String message,
    String type,
  ) async {
    await DatabaseHelper().insertNotification({
      'id': _buildNotifId(order.id, templateId),
      'order_id': order.id,
      'template_id': templateId,
      'recipient_phone': order.clientPhone,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': 'pending',
      'message': message,
      'type': type,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  String _buildNotifId(String orderId, String templateId) {
    return '${orderId}_$templateId';
  }

  int _generateId(Order order, String suffix) {
    // Генерируем числовой ID из UUID
    final hash = (order.id + suffix).hashCode.abs();
    return (hash % 100000) + 10000; // 5-значное число
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
