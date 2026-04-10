import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/price_item.dart';
import '../database/database_helper.dart';
import 'app_logger.dart';

/// Сервис управления прайс-листами
/// Загружает дефолтные цены из assets, позволяет сохранять кастомные в БД
class PriceListService {
  static final PriceListService _instance = PriceListService._internal();
  factory PriceListService() => _instance;
  PriceListService._internal();

  /// Кэш загруженных прайсов: work_type -> List<PriceItem>
  final Map<String, List<PriceItem>> _cache = {};
  final Uuid _uuid = const Uuid();

  /// Загрузить прайс для типа работ
  Future<List<PriceItem>> getPriceList(String workType) async {
    // Проверяем кэш
    if (_cache.containsKey(workType)) {
      AppLogger.debug(
        'PriceListService',
        'Кэш для $workType: ${_cache[workType]!.length} позиций',
      );
      return _cache[workType]!;
    }

    // Пробуем загрузить из БД
    final dbItems = await _loadFromDatabase(workType);

    if (dbItems.isNotEmpty) {
      AppLogger.success(
        'PriceListService',
        'Возвращаем из БД: ${dbItems.length} позиций для $workType',
      );
      _cache[workType] = dbItems;
      return dbItems;
    }

    // Загружаем дефолтный прайс из assets
    AppLogger.info(
      'PriceListService',
      'БД пуста для $workType, загружаем из assets',
    );
    final items = await _loadDefaultPrices(workType);

    if (items.isNotEmpty) {
      // Сохраняем в БД
      await _saveToDatabase(workType, items);
    }

    // Кэшируем
    _cache[workType] = items;

    return items;
  }

  /// Загрузить цены из БД
  Future<List<PriceItem>> _loadFromDatabase(String workType) async {
    try {
      final db = DatabaseHelper();
      final maps = await db.getPricesForWorkType(workType);

      if (maps.isEmpty) return [];

      AppLogger.info(
        'PriceListService',
        'Загружено ${maps.length} записей из БД для $workType',
      );

      final items = <PriceItem>[];
      for (final map in maps) {
        try {
          items.add(PriceItem.fromMap(map));
        } catch (e) {
          AppLogger.warn(
            'PriceListService',
            'Пропуск записи для $workType: $e. Данные: $map',
          );
        }
      }

      return items;
    } catch (e, st) {
      AppLogger.error(
        'PriceListService',
        'Ошибка загрузки из БД: $workType',
        e,
        st,
      );
      return [];
    }
  }

  /// Сохранить цены в БД
  Future<void> _saveToDatabase(String workType, List<PriceItem> items) async {
    try {
      final db = DatabaseHelper();
      final now = DateTime.now().toIso8601String();

      for (final item in items) {
        await db.upsertPriceItem({
          'id': item.id,
          'work_type': workType,
          'item_id': item.id,
          'name': item.name,
          'unit': item.unit,
          'price': item.price,
          'formula': item.formula,
          'multiply_by_count': item.multiplyByCount ? 1 : 0,
          'is_custom': 0,
          'created_at': now,
          'updated_at': now,
        });
      }
    } catch (e, st) {
      AppLogger.error(
        'PriceListService',
        'Ошибка сохранения в БД: $workType',
        e,
        st,
      );
    }
  }

  /// Обновить цену в прайсе
  Future<void> updatePrice(
    String workType,
    String itemId,
    double newPrice,
  ) async {
    final items = await getPriceList(workType);
    final index = items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _cache[workType]![index] = items[index].copyWith(price: newPrice);

      // Обновляем в БД
      try {
        final db = DatabaseHelper();
        await db.updatePriceItem(itemId, newPrice);
      } catch (e, st) {
        AppLogger.error(
          'PriceListService',
          'Ошибка обновления цены: $itemId',
          e,
          st,
        );
      }
    }
  }

  /// Обновить весь прайс-лист
  Future<void> updatePriceList(String workType, List<PriceItem> items) async {
    _cache[workType] = items;

    // Обновляем в БД
    try {
      final db = DatabaseHelper();
      await db.deleteAllPricesForWorkType(workType);
      await _saveToDatabase(workType, items);
    } catch (e, st) {
      AppLogger.error(
        'PriceListService',
        'Ошибка сохранения прайс-листа: $workType',
        e,
        st,
      );
    }
  }

  /// Добавить новую позицию в прайс
  Future<PriceItem> addPriceItem(String workType, PriceItem newItem) async {
    final items = await getPriceList(workType);
    items.add(newItem);
    _cache[workType] = items;

    // Сохраняем в БД
    try {
      final db = DatabaseHelper();
      final now = DateTime.now().toIso8601String();
      await db.upsertPriceItem({
        'id': newItem.id,
        'work_type': workType,
        'item_id': newItem.id,
        'name': newItem.name,
        'unit': newItem.unit,
        'price': newItem.price,
        'formula': newItem.formula,
        'multiply_by_count': newItem.multiplyByCount ? 1 : 0,
        'is_custom': 1,
        'created_at': now,
        'updated_at': now,
      });
      AppLogger.info('PriceListService', 'Добавлена позиция: ${newItem.name}');
    } catch (e, st) {
      AppLogger.error('PriceListService', 'Ошибка добавления позиции', e, st);
    }

    return newItem;
  }

  /// Удалить позицию из прайса
  Future<void> deletePriceItem(String workType, String itemId) async {
    final items = await getPriceList(workType);
    items.removeWhere((item) => item.id == itemId);
    _cache[workType] = items;

    // Удаляем из БД
    try {
      final db = DatabaseHelper();
      await db.deletePriceItem(itemId);
      AppLogger.info('PriceListService', 'Удалена позиция: $itemId');
    } catch (e, st) {
      AppLogger.error('PriceListService', 'Ошибка удаления позиции', e, st);
    }
  }

  /// Сбросить прайс к дефолтному
  Future<void> resetToDefault(String workType) async {
    _cache.remove(workType);

    // Удаляем из БД пользовательские цены
    try {
      final db = DatabaseHelper();
      await db.deleteAllPricesForWorkType(workType);
      AppLogger.info('PriceListService', 'Прайс сброшен: $workType');
    } catch (e, st) {
      AppLogger.error('PriceListService', 'Ошибка сброса прайса', e, st);
    }

    // Перезагружаем дефолтные
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

  /// Сгенерировать уникальный ID для новой позиции
  String generateItemId(String baseName) {
    return '${baseName.toLowerCase().replaceAll(' ', '_')}_${_uuid.v4().substring(0, 8)}';
  }

  /// Загрузить дефолтные цены из JSON-файлов
  Future<List<PriceItem>> _loadDefaultPrices(String workType) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/prices/${workType}_price.json',
      );
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final List<dynamic> itemsJson = json['items'] as List;
      AppLogger.info(
        'PriceListService',
        'Загружено ${itemsJson.length} позиций из JSON для $workType',
      );

      final items = <PriceItem>[];
      for (final itemJson in itemsJson) {
        try {
          items.add(PriceItem.fromMap(itemJson as Map<String, dynamic>));
        } catch (e) {
          AppLogger.warn(
            'PriceListService',
            'Пропуск позиции из JSON для $workType: $e',
          );
        }
      }

      AppLogger.success(
        'PriceListService',
        'Распарсено ${items.length}/${itemsJson.length} позиций для $workType',
      );
      return items;
    } catch (e, st) {
      AppLogger.error(
        'PriceListService',
        'Ошибка загрузки JSON для $workType',
        e,
        st,
      );
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
  static double _calculateQuantity(PriceItem item, Map<String, dynamic> data) {
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
    final keys = data.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

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
    while (_pos < _expr.length && (_expr[_pos].contains(RegExp(r'[0-9.]')))) {
      _pos++;
    }
    final numStr = _expr.substring(start, _pos);
    return double.tryParse(numStr) ?? 0;
  }
}
