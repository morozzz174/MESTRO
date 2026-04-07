import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Сервис локальных уведомлений (для мастера)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Инициализируем timezone
    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    // Запрос разрешений на Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  /// Отправить уведомление немедленно
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'mestro_channel',
      'MESTRO Уведомления',
      channelDescription: 'Уведомления о замерах',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Запланировать уведомление
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'mestro_scheduled_channel',
      'MESTRO Плановые уведомления',
      channelDescription: 'Напоминания о предстоящих замерах',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Отменить конкретное уведомление
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Отменить все уведомления
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

/// Шаблоны уведомлений
class NotificationTemplates {
  /// Напоминание мастеру за 1 час до замера
  static String masterReminder(String clientName, String address, String workType, String time) {
    return '⏰ Через 1 час: замер у "$clientName"\n'
        '📍 $address\n'
        '🔧 $workType в $time';
  }

  /// Напоминание мастеру за 30 минут
  static String masterSoonReminder(String clientName, String time) {
    return '🚗 Через 30 минут: замер у "$clientName" в $time';
  }

  /// Новое уведомление о созданном замере
  static String newAppointment(String clientName, String date) {
    return '📋 Новый замер: "$clientName" на $date';
  }
}
