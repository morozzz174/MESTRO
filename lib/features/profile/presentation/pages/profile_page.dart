import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../database/database_helper.dart';
import '../../../../models/user.dart';
import '../../../../screens/registration_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await DatabaseHelper().getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Очищаем данные пользователя
      final db = await DatabaseHelper().database;
      await db.delete('users');

      if (!mounted) return;

      // Возвращаемся на экран регистрации
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RegistrationScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return const Center(
        child: Text('Данные пользователя не найдены'),
      );
    }

    final dateFormat = DateFormat('dd.MM.yyyy', 'ru');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Аватар и имя
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _user!.fullName ?? 'Пользователь',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _user!.phone,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Информация
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Информация',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.phone,
                  label: 'Телефон',
                  value: _user!.phone,
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'ФИО',
                  value: _user!.fullName ?? 'Не указано',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.event_available,
                  label: 'Дата согласия',
                  value: dateFormat.format(_user!.consentDate),
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.file_copy,
                  label: 'Версия согласия',
                  value: _user!.consentVersion,
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Дата регистрации',
                  value: dateFormat.format(_user!.createdAt),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Настройки уведомлений
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Уведомления',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.alarm,
                  label: 'За 1 час до замера',
                  value: 'Локальное ✓',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.alarm,
                  label: 'За 30 мин до замера',
                  value: 'Локальное ✓',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.sms,
                  label: 'Клиенту за 24 часа',
                  value: 'SMS (настр.)',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.sms,
                  label: 'Клиенту за 2 часа',
                  value: 'SMS (настр.)',
                ),
                const SizedBox(height: 12),
                Text(
                  'Для SMS-уведомлений укажите API ключ в настройках приложения.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'О приложении',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.info_outline,
                  label: 'Версия',
                  value: '1.0.0',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.business,
                  label: 'Разработчик',
                  value: 'MESTRO',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Кнопка выхода
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Выйти из аккаунта',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
