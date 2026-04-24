import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

/// Сервис экспорта данных в Excel
class ExportService {
  /// Экспорт всех заявок в Excel
  static Future<bool> exportToExcel() async {
    try {
      final orders = await DatabaseHelper().getAllOrders();
      final excel = Excel.createExcel();

      // Удаляем дефолтный лист
      excel.delete(excel.getDefaultSheet()!);
      final sheet = excel['Заявки'];

      // Заголовки
      final headers = [
        'Дата создания',
        'Клиент',
        'Телефон',
        'Адрес',
        'Тип работ',
        'Статус',
        'Дата замера',
        'Стоимость',
        'Заметки',
        'Кол-во фото',
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
      }

      // Данные
      final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');
      final currencyFormat = NumberFormat.currency(
        locale: 'ru_RU',
        symbol: '',
        decimalDigits: 0,
      );

      for (var i = 0; i < orders.length; i++) {
        final order = orders[i];
        final row = i + 1;

        final rowData = [
          TextCellValue(dateFormat.format(order.createdAt)),
          TextCellValue(order.clientName),
          TextCellValue(order.clientPhone ?? ''),
          TextCellValue(order.address),
          TextCellValue(order.workType.title),
          TextCellValue(order.status.label),
          TextCellValue(dateFormat.format(order.date)),
          order.estimatedCost != null
              ? TextCellValue(currencyFormat.format(order.estimatedCost))
              : TextCellValue(''),
          TextCellValue(order.notes ?? ''),
          TextCellValue(order.photos.length.toString()),
        ];

        for (var j = 0; j < rowData.length; j++) {
          sheet
                  .cell(
                    CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row),
                  )
                  .value =
              rowData[j];
        }
      }

      sheet.setDefaultColumnWidth(20);

      // Сохранение
      final bytes = excel.encode()!;
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final fileName = 'mestro_export_$timestamp.xlsx';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить экспорт',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );

      return result != null;
    } catch (e) {
      print('[Export] Error: $e');
      return false;
    }
  }
}
