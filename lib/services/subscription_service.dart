import '../database/database_helper.dart';
import '../models/user.dart';

/// Сервис управления премиум-подпиской
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// Текущий пользователь (кэширован)
  User? _currentUser;

  /// Получить текущего пользователя
  Future<User?> getCurrentUser() async {
    _currentUser ??= await DatabaseHelper().getCurrentUser();
    return _currentUser;
  }

  /// Проверить: активна ли премиум-подписка
  Future<bool> isPremiumActive() async {
    final user = await getCurrentUser();
    return user?.isPremiumActive ?? false;
  }

  /// Активировать премиум-подписку
  /// [durationDays] — длительность в днях (null = бессрочно)
  Future<bool> activatePremium({int? durationDays}) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    final now = DateTime.now();
    DateTime? premiumUntil;
    if (durationDays != null) {
      premiumUntil = now.add(Duration(days: durationDays));
    }

    final updated = user.copyWith(
      isPremium: true,
      premiumUntil: premiumUntil,
      premiumActivatedAt: now,
      updatedAt: now,
    );

    await DatabaseHelper().updateUser(updated);
    _currentUser = updated;
    return true;
  }

  /// Деактивировать премиум-подписку
  Future<bool> deactivatePremium() async {
    final user = await getCurrentUser();
    if (user == null) return false;

    final updated = user.copyWith(
      isPremium: false,
      premiumUntil: null,
      premiumActivatedAt: null,
      updatedAt: DateTime.now(),
    );

    await DatabaseHelper().updateUser(updated);
    _currentUser = updated;
    return true;
  }

  /// Получить информацию о подписке в виде карты
  Future<Map<String, dynamic>> getSubscriptionInfo() async {
    final user = await getCurrentUser();
    if (user == null) {
      return {'isActive': false, 'message': 'Пользователь не найден'};
    }

    final isActive = user.isPremiumActive;
    String message;
    String? untilStr;

    if (!isActive) {
      message = 'Премиум не активен';
    } else if (user.premiumUntil == null) {
      message = 'Премиум активирован бессрочно';
    } else {
      final daysLeft = user.premiumUntil!.difference(DateTime.now()).inDays;
      if (daysLeft > 0) {
        message = 'Премиум активен ещё $daysLeft дней';
        untilStr = user.premiumUntil!.toLocal().toString().split(' ')[0];
      } else {
        message = 'Срок премиум-подписки истёк';
      }
    }

    return {
      'isActive': isActive,
      'isPremium': user.isPremium,
      'activatedAt': user.premiumActivatedAt?.toLocal().toString().split(' ')[0],
      'until': untilStr,
      'message': message,
    };
  }

  /// Сбросить кэш (при выходе из аккаунта)
  void resetCache() {
    _currentUser = null;
  }
}
