import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/price_item.dart';
import '../../../../services/price_list_service.dart';
import '../../../../utils/cost_calculator.dart';
import '../../../../services/app_logger.dart';
import '../../../../services/price_list_excel_service.dart';
import '../../../../services/subscription_service.dart';

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
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportToExcel(context),
            tooltip: 'Экспорт в Excel',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => _importFromExcel(context),
            tooltip: 'Импорт из Excel',
          ),
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
      final service = PriceListService();
      for (final category in _priceCategories) {
        await service.resetToDefault(category.workType);
      }
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

  Future<void> _exportToExcel(BuildContext context) async {
    // Проверяем премиум
    final isPremium = await SubscriptionService().isPremiumActive();
    if (!isPremium && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Экспорт в Excel доступен только для Премиум'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Формирование файла...'),
        duration: Duration(seconds: 2),
      ),
    );

    final success = await PriceListExcelService.exportAllPriceLists();

    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Прайс-лист экспортирован' : 'Экспорт отменён',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _importFromExcel(BuildContext context) async {
    // Проверяем премиум
    final isPremium = await SubscriptionService().isPremiumActive();
    if (!isPremium && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Импорт из Excel доступен только для Премиум'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Выберите файл для импорта...'),
        duration: Duration(seconds: 2),
      ),
    );

    final result = await PriceListExcelService.importPriceLists();

    if (context.mounted) {
      if (!result.isSuccess) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Импорт отменён'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (result.errorCount > 0) {
        // Показываем детали ошибок
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Импорт завершён с ошибками'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Результат: ${result.summary}'),
                  const SizedBox(height: 8),
                  if (result.errors.isNotEmpty) ...[
                    const Text(
                      'Ошибки:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...result.errors.take(10).map((e) => Text('• $e')),
                    if (result.errors.length > 10)
                      Text('...и ещё ${result.errors.length - 10}'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Импорт: ${result.summary}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
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
  final PriceListService _priceService = PriceListService();
  List<PriceItem> _items = [];
  bool _isLoading = true;
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

  Future<void> _loadPrices() async {
    setState(() => _isLoading = true);

    final items = await _priceService.getPriceList(widget.workType);

    // Синхронизируем с калькулятором
    for (final item in items) {
      CostCalculator.updatePrice(widget.workType, item.id, item.price);
    }
    AppLogger.info(
      'PriceEdit',
      'Загружено ${items.length} позиций для ${widget.workType}',
    );

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _updatePrice(String itemId, double newPrice) async {
    await _priceService.updatePrice(widget.workType, itemId, newPrice);
    // Синхронизируем с калькулятором
    CostCalculator.updatePrice(widget.workType, itemId, newPrice);
    AppLogger.info(
      'PriceEdit',
      'Цена обновлена: $itemId = $newPrice для ${widget.workType}',
    );
    await _loadPrices();
  }

  Future<void> _deleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить позицию?'),
        content: const Text('Эта позиция будет удалена из прайс-листа.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _priceService.deletePriceItem(widget.workType, itemId);
      await _loadPrices();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Позиция удалена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Синхронизировать текущие цены из PriceListService в CostCalculator
  Future<void> _syncPricesToCalculator() async {
    final items = await _priceService.getPriceList(widget.workType);
    for (final item in items) {
      CostCalculator.updatePrice(widget.workType, item.id, item.price);
    }
    AppLogger.info(
      'PriceEdit',
      'Синхронизировано ${items.length} позиций для ${widget.workType}',
    );
  }

  Future<void> _showAddItemDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final unitController = TextEditingController();
    final formController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить позицию'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например: Монтаж двери',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Цена',
                  hintText: '0',
                  suffixText: '₽',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Единица измерения',
                  hintText: 'шт, м², м.п., компл.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: formController,
                decoration: const InputDecoration(
                  labelText: 'Формула (необязательно)',
                  hintText: 'Например: (width/1000) * (height/1000)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      final price = double.tryParse(priceController.text);
      final unit = unitController.text.trim();
      final formula = formController.text.trim();

      if (name.isEmpty || price == null || unit.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заполните все обязательные поля'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final newItem = PriceItem(
        id: _priceService.generateItemId(name),
        name: name,
        unit: unit,
        price: price,
        formula: formula.isEmpty ? null : formula,
      );

      await _priceService.addPriceItem(widget.workType, newItem);
      await _loadPrices();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Позиция добавлена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  double get _totalEstimated {
    double total = 0;
    for (final item in _items) {
      total += item.price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.workTypeName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                Text(
                  'Позиций: ${_items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // Список позиций
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет позиций',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите + чтобы добавить',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      return Dismissible(
                        key: Key(item.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Удалить позицию?'),
                              content: Text('Удалить "${item.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Отмена'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await _deleteItem(item.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_currencyFormat.format(item.price)} / ${item.unit}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (item.formula != null &&
                                          item.formula!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            'Формула: ${item.formula}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    key: ValueKey('price_${item.id}'),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                        _updatePrice(item.id, newPrice);
                                      }
                                    },
                                    onEditingComplete: () {
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _resetPrices() async {
    final confirmed = await showDialog<bool>(
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
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _doReset();
    }
  }

  Future<void> _doReset() async {
    await _priceService.resetToDefault(widget.workType);
    // Синхронизируем с калькулятором
    await _syncPricesToCalculator();
    await _loadPrices();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Цены сброшены'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
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
    items: 15,
  ),
  _PriceCategory(
    workType: 'doors',
    title: 'Двери',
    icon: Icons.door_front_door,
    color: Colors.brown,
    items: 16,
  ),
  _PriceCategory(
    workType: 'air_conditioners',
    title: 'Кондиционеры',
    icon: Icons.ac_unit,
    color: Colors.cyan,
    items: 13,
  ),
  _PriceCategory(
    workType: 'kitchens',
    title: 'Кухни',
    icon: Icons.kitchen,
    color: Colors.orange,
    items: 18,
  ),
  _PriceCategory(
    workType: 'tiles',
    title: 'Плиточные работы',
    icon: Icons.grid_on,
    color: Colors.teal,
    items: 19,
  ),
  _PriceCategory(
    workType: 'furniture',
    title: 'Мебельные блоки',
    icon: Icons.chair,
    color: Colors.deepPurple,
    items: 21,
  ),
  _PriceCategory(
    workType: 'engineering',
    title: 'Инженерные системы',
    icon: Icons.plumbing,
    color: Colors.red,
    items: 29,
  ),
  _PriceCategory(
    workType: 'electrical',
    title: 'Электрика',
    icon: Icons.electrical_services,
    color: Colors.amber,
    items: 21,
  ),
  _PriceCategory(
    workType: 'foundations',
    title: 'Фундаменты',
    icon: Icons.foundation,
    color: Colors.deepOrange,
    items: 10,
  ),
  _PriceCategory(
    workType: 'walls_box',
    title: 'Коробка (стены)',
    icon: Icons.wallpaper,
    color: Colors.blueGrey,
    items: 9,
  ),
  _PriceCategory(
    workType: 'roofing',
    title: 'Кровля',
    icon: Icons.roofing,
    color: Colors.redAccent,
    items: 14,
  ),
  _PriceCategory(
    workType: 'facades',
    title: 'Фасады',
    icon: Icons.business,
    color: Colors.indigo,
    items: 13,
  ),
  _PriceCategory(
    workType: 'metal_structures',
    title: 'Металлоконструкции',
    icon: Icons.architecture,
    color: Colors.grey,
    items: 10,
  ),
  _PriceCategory(
    workType: 'external_networks',
    title: 'Внешние сети',
    icon: Icons.pets,
    color: Colors.green,
    items: 14,
  ),
  _PriceCategory(
    workType: 'house_construction',
    title: 'Строительство ИЖС',
    icon: Icons.home,
    color: Colors.tealAccent,
    items: 11,
  ),
];
