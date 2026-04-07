import 'package:flutter_test/flutter_test.dart';
import 'package:metro_2/models/order.dart';
import 'package:metro_2/models/checklist_config.dart';
import 'package:metro_2/utils/cost_calculator.dart';

void main() {
  group('CostCalculator', () {
    late Order sampleOrder;
    late ChecklistConfig sampleConfig;

    setUp(() {
      // Сбрасываем цены к дефолтным перед каждым тестом
      CostCalculator.resetToDefaults();

      sampleConfig = ChecklistConfig(
        workType: 'windows',
        title: 'Тест',
        fields: [],
      );
    });

    group('Windows calculation', () {
      test('should calculate basic window cost', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.windows,
          checklistData: {
            'width': 1500.0, // 1.5м
            'height': 1400.0, // 1.4м
            'glass_type': 'single',
            'has_slopes': false,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // area = 1.5 * 1.4 = 2.1 м²
        // frame: 2.1 * 3500 = 7350
        // glass_single: 2.1 * 1500 = 3150
        // hardware: 2000
        // sill: 1.5 * 800 = 1200
        // installation: 2.1 * 2500 = 5250
        // Total: 7350 + 3150 + 2000 + 1200 + 5250 = 18950
        expect(cost, 18950.0);
      });

      test('should calculate window with slopes and double glass', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.windows,
          checklistData: {
            'width': 2000.0, // 2м
            'height': 1500.0, // 1.5м
            'glass_type': 'double',
            'has_slopes': true,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // area = 2 * 1.5 = 3 м²
        // frame: 3 * 3500 = 10500
        // glass_double: 3 * 2500 = 7500
        // hardware: 2000
        // sill: 2 * 800 = 1600
        // slopes: perimeter = 2*2 + 1.5 = 5.5м, 5.5 * 1200 = 6600
        // installation: 3 * 2500 = 7500
        // Total: 10500 + 7500 + 2000 + 1600 + 6600 + 7500 = 35700
        expect(cost, 35700.0);
      });
    });

    group('Doors calculation', () {
      test('should calculate basic door cost', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.doors,
          checklistData: {
            'has_lock': true,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // door_leaf: 8000
        // door_frame: 3000
        // door_lock: 2500
        // door_handle: 800
        // door_installation: 5000
        // Total: 19300
        expect(cost, 19300.0);
      });

      test('should calculate door without lock', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.doors,
          checklistData: {
            'has_lock': false,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // door_leaf: 8000
        // door_frame: 3000
        // door_handle: 800
        // door_installation: 5000
        // Total: 16800
        expect(cost, 16800.0);
      });
    });

    group('Air Conditioners calculation', () {
      test('should calculate basic AC installation', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.airConditioners,
          checklistData: {
            'install_type': 'basic',
            'pipe_length': 5.0,
            'drain_length': 3.0,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // ac_install_basic: 15000
        // ac_mount: 3000
        // copper_pipe: 5 * 800 = 4000
        // drain: 3 * 500 = 1500
        // Total: 23500
        expect(cost, 23500.0);
      });

      test('should calculate complex AC installation', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.airConditioners,
          checklistData: {
            'install_type': 'complex',
            'pipe_length': 10.0,
            'drain_length': 5.0,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // ac_install_complex: 25000
        // ac_mount: 3000
        // copper_pipe: 10 * 800 = 8000
        // drain: 5 * 500 = 2500
        // Total: 38500
        expect(cost, 38500.0);
      });
    });

    group('Kitchen calculation', () {
      test('should calculate kitchen cost with appliance install', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.kitchens,
          checklistData: {
            'kitchen_length': 3000.0, // 3м
            'has_appliance_install': true,
            'appliance_count': 3,
            'has_backsplash': true,
            'backsplash_length': 2000.0, // 2м
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // kitchen_lm: 3 * 15000 = 45000
        // countertop: 3 * 8000 = 24000
        // appliance_install: 3 * 3000 = 9000
        // backsplash: 2 * 0.6 * 2000 = 2400
        // Total: 80400
        expect(cost, 80400.0);
      });
    });

    group('Tiles calculation', () {
      test('should calculate floor tiling cost', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.tiles,
          checklistData: {
            'surface_type': 'Пол',
            'floor_length': 3000.0, // 3м
            'floor_width': 2000.0, // 2м
            'laying_method': 'Прямая',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // area = 3 * 2 = 6 м²
        // tile: 6 * 800 = 4800
        // tile_install_simple: 6 * 1200 = 7200
        // grout: 6 * 150 = 900
        // glue: 6 * 200 = 1200
        // Total: 14100
        expect(cost, 14100.0);
      });

      test('should calculate diagonal tiling with underfloor heating', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.tiles,
          checklistData: {
            'surface_type': 'Пол',
            'floor_length': 4000.0, // 4м
            'floor_width': 3000.0, // 3м
            'laying_method': 'Диагональная',
            'has_underfloor_heating': true,
            'heating_area': 10.0,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // area = 4 * 3 = 12 м²
        // tile: 12 * 800 = 9600
        // tile_install_diagonal: 12 * 1600 = 19200
        // grout: 12 * 150 = 1800
        // glue: 12 * 200 = 2400
        // warm_floor: 10 * 800 = 8000
        // Total: 41000
        expect(cost, 41000.0);
      });
    });

    group('Furniture calculation', () {
      test('should calculate MDF furniture cost with drawers', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.furniture,
          checklistData: {
            'body_material': 'МДФ',
            'wall_length': 3000.0, // 3м
            'ceiling_height': 2700.0, // 2.7м
            'has_drawers': true,
            'drawers_count': 4,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // area = 3 * 2.7 = 8.1 м²
        // mdf: 8.1 * 3500 = 28350
        // facade: 8.1 * 4000 = 32400
        // drawers: 4 * 1500 = 6000
        // assembly: 3 * 3000 = 9000
        // Total: 75750
        expect(cost, 75750.0);
      });
    });

    group('Engineering calculation', () {
      test('should calculate gas boiler cost', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.engineering,
          checklistData: {
            'system_type': 'Котельная',
            'boiler_type': 'Газовый',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // boiler_gas: 35000
        expect(cost, 35000.0);
      });

      test('should calculate radiator heating cost', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.engineering,
          checklistData: {
            'system_type': 'Отопление',
            'radiator_sections_count': 8,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // 8 * 5000 = 40000
        expect(cost, 40000.0);
      });
    });

    group('Electrical calculation', () {
      test('should calculate electrical cost with smart home', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.electrical,
          checklistData: {
            'sockets_count': 10,
            'lighting_count': 5,
            'wall_routes_length': 20.0,
            'floor_routes_length': 10.0,
            'ceiling_routes_length': 15.0,
            'has_smart_home': true,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // sockets: 10 * 400 = 4000
        // lighting: 5 * 800 = 4000
        // cable_routing: (20+10+15) * 300 = 13500
        // panel_assembly: 5000
        // smart_home: 3000
        // Total: 29500
        expect(cost, 29500.0);
      });
    });

    group('Edge cases', () {
      test('should handle empty checklist data', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.windows,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // area = 0, only hardware + sill(0) = 2000
        expect(cost, 2000.0);
      });

      test('should handle zero dimensions', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.windows,
          checklistData: {
            'width': 0,
            'height': 0,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // area = 0, only hardware = 2000
        expect(cost, 2000.0);
      });

      test('should return rounded value', () {
        final order = Order(
          id: '1',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.windows,
          checklistData: {
            'width': 1234.0,
            'height': 1567.0,
            'glass_type': 'single',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cost = CostCalculator.calculate(order, sampleConfig);

        // Проверяем что результат округлён (целое число)
        expect(cost, equals(cost.roundToDouble()));
      });
    });

    group('Price management', () {
      test('should update price for specific work type', () {
        const workType = 'windows';
        const itemId = 'frame_per_m2';
        const newPrice = 5000.0;

        CostCalculator.updatePrice(workType, itemId, newPrice);
        final price = CostCalculator.getPrice(workType, itemId);

        expect(price, newPrice);
      });

      test('should reset prices to defaults', () {
        CostCalculator.updatePrice('windows', 'frame_per_m2', 9999.0);
        CostCalculator.resetToDefaults();
        final price = CostCalculator.getPrice('windows', 'frame_per_m2');

        expect(price, 3500.0);
      });

      test('should return 0 for unknown price item', () {
        final price = CostCalculator.getPrice('windows', 'nonexistent_item');
        expect(price, 0);
      });
    });
  });
}
