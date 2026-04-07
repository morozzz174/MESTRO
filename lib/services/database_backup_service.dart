import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

/// Сервис резервного копирования базы данных
class DatabaseBackupService {
  /// Получить путь к файлу БД
  static Future<File> getDbFile() async {
    final dbPath = await getDatabasesPath();
    return File(path.join(dbPath, 'mestro.db'));
  }

  /// Экспорт БД в файл
  static Future<bool> exportDatabase(BuildContext context) async {
    try {
      final dbFile = await getDbFile();
      if (!await dbFile.exists()) {
        _showSnackbar(context, 'База данных не найдена', isError: true);
        return false;
      }

      final bytes = await dbFile.readAsBytes();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'mestro_backup_$timestamp.db';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить резервную копию',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['db'],
        bytes: bytes,
      );

      if (result != null) {
        _showSnackbar(context, 'Резервная копия сохранена: $fileName');
        return true;
      }
      return false;
    } catch (e) {
      _showSnackbar(context, 'Ошибка экспорта: $e', isError: true);
      return false;
    }
  }

  /// Импорт БД из файла
  static Future<bool> importDatabase(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        _showSnackbar(context, 'Не удалось прочитать файл', isError: true);
        return false;
      }

      // Подтверждение
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Восстановить из резервной копии?'),
          content: const Text(
            'Текущие данные будут заменены данными из резервной копии. '
            'Это действие нельзя отменить.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Восстановить'),
            ),
          ],
        ),
      );

      if (confirmed != true) return false;

      // Копируем файл в БД
      final dbFile = await getDbFile();
      final sourceFile = File(filePath);
      await sourceFile.copy(dbFile.path);

      _showSnackbar(context, 'Резервная копия восстановлена');
      return true;
    } catch (e) {
      _showSnackbar(context, 'Ошибка импорта: $e', isError: true);
      return false;
    }
  }

  static void _showSnackbar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
