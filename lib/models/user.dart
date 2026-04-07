/// Модель пользователя
class User {
  final String id;
  final String phone;
  final String? fullName;
  final DateTime consentDate;
  final String consentVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.phone,
    this.fullName,
    required this.consentDate,
    required this.consentVersion,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      consentDate: consentDate ?? this.consentDate,
      consentVersion: consentVersion ?? this.consentVersion,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      phone: map['phone'] as String,
      fullName: map['full_name'] as String?,
      consentDate: DateTime.parse(map['consent_date'] as String),
      consentVersion: map['consent_version'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
