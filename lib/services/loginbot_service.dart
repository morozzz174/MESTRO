import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LoginBotService {
  final String apiToken;
  static const String _baseUrl = 'https://api.loginbot.ru/api/v1';

  LoginBotService({required this.apiToken});

  Future<LoginBotAuthResponse> requestAuth(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final url = '$_baseUrl/$apiToken/call/auth/$cleanPhone';

    debugPrint('[LoginBot] POST $url');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'timeout': 180}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[LoginBot] Response: ${response.statusCode} ${response.body}');

      if (response.statusCode != 200) {
        return LoginBotAuthResponse(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginBotAuthResponse(
        success: true,
        requestId: json['requestId'] as String?,
        callToPhone: json['callToPhone'] as String?,
        timeout: json['timeout'] as int? ?? 180,
      );
    } catch (e) {
      debugPrint('[LoginBot] requestAuth error: $e');
      return LoginBotAuthResponse(success: false, error: e.toString());
    }
  }

  Future<LoginBotStatusResponse> checkStatus(String requestId) async {
    final url = '$_baseUrl/$apiToken/call/status/$requestId';

    debugPrint('[LoginBot] GET $url');

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      debugPrint(
        '[LoginBot] Status response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode != 200) {
        return LoginBotStatusResponse(
          success: false,
          status: 'error',
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginBotStatusResponse(
        success: true,
        status: json['status'] as String? ?? 'error',
        phone: json['phone'] as String?,
      );
    } catch (e) {
      debugPrint('[LoginBot] checkStatus error: $e');
      return LoginBotStatusResponse(
        success: false,
        status: 'error',
        error: e.toString(),
      );
    }
  }
}

class LoginBotAuthResponse {
  final bool success;
  final String? requestId;
  final String? callToPhone;
  final int timeout;
  final String? error;

  LoginBotAuthResponse({
    required this.success,
    this.requestId,
    this.callToPhone,
    this.timeout = 180,
    this.error,
  });
}

class LoginBotStatusResponse {
  final bool success;
  final String status;
  final String? phone;
  final String? error;

  LoginBotStatusResponse({
    required this.success,
    required this.status,
    this.phone,
    this.error,
  });

  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'canceled';
  bool get isError => status == 'error' || !success;
}
