import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Сервис для работы с API ucaller.ru
class UCallerService {
  static const String _baseUrl = 'https://api.ucaller.ru';

  /// ID сервиса из личного кабинета ucaller
  final int serviceId;

  /// Секретный ключ сервиса из личного кабинета ucaller
  final String secretKey;

  UCallerService({required this.serviceId, required this.secretKey});

  /// =====================
  /// InitCall — инициализация звонка
  /// POST https://api.ucaller.ru/initCall
  /// Аутентификация: JSON body с key + service_id
  /// =====================
  Future<ResponseInitCall> initCall({
    required String phone,
    int? code,
    String? client,
    String? unique,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    final body = <String, dynamic>{
      'phone': int.parse(cleanPhone),
      'key': secretKey,
      'service_id': serviceId.toString(),
    };

    if (code != null) body['code'] = code;
    if (client != null) body['client'] = client;
    if (unique != null) body['unique'] = unique;

    final url = '$_baseUrl/initCall';
    debugPrint('[uCaller] POST $url');
    debugPrint('[uCaller] Body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    debugPrint('[uCaller] Response: ${response.statusCode} ${response.body}');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ResponseInitCall.fromJson(json);
  }

  /// =====================
  /// InitRepeat — бесплатный повтор звонка
  /// POST https://api.ucaller.ru/initRepeat
  /// =====================
  Future<ResponseInitRepeat> initRepeat(int ucallerId) async {
    final body = {
      'ucaller_id': ucallerId,
      'key': secretKey,
      'service_id': serviceId.toString(),
    };

    final url = '$_baseUrl/initRepeat';
    debugPrint('[uCaller] POST $url');
    debugPrint('[uCaller] Body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    debugPrint('[uCaller] Response: ${response.statusCode} ${response.body}');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ResponseInitRepeat.fromJson(json);
  }

  /// =====================
  /// GetInfo — проверка статуса звонка и кода
  /// GET https://api.ucaller.ru/getInfo?key=X&service_id=Y&ucaller_id=Z
  /// =====================
  Future<ResponseInfo> getInfo(int ucallerId) async {
    final url =
        '$_baseUrl/getInfo?key=$secretKey&service_id=$serviceId&ucaller_id=$ucallerId';
    debugPrint('[uCaller] GET $url');

    final response = await http.get(Uri.parse(url));

    debugPrint('[uCaller] Response: ${response.statusCode} ${response.body}');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ResponseInfo.fromJson(json);
  }

  /// =====================
  /// GetBalance — остаток на счёте
  /// GET https://api.ucaller.ru/getBalance?key=X&service_id=Y
  /// =====================
  Future<ResponseBalance> getBalance() async {
    final url = '$_baseUrl/getBalance?key=$secretKey&service_id=$serviceId';
    debugPrint('[uCaller] GET $url');

    final response = await http.get(Uri.parse(url));

    debugPrint('[uCaller] Response: ${response.statusCode} ${response.body}');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ResponseBalance.fromJson(json);
  }
}

// ===== Структуры ответов =====

class ResponseInitCall {
  final bool status;
  final int? ucallerId;
  final String? phone;
  final dynamic code;
  final String? client;
  final String? uniqueRequestId;
  final bool exists;
  final String? error;

  ResponseInitCall({
    required this.status,
    this.ucallerId,
    this.phone,
    this.code,
    this.client,
    this.uniqueRequestId,
    this.exists = false,
    this.error,
  });

  factory ResponseInitCall.fromJson(Map<String, dynamic> json) {
    return ResponseInitCall(
      status: json['status'] as bool? ?? false,
      ucallerId: json['ucaller_id'] != null
          ? int.tryParse(json['ucaller_id'].toString())
          : null,
      phone: json['phone']?.toString(),
      code: json['code'],
      client: json['client'] as String?,
      uniqueRequestId: json['unique_request_id']?.toString(),
      exists: json['exists'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }

  bool get hasError => error != null && error!.isNotEmpty;
}

class ResponseInitRepeat {
  final bool status;
  final int? ucallerId;
  final String? phone;
  final dynamic code;
  final String? client;
  final String? uniqueRequestId;
  final bool exists;
  final bool freeRepeated;
  final String? error;

  ResponseInitRepeat({
    required this.status,
    this.ucallerId,
    this.phone,
    this.code,
    this.client,
    this.uniqueRequestId,
    this.exists = false,
    this.freeRepeated = false,
    this.error,
  });

  factory ResponseInitRepeat.fromJson(Map<String, dynamic> json) {
    return ResponseInitRepeat(
      status: json['status'] as bool? ?? false,
      ucallerId: json['ucaller_id'] != null
          ? int.tryParse(json['ucaller_id'].toString())
          : null,
      phone: json['phone']?.toString(),
      code: json['code'],
      client: json['client'] as String?,
      uniqueRequestId: json['unique_request_id']?.toString(),
      exists: json['exists'] as bool? ?? false,
      freeRepeated: json['free_repeated'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }

  bool get hasError => error != null && error!.isNotEmpty;
}

class ResponseInfo {
  final bool status;
  final int? ucallerId;
  final int? initTime;

  /// Статус звонка: -1 — проверка, 0 — неудача, 1 — дозвон
  final int callStatus;
  final bool isRepeated;
  final bool repeatable;
  final int repeatTimes;
  final List<int> repeatedUids;
  final String? unique;
  final String? client;
  final String? phone;

  /// Код верификации (приходит после дозвона)
  final int? code;
  final String? countryCode;
  final String? countryImage;
  final List<PhoneInfo> phoneInfo;
  final double? cost;
  final String? error;

  ResponseInfo({
    required this.status,
    this.ucallerId,
    this.initTime,
    this.callStatus = -1,
    this.isRepeated = false,
    this.repeatable = false,
    this.repeatTimes = 0,
    this.repeatedUids = const [],
    this.unique,
    this.client,
    this.phone,
    this.code,
    this.countryCode,
    this.countryImage,
    this.phoneInfo = const [],
    this.cost,
    this.error,
  });

  factory ResponseInfo.fromJson(Map<String, dynamic> json) {
    final phoneInfoList = json['phone_info'] as List?;
    final phoneInfo = phoneInfoList != null
        ? phoneInfoList
              .map((e) => PhoneInfo.fromJson(e as Map<String, dynamic>))
              .toList()
        : <PhoneInfo>[];

    return ResponseInfo(
      status: json['status'] as bool? ?? false,
      ucallerId: json['ucaller_id'] != null
          ? int.tryParse(json['ucaller_id'].toString())
          : null,
      initTime: json['init_time'] != null
          ? int.tryParse(json['init_time'].toString())
          : null,
      callStatus: json['call_status'] != null
          ? (json['call_status'] as num).toInt()
          : -1,
      isRepeated: json['is_repeated'] as bool? ?? false,
      repeatable: json['repeatable'] as bool? ?? false,
      repeatTimes: json['repeat_times'] != null
          ? (json['repeat_times'] as num).toInt()
          : 0,
      repeatedUids:
          (json['repeated_ucaller_ids'] as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [],
      unique: json['unique']?.toString(),
      client: json['client'] as String?,
      phone: json['phone']?.toString(),
      code: json['code'] != null ? int.tryParse(json['code'].toString()) : null,
      countryCode: json['country_code'] as String?,
      countryImage: json['country_image'] as String?,
      phoneInfo: phoneInfo,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      error: json['error'] as String?,
    );
  }

  /// Дозвонился ли оператор до пользователя
  bool get isCallSuccessful => callStatus == 1;

  bool get hasError => error != null && error!.isNotEmpty;
}

class PhoneInfo {
  final String? operator;
  final String? region;
  final String? mnp;

  PhoneInfo({this.operator, this.region, this.mnp});

  factory PhoneInfo.fromJson(Map<String, dynamic> json) {
    return PhoneInfo(
      operator: json['operator'] as String?,
      region: json['region'] as String?,
      mnp: json['mnp'] as String?,
    );
  }
}

class ResponseBalance {
  final bool status;
  final double? rubBalance;
  final double? bonusBalance;
  final String? tariff;
  final String? tariffName;
  final String? error;

  ResponseBalance({
    required this.status,
    this.rubBalance,
    this.bonusBalance,
    this.tariff,
    this.tariffName,
    this.error,
  });

  factory ResponseBalance.fromJson(Map<String, dynamic> json) {
    return ResponseBalance(
      status: json['status'] as bool? ?? false,
      rubBalance: json['rub_balance'] != null
          ? (json['rub_balance'] as num).toDouble()
          : null,
      bonusBalance: json['bonus_balance'] != null
          ? (json['bonus_balance'] as num).toDouble()
          : null,
      tariff: json['tariff'] as String?,
      tariffName: json['tariff_name'] as String?,
      error: json['error'] as String?,
    );
  }
}
