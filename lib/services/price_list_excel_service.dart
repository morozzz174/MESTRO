import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/price_item.dart';
import '../services/price_list_service.dart';
import '../utils/cost_calculator.dart';
import 'app_logger.dart';

/// Сервис экспорта и импорта прайс-листов в Excel
class PriceListExcelService {
  static final _dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');

  /// Экспорт всех прайс-листов в один Excel-файл
  static Future<bool> exportAllPriceLists() async {
    try {
      final service = PriceListService();
      final workTypes = _allWorkTypes;

      final excel = Excel.createExcel();
      // Удаляем дефолтный лист
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }

      // Лист «Обзор» — сводка по всем нишам
      final overviewSheet = excel['Обзор'];
      _buildOverviewSheet(overviewSheet, service);

      // По одному листу на каждую нишу
      for (final workType in workTypes) {
        final items = await service.getPriceList(workType);
        final sheetName = _workTypeToSheetName(workType);
        final sheet = excel[sheetName];
        _buildWorkTypeSheet(sheet, workType, items);
      }

      // Сохраняем
      final bytes = excel.encode()!;
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final fileName = 'mestro_pricelist_$timestamp.xlsx';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить прайс-лист',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );

      if (result != null) {
        AppLogger.success('PriceListExcel', 'Экспорт сохранён: $result');
      }
      return result != null;
    } catch (e, st) {
      AppLogger.error('PriceListExcel', 'Ошибка экспорта прайс-листа', e, st);
      return false;
    }
  }

  /// Импорт прайс-листов из Excel-файла
  static Future<ImportResult> importPriceLists() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult.cancelled();
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        return ImportResult.error('Файл не найден');
      }

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      int updatedCount = 0;
      int addedCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      final priceService = PriceListService();

      for (final workType in _allWorkTypes) {
        final sheetName = _workTypeToSheetName(workType);
        final sheet = excel[sheetName];
        if (sheet == null) continue;

        final items = _parseWorkTypeSheet(sheet, workType);

        for (final item in items) {
          try {
            // Проверяем, существует ли позиция
            final existingItems = await priceService.getPriceList(workType);
            final existingIndex = existingItems.indexWhere(
              (i) => i.id == item.id,
            );

            if (existingIndex != -1) {
              // Обновляем существующую позицию
              await priceService.updatePrice(workType, item.id, item.price);
              CostCalculator.updatePrice(workType, item.id, item.price);
              updatedCount++;
            } else {
              // Добавляем новую позицию
              await priceService.addPriceItem(workType, item);
              CostCalculator.updatePrice(workType, item.id, item.price);
              addedCount++;
            }
          } catch (e) {
            errorCount++;
            errors.add('${_workTypeToTitle(workType)} / ${item.name}: $e');
          }
        }
      }

      AppLogger.success(
        'PriceListExcel',
        'Импорт завершён: обновлено=$updatedCount, добавлено=$addedCount, ошибок=$errorCount',
      );

      return ImportResult(
        updatedCount: updatedCount,
        addedCount: addedCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e, st) {
      AppLogger.error('PriceListExcel', 'Ошибка импорта прайс-листа', e, st);
      return ImportResult.error('Ошибка импорта: $e');
    }
  }

  // ===== Вспомогательные методы =====

  static const _allWorkTypes = [
    'windows',
    'doors',
    'air_conditioners',
    'kitchens',
    'tiles',
    'furniture',
    'engineering',
    'electrical',
  ];

  static String _workTypeToSheetName(String workType) {
    const map = {
      'windows': 'Окна',
      'doors': 'Двери',
      'air_conditioners': 'Кондиционеры',
      'kitchens': 'Кухни',
      'tiles': 'Плитка',
      'furniture': 'Мебель',
      'engineering': 'Инженерные',
      'electrical': 'Электрика',
    };
    return map[workType] ?? workType;
  }

  static String _workTypeToTitle(String workType) {
    const map = {
      'windows': 'Окна',
      'doors': 'Двери',
      'air_conditioners': 'Кондиционеры',
      'kitchens': 'Кухни',
      'tiles': 'Плиточные работы',
      'furniture': 'Мебельные блоки',
      'engineering': 'Инженерные системы',
      'electrical': 'Электрика',
    };
    return map[workType] ?? workType;
  }

  static String _sheetNameToWorkType(String sheetName) {
    const map = {
      'Окна': 'windows',
      'Двери': 'doors',
      'Кондиционеры': 'air_conditioners',
      'Кухни': 'kitchens',
      'Плитка': 'tiles',
      'Мебель': 'furniture',
      'Инженерные': 'engineering',
      'Электрика': 'electrical',
    };
    return map[sheetName] ?? '';
  }

  // ===== Построение листа «Обзор» =====

  static void _buildOverviewSheet(Sheet sheet, PriceListService service) {
    // Заголовки
    final headers = [
      'Ниша',
      'Кол-во позиций',
      'Мин. цена',
      'Макс. цена',
      'Средняя цена',
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
    }

    var row = 1;
    for (final workType in _allWorkTypes) {
      final title = _workTypeToTitle(workType);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        title,
      );
      row++;
    }

    sheet.setDefaultColumnWidth(25);
  }

  // ===== Построение листа ниши =====

  static void _buildWorkTypeSheet(
    Sheet sheet,
    String workType,
    List<PriceItem> items,
  ) {
    // Заголовки
    final headers = [
      'ID',
      'Название',
      'Цена (₽)',
      'Ед. измерения',
      'Формула',
      'Умножать на кол-во',
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
    }

    // Данные
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final row = i + 1;

      final rowData = [
        TextCellValue(item.id),
        TextCellValue(item.name),
        DoubleCellValue(item.price),
        TextCellValue(item.unit),
        TextCellValue(item.formula ?? ''),
        TextCellValue(item.multiplyByCount ? 'Да' : 'Нет'),
      ];

      for (var j = 0; j < rowData.length; j++) {
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row))
                .value =
            rowData[j];
      }
    }

    sheet.setDefaultColumnWidth(30);
    // Выделяем столбец цены уже
    try {
      sheet.setColumnWidth(2, 15);
    } catch (_) {}
  }

  // ===== Парсинг листа ниши =====

  static List<PriceItem> _parseWorkTypeSheet(Sheet sheet, String workType) {
    final items = <PriceItem>[];
    final maxRows = sheet.maxRows;

    // Пропускаем заголовок (row 0)
    for (var row = 1; row < maxRows; row++) {
      try {
        final idCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        );
        final nameCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        );
        final priceCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
        );
        final unitCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
        );
        final formulaCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
        );
        final multiplyCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
        );

        final id = idCell.value?.toString().trim();
        final name = nameCell.value?.toString().trim();
        final unitValue = unitCell.value?.toString().trim();
        final unit = (unitValue != null && unitValue.isNotEmpty)
            ? unitValue
            : 'шт.';

        if (id == null || id.isEmpty || name == null || name.isEmpty) {
          continue; // пустая строка
        }

        double price = 0;
        final priceValue = priceCell.value;
        if (priceValue is DoubleCellValue) {
          price = priceValue.value;
        } else {
          price = double.tryParse(priceValue?.toString() ?? '0') ?? 0;
        }

        final formulaStr = formulaCell.value?.toString().trim();
        final formula = (formulaStr != null && formulaStr.isNotEmpty)
            ? formulaStr
            : null;

        final multiplyStr = multiplyCell.value?.toString().trim().toLowerCase();
        final multiplyByCount =
            multiplyStr == 'да' || multiplyStr == 'true' || multiplyStr == '1';

        items.add(
          PriceItem(
            id: id,
            name: name,
            unit: unit,
            price: price,
            formula: formula,
            multiplyByCount: multiplyByCount,
          ),
        );
      } catch (e) {
        AppLogger.warn(
          'PriceListExcel',
          'Ошибка парсинга строки $row для $workType: $e',
        );
      }
    }

    return items;
  }
}

/// Результат импорта
class ImportResult {
  final int updatedCount;
  final int addedCount;
  final int errorCount;
  final List<String> errors;
  final bool isSuccess;
  final String? errorMessage;

  ImportResult({
    this.updatedCount = 0,
    this.addedCount = 0,
    this.errorCount = 0,
    this.errors = const [],
    this.isSuccess = true,
    this.errorMessage,
  });

  factory ImportResult.cancelled() =>
      ImportResult(isSuccess: false, errorMessage: 'Отменено');

  factory ImportResult.error(String message) =>
      ImportResult(isSuccess: false, errorMessage: message);

  String get summary {
    if (!isSuccess) return errorMessage ?? 'Ошибка';
    final parts = <String>[];
    if (updatedCount > 0) parts.add('обновлено: $updatedCount');
    if (addedCount > 0) parts.add('добавлено: $addedCount');
    if (errorCount > 0) parts.add('ошибок: $errorCount');
    return parts.isEmpty ? 'Ничего не изменено' : parts.join(', ');
  }
}
