import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/order.dart';

class PdfGenerator {
  static Future<File> generateProposal(Order order) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Заголовок
          pw.Header(
            level: 0,
            child: pw.Text(
              'Коммерческое предложение',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 20),

          // Информация о заявке
          pw.Text(
            'Информация о заявке',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Клиент:', order.clientName),
          _buildInfoRow('Адрес:', order.address),
          _buildInfoRow('Дата:', dateFormat.format(order.date)),
          _buildInfoRow('Тип работ:', order.workType.title),
          _buildInfoRow('Статус:', order.status.label),

          pw.SizedBox(height: 20),

          // Замеры
          pw.Text(
            'Результаты замера',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...order.checklistData.entries.map(
            (e) => _buildInfoRow('${e.key}:', e.value.toString()),
          ),

          pw.SizedBox(height: 20),

          // Стоимость
          if (order.estimatedCost != null) ...[
            pw.Text(
              'Итоговая стоимость',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
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
                    ),
                  ),
                  pw.Text(
                    currencyFormat.format(order.estimatedCost),
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // Фото
          if (order.photos.isNotEmpty) ...[
            pw.Text(
              'Фотофиксация',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
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
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Дата: ${dateFormat.format(photo.timestamp)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (photo.latitude != null)
                    pw.Text(
                      'Координаты: ${photo.latitude}, ${photo.longitude}',
                      style: const pw.TextStyle(fontSize: 10),
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

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
