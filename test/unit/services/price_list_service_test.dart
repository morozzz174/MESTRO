import 'package:flutter_test/flutter_test.dart';
import 'package:metro_2/models/price_item.dart';
import 'package:metro_2/services/price_list_service.dart';

void main() {
  group('PriceListService', () {
    group('calculate', () {
      test('should calculate total from fixed prices', () {
        final items = [
          PriceItem(id: 'hardware', name: 'Фурнитура', unit: 'шт', price: 2000),
          PriceItem(id: 'sill', name: 'Подоконник', unit: 'м.п.', price: 800),
        ];
        final data = {
          'hardware': 1,
          'sill': 2,
        };

        final total = PriceListService.calculate(items, data);

        // 2000*1 + 800*2 = 3600
        expect(total, 3600.0);
      });

      test('should calculate using formula', () {
        final items = [
          PriceItem(
            id: 'frame',
            name: 'Рама',
            unit: 'м²',
            price: 3500,
            formula: '(width / 1000) * (height / 1000)',
          ),
        ];
        final data = {
          'width': 1500.0,
          'height': 1400.0,
        };

        final total = PriceListService.calculate(items, data);

        // area = 1.5 * 1.4 = 2.1, 2.1 * 3500 = 7350
        expect(total, 7350.0);
      });

      test('should handle boolean values in formula', () {
        final items = [
          PriceItem(
            id: 'slopes',
            name: 'Откосы',
            unit: 'м.п.',
            price: 1200,
            formula: 'has_slopes * (2 * (width / 1000) + (height / 1000))',
          ),
        ];
        final data = {
          'has_slopes': true,
          'width': 2000.0,
          'height': 1500.0,
        };

        final total = PriceListService.calculate(items, data);

        // perimeter = 2*2 + 1.5 = 5.5, 5.5 * 1200 = 6600
        expect(total, 6600.0);
      });

      test('should handle boolean false in formula', () {
        final items = [
          PriceItem(
            id: 'slopes',
            name: 'Откосы',
            unit: 'м.п.',
            price: 1200,
            formula: 'has_slopes * (2 * (width / 1000) + (height / 1000))',
          ),
        ];
        final data = {
          'has_slopes': false,
          'width': 2000.0,
          'height': 1500.0,
        };

        final total = PriceListService.calculate(items, data);

        // has_slopes = 0, total = 0
        expect(total, 0.0);
      });

      test('should handle complex multi-item calculation', () {
        final items = [
          PriceItem(
            id: 'frame',
            name: 'Рама',
            unit: 'м²',
            price: 3500,
            formula: '(width / 1000) * (height / 1000)',
          ),
          PriceItem(
            id: 'glass',
            name: 'Стеклопакет',
            unit: 'м²',
            price: 1500,
            formula: '(width / 1000) * (height / 1000)',
          ),
          PriceItem(id: 'hardware', name: 'Фурнитура', unit: 'шт', price: 2000),
          PriceItem(
            id: 'sill',
            name: 'Подоконник',
            unit: 'м.п.',
            price: 800,
            formula: 'width / 1000',
          ),
        ];
        final data = {
          'width': 1500.0,
          'height': 1400.0,
          'hardware': 1, // фурнитура без формулы — берём количество из данных
        };

        final total = PriceListService.calculate(items, data);

        // frame: 2.1 * 3500 = 7350
        // glass: 2.1 * 1500 = 3150
        // hardware: 1 * 2000 = 2000
        // sill: 1.5 * 800 = 1200
        // Total: 13700
        expect(total, 13700.0);
      });

      test('should return 0 for missing data', () {
        final items = [
          PriceItem(
            id: 'frame',
            name: 'Рама',
            unit: 'м²',
            price: 3500,
            formula: '(width / 1000) * (height / 1000)',
          ),
        ];
        final data = <String, dynamic>{};

        final total = PriceListService.calculate(items, data);

        // width/height = 0, total = 0
        expect(total, 0.0);
      });

      test('should round result to integer', () {
        final items = [
          PriceItem(
            id: 'item',
            name: 'Тест',
            unit: 'шт',
            price: 100.5,
            formula: 'count',
          ),
        ];
        final data = {'count': 3};

        final total = PriceListService.calculate(items, data);

        // 100.5 * 3 = 301.5 -> rounds to 302 (or 301 depending on rounding)
        expect(total, equals(total.roundToDouble()));
      });
    });

    group('Formula parser', () {
      test('should evaluate simple addition', () {
        // Тестируем через calculate с формулой
        final items = [
          PriceItem(id: 'test', name: 'Тест', unit: '', price: 1, formula: '2 + 3'),
        ];

        final result = PriceListService.calculate(items, {});
        expect(result, 5.0);
      });

      test('should evaluate multiplication', () {
        final items = [
          PriceItem(id: 'test', name: 'Тест', unit: '', price: 1, formula: '4 * 5'),
        ];

        final result = PriceListService.calculate(items, {});
        expect(result, 20.0);
      });

      test('should evaluate expression with parentheses', () {
        final items = [
          PriceItem(
            id: 'test',
            name: 'Тест',
            unit: '',
            price: 1,
            formula: '(2 + 3) * 4',
          ),
        ];

        final result = PriceListService.calculate(items, {});
        expect(result, 20.0);
      });

      test('should handle division by zero gracefully', () {
        final items = [
          PriceItem(id: 'test', name: 'Тест', unit: '', price: 1, formula: '5 / 0'),
        ];

        // Не должно выбрасывать исключение
        final result = PriceListService.calculate(items, {});
        expect(result, isA<double>());
      });

      test('should handle nested parentheses', () {
        final items = [
          PriceItem(
            id: 'test',
            name: 'Тест',
            unit: '',
            price: 1,
            formula: '((2 + 3) * (4 - 1)) / 3',
          ),
        ];

        final result = PriceListService.calculate(items, {});
        // (5 * 3) / 3 = 5
        expect(result, 5.0);
      });

      test('should handle unary minus', () {
        final items = [
          PriceItem(id: 'test', name: 'Тест', unit: '', price: 1, formula: '-5 + 10'),
        ];

        final result = PriceListService.calculate(items, {});
        expect(result, 5.0);
      });

      test('should handle decimal numbers', () {
        final items = [
          PriceItem(
            id: 'test',
            name: 'Тест',
            unit: '',
            price: 1,
            formula: '2.5 * 3.2',
          ),
        ];

        final result = PriceListService.calculate(items, {});
        expect(result, 8.0);
      });

      test('should handle mixed operations with precedence', () {
        final items = [
          PriceItem(
            id: 'test',
            name: 'Тест',
            unit: '',
            price: 1,
            formula: '2 + 3 * 4 - 6 / 2',
          ),
        ];

        final result = PriceListService.calculate(items, {});
        // 2 + 12 - 3 = 11
        expect(result, 11.0);
      });
    });

    group('Edge cases', () {
      test('should handle empty price list', () {
        final items = <PriceItem>[];
        final data = {'width': 1000};

        final total = PriceListService.calculate(items, data);
        expect(total, 0.0);
      });

      test('should handle string values as quantity 1', () {
        final items = [
          PriceItem(id: 'service', name: 'Услуга', unit: 'шт', price: 5000),
        ];
        final data = {'service': 'some_value'};

        final total = PriceListService.calculate(items, data);
        expect(total, 5000.0);
      });

      test('should handle empty string as quantity 0', () {
        final items = [
          PriceItem(id: 'item', name: 'Предмет', unit: 'шт', price: 100),
        ];
        final data = {'item': ''};

        final total = PriceListService.calculate(items, data);
        expect(total, 0.0);
      });
    });
  });
}
