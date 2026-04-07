import '../database/database_helper.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

/// Реализация UserRepository на основе DatabaseHelper
class UserRepositoryImpl implements UserRepository {
  final DatabaseHelper _db = DatabaseHelper();

  @override
  Future<User?> getCurrentUser() => _db.getCurrentUser();

  @override
  Future<void> insertUser(User user) => _db.insertUser(user);

  @override
  Future<void> updateUser(User user) => _db.updateUser(user);

  @override
  Future<bool> isUserRegistered() => _db.isUserRegistered();
}
