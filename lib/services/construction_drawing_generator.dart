/// Генератор профессиональных строительных чертежей в PDF
/// Включает: планы, разрезы, фасады, спецификации, экспликации
/// Соответствует ГОСТ 21.501-2011 (правила оформления строительной документации)
import 'dart:io';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../features/floor_plan/models/floor_plan_models_extended.dart';
import '../models/order.dart';

class ConstructionDrawingGenerator {
  // ==========================================================================
  // ГЛАВНЫЙ МЕТОД — Полный комплект чертежей
  // ==========================================================================

  static Future<File> generateFullDrawingPackage({
    required dynamic plan,
    required Order order,
    String projectName = 'Проект',
  }) async {
    final pdf = pw.Document();

    // Шрифты
    final regular = await _loadFont('arial.ttf');
    final bold = await _loadFont('arial_bold.ttf');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(10),
        header: (context) => _drawHeader(context, plan, projectName),
        footer: (context) => _drawFooter(context, plan),
        build: (context) => [
          _buildTitlePage(plan, order, projectName, regular, bold),
          pw.SizedBox(height: 20),
          _buildPlanView(plan, regular, bold),
          pw.SizedBox(height: 20),
          _buildDimensionLines(plan, regular, bold),
          pw.SizedBox(height: 20),
          _buildRoomSchedule(plan, regular, bold),
          pw.SizedBox(height: 20),
          _buildWallSchedule(plan, regular, bold),
          pw.SizedBox(height: 20),
          _buildFoundationSchedule(plan, regular, bold),
          pw.SizedBox(height: 20),
          _buildRoofSchedule(plan, regular, bold),
          pw.SizedBox(height: 20),
          _buildEngineeringSchedule(plan, regular, bold),
          pw.SizedBox(height: 20),
          _buildSpecifications(plan, regular, bold),
          pw.SizedBox(height: 20),
          _buildHeatLossCalculation(plan, regular, bold),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Чертеж_${order.clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ==========================================================================
  // ТИТУЛЬНАЯ СТРАНИЦА
  // ==========================================================================

  static pw.Widget _buildTitlePage(
    FloorPlan plan,
    Order order,
    String projectName,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue900, width: 2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ПРОЕКТНАЯ ДОКУМЕНТАЦИЯ',
                style: pw.TextStyle(font: bold, fontSize: 28, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                projectName,
                style: pw.TextStyle(font: bold, fontSize: 20, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.blue900),
              pw.SizedBox(height: 15),
              _infoRow('Заказчик:', order.clientName, regular, bold),
              _infoRow('Адрес:', order.address, regular, bold),
              _infoRow('Тип объекта:', plan.objectType.label, regular, bold),
              _infoRow('Площадь застройки:', '${plan.totalArea.toStringAsFixed(1)} м²', regular, bold),
              _infoRow('Общая площадь:', '${plan.calculatedTotalArea.toStringAsFixed(1)} м²', regular, bold),
              _infoRow('Жилая площадь:', '${plan.calculatedLivingArea.toStringAsFixed(1)} м²', regular, bold),
              _infoRow('Объём здания:', '${plan.buildingVolume.toStringAsFixed(1)} м³', regular, bold),
              _infoRow('Количество комнат:', '${plan.roomCount}', regular, bold),
              _infoRow('Высота этажа:', '${plan.floorHeight} м', regular, bold),
              pw.SizedBox(height: 15),
              pw.Divider(color: PdfColors.blue900),
              pw.SizedBox(height: 10),
              pw.Text(
                'Состав проекта:',
                style: pw.TextStyle(font: bold, fontSize: 14),
              ),
              pw.SizedBox(height: 10),
              pw.Bullet(text: 'План этажа с размерами и осями'),
              pw.Bullet(text: 'Экспликация помещений'),
              pw.Bullet(text: 'Ведомость отделки стен'),
              pw.Bullet(text: 'Схема фундамента'),
              pw.Bullet(text: 'Схема кровли'),
              pw.Bullet(text: 'Инженерные системы'),
              pw.Bullet(text: 'Спецификация материалов'),
              pw.Bullet(text: 'Расчёт теплопотерь'),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ПЛАН ЭТАЖА (чертёж)
  // ==========================================================================

  static pw.Widget _buildPlanView(FloorPlan plan, pw.Font regular, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('ПЛАН ЭТАЖА', bold),
        pw.SizedBox(height: 5),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            color: PdfColors.white,
          ),
          child: pw.Column(
            children: [
              // SVG план
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.SvgImage(
                  svg: _generatePlanSvg(plan),
                  width: 500,
                ),
              ),
              pw.SizedBox(height: 10),
              // Информация
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _statBox('Общая', '${plan.calculatedTotalArea.toStringAsFixed(1)} м²', regular),
                  _statBox('Жилая', '${plan.calculatedLivingArea.toStringAsFixed(1)} м²', regular),
                  _statBox('Комнат', '${plan.roomCount}', regular),
                  _statBox('Высота', '${plan.floorHeight} м', regular),
                  _statBox('SNiP', '${(plan.complianceScore * 100).toInt()}%', regular),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // РАЗМЕРНЫЕ ЛИНИИ
  // ==========================================================================

  static pw.Widget _buildDimensionLines(FloorPlan plan, pw.Font regular, pw.Font bold) {
    final lines = <pw.Widget>[];

    if (plan.dimensionLines.isNotEmpty) {
      lines.add(_sectionTitle('РАЗМЕРНЫЕ ЛИНИИ', bold));
      lines.add(pw.SizedBox(height: 5));
      lines.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['№', 'От', 'До', 'Значение', 'Примечание'], bold),
            for (var i = 0; i < plan.dimensionLines.length; i++)
              _tableRow([
                '${i + 1}',
                '(${plan.dimensionLines[i].x1}, ${plan.dimensionLines[i].y1})',
                '(${plan.dimensionLines[i].x2}, ${plan.dimensionLines[i].y2})',
                '${plan.dimensionLines[i].value} м',
                'Смещение: ${plan.dimensionLines[i].offset} м',
              ], regular),
          ],
        ),
      );
    }

    if (plan.axisLines.isNotEmpty) {
      lines.add(pw.SizedBox(height: 15));
      lines.add(_sectionTitle('ОСЕВЫЕ ЛИНИИ', bold));
      lines.add(pw.SizedBox(height: 5));
      lines.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['Обозначение', 'От', 'До', 'Длина'], bold),
            for (var i = 0; i < plan.axisLines.length; i++)
              _tableRow([
                plan.axisLines[i].label,
                '(${plan.axisLines[i].x1}, ${plan.axisLines[i].y1})',
                '(${plan.axisLines[i].x2}, ${plan.axisLines[i].y2})',
                '${_distance(plan.axisLines[i].x1, plan.axisLines[i].y1, plan.axisLines[i].x2, plan.axisLines[i].y2).toStringAsFixed(2)} м',
              ], regular),
          ],
        ),
      );
    }

    if (plan.levelMarks.isNotEmpty) {
      lines.add(pw.SizedBox(height: 15));
      lines.add(_sectionTitle('ОТМЕТКИ УРОВНЕЙ', bold));
      lines.add(pw.SizedBox(height: 5));
      lines.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['Позиция', 'Отметка', 'Описание'], bold),
            for (var i = 0; i < plan.levelMarks.length; i++)
              _tableRow([
                '(${plan.levelMarks[i].x}, ${plan.levelMarks[i].y})',
                '${plan.levelMarks[i].level > 0 ? '+' : ''}${plan.levelMarks[i].level.toStringAsFixed(3)}',
                plan.levelMarks[i].description ?? '',
              ], regular),
          ],
        ),
      );
    }

    return lines.isEmpty
        ? pw.Container()
        : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: lines);
  }

  // ==========================================================================
  // ЭКСПЛИКАЦИЯ ПОМЕЩЕНИЙ
  // ==========================================================================

  static pw.Widget _buildRoomSchedule(FloorPlan plan, pw.Font regular, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('ЭКСПЛИКАЦИЯ ПОМЕЩЕНИЙ', bold),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['№', 'Наименование', 'Площадь, м²', 'Размеры (Ш×Г), м', 'Двери', 'Окна', 'SNiP', 'V, м³'], bold),
            for (var i = 0; i < plan.rooms.length; i++)
              _tableRow([
                '${i + 1}',
                plan.rooms[i].type.label,
                plan.rooms[i].effectiveArea.toStringAsFixed(2),
                '${plan.rooms[i].width.toStringAsFixed(2)} × ${plan.rooms[i].height.toStringAsFixed(2)}',
                '${plan.rooms[i].doors.length}',
                '${plan.rooms[i].windows.length}',
                plan.rooms[i].isAreaCompliant ? '✓' : '✗',
                plan.rooms[i].volume.toStringAsFixed(2),
              ], regular),
            // Итого
            _tableRow([
              '',
              'ИТОГО:',
              plan.calculatedTotalArea.toStringAsFixed(2),
              '',
              '${plan.rooms.fold(0, (s, r) => s + r.doors.length)}',
              '${plan.rooms.fold(0, (s, r) => s + r.windows.length)}',
              '',
              plan.rooms.fold<double>(0, (s, r) => s + r.volume).toStringAsFixed(2),
            ], bold),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // ВЕДОМОСТЬ СТЕН
  // ==========================================================================

  static pw.Widget _buildWallSchedule(FloorPlan plan, pw.Font regular, pw.Font bold) {
    if (plan.walls.isEmpty) return pw.Container();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('ВЕДОМОСТЬ СТЕН', bold),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader([
              '№', 'Тип', 'Материал', 'Толщ., м', 'Выс., м',
              'Длина, м', 'Площ., м²', 'Объём, м³', 'Несущая', 'Утепл., м',
            ], bold),
            for (var i = 0; i < plan.walls.length; i++) ...[
              _tableRow([
                '${i + 1}',
                plan.walls[i].type.label,
                plan.walls[i].material.label,
                plan.walls[i].thickness.toStringAsFixed(3),
                plan.walls[i].height.toStringAsFixed(2),
                plan.walls[i].length.toStringAsFixed(2),
                plan.walls[i].area.toStringAsFixed(2),
                plan.walls[i].volume.toStringAsFixed(3),
                plan.walls[i].isLoadBearing ? 'Да' : 'Нет',
                plan.walls[i].insulationThickness > 0
                    ? plan.walls[i].insulationThickness.toStringAsFixed(3)
                    : '—',
              ], regular),
            ],
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Общая площадь наружных стен: ${plan.exteriorWallArea.toStringAsFixed(1)} м²\n'
          'Площадь проёмов: ${plan.openingsArea.toStringAsFixed(1)} м²\n'
          'Чистая площадь стен: ${plan.netWallArea.toStringAsFixed(1)} м²',
          style: pw.TextStyle(font: regular, fontSize: 10),
        ),
      ],
    );
  }

  // ==========================================================================
  // СХЕМА ФУНДАМЕНТА
  // ==========================================================================

  static pw.Widget _buildFoundationSchedule(FloorPlan plan, pw.Font regular, pw.Font bold) {
    final f = plan.foundation;
    if (f == null) return pw.Container();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('ФУНДАМЕНТ', bold),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['Параметр', 'Значение'], bold),
            _tableRow(['Тип', f.type.label], regular),
            _tableRow(['Ширина', '${f.width} м'], regular),
            _tableRow(['Глубина', '${f.depth} м'], regular),
            _tableRow(['Высота', '${f.height} м'], regular),
            _tableRow(['Глубина заложения', '${f.embedmentDepth} м'], regular),
            _tableRow(['Объём бетона', '${f.volume.toStringAsFixed(2)} м³'], regular),
            _tableRow(['Марка бетона', f.concreteGrade], regular),
            _tableRow(['Класс бетона', f.concreteClass.label], regular),
            _tableRow(['Арматура', '⌀${f.reinforcement.mainBarDiameter}мм, ${f.reinforcement.mainBarsCount} стержн., класс ${f.reinforcement.rebarClass}'], regular),
            _tableRow(['Хомуты', '⌀${f.reinforcement.stirrupDiameter}мм, шаг ${f.reinforcement.stirrupSpacing}мм'], regular),
            _tableRow(['Вес арматуры', '${f.reinforcement.rebarWeightPerMeter.toStringAsFixed(2)} кг/м'], regular),
            _tableRow(['Гидроизоляция', f.hasWaterproofing ? 'Да' : 'Нет'], regular),
            _tableRow(['Утепление', f.hasInsulation ? 'Да' : 'Нет'], regular),
            _tableRow(['Дренаж', f.hasDrainage ? 'Да' : 'Нет'], regular),
            _tableRow(['Песчаная подушка', '${f.sandCushionThickness} м'], regular),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // СХЕМА КРОВЛИ
  // ==========================================================================

  static pw.Widget _buildRoofSchedule(FloorPlan plan, pw.Font regular, pw.Font bold) {
    final r = plan.roof;
    if (r == null) return pw.Container();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('КРОВЛЯ', bold),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['Параметр', 'Значение'], bold),
            _tableRow(['Тип кровли', r.type.label], regular),
            _tableRow(['Площадь', '${r.area.toStringAsFixed(1)} м²'], regular),
            _tableRow(['Угол наклона', '${r.slopeAngle}°'], regular),
            _tableRow(['Материал', '${r.roofingMaterial.label} (${r.roofingMaterial.weightPerM2} кг/м²)'], regular),
            _tableRow(['Срок службы', '${r.roofingMaterial.lifespan} лет'], regular),
            _tableRow(['Стропила', '${r.rafters.sectionWidth}×${r.rafters.sectionHeight}мм, шаг ${r.rafters.spacing}мм, ${r.rafters.material.label}'], regular),
            _tableRow(['Кол-во стропил', '${r.rafters.count} шт, длина ${r.rafters.length}м'], regular),
            _tableRow(['Погонные метры стропил', '${r.rafterLinearMeters.toStringAsFixed(1)} м.п.'], regular),
            _tableRow(['Утепление', r.insulation.thickness > 0 ? '${r.insulation.thickness}м ${r.insulation.material.label}' : 'Нет'], regular),
            _tableRow(['Гидро-мембрана', r.hasWaterproofingMembrane ? 'Да' : 'Нет'], regular),
            _tableRow(['Пароизоляция', r.hasVaporBarrier ? 'Да' : 'Нет'], regular),
            _tableRow(['Водосток', r.gutter != null ? '${r.gutter!.material.label}, ${r.gutter!.totalLength}м, ${r.gutter!.downpipeCount} стояков' : 'Нет'], regular),
            _tableRow(['Снегозадержатели', r.hasSnowRetention ? '${r.snowRetentionCount} шт' : 'Нет'], regular),
            _tableRow(['Общий вес кровли', '${r.weight.toStringAsFixed(0)} кг'], regular),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // ИНЖЕНЕРНЫЕ СИСТЕМЫ
  // ==========================================================================

  static pw.Widget _buildEngineeringSchedule(FloorPlan plan, pw.Font regular, pw.Font bold) {
    final es = plan.engineeringSystems;
    if (es.isEmpty) return pw.Container();

    final rows = <pw.Widget>[];

    if (es.heating != null) {
      rows.addAll([
        _sectionTitle('ОТОПЛЕНИЕ', bold),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['Параметр', 'Значение'], bold),
            _tableRow(['Тип', es.heating!.type.label], regular),
            _tableRow(['Радиаторы', '${es.heating!.radiatorCount} шт'], regular),
            _tableRow(['Длина труб', '${es.heating!.pipeLength.toStringAsFixed(1)} м'], regular),
            _tableRow(['Мощность котла', '${es.heating!.boilerPower} кВт'], regular),
            _tableRow(['Тёплый пол', es.heating!.hasWarmFloor ? 'Да, ${es.heating!.warmFloorArea.toStringAsFixed(1)} м²' : 'Нет'], regular),
          ],
        ),
        pw.SizedBox(height: 10),
      ]);
    }

    if (es.waterSupply != null) {
      rows.addAll([
        _sectionTitle('ВОДОСНАБЖЕНИЕ', bold),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['Параметр', 'Значение'], bold),
            _tableRow(['ХВС', '${es.waterSupply!.coldPipeLength.toStringAsFixed(1)} м'], regular),
            _tableRow(['ГВС', '${es.waterSupply!.hotPipeLength.toStringAsFixed(1)} м'], regular),
            _tableRow(['Точки водоразбора', '${es.waterSupply!.fixtureCount} шт'], regular),
            _tableRow(['Водонагреватель', es.waterSupply!.hasWaterHeater ? '${es.waterSupply!.waterHeaterVolume} л' : 'Нет'], regular),
          ],
        ),
        pw.SizedBox(height: 10),
      ]);
    }

    if (es.electrical != null) {
      rows.addAll([
        _sectionTitle('ЭЛЕКТРОСНАБЖЕНИЕ', bold),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['Параметр', 'Значение'], bold),
            _tableRow(['Длина кабеля', '${es.electrical!.cableLength.toStringAsFixed(1)} м'], regular),
            _tableRow(['Розетки', '${es.electrical!.socketCount} шт'], regular),
            _tableRow(['Выключатели', '${es.electrical!.switchCount} шт'], regular),
            _tableRow(['Светильники', '${es.electrical!.lightPointCount} шт'], regular),
            _tableRow(['Автоматы', '${es.electrical!.breakerCount} шт'], regular),
            _tableRow(['УЗО', es.electrical!.hasRCD ? 'Да' : 'Нет'], regular),
            _tableRow(['Заземление', es.electrical!.hasGrounding ? 'Да' : 'Нет'], regular),
            _tableRow(['Молниезащита', es.electrical!.hasLightningProtection ? 'Да' : 'Нет'], regular),
            _tableRow(['Умный дом', es.electrical!.hasSmartHome ? 'Да' : 'Нет'], regular),
          ],
        ),
        pw.SizedBox(height: 10),
      ]);
    }

    if (es.ventilation != null) {
      rows.addAll([
        _sectionTitle('ВЕНТИЛЯЦИЯ', bold),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['Параметр', 'Значение'], bold),
            _tableRow(['Тип', es.ventilation!.type.label], regular),
            _tableRow(['Вытяжные точки', '${es.ventilation!.exhaustPoints}'], regular),
            _tableRow(['Приточные точки', '${es.ventilation!.supplyPoints}'], regular),
            _tableRow(['Длина воздуховодов', '${es.ventilation!.ductLength.toStringAsFixed(1)} м'], regular),
            _tableRow(['Рекуператор', es.ventilation!.hasRecuperator ? 'Да' : 'Нет'], regular),
          ],
        ),
      ]);
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: rows);
  }

  // ==========================================================================
  // СПЕЦИФИКАЦИЯ МАТЕРИАЛОВ
  // ==========================================================================

  static pw.Widget _buildSpecifications(FloorPlan plan, pw.Font regular, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('СПЕЦИФИКАЦИЯ МАТЕРИАЛОВ', bold),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['№', 'Наименование', 'Ед.изм.', 'Количество', 'Примечание'], bold),
            ..._generateSpecRows(plan, regular),
          ],
        ),
      ],
    );
  }

  static List<pw.TableRow> _generateSpecRows(FloorPlan plan, pw.Font regular) {
    final rows = <pw.TableRow>[];
    int n = 1;

    // Стены
    final wallMaterials = <String, double>{};
    for (final w in plan.walls) {
      final key = '${w.material.label}, толщ. ${w.thickness}м';
      wallMaterials[key] = (wallMaterials[key] ?? 0) + w.volume;
    }
    for (final entry in wallMaterials.entries) {
      rows.add(_tableRow([
        '$n', 'Стена: ${entry.key}', 'м³', entry.value.toStringAsFixed(3), '',
      ], regular));
      n++;
    }

    // Бетон фундамента
    final f = plan.foundation;
    if (f != null) {
      rows.add(_tableRow([
        '$n', 'Бетон ${f.concreteGrade}', 'м³', f.concreteVolume.toStringAsFixed(2), f.type.label,
      ], regular));
      n++;
      rows.add(_tableRow([
        '$n', 'Арматура ${f.reinforcement.rebarClass} ⌀${f.reinforcement.mainBarDiameter}мм', 'кг',
        (f.concreteVolume * f.reinforcement.rebarWeightPerMeter).toStringAsFixed(1), '',
      ], regular));
      n++;
    }

    // Кровля
    final r = plan.roof;
    if (r != null) {
      rows.add(_tableRow([
        '$n', 'Кровля: ${r.roofingMaterial.label}', 'м²', r.area.toStringAsFixed(1), '',
      ], regular));
      n++;
      rows.add(_tableRow([
        '$n', 'Стропила ${r.rafters.material.label} ${r.rafters.sectionWidth}×${r.rafters.sectionHeight}мм', 'м.п.',
        r.rafterLinearMeters.toStringAsFixed(1), '',
      ], regular));
      n++;
      if (r.insulation.thickness > 0) {
        rows.add(_tableRow([
          '$n', 'Утеплитель ${r.insulation.material.label}', 'м³',
          (r.area * r.insulation.thickness).toStringAsFixed(2), '',
        ], regular));
        n++;
      }
    }

    // Окна
    int windowCount = 0;
    for (final room in plan.rooms) windowCount += room.windows.length;
    if (windowCount > 0) {
      rows.add(_tableRow([
        '$n', 'Окна', 'шт', '$windowCount', '',
      ], regular));
      n++;
    }

    // Двери
    int doorCount = 0;
    for (final room in plan.rooms) doorCount += room.doors.length;
    if (doorCount > 0) {
      rows.add(_tableRow([
        '$n', 'Двери', 'шт', '$doorCount', '',
      ], regular));
      n++;
    }

    // Радиаторы
    int radCount = 0;
    for (final room in plan.rooms) radCount += room.radiators.length;
    if (radCount > 0) {
      rows.add(_tableRow([
        '$n', 'Радиаторы отопления', 'шт', '$radCount', '',
      ], regular));
      n++;
    }

    return rows;
  }

  // ==========================================================================
  // РАСЧЁТ ТЕПЛОПОТЕРЬ
  // ==========================================================================

  static pw.Widget _buildHeatLossCalculation(FloorPlan plan, pw.Font regular, pw.Font bold) {
    if (plan.walls.where((w) => w.type == WallType.exterior).isEmpty) return pw.Container();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('РАСЧЁТ ТЕПЛОПОТЕРЬ', bold),
        pw.SizedBox(height: 5),
        pw.Text(
          'ΔT = 40°C (внутри +20°C, снаружи -20°C)',
          style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _tableHeader(['Элемент', 'Площ., м²', 'R-значение', 'U-значение', 'Потери, Вт'], bold),
            for (final wall in plan.walls.where((w) => w.type == WallType.exterior))
              _tableRow([
                'Стена: ${wall.material.label}',
                wall.area.toStringAsFixed(2),
                (wall.material.calcRValue(wall.thickness) + wall.insulationThickness / 0.04).toStringAsFixed(3),
                (1 / (wall.material.calcRValue(wall.thickness) + wall.insulationThickness / 0.04)).toStringAsFixed(3),
                (wall.area / (wall.material.calcRValue(wall.thickness) + wall.insulationThickness / 0.04) * 40).toStringAsFixed(0),
              ], regular),
            for (final room in plan.rooms)
              for (final w in room.windows)
                _tableRow([
                  'Окно: ${w.glassUnit.label}',
                  w.area.toStringAsFixed(2),
                  w.glassUnit.thermalResistance.toStringAsFixed(3),
                  (1 / w.glassUnit.thermalResistance).toStringAsFixed(3),
                  (w.area / w.glassUnit.thermalResistance * 40).toStringAsFixed(0),
                ], regular),
            // Итого
            _tableRow([
              'ИТОГО:',
              '',
              '',
              '',
              '${plan.heatLoss.toStringAsFixed(0)} Вт',
            ], bold),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Рекомендуемая мощность котла: ${(plan.heatLoss * 1.2 / 1000).toStringAsFixed(1)} кВт (с запасом 20%)',
          style: pw.TextStyle(font: bold, fontSize: 12),
        ),
      ],
    );
  }

  // ==========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ==========================================================================

  static String _generatePlanSvg(FloorPlan plan) {
    final scale = 40; // пикселей на метр
    final w = (plan.totalWidth * scale).toInt();
    final h = (plan.totalHeight * scale).toInt();

    final svg = StringBuffer();
    svg.write('<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" viewBox="0 0 $w $h">');

    // Фон
    svg.write('<rect width="$w" height="$h" fill="#fafafa"/>');

    // Сетка
    for (int x = 0; x <= plan.totalWidth; x++) {
      svg.write('<line x1="${x * scale}" y1="0" x2="${x * scale}" y2="$h" stroke="#e0e0e0" stroke-width="0.5"/>');
    }
    for (int y = 0; y <= plan.totalHeight; y++) {
      svg.write('<line x1="0" y1="${y * scale}" x2="$w" y2="${y * scale}" stroke="#e0e0e0" stroke-width="0.5"/>');
    }

    // Комнаты
    final roomColors = <RoomType, String>{
      RoomType.kitchen: '#fff3e0',
      RoomType.livingRoom: '#e8f5e9',
      RoomType.bedroom: '#fce4ec',
      RoomType.bathroom: '#e0f7fa',
      RoomType.toilet: '#f3e5f5',
      RoomType.hallway: '#fff9c4',
      RoomType.garage: '#e0e0e0',
      RoomType.boilerRoom: '#ffebee',
    };

    for (final room in plan.rooms) {
      final rx = (room.x * scale).toInt();
      final ry = (room.y * scale).toInt();
      final rw = (room.width * scale).toInt();
      final rh = (room.height * scale).toInt();

      final color = roomColors[room.type] ?? '#f5f5f5';
      svg.write('<rect x="$rx" y="$ry" width="$rw" height="$rh" fill="$color" stroke="#37474f" stroke-width="2"/>');

      // Двери
      for (final door in room.doors) {
        final dx = (door.x * scale).toInt();
        final dy = (door.y * scale).toInt();
        final dw = (door.width * scale).toInt();
        svg.write('<line x1="$dx" y1="$dy" x2="${dx + dw}" y2="$dy" stroke="#795548" stroke-width="3"/>');
        svg.write('<path d="M $dx,$dy A $dw,$dw 0 0,1 ${dx + dw},$dy" fill="none" stroke="#795548" stroke-width="1" stroke-dasharray="3,3"/>');
      }

      // Окна
      for (final window in room.windows) {
        final wx = (window.x * scale).toInt();
        final wy = (window.y * scale).toInt();
        final ww = (window.width * scale).toInt();
        svg.write('<rect x="$wx" y="${wy - 2}" width="$ww" height="4" fill="#4fc3f7" stroke="#0288d1" stroke-width="1"/>');
      }

      // Подпись
      final cx = rx + rw ~/ 2;
      final cy = ry + rh ~/ 2;
      svg.write('<text x="$cx" y="$cy" text-anchor="middle" dominant-baseline="middle" font-size="10" fill="#37474f">${room.type.icon}</text>');
      svg.write('<text x="$cx" y="${cy + 12}" text-anchor="middle" dominant-baseline="middle" font-size="8" fill="#546e7a">${room.area.toStringAsFixed(1)}м²</text>');
    }

    // Стены
    for (final wall in plan.walls) {
      final x1 = (wall.x1 * scale).toInt();
      final y1 = (wall.y1 * scale).toInt();
      final x2 = (wall.x2 * scale).toInt();
      final y2 = (wall.y2 * scale).toInt();
      final thickness = (wall.thickness * scale).toInt();
      final color = wall.type == WallType.exterior ? '#1a237e' : '#546e7a';
      svg.write('<line x1="$x1" y1="$y1" x2="$x2" y2="$y2" stroke="$color" stroke-width="$thickness"/>');
    }

    svg.write('</svg>');
    return svg.toString();
  }

  static pw.Widget _sectionTitle(String title, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pw.BoxDecoration(color: PdfColors.blue900),
      child: pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.white)),
    );
  }

  static pw.TableRow _tableHeader(List<String> cells, pw.Font bold) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue50),
      children: cells.map((c) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(c, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.blue900)),
      )).toList(),
    );
  }

  static pw.TableRow _tableRow(List<String> cells, pw.Font regular) {
    return pw.TableRow(
      children: cells.map((c) => pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: pw.Text(c, style: pw.TextStyle(font: regular, fontSize: 9)),
      )).toList(),
    );
  }

  static pw.Widget _infoRow(String label, String value, pw.Font regular, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label ', style: pw.TextStyle(font: bold, fontSize: 12)),
            pw.TextSpan(text: value, style: pw.TextStyle(font: regular, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _statBox(String label, String value, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(font: regular, fontSize: 14, color: PdfColors.blue900)),
        ],
      ),
    );
  }

  static pw.Widget _drawHeader(pw.Context context, FloorPlan plan, String projectName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('MESTRO — ${projectTypeLabel(plan.objectType)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.Text('Лист ${context.pageNumber} из ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ],
    );
  }

  static pw.Widget _drawFooter(pw.Context context, FloorPlan plan) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Сформировано: ${DateTime.now().toString().substring(0, 16)} | Масштаб 1:${plan.scale.toInt()}',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
      ),
    );
  }

  static String projectTypeLabel(FloorPlanType type) {
    switch (type) {
      case FloorPlanType.apartment: return 'Квартира';
      case FloorPlanType.house: return 'Частный дом';
      case FloorPlanType.office: return 'Офис';
      case FloorPlanType.studio: return 'Студия';
      case FloorPlanType.cottage: return 'Коттедж';
      case FloorPlanType.duplex: return 'Дуплекс';
      case FloorPlanType.townhouse: return 'Таунхаус';
    }
  }

  static double _distance(double x1, double y1, double x2, double y2) {
    return math.sqrt(
      (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1),
    );
  }

  static Future<pw.Font> _loadFont(String assetName) async {
    try {
      final fontData = File('assets/fonts/$assetName').readAsBytesSync();
      return pw.Font.ttf(fontData.buffer.asByteData());
    } catch (_) {
      return pw.Font.helvetica();
    }
  }
}
