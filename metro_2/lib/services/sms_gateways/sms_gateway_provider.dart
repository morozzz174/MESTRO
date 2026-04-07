/// Интерфейс SMS-шлюза
abstract class SmsGatewayProvider {
  Future<SmsResult> sendSMS({
    required String phone,
    required String message,
  });
}

class SmsResult {
  final bool success;
  final String? messageId;
  final String? error;

  SmsResult({required this.success, this.messageId, this.error});

  factory SmsResult.ok({String? messageId}) {
    return SmsResult(success: true, messageId: messageId);
  }

  factory SmsResult.fail(String error) {
    return SmsResult(success: false, error: error);
  }
}
