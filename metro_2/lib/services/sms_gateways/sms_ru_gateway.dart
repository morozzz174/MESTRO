import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sms_gateway_provider.dart';

/// SMS.RU — https://sms.ru/
/// Документация: https://sms.ru/api/doc
class SmsRuGateway implements SmsGatewayProvider {
  static const _baseUrl = 'https://sms.ru/sms/send';
  final String apiKey;

  SmsRuGateway({required this.apiKey});

  @override
  Future<SmsResult> sendSMS({
    required String phone,
    required String message,
  }) async {
    try {
      // Убираем всё кроме цифр
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'api_id': apiKey,
        'to': cleanPhone,
        'msg': message,
        'json': '1',
      });

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return SmsResult.fail('HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final smsId = data['sms']?.first?['sms_id'] as String?;
        return SmsResult.ok(messageId: smsId);
      } else {
        final errorText = data['error'] ?? data['status_text'] ?? 'Неизвестная ошибка';
        return SmsResult.fail(errorText);
      }
    } catch (e) {
      return SmsResult.fail('Ошибка: $e');
    }
  }
}
