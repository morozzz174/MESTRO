/// Модель пользователя
class User {
  final String id;
  final String phone;
  final String? fullName;
  final DateTime consentDate;
  final String consentVersion;

  /// Выбранные ниши мастера (тип работ)
  final List<String> selectedWorkTypes;

  /// Путь к аватару пользователя
  final String? avatarPath;

  /// Флаг премиум-подписки
  final bool isPremium;

  /// Дата окончания премиум-подписки (null = бессрочно)
  final DateTime? premiumUntil;

  /// Дата активации премиум-подписки
  final DateTime? premiumActivatedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.phone,
    this.fullName,
    required this.consentDate,
    required this.consentVersion,
    this.selectedWorkTypes = const [],
    this.avatarPath,
    this.isPremium = false,
    this.premiumUntil,
    this.premiumActivatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Текущая версия согласия (увеличивается при изменении текста)
  /// Версия 2.0 — обновлены реквизиты Оператора (ИП Морозов М.И.)
  static const String currentConsentVersion = '2.0';

  /// Проверка: активна ли премиум-подписка
  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumUntil == null) return true; // бессрочно
    return premiumUntil!.isAfter(DateTime.now());
  }

  User copyWith({
    String? id,
    String? phone,
    String? fullName,
    DateTime? consentDate,
    String? consentVersion,
    List<String>? selectedWorkTypes,
    String? avatarPath,
    bool? isPremium,
    DateTime? premiumUntil,
    DateTime? premiumActivatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      consentDate: consentDate ?? this.consentDate,
      consentVersion: consentVersion ?? this.consentVersion,
      selectedWorkTypes: selectedWorkTypes ?? this.selectedWorkTypes,
      avatarPath: avatarPath ?? this.avatarPath,
      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      premiumActivatedAt: premiumActivatedAt ?? this.premiumActivatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone': phone,
      'full_name': fullName,
      'consent_date': consentDate.toIso8601String(),
      'consent_version': consentVersion,
      'selected_work_types': selectedWorkTypes.join(','),
      'avatar_path': avatarPath,
      'is_premium': isPremium ? 1 : 0,
      'premium_until': premiumUntil?.toIso8601String(),
      'premium_activated_at': premiumActivatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    final workTypesStr = map['selected_work_types'] as String?;
    final selectedWorkTypes = workTypesStr != null && workTypesStr.isNotEmpty
        ? workTypesStr.split(',')
        : <String>[];

    return User(
      id: map['id'] as String,
      phone: map['phone'] as String,
      fullName: map['full_name'] as String?,
      consentDate: DateTime.parse(map['consent_date'] as String),
      consentVersion: map['consent_version'] as String,
      selectedWorkTypes: selectedWorkTypes,
      avatarPath: map['avatar_path'] as String?,
      isPremium: (map['is_premium'] as int? ?? 0) == 1,
      premiumUntil: map['premium_until'] != null
          ? DateTime.parse(map['premium_until'] as String)
          : null,
      premiumActivatedAt: map['premium_activated_at'] != null
          ? DateTime.parse(map['premium_activated_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
