import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/price_item.dart';

/// Сервис управления прайс-листами
/// Загружает дефолтные цены из assets, позволяет сохранять кастомные
class PriceListService {
  static final PriceListService _instance = PriceListService._internal();
  factory PriceListService() => _instance;
  PriceListService._internal();

  /// Кэш загруженных прайсов: work_type -> List<PriceItem>
  final Map<String, List<PriceItem>> _cache = {};

  /// Загрузить прайс для типа работ
  Future<List<PriceItem>> getPriceList(String workType) async {
    // Проверяем кэш
    if (_cache.containsKey(workType)) {
      return _cache[workType]!;
    }

    // Загружаем дефолтный прайс из assets
    final items = await _loadDefaultPrices(workType);

    // Кэшируем
    _cache[workType] = items;

    return items;
  }

  /// Обновить цену в прайсе
  Future<void> updatePrice(String workType, String itemId, double newPrice) async {
    final items = await getPriceList(workType);
    final index = items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _cache[workType]![index] = items[index].copyWith(price: newPrice);
    }
  }

  /// Обновить весь прайс-лист
  Future<void> updatePriceList(String workType, List<PriceItem> items) async {
    _cache[workType] = items;
  }

  /// Сбросить прайс к дефолтному
  Future<void> resetToDefault(String workType) async {
    _cache.remove(workType);
    await getPriceList(workType);
  }

  /// Получить цену по ID позиции
  Future<double> getPrice(String workType, String itemId) async {
    final items = await getPriceList(workType);
    final item = items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => PriceItem(id: '', name: '', unit: '', price: 0),
    );
    return item.price;
  }

  /// Загрузить дефолтные цены из JSON-файлов
  Future<List<PriceItem>> _loadDefaultPrices(String workType) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/prices/${workType}_price.json',
      );
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final List<dynamic> itemsJson = json['items'] as List;
      return itemsJson
          .map((itemJson) => PriceItem.fromMap(itemJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Если файл не найден — возвращаем пустой список
      return [];
    }
  }

  /// Рассчитать стоимость по прайс-листу и данным чек-листа
  static double calculate(
    List<PriceItem> priceItems,
    Map<String, dynamic> checklistData,
  ) {
    double total = 0;

    for (final item in priceItems) {
      final quantity = _calculateQuantity(item, checklistData);
      total += quantity * item.price;
    }

    return total.roundToDouble();
  }

  /// Рассчитать количество для позиции прайса
  static double _calculateQuantity(
    PriceItem item,
    Map<String, dynamic> data,
  ) {
    // Если есть формула — вычисляем
    if (item.formula != null && item.formula!.isNotEmpty) {
      return _evaluateFormula(item.formula!, data);
    }

    // Иначе ищем поле с таким же ID в данных
    final value = data[item.id];
    if (value is num) {
      return value.toDouble();
    }

    // Пробуем распарсить как boolean (включено/выключено)
    if (value is bool) {
      return value ? 1.0 : 0.0;
    }

    // Строковое значение — считаем как 1 (фиксированная услуга)
    if (value is String && value.isNotEmpty) {
      return 1.0;
    }

    return 0;
  }

  /// Вычислить значение формулы
  /// Поддерживаемые операции: +, -, *, /, (), и переменные из data
  static double _evaluateFormula(String formula, Map<String, dynamic> data) {
    String expr = formula;

    // Заменяем переменные на значения
    // Порядок: сначала длинные имена (чтобы wall_height не совпало с height)
    final keys = data.keys.toList()..sort((a, b) => b.length.compareTo(a.length));

    for (final key in keys) {
      final value = data[key];
      double numValue;
      if (value is num) {
        numValue = value.toDouble();
      } else if (value is bool) {
        numValue = value ? 1.0 : 0.0;
      } else {
        continue;
      }
      // Заменяем все вхождения ключа
      expr = expr.replaceAll(key, numValue.toString());
    }

    // Вычисляем математическое выражение
    try {
      return _safeEval(expr);
    } catch (e) {
      return 0;
    }
  }

  /// Безопасное вычисление математического выражения
  /// Поддерживает: числа, +, -, *, /, (), унарный минус
  static double _safeEval(String expr) {
    // Убираем пробелы
    expr = expr.replaceAll(' ', '');

    // Парсим и вычисляем
    return _ExpressionParser(expr).evaluate();
  }
}

/// Простой парсер математических выражений
class _ExpressionParser {
  final String _expr;
  int _pos = 0;

  _ExpressionParser(this._expr);

  double evaluate() {
    final result = _parseExpression();
    return result;
  }

  double _parseExpression() {
    double result = _parseTerm();
    while (_pos < _expr.length) {
      if (_expr[_pos] == '+') {
        _pos++;
        result += _parseTerm();
      } else if (_expr[_pos] == '-') {
        _pos++;
        result -= _parseTerm();
      } else {
        break;
      }
    }
    return result;
  }

  double _parseTerm() {
    double result = _parseFactor();
    while (_pos < _expr.length) {
      if (_expr[_pos] == '*') {
        _pos++;
        result *= _parseFactor();
      } else if (_expr[_pos] == '/') {
        _pos++;
        final divisor = _parseFactor();
        if (divisor != 0) {
          result /= divisor;
        }
      } else {
        break;
      }
    }
    return result;
  }

  double _parseFactor() {
    if (_pos >= _expr.length) return 0;

    // Унарный минус
    if (_expr[_pos] == '-') {
      _pos++;
      return -_parseFactor();
    }

    // Скобки
    if (_expr[_pos] == '(') {
      _pos++; // пропускаем '('
      final result = _parseExpression();
      if (_pos < _expr.length && _expr[_pos] == ')') {
        _pos++; // пропускаем ')'
      }
      return result;
    }

    // Число
    return _parseNumber();
  }

  double _parseNumber() {
    final start = _pos;
    while (_pos < _expr.length &&
        (_expr[_pos].contains(RegExp(r'[0-9.]')))) {
      _pos++;
    }
    final numStr = _expr.substring(start, _pos);
    return double.tryParse(numStr) ?? 0;
  }
}
