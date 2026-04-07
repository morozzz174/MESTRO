import 'dart:convert';
import 'package:http/http.dart' as http;

/// Сервис для работы с API ucaller.ru
class UCallerService {
  static const String _baseUrl = 'https://api.ucaller.ru/v1.0';

  /// ID сервиса из личного кабинета ucaller
  final int serviceId;

  /// Секретный ключ сервиса из личного кабинета ucaller
  final String secretKey;

  UCallerService({
    required this.serviceId,
    required this.secretKey,
  });

  /// Формирует URL для запроса
  String _buildUrl(String method) {
    return '$_baseUrl/$method?serviceId=$serviceId&secretKey=$secretKey';
  }

  /// =====================
  /// InitCall — инициализация звонка
  /// =====================
  Future<ResponseInitCall> initCall({
    required String phone,
    int? code,
    String? client,
    String? unique,
  }) async {
    // phone — номер без '+'
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    final body = <String, dynamic>{
      'phone': int.parse(cleanPhone),
    };

    if (code != null) body['code'] = code;
    if (client != null) body['client'] = client;
    if (unique != null) body['unique'] = unique;

    final url = _buildUrl('initCall');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ResponseInitCall.fromJson(json);
  }

  /// =====================
  /// InitRepeat — бесплатный повтор звонка
  /// =====================
  Future<ResponseInitRepeat> initRepeat(int ucallerId) async {
    final url = _buildUrl('initRepeat');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ucaller_id': ucallerId}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ResponseInitRepeat.fromJson(json);
  }

  /// =====================
  /// GetInfo — проверка статуса звонка и кода
  /// =====================
  Future<ResponseInfo> getInfo(int ucallerId) async {
    final url = _buildUrl('getInfo');

    final response = await http.get(
      Uri.parse('$url&ucaller_id=$ucallerId'),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ResponseInfo.fromJson(json);
  }

  /// =====================
  /// GetBalance — остаток на счёте
  /// =====================
  Future<ResponseBalance> getBalance() async {
    final url = _buildUrl('getBalance');

    final response = await http.get(Uri.parse(url));

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
      repeatedUids: (json['repeated_ucaller_ids'] as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [],
      unique: json['unique']?.toString(),
      client: json['client'] as String?,
      phone: json['phone']?.toString(),
      code: json['code'] != null
          ? int.tryParse(json['code'].toString())
          : null,
      countryCode: json['country_code'] as String?,
      countryImage: json['country_image'] as String?,
      phoneInfo: phoneInfo,
      cost: json['cost'] != null
          ? (json['cost'] as num).toDouble()
          : null,
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

  PhoneInfo({
    this.operator,
    this.region,
    this.mnp,
  });

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
