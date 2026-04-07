import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../utils/cost_calculator.dart';

/// Экран выбора типа работ для редактирования прайса
class PriceListScreen extends StatelessWidget {
  const PriceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Прайс-листы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _resetAllPrices(context),
            tooltip: 'Сбросить все цены',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _priceCategories.length,
        itemBuilder: (context, index) {
          final category = _priceCategories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.color),
              ),
              title: Text(
                category.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${category.items} позиций'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PriceEditScreen(
                      workType: category.workType,
                      workTypeName: category.title,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _resetAllPrices(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить все цены?'),
        content: const Text(
          'Все цены будут возвращены к значениям по умолчанию. '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      CostCalculator.resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Все цены сброшены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

/// Экран редактирования цен для конкретного типа работ
class PriceEditScreen extends StatefulWidget {
  final String workType;
  final String workTypeName;

  const PriceEditScreen({
    super.key,
    required this.workType,
    required this.workTypeName,
  });

  @override
  State<PriceEditScreen> createState() => _PriceEditScreenState();
}

class _PriceEditScreenState extends State<PriceEditScreen> {
  late List<_PriceItemData> _items;
  final _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  void _loadPrices() {
    final prices = CostCalculator.getPricesForType(widget.workType);
    final itemNames = _getItemNames(widget.workType);

    _items = itemNames
        .where((item) => prices.containsKey(item.id))
        .map(
          (item) => _PriceItemData(
            id: item.id,
            name: item.name,
            unit: item.unit,
            price: prices[item.id] ?? 0,
            defaultPrice: item.defaultPrice,
          ),
        )
        .toList();
  }

  List<_PriceItemName> _getItemNames(String workType) {
    switch (workType) {
      case 'windows':
        return const [
          _PriceItemName('frame_per_m2', 'Рама (профиль)', 'м²', 3500),
          _PriceItemName(
            'glass_single',
            'Однокамерный стеклопакет',
            'м²',
            1500,
          ),
          _PriceItemName(
            'glass_double',
            'Двухкамерный стеклопакет',
            'м²',
            2500,
          ),
          _PriceItemName('hardware', 'Фурнитура', 'компл.', 2000),
          _PriceItemName('sill', 'Подоконник', 'м.п.', 800),
          _PriceItemName('slope', 'Откосы', 'м.п.', 1200),
          _PriceItemName('installation', 'Монтаж', 'м²', 2500),
        ];
      case 'doors':
        return const [
          _PriceItemName('door_leaf', 'Дверное полотно', 'шт', 8000),
          _PriceItemName('door_frame', 'Дверная коробка', 'шт', 3000),
          _PriceItemName('door_lock', 'Замок', 'шт', 2500),
          _PriceItemName('door_handle', 'Ручка', 'шт', 800),
          _PriceItemName('door_installation', 'Монтаж двери', 'шт', 5000),
        ];
      case 'air_conditioners':
        return const [
          _PriceItemName('ac_install_basic', 'Базовый монтаж', 'шт', 15000),
          _PriceItemName('ac_install_complex', 'Сложный монтаж', 'шт', 25000),
          _PriceItemName('ac_mount', 'Кронштейны', 'компл.', 3000),
          _PriceItemName('ac_copper_pipe', 'Медная труба', 'м.п.', 800),
          _PriceItemName('ac_drain', 'Дренаж', 'м.п.', 500),
        ];
      case 'kitchens':
        return const [
          _PriceItemName('kitchen_lm_meter', 'Кухня за п.м.', 'м.п.', 15000),
          _PriceItemName('kitchen_countertop', 'Столешница', 'м.п.', 8000),
          _PriceItemName(
            'kitchen_appliance_install',
            'Установка техники',
            'шт',
            3000,
          ),
          _PriceItemName('kitchen_sink', 'Мойка', 'шт', 5000),
          _PriceItemName('kitchen_backsplash', 'Фартук', 'м²', 2000),
        ];
      case 'tiles':
        return const [
          _PriceItemName('tile_per_m2', 'Плитка (материал)', 'м²', 800),
          _PriceItemName('tile_install_simple', 'Укладка простая', 'м²', 1200),
          _PriceItemName(
            'tile_install_diagonal',
            'Укладка диагональная',
            'м²',
            1600,
          ),
          _PriceItemName('tile_grout', 'Затирка', 'м²', 150),
          _PriceItemName('tile_glue', 'Клей', 'м²', 200),
          _PriceItemName('tile_warm_floor', 'Тёплый пол', 'м²', 800),
        ];
      case 'furniture':
        return const [
          _PriceItemName('ldsp_per_m2', 'Корпус ЛДСП', 'м²', 2500),
          _PriceItemName('mdf_per_m2', 'Корпус МДФ', 'м²', 3500),
          _PriceItemName('solid_per_m2', 'Корпус массив', 'м²', 6000),
          _PriceItemName('facade_per_m2', 'Фасады', 'м²', 4000),
          _PriceItemName('drawer_mechanism', 'Механизм выдвижной', 'шт', 1500),
          _PriceItemName('furniture_assembly', 'Сборка', 'м.п.', 3000),
        ];
      case 'engineering':
        return const [
          _PriceItemName('boiler_gas', 'Газовый котёл', 'шт', 35000),
          _PriceItemName('boiler_electric', 'Электрический котёл', 'шт', 20000),
          _PriceItemName('radiator_section', 'Секция радиатора', 'шт', 5000),
          _PriceItemName('pipe_pp_per_m', 'Труба ПП', 'м.п.', 200),
          _PriceItemName('pipe_pex_per_m', 'Труба PEX', 'м.п.', 350),
          _PriceItemName(
            'warm_floor_water_per_m2',
            'Водяной тёплый пол',
            'м²',
            1500,
          ),
          _PriceItemName(
            'warm_floor_electric_per_m2',
            'Электрический тёплый пол',
            'м²',
            2000,
          ),
          _PriceItemName(
            'sewage_pipe_per_m',
            'Канализационная труба',
            'м.п.',
            500,
          ),
          _PriceItemName(
            'ventilation_install',
            'Вентиляция (точка)',
            'точка',
            3000,
          ),
        ];
      case 'electrical':
        return const [
          _PriceItemName('cable_vvg_per_m', 'Кабель ВВГнг', 'м.п.', 80),
          _PriceItemName('cable_nym_per_m', 'Кабель NYM', 'м.п.', 100),
          _PriceItemName('socket', 'Розетка', 'шт', 400),
          _PriceItemName('switch', 'Выключатель', 'шт', 350),
          _PriceItemName('light_point', 'Точка освещения', 'шт', 800),
          _PriceItemName('panel_assembly', 'Сборка щитка', 'шт', 5000),
          _PriceItemName(
            'cable_routing_per_m',
            'Прокладка кабеля',
            'м.п.',
            300,
          ),
          _PriceItemName(
            'smart_home_point',
            'Точка умного дома',
            'точка',
            3000,
          ),
        ];
      default:
        return [];
    }
  }

  double get _totalEstimated {
    // Примерная сумма: берём все позиции как "1 единица"
    double total = 0;
    for (final item in _items) {
      total += item.price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workTypeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetPrices,
            tooltip: 'Сбросить цены',
          ),
        ],
      ),
      body: Column(
        children: [
          // Итого
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Базовая сумма (все позиции × 1)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(_totalEstimated),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          // Список позиций
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isModified = item.price != item.defaultPrice;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isModified ? Colors.amber.withOpacity(0.08) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (isModified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'изменено',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_currencyFormat.format(item.price)} / ${item.unit}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: '0',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            controller: TextEditingController(
                              text: item.price.toInt().toString(),
                            ),
                            onSubmitted: (value) {
                              final newPrice = double.tryParse(value);
                              if (newPrice != null && newPrice >= 0) {
                                setState(() {
                                  item.price = newPrice;
                                  CostCalculator.updatePrice(
                                    widget.workType,
                                    item.id,
                                    newPrice,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPrices() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить цены?'),
        content: Text(
          'Все цены для "${widget.workTypeName}" будут возвращены к значениям по умолчанию.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              _doReset();
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  void _doReset() {
    CostCalculator.resetToDefaults();
    setState(() => _loadPrices());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Цены сброшены'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _PriceItemData {
  final String id;
  final String name;
  final String unit;
  double price;
  final double defaultPrice;

  _PriceItemData({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.defaultPrice,
  });
}

class _PriceItemName {
  final String id;
  final String name;
  final String unit;
  final double defaultPrice;

  const _PriceItemName(this.id, this.name, this.unit, this.defaultPrice);
}

// ===== Категории для главного экрана =====

class _PriceCategory {
  final String workType;
  final String title;
  final IconData icon;
  final Color color;
  final int items;

  const _PriceCategory({
    required this.workType,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

final _priceCategories = [
  _PriceCategory(
    workType: 'windows',
    title: 'Окна',
    icon: Icons.window,
    color: Colors.blue,
    items: 7,
  ),
  _PriceCategory(
    workType: 'doors',
    title: 'Двери',
    icon: Icons.door_front_door,
    color: Colors.brown,
    items: 5,
  ),
  _PriceCategory(
    workType: 'air_conditioners',
    title: 'Кондиционеры',
    icon: Icons.ac_unit,
    color: Colors.cyan,
    items: 5,
  ),
  _PriceCategory(
    workType: 'kitchens',
    title: 'Кухни',
    icon: Icons.kitchen,
    color: Colors.orange,
    items: 5,
  ),
  _PriceCategory(
    workType: 'tiles',
    title: 'Плиточные работы',
    icon: Icons.grid_on,
    color: Colors.teal,
    items: 6,
  ),
  _PriceCategory(
    workType: 'furniture',
    title: 'Мебельные блоки',
    icon: Icons.chair,
    color: Colors.deepPurple,
    items: 6,
  ),
  _PriceCategory(
    workType: 'engineering',
    title: 'Инженерные системы',
    icon: Icons.plumbing,
    color: Colors.red,
    items: 9,
  ),
  _PriceCategory(
    workType: 'electrical',
    title: 'Электрика',
    icon: Icons.electrical_services,
    color: Colors.amber,
    items: 8,
  ),
];
