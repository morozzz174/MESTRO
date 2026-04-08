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
    required this.createdAt,
    required this.updatedAt,
  });

  /// Текущая версия согласия (увеличивается при изменении текста)
  static const String currentConsentVersion = '1.0';

  User copyWith({
    String? id,
    String? phone,
    String? fullName,
    DateTime? consentDate,
    String? consentVersion,
    List<String>? selectedWorkTypes,
    String? avatarPath,
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
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
