import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Результат голосового распознавания
class VoiceInputResult {
  final String recognizedText;
  final bool isFinal;
  final double confidence;

  const VoiceInputResult({
    required this.recognizedText,
    this.isFinal = false,
    this.confidence = 0.0,
  });
}

/// Сервис голосового ввода для замеров
/// Распознаёт речь и извлекает структурированные данные
class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _currentText = '';

  // Callback для обновления UI в реальном времени
  Function(VoiceInputResult)? onResult;

  bool get isListening => _isListening;
  bool get isAvailable => _speech.isAvailable;
  String get currentText => _currentText;

  /// Инициализация сервиса
  Future<bool> initialize() async {
    final available = await _speech.initialize(
      onError: (error) {
        _isListening = false;
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
        }
      },
    );
    return available;
  }

  /// Запрос разрешения на запись микрофона
  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Начать распознавание речи
  Future<bool> startListening({String? localeId}) async {
    if (_isListening) return false;

    final hasPermission = await _requestMicPermission();
    if (!hasPermission) return false;

    if (!_speech.isAvailable) {
      final available = await initialize();
      if (!available) return false;
    }

    _currentText = '';

    final started = await _speech.listen(
      onResult: (result) {
        _currentText = result.recognizedWords;
        onResult?.call(
          VoiceInputResult(
            recognizedText: _currentText,
            isFinal: result.finalResult,
            confidence: result.confidence,
          ),
        );
      },
      localeId: localeId ?? 'ru_RU',
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
    );

    if (started) {
      _isListening = true;
    }
    return started;
  }

  /// Остановить распознавание
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  /// Отменить распознавание
  Future<void> cancelListening() async {
    await stopListening();
    _currentText = '';
  }

  /// Извлечь структурированные данные из распознанного текста
  VoiceExtractedData extractData(String text) {
    final data = VoiceExtractedData();
    final lowerText = text.toLowerCase();

    // ===== Размеры окон =====
    data.windowWidth = _extractDouble(lowerText, [
      r'ширин[аоы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*)?(?:ширин|ш)\b',
    ]);

    data.windowHeight = _extractDouble(lowerText, [
      r'высот[аоы]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*)?(?:высот|выс|в)\b',
    ]);

    // ===== Площадь помещения =====
    data.area = _extractDouble(lowerText, [
      r'площад[ьы]?[ьб]?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
      r'([0-9]+[,.]?[0-9]*)\s*(?:м\.?\s*)?(?:кв\.?\s*м|площад|площ)',
    ]);

    // ===== Количество окон =====
    data.windowCount = _extractInt(lowerText, [
      r'(?:количеств[оа]|сколько|штук|шт)\s*(?:окон?|створок?)\s*[:=]?\s*([0-9]+)',
      r'([0-9]+)\s*(?:окон?|окно|створок?)',
    ]);

    // ===== Тип окна =====
    if (lowerText.contains('одностворч') || lowerText.contains('одно створч')) {
      data.windowType = 'Одностворчатое';
    } else if (lowerText.contains('двустворч') ||
        lowerText.contains('двух створч') ||
        lowerText.contains('двухстворч')) {
      data.windowType = 'Двустворчатое';
    } else if (lowerText.contains('трёхстворч') ||
        lowerText.contains('трехстворч') ||
        lowerText.contains('трех створч') ||
        lowerText.contains('трёх створч')) {
      data.windowType = 'Трёхстворчатое';
    } else if (lowerText.contains('балкон') || lowerText.contains('лоджи')) {
      data.windowType = 'Балконный блок';
    }

    // ===== Тип подоконника =====
    if (lowerText.contains('подоконник') || lowerText.contains('подоконн')) {
      data.hasSill = true;
      data.sillWidth = _extractDouble(lowerText, [
        r'подоконник\s*(?:ширин[аоы]?)?\s*[:=]?\s*([0-9]+[,.]?[0-9]*)',
        r'([0-9]+[,.]?[0-9]*)\s*(?:см|мм|м)\s*(?:подоконник|подок)',
      ]);
    }

    // ===== Тип откосов =====
    if (lowerText.contains('откос') || lowerText.contains('откوس')) {
      data.hasSlopes = true;
    }

    // ===== Отлив =====
    if (lowerText.contains('отлив')) {
      data.hasSillOutside = true;
    }

    // ===== москитная сетка =====
    if (lowerText.contains('москитн') || lowerText.contains('сетк')) {
      data.hasMosquitoNet = true;
    }

    // ===== Дополнительные заметки =====
    data.notes = _extractNotes(text);

    return data;
  }

  /// Извлечь число (double) по паттернам
  double? _extractDouble(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final valueStr = match
            .group(1)!
            .replaceAll(',', '.')
            .replaceAll(' ', '');
        final value = double.tryParse(valueStr);
        if (value != null) return value;
      }
    }
    return null;
  }

  /// Извлечь целое число по паттернам
  int? _extractInt(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final valueStr = match.group(1)!.replaceAll(' ', '');
        final value = int.tryParse(valueStr);
        if (value != null) return value;
      }
    }
    return null;
  }

  /// Извлечь заметки (всё что не попало в поля)
  String _extractNotes(String text) {
    final lowerText = text.toLowerCase();
    final notes = <String>[];

    // Цвет профиля
    if (lowerText.contains('белый') || lowerText.contains('бел')) {
      notes.add('Цвет: белый');
    } else if (lowerText.contains('коричнев') ||
        lowerText.contains('ламинат')) {
      notes.add('Цвет: коричневый/ламинат');
    }

    // Тип стеклопакета
    if (lowerText.contains('однокамерн')) {
      notes.add('Стеклопакет: однокамерный');
    } else if (lowerText.contains('двухкамерн')) {
      notes.add('Стеклопакет: двухкамерный');
    } else if (lowerText.contains('энергосберегающ') ||
        lowerText.contains('энергетич')) {
      notes.add('Стеклопакет: энергосберегающий');
    }

    // Этажность / доступ
    if (lowerText.contains('этаж')) {
      final floorMatch = RegExp(
        r'этаж\s*[:=]?\s*([0-9]+)\s*(?:из|\/)\s*([0-9]+)',
        caseSensitive: false,
      ).firstMatch(lowerText);
      if (floorMatch != null) {
        notes.add('Этаж: ${floorMatch.group(1)}/${floorMatch.group(2)}');
      }
    }

    // Доступ
    if (lowerText.contains('ключ') || lowerText.contains('пропуск')) {
      notes.add('Нужен ключ/пропуск');
    }

    return notes.join('; ');
  }
}

/// Структурированные данные, извлечённые из голосового ввода
class VoiceExtractedData {
  double? windowWidth;
  double? windowHeight;
  double? area;
  int? windowCount;
  String? windowType;
  bool hasSill = false;
  double? sillWidth;
  bool hasSlopes = false;
  bool hasSillOutside = false;
  bool hasMosquitoNet = false;
  String? notes;

  /// Есть ли хоть какие-то данные
  bool get hasData =>
      windowWidth != null ||
      windowHeight != null ||
      area != null ||
      windowCount != null ||
      windowType != null ||
      notes != null;

  @override
  String toString() {
    final parts = <String>[];
    if (windowWidth != null) parts.add('Ширина: $windowWidth м');
    if (windowHeight != null) parts.add('Высота: $windowHeight м');
    if (area != null) parts.add('Площадь: $area м²');
    if (windowCount != null) parts.add('Окон: $windowCount');
    if (windowType != null) parts.add('Тип: $windowType');
    if (hasSill) parts.add('Подоконник: да');
    if (hasSlopes) parts.add('Откосы: да');
    if (hasSillOutside) parts.add('Отлив: да');
    if (hasMosquitoNet) parts.add('Москитная сетка: да');
    if (notes != null && notes!.isNotEmpty) parts.add('Заметки: $notes');
    return parts.join(', ');
  }
}
