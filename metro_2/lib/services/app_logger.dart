import 'package:flutter/foundation.dart';

/// Централизованный сервис логирования
/// Заменяет прямой вызов debugPrint, обеспечивает единообразный формат логов
class AppLogger {
  static const _prefix = '[MESTRO]';

  /// Информационное сообщение
  static void info(String tag, String message) {
    debugPrint('$_prefix [INFO] [$tag] $message');
  }

  /// Предупреждение
  static void warn(String tag, String message) {
    debugPrint('$_prefix [WARN] [$tag] $message');
  }

  /// Ошибка с необязательным стектрейсом
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('$_prefix [ERROR] [$tag] $message');
    if (error != null) {
      debugPrint('$_prefix [ERROR] [$tag] Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('$_prefix [ERROR] [$tag] StackTrace: $stackTrace');
    }
  }

  /// Отладочное сообщение (только в debug режиме)
  static void debug(String tag, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [DEBUG] [$tag] $message');
    }
  }

  /// Логирование успешного завершения операции
  static void success(String tag, String message) {
    debugPrint('$_prefix [OK] [$tag] $message');
  }
}
