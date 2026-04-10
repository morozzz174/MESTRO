import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../features/floor_plan/models/floor_plan_models.dart';
import '../features/floor_plan/engine/floor_plan_rule_engine.dart';

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

          // Floor Plan — генерация плана помещения на основе замеров
          ..._buildFloorPlanSection(order, smallStyle),
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
        'width_top': 'Ширина — верх',
        'width_middle': 'Ширина — середина',
        'width_bottom': 'Ширина — низ',
        'height_left': 'Высота — лево',
        'height_middle': 'Высота — центр',
        'height_right': 'Высота — право',
        'diagonal_1': 'Диагональ 1',
        'diagonal_2': 'Диагональ 2',
        'opening_depth': 'Глубина проёма',
        'glass_type': 'Тип стеклопакета',
        'has_quarter': 'Есть четверть',
        'quarter_depth': 'Глубина четверти',
        'quarter_width': 'Ширина четверти',
        'has_slopes': 'Откосы',
        'slope_type': 'Тип откосов',
        'has_sill': 'Подоконник',
        'sill_width': 'Ширина подоконника',
        'has_drip_cap': 'Отлив',
        'drip_cap_width': 'Ширина отлива',
        'opening_type': 'Тип открывания',
        'floor_number': 'Этаж',
      },
      'doors': {
        ...commonLabels,
        'width_top': 'Ширина — верх',
        'width_middle': 'Ширина — середина',
        'width_bottom': 'Ширина — низ',
        'height_left': 'Высота — лево',
        'height_right': 'Высота — право',
        'floor_level_difference': 'Перепад высот в проёме',
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
        'outdoor_unit_access': 'Доступ к нар. блоку',
        'pipe_length': 'Длина трубы',
        'route_method': 'Способ прокладки',
        'drain_length': 'Длина дренажа',
        'power_supply': 'Электроснабжение',
        'has_drain_pump': 'Дренажная помпа',
        'has_wifi_module': 'Wi-Fi модуль',
        'wall_material': 'Материал стены',
      },
      'kitchens': {
        ...commonLabels,
        'kitchen_length': 'Длина кухни',
        'kitchen_length_150': 'Длина на 150 мм',
        'kitchen_length_850': 'Длина на 850 мм',
        'kitchen_length_2000': 'Длина на 2000 мм',
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
        'distance_corner_to_window': 'Расст. до окна',
        'distance_corner_to_door': 'Расст. до двери',
        'sill_height_from_floor': 'Высота подоконника',
        'sill_projection': 'Выступ подоконника',
        'has_gas_pipe': 'Газовая труба',
        'gas_pipe_position': 'Расположение газа',
        'has_water_supply': 'Водопровод',
        'water_pipe_position': 'Расположение воды',
        'has_sewage_outlet': 'Канализация',
        'sewage_outlet_position': 'Расположение канализации',
        'has_ventilation_duct': 'Вентканал',
        'ventilation_position': 'Расположение вентиляции',
      },
      'furniture': {
        ...commonLabels,
        'room_type': 'Тип комнаты',
        'wall_length': 'Длина стены',
        'wall_length_top': 'Длина стены — потолок',
        'wall_length_middle': 'Длина стены — середина',
        'wall_length_bottom': 'Длина стены — пол',
        'ceiling_height': 'Высота потолка',
        'ceiling_height_left': 'Высота потолка — лево',
        'ceiling_height_middle': 'Высота потолка — центр',
        'ceiling_height_right': 'Высота потолка — право',
        'wall_curvature': 'Кривизна стены',
        'has_niches': 'Есть ниши',
        'niche_width': 'Ширина ниши',
        'niche_height': 'Высота ниши',
        'niche_depth': 'Глубина ниши',
        'niche_position': 'Расположение ниши',
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
      'tiles': {
        ...commonLabels,
        'surface_type': 'Тип поверхности',
        'tile_material': 'Материал плитки',
        'laying_method': 'Способ укладки',
        'wall_height': 'Высота стены',
        'wall_length': 'Длина стены',
        'has_windows_doors': 'Окна/двери для вычета',
        'windows_doors_area': 'Площадь окон/дверей',
        'floor_length': 'Длина пола',
        'floor_width': 'Ширина пола',
        'floor_complex_shape': 'Сложная форма пола',
        'apron_height': 'Высота фартука',
        'apron_length': 'Длина фартука',
        'has_sockets': 'Розетки на фартуке',
        'sockets_count': 'Кол-во розеток',
        'tile_length': 'Длина плитки',
        'tile_width': 'Ширина плитки',
        'tile_thickness': 'Толщина плитки',
        'tile_caliber': 'Калибр плитки',
        'surface_evenness': 'Ровность основания',
        'base_type': 'Тип основания',
        'reserve_coefficient': 'Запас материала',
        'has_decorative_inserts': 'Декоративные вставки',
        'decorative_inserts_count': 'Кол-во вставок',
        'has_underfloor_heating': 'Тёплый пол',
        'heating_type': 'Тип тёплого пола',
        'heating_power': 'Мощность тёплого пола',
        'heating_area': 'Площадь тёплого пола',
      },
      'engineering': {
        ...commonLabels,
        'system_type': 'Тип системы',
        'room_area': 'Площадь комнаты',
        'ceiling_height': 'Высота потолка',
        'wall_material': 'Материал наружных стен',
        'wall_thickness_external': 'Толщина наружных стен',
        'has_insulation': 'Утепление наружных стен',
        'insulation_type': 'Тип утеплителя',
        'insulation_thickness': 'Толщина утеплителя',
        'window_type': 'Тип остекления',
        'floor_type': 'Тип пола',
        'has_floor_insulation': 'Утепление пола',
        'floor_insulation_thickness': 'Толщина утепления пола',
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

    // Генерируем план из заказа
    final plan = FloorPlanRuleEngine.generateFromOrder(order);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
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

            // Визуальный план помещения
            pw.SizedBox(height: 16),
            pw.Text(
              'Планировка',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: fontBold,
              ),
            ),
            pw.SizedBox(height: 8),

            // Рисуем план помещения
            _buildFloorPlanDrawing(plan, font, fontBold),

            pw.SizedBox(height: 16),
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

            // Информация о плане
            pw.SizedBox(height: 8),
            pw.Text(
              'Информация о плане',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: fontBold,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildInfoRow(
              'Общая площадь:',
              '${plan.totalArea.toStringAsFixed(1)} м²',
              pw.TextStyle(fontSize: 12, font: fontBold),
              pw.TextStyle(fontSize: 12, font: font),
            ),
            _buildInfoRow(
              'Жилая площадь:',
              '${plan.livingArea.toStringAsFixed(1)} м²',
              pw.TextStyle(fontSize: 12, font: fontBold),
              pw.TextStyle(fontSize: 12, font: font),
            ),
            _buildInfoRow(
              'Количество комнат:',
              '${plan.roomCount}',
              pw.TextStyle(fontSize: 12, font: fontBold),
              pw.TextStyle(fontSize: 12, font: font),
            ),
            _buildInfoRow(
              'Тип помещения:',
              plan.objectType.label,
              pw.TextStyle(fontSize: 12, font: fontBold),
              pw.TextStyle(fontSize: 12, font: font),
            ),

            // Список комнат
            if (plan.rooms.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Комнаты:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: fontBold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Комната',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            font: fontBold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Площадь',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            font: fontBold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Двери',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            font: fontBold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Окна',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            font: fontBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...plan.rooms.map(
                    (room) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '${room.type.icon} ${room.type.label}',
                            style: pw.TextStyle(fontSize: 10, font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '${room.area.toStringAsFixed(1)} м²',
                            style: pw.TextStyle(fontSize: 10, font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '${room.doors.length}',
                            style: pw.TextStyle(fontSize: 10, font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '${room.windows.length}',
                            style: pw.TextStyle(fontSize: 10, font: font),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Стоимость
            if (order.estimatedCost != null) ...[
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
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
          ];
        },
      ),
    );

    final tempDir = Directory.systemTemp;
    final filePath = '${tempDir.path}/floor_plan_${order.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Построить визуальный план помещения для PDF
  static pw.Widget _buildFloorPlanDrawing(
    FloorPlan plan,
    pw.Font font,
    pw.Font fontBold,
  ) {
    // Масштаб: 1 метр = 50 пикселей
    const pixelsPerMeter = 50.0;
    final planWidth = plan.totalWidth * pixelsPerMeter;
    final planHeight = plan.totalHeight * pixelsPerMeter;

    // Рисуем план как SVG
    final svgContent = _generateFloorPlanSVG(plan, pixelsPerMeter);

    return pw.Container(
      width: planWidth,
      height: planHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey800, width: 2),
        color: PdfColors.grey50,
      ),
      child: pw.SvgImage(svg: svgContent),
    );
  }

  /// Генерировать SVG плана помещения
  static String _generateFloorPlanSVG(FloorPlan plan, double pixelsPerMeter) {
    final width = plan.totalWidth * pixelsPerMeter;
    final height = plan.totalHeight * pixelsPerMeter;

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height">',
    );

    // Фон
    buffer.writeln('<rect width="$width" height="$height" fill="#f5f5f5"/>');

    // Сетка (1 клетка = 1 метр)
    buffer.writeln('<g stroke="#e0e0e0" stroke-width="0.5">');
    for (double x = 0; x <= plan.totalWidth; x += 1) {
      final px = x * pixelsPerMeter;
      buffer.writeln('<line x1="$px" y1="0" x2="$px" y2="$height"/>');
    }
    for (double y = 0; y <= plan.totalHeight; y += 1) {
      final py = y * pixelsPerMeter;
      buffer.writeln('<line x1="0" y1="$py" x2="$width" y2="$py"/>');
    }
    buffer.writeln('</g>');

    // Комнаты
    for (final room in plan.rooms) {
      final x = room.x * pixelsPerMeter;
      final y = room.y * pixelsPerMeter;
      final w = room.width * pixelsPerMeter;
      final h = room.height * pixelsPerMeter;

      // Цвет комнаты в зависимости от типа
      String fillColor = '#e3f2fd'; // default
      switch (room.type) {
        case RoomType.kitchen:
          fillColor = '#fff3e0';
          break;
        case RoomType.livingRoom:
          fillColor = '#e8f5e9';
          break;
        case RoomType.bedroom:
          fillColor = '#fce4ec';
          break;
        case RoomType.bathroom:
          fillColor = '#e0f7fa';
          break;
        case RoomType.toilet:
          fillColor = '#f3e5f5';
          break;
        case RoomType.hallway:
          fillColor = '#fff9c4';
          break;
        case RoomType.balcony:
          fillColor = '#e8eaf6';
          break;
        case RoomType.storage:
          fillColor = '#efebe9';
          break;
        case RoomType.office:
          fillColor = '#e0f2f1';
          break;
        case RoomType.childrenRoom:
          fillColor = '#fff3e0';
          break;
      }

      // Комната
      buffer.writeln(
        '<rect x="$x" y="$y" width="$w" height="$h" fill="$fillColor" stroke="#1976d2" stroke-width="2"/>',
      );

      // Двери
      for (final door in room.doors) {
        final dx = (room.x + door.x) * pixelsPerMeter;
        final dy = (room.y + door.y) * pixelsPerMeter;
        final dw = door.width * pixelsPerMeter;

        buffer.writeln(
          '<line x1="$dx" y1="$dy" x2="${dx + dw}" y2="$dy" stroke="#795548" stroke-width="3"/>',
        );
        // Дуга открывания
        buffer.writeln(
          '<path d="M $dx $dy Q ${dx + dw / 2} ${dy - dw / 2} ${dx + dw} $dy" fill="none" stroke="#795548" stroke-width="1" stroke-dasharray="3,3"/>',
        );
      }

      // Окна
      for (final window in room.windows) {
        final wx = (room.x + window.x) * pixelsPerMeter;
        final wy = (room.y + window.y) * pixelsPerMeter;
        final ww = window.width * pixelsPerMeter;

        buffer.writeln(
          '<rect x="$wx" y="${wy - 3}" width="$ww" height="6" fill="#4fc3f7" stroke="#0288d1" stroke-width="1.5"/>',
        );
      }

      // Название комнаты
      final centerX = x + w / 2;
      final centerY = y + h / 2;
      buffer.writeln(
        '<text x="$centerX" y="$centerY" text-anchor="middle" dominant-baseline="middle" font-size="12" fill="#333">${room.type.icon} ${room.type.label}</text>',
      );

      // Площадь
      buffer.writeln(
        '<text x="$centerX" y="${centerY + 15}" text-anchor="middle" font-size="10" fill="#666">${room.area.toStringAsFixed(1)} м²</text>',
      );
    }

    // Размерные линии (верхняя и правая)
    // Верхняя размерная линия
    final dimY = -10;
    buffer.writeln(
      '<line x1="0" y1="$dimY" x2="$width" y2="$dimY" stroke="#333" stroke-width="1"/>',
    );
    buffer.writeln(
      '<text x="${width / 2}" y="${dimY - 5}" text-anchor="middle" font-size="10" fill="#333">${plan.totalWidth.toStringAsFixed(1)} м</text>',
    );

    // Правая размерная линия
    final dimX = width + 10;
    buffer.writeln(
      '<line x1="$dimX" y1="0" x2="$dimX" y2="$height" stroke="#333" stroke-width="1"/>',
    );
    buffer.writeln(
      '<text x="${dimX + 5}" y="${height / 2}" text-anchor="middle" font-size="10" fill="#333" transform="rotate(90, $dimX, ${height / 2})">${plan.totalHeight.toStringAsFixed(1)} м</text>',
    );

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Генерация секции Floor Plan для PDF (на основе данных замера)
  static List<pw.Widget> _buildFloorPlanSection(
    Order order,
    pw.TextStyle smallStyle,
  ) {
    final cd = order.checklistData;

    // Извлекаем размеры помещения из данных чек-листа
    final width = (cd['width'] as num?)?.toDouble();
    final height = (cd['height'] as num?)?.toDouble();
    final floorLength = (cd['floor_length'] as num?)?.toDouble();
    final floorWidth = (cd['floor_width'] as num?)?.toDouble();

    // Если нет размеров — ничего не показываем
    final planWidth = width ?? floorLength;
    final planHeight = height ?? floorWidth;
    if (planWidth == null || planHeight == null) return [];

    // Генерируем план помещения через Rule Engine
    final plan = FloorPlanRuleEngine.generateFromOrder(order);

    return [
      pw.SizedBox(height: 20),
      pw.Text(
        'План помещения',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Размеры:', style: smallStyle),
                pw.Text(
                  '${planWidth.toStringAsFixed(0)} × ${planHeight.toStringAsFixed(0)} мм',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Тип помещения:', style: smallStyle),
                pw.Text(plan.objectType.label),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Площадь:', style: smallStyle),
                pw.Text(
                  '${plan.totalArea.toStringAsFixed(1)} м²',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            if (plan.rooms.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text('Комнаты:', style: smallStyle),
              ...plan.rooms.map(
                (room) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, top: 2),
                  child: pw.Text(
                    '• ${room.type.label} (${room.area.toStringAsFixed(1)} м²)',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(height: 10),
    ];
  }
}
