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
    return PriceItem(
      id: map['item_id'] as String,
      name: map['name'] as String,
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
      formula: map['formula'] as String?,
      multiplyByCount: (map['multiply_by_count'] as int?) == 1,
    );
  }

  @override
  String toString() => '$name: $price ₽/$unit';
}
