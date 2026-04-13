import '../services/app_logger.dart';

/// Элемент прайс-листа — одна позиция расценки
class PriceItem {
  /// Уникальный ID позиции (например: frame_per_m2, socket, tile_per_m2)
  final String id;

  /// Название для отображения (например: "Рама за м²")
  final String name;

  /// Единица измерения (м², м.п., шт, компл.)
  final String unit;

  /// Цена за единицу
  final double price;

  /// Формула расчёта количества из полей чек-листа
  /// Поддерживаемые переменные: width, height, area, count, length
  /// Примеры: "(width/1000) * (height/1000)", "count", "length/1000"
  final String? formula;

  /// Нужно ли умножать на количество (true для типовых позиций)
  final bool multiplyByCount;

  const PriceItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    this.formula,
    this.multiplyByCount = false,
  });

  PriceItem copyWith({
    String? id,
    String? name,
    String? unit,
    double? price,
    String? formula,
    bool? multiplyByCount,
  }) {
    return PriceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      formula: formula ?? this.formula,
      multiplyByCount: multiplyByCount ?? this.multiplyByCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'price': price,
      'formula': formula,
      'multiply_by_count': multiplyByCount ? 1 : 0,
    };
  }

  factory PriceItem.fromMap(Map<String, dynamic> map) {
    // Поддерживаем оба варианта: 'item_id' (из БД) и 'id' (из JSON)
    final itemId = (map['item_id'] as String?) ?? (map['id'] as String?);
    final name = map['name'] as String?;
    final unit = map['unit'] as String?;
    final priceVal = map['price'];
    final formula = map['formula'] as String?;
    final multiplyRaw = map['multiply_by_count'];

    // Если обязательные поля отсутствуют — бросаем AssertionError для отлова
    if (itemId == null || itemId.isEmpty) {
      throw FormatException('PriceItem: missing item_id');
    }
    if (name == null || name.isEmpty) {
      throw FormatException('PriceItem: missing name for id=$itemId');
    }
    if (unit == null || unit.isEmpty) {
      throw FormatException('PriceItem: missing unit for id=$itemId');
    }
    if (priceVal == null) {
      throw FormatException('PriceItem: missing price for id=$itemId');
    }

    double price;
    if (priceVal is num) {
      price = priceVal.toDouble();
    } else if (priceVal is String) {
      price = double.tryParse(priceVal) ?? 0;
    } else {
      price = 0;
    }

    int multiplyByCount = 0;
    if (multiplyRaw is int) {
      multiplyByCount = multiplyRaw;
    } else if (multiplyRaw is num) {
      multiplyByCount = multiplyRaw.toInt();
    } else if (multiplyRaw is String) {
      multiplyByCount = int.tryParse(multiplyRaw) ?? 0;
    }

    return PriceItem(
      id: itemId,
      name: name,
      unit: unit,
      price: price,
      formula: (formula != null && formula.isNotEmpty) ? formula : null,
      multiplyByCount: multiplyByCount == 1,
    );
  }

  @override
  String toString() => '$name: $price ₽/$unit';
}
