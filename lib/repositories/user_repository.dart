import '../models/user.dart';

/// Абстрактный репозиторий для работы с пользователями
/// Отделяет бизнес-логику от прямого доступа к БД
abstract class UserRepository {
  Future<User?> getCurrentUser();

  Future<void> insertUser(User user);

  Future<void> updateUser(User user);

  Future<bool> isUserRegistered();
}
