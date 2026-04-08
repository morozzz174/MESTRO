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
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey, font: font),
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
        'has_quarter': 'Есть четверть',
        'quarter_depth': 'Глубина четверти',
        'quarter_width': 'Ширина четверти',
        'has_slopes': 'Откосы',
        'slope_type': 'Тип откосов',
        'has_sill': 'Подоконник',
        'sill_width': 'Ширина подоконника',
        'opening_type': 'Тип открывания',
        'floor_number': 'Этаж',
      },
      'doors': {
        ...commonLabels,
        'wall_thickness': 'Толщина стены',
        'door_type': 'Тип двери',
        'opening_direction': 'Направление открывания',
        'has_lock': 'Замок',
        'lock_type': 'Тип замка',
        'has_threshold': 'Порог',
        'threshold_height': 'Высота порога',
        'has_peephole': 'Глазок',
        'finish_material': 'Материал отделки',
      },
      'air_conditioners': {
        ...commonLabels,
        'room_area': 'Площадь комнаты',
        'room_height': 'Высота комнаты',
        'ac_power': 'Мощность кондиционера',
        'install_type': 'Тип монтажа',
        'indoor_unit_location': 'Расположение внутр. блока',
        'outdoor_unit_location': 'Расположение нар. блока',
        'pipe_length': 'Длина трубы',
        'drain_length': 'Длина дренажа',
        'has_drain_pump': 'Дренажная помпа',
        'has_wifi_module': 'Wi-Fi модуль',
        'wall_material': 'Материал стены',
      },
      'kitchens': {
        ...commonLabels,
        'kitchen_length': 'Длина кухни',
        'kitchen_type': 'Тип кухни',
        'countertop_material': 'Материал столешницы',
        'facade_material': 'Материал фасада',
        'has_backsplash': 'Фартук',
        'backsplash_length': 'Длина фартука',
        'backsplash_material': 'Материал фартука',
        'has_appliance_install': 'Установка техники',
        'appliance_count': 'Кол-во техники',
        'has_dishwasher': 'Посудомоечная машина',
        'has_washing_machine': 'Стиральная машина',
        'has_oven': 'Духовой шкаф',
        'has_hood': 'Вытяжка',
        'sink_type': 'Тип мойки',
      },
      'furniture': {
        ...commonLabels,
        'room_type': 'Тип комнаты',
        'wall_length': 'Длина стены',
        'ceiling_height': 'Высота потолка',
        'has_baseboards': 'Плинтуса',
        'has_sockets_switches': 'Розетки/выключатели',
        'sockets_position': 'Расположение розеток',
        'check_angles': 'Проверка углов',
        'angle_deviation': 'Отклонение угла',
        'furniture_type': 'Тип мебели',
        'door_type': 'Тип дверей',
        'has_mezzanine': 'Антресоль',
        'has_open_shelves': 'Открытые полки',
        'has_drawers': 'Выдвижные ящики',
        'drawers_count': 'Кол-во ящиков',
        'has_rods': 'Штанги',
        'has_pantograph': 'Пантограф',
        'body_material': 'Материал корпуса',
        'facade_color': 'Цвет фасада',
        'facade_texture': 'Текстура фасада',
        'edge_type': 'Тип кромки',
        'edge_thickness': 'Толщина кромки',
        'handles_type': 'Тип ручек',
        'has_skewed_corners': 'Скошенные углы',
        'has_columns': 'Колонны',
        'has_heating_pipe': 'Труба отопления',
        'heating_pipe_position': 'Расположение трубы',
        'door_opening_clearance': 'Зазор открывания двери',
      },
      'engineering': {
        ...commonLabels,
        'system_type': 'Тип системы',
        'room_area': 'Площадь комнаты',
        'ceiling_height': 'Высота потолка',
        'boiler_type': 'Тип котла',
        'boiler_power': 'Мощность котла',
        'boiler_position': 'Расположение котла',
        'chimney_diameter': 'Диаметр дымохода',
        'chimney_height': 'Высота дымохода',
        'wiring_scheme': 'Схема разводки',
        'heating_system_type': 'Тип системы отопления',
        'radiator_type': 'Тип радиатора',
        'radiator_sections_count': 'Секции радиатора',
        'pipes_material': 'Материал труб',
        'pipes_diameter': 'Диаметр труб',
        'pipes_installation': 'Монтаж труб',
        'floor_heating_contours': 'Контуры тёплого пола',
        'floor_heating_contour_length': 'Длина контура',
        'floor_heating_step': 'Шаг укладки',
        'collector_box_location': 'Расположение коллектора',
        'collector_outputs': 'Выходы коллектора',
        'water_source': 'Источник воды',
        'input_pipe_diameter': 'Диаметр подводящей трубы',
        'has_filters': 'Фильтры',
        'has_water_meter': 'Счётчик воды',
        'water_points': 'Точки водоразбора',
        'sewage_type': 'Тип канализации',
        'sewage_standpipe_diameter': 'Диаметр стояка',
        'toilet_outlet_type': 'Тип выпуска унитаза',
        'has_floor_drains': 'Напольные трапы',
        'ventilation_type': 'Тип вентиляции',
        'hood_duct_diameter': 'Диаметр воздуховода',
        'intake_valves_count': 'Приточные клапаны',
        'has_recuperator': 'Рекуператор',
        'recuperator_model': 'Модель рекуператора',
      },
      'electrical': {
        ...commonLabels,
        'object_type': 'Тип объекта',
        'wall_perimeter': 'Периметр стен',
        'ceiling_height': 'Высота потолка',
        'windows_count': 'Кол-во окон',
        'doors_count': 'Кол-во дверей',
        'power_appliances': 'Мощные приборы',
        'sockets_count': 'Розетки',
        'sockets_type': 'Тип розеток',
        'lighting_type': 'Тип освещения',
        'lighting_count': 'Освещение',
        'switches_type': 'Тип выключателей',
        'input_voltage': 'Напряжение ввода',
        'input_current': 'Ток ввода',
        'circuits_count': 'Кол-во линий',
        'has_rcd': 'УЗО',
        'rcd_leakage_current': 'Ток утечки УЗО',
        'panel_location': 'Расположение щитка',
        'panel_dimensions': 'Размеры щитка',
        'cable_routing': 'Прокладка кабеля',
        'cable_brand': 'Марка кабеля',
        'wall_routes_length': 'Трассы в стенах',
        'floor_routes_length': 'Трассы в полу',
        'ceiling_routes_length': 'Трассы в потолке',
        'has_lightning_protection': 'Защита от молний',
        'has_grounding_circuit': 'Заземление',
        'has_internet_tv': 'Интернет/ТВ',
        'internet_tv_sockets_count': 'Розетки интернет/ТВ',
        'has_cctv': 'Видеонаблюдение',
        'has_smart_home': 'Умный дом',
        'smart_home_devices': 'Устройства умного дома',
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

  /// Генерация PDF плана помещения (для Floor Plan)
  static Future<File> generateFloorPlanPdf(Order order) async {
    final font = await _loadFont('arial.ttf');
    final fontBold = await _loadFont('arial_bold.ttf');
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок
              pw.Text(
                'План помещения',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: fontBold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Заявка: ${order.clientName}',
                style: pw.TextStyle(fontSize: 14, font: font),
              ),
              pw.Text(
                'Адрес: ${order.address}',
                style: pw.TextStyle(fontSize: 12, font: font),
              ),
              pw.Text(
                'Дата: ${DateFormat('dd.MM.yyyy', 'ru').format(order.date)}',
                style: pw.TextStyle(fontSize: 12, font: font),
              ),
              pw.Divider(),

              // Параметры
              pw.Text(
                'Параметры замера:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: fontBold,
                ),
              ),
              pw.SizedBox(height: 8),
              ...order.checklistData.entries.map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 150,
                        child: pw.Text(
                          '${_fieldLabel(e.key, order.workType)}:',
                          style: pw.TextStyle(fontSize: 12, font: fontBold),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          _formatFieldValue(e.key, e.value),
                          style: pw.TextStyle(fontSize: 12, font: font),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 16),
              pw.Divider(),

              // Стоимость
              if (order.estimatedCost != null) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'Итого: ${currencyFormat.format(order.estimatedCost)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    font: fontBold,
                    color: PdfColors.green800,
                  ),
                ),
              ],

              pw.Spacer(),
              pw.Text(
                'Сформировано в Mestro • ${DateFormat('dd.MM.yyyy HH:mm', 'ru').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey,
                  font: font,
                ),
              ),
            ],
          );
        },
      ),
    );

    final tempDir = Directory.systemTemp;
    final filePath = '${tempDir.path}/floor_plan_${order.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
