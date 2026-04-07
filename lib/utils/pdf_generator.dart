import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/order.dart';

class PdfGenerator {
  /// Загрузить шрифт с поддержкой кириллицы из assets
  static Future<pw.Font> _loadFont(String assetName) async {
    try {
      final data = await rootBundle.load('assets/fonts/$assetName');
      return pw.Font.ttf(data);
    } catch (e) {
      // Fallback: встроенный шрифт (может не поддерживать кириллицу)
      return pw.Font.helvetica();
    }
  }

  static Future<File> generateProposal(Order order) async {
    final font = await _loadFont('arial.ttf');
    final fontBold = await _loadFont('arial_bold.ttf');
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    // Стили
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      font: fontBold,
    );
    final headerStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      font: fontBold,
    );
    final labelStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      font: fontBold,
    );
    final valueStyle = pw.TextStyle(fontSize: 12, font: font);
    final smallStyle = pw.TextStyle(fontSize: 10, font: font);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Заголовок
          pw.Header(
            level: 0,
            child: pw.Text('Коммерческое предложение', style: titleStyle),
          ),

          pw.SizedBox(height: 20),

          // Информация о заявке
          pw.Text('Информация о заявке', style: headerStyle),
          pw.SizedBox(height: 10),
          _buildInfoRow('Клиент:', order.clientName, labelStyle, valueStyle),
          _buildInfoRow('Адрес:', order.address, labelStyle, valueStyle),
          _buildInfoRow(
            'Дата:',
            dateFormat.format(order.date),
            labelStyle,
            valueStyle,
          ),
          _buildInfoRow(
            'Тип работ:',
            order.workType.title,
            labelStyle,
            valueStyle,
          ),
          _buildInfoRow('Статус:', order.status.label, labelStyle, valueStyle),

          pw.SizedBox(height: 20),

          // Замеры
          pw.Text('Результаты замера', style: headerStyle),
          pw.SizedBox(height: 10),
          ...order.checklistData.entries.map(
            (e) => _buildInfoRow(
              '${_fieldLabel(e.key, order.workType)}:',
              _formatFieldValue(e.key, e.value),
              labelStyle,
              valueStyle,
            ),
          ),

          pw.SizedBox(height: 20),

          // Стоимость
          if (order.estimatedCost != null) ...[
            pw.Text('Итоговая стоимость', style: headerStyle),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Итого:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      font: fontBold,
                    ),
                  ),
                  pw.Text(
                    currencyFormat.format(order.estimatedCost),
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                      font: fontBold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // Фото
          if (order.photos.isNotEmpty) ...[
            pw.Text('Фотофиксация', style: headerStyle),
            pw.SizedBox(height: 10),
            ...order.photos.map((photo) {
              final image = pw.MemoryImage(
                File(photo.annotatedPath ?? photo.filePath).readAsBytesSync(),
              );
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Пункт: ${photo.checklistFieldId ?? "Не указан"}',
                    style: smallStyle,
                  ),
                  pw.Text(
                    'Дата: ${dateFormat.format(photo.timestamp)}',
                    style: smallStyle,
                  ),
                  if (photo.latitude != null)
                    pw.Text(
                      'Координаты: ${photo.latitude}, ${photo.longitude}',
                      style: smallStyle,
                    ),
                  pw.SizedBox(height: 5),
                  pw.Image(image, width: 300),
                  pw.SizedBox(height: 10),
                ],
              );
            }),
          ],
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'Сформировано в приложении Mestro • ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ),
      ),
    );

    // Сохраняем PDF во временный файл
    final tempDir = Directory.systemTemp;
    final filePath = '${tempDir.path}/proposal_${order.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, style: labelStyle)),
          pw.Expanded(child: pw.Text(value, style: valueStyle)),
        ],
      ),
    );
  }

  /// Маппинг английских ключей на русские лейблы
  static String _fieldLabel(String key, WorkType workType) {
    const commonLabels = {
      'width': 'Ширина проёма',
      'height': 'Высота проёма',
      'area': 'Площадь',
      'notes': 'Заметки',
      'count': 'Количество',
      'comment': 'Комментарий',
    };

    final allLabels = <String, Map<String, String>>{
      'windows': {
        ...commonLabels,
        'glass_type': 'Тип стеклопакета',
        'has_slopes': 'Откосы',
        'has_sill': 'Подоконник',
        'sill_width': 'Ширина подоконника',
        'opening_type': 'Тип открывания',
        'frame_type': 'Тип профиля',
        'mosquito_net': 'Москитная сетка',
        'film': 'Плёнка',
        'color': 'Цвет профиля',
      },
      'doors': {
        ...commonLabels,
        'door_type': 'Тип двери',
        'has_lock': 'Замок',
        'door_width': 'Ширина двери',
        'door_height': 'Высота двери',
        'opening_direction': 'Направление открывания',
      },
      'air_conditioners': {
        ...commonLabels,
        'install_type': 'Тип монтажа',
        'pipe_length': 'Длина трубы',
        'drain_length': 'Длина дренажа',
        'ac_model': 'Модель кондиционера',
        'power': 'Мощность',
      },
      'kitchens': {
        ...commonLabels,
        'kitchen_length': 'Длина кухни',
        'has_appliance_install': 'Установка техники',
        'appliance_count': 'Кол-во техники',
        'has_backsplash': 'Фартук',
        'backsplash_length': 'Длина фартука',
        'material': 'Материал',
      },
      'tiles': {
        ...commonLabels,
        'surface_type': 'Тип поверхности',
        'wall_height': 'Высота стены',
        'wall_length': 'Длина стены',
        'floor_length': 'Длина пола',
        'floor_width': 'Ширина пола',
        'has_windows_doors': 'Есть окна/двери',
        'windows_doors_area': 'Площадь окон/дверей',
        'laying_method': 'Способ укладки',
        'has_underfloor_heating': 'Тёплый пол',
        'heating_area': 'Площадь тёплого пола',
        'tile_type': 'Тип плитки',
      },
      'furniture': {
        ...commonLabels,
        'body_material': 'Материал корпуса',
        'wall_length': 'Длина стены',
        'ceiling_height': 'Высота потолка',
        'has_drawers': 'Выдвижные ящики',
        'drawers_count': 'Кол-во ящиков',
        'facade_type': 'Тип фасадов',
      },
      'engineering': {
        ...commonLabels,
        'system_type': 'Тип системы',
        'boiler_type': 'Тип котла',
        'radiator_sections_count': 'Секции радиатора',
        'pipe_length': 'Длина трубы',
        'pipe_type': 'Тип трубы',
        'floor_area': 'Площадь пола',
        'intake_valves_count': 'Клапаны',
      },
      'electrical': {
        ...commonLabels,
        'sockets_count': 'Розетки',
        'lighting_count': 'Освещение',
        'switches_count': 'Выключатели',
        'wall_routes_length': 'Трассы в стенах',
        'floor_routes_length': 'Трассы в полу',
        'ceiling_routes_length': 'Трассы в потолке',
        'has_smart_home': 'Умный дом',
        'smart_home_points_count': 'Точки умного дома',
        'panel_type': 'Тип щитка',
      },
    };

    return allLabels[workType.checklistFile]?[key] ?? commonLabels[key] ?? key;
  }

  /// Форматирование значения поля
  static String _formatFieldValue(String key, dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Да' : 'Нет';
    if (value is double) {
      // Если значение в мм — показываем с единицами
      if (key.contains('width') ||
          key.contains('height') ||
          key.contains('length')) {
        return '${value.toInt()} мм';
      }
      return value.toStringAsFixed(1);
    }
    if (value is int) return value.toString();

    // Маппинг значений для select-полей
    final stringVal = value.toString();
    const glassTypes = {
      'single': 'Однокамерный',
      'double': 'Двухкамерный',
      'energy': 'Энергосберегающий',
    };
    if (glassTypes.containsKey(stringVal)) return glassTypes[stringVal]!;

    return stringVal;
  }
}
