import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../repositories/impl/user_repository_impl.dart';
import '../../../../database/database_helper.dart';
import '../../../../models/user.dart';
import '../../../../models/order.dart';
import '../../../../screens/registration_screen.dart';
import '../../../../utils/app_design.dart';
import '../../../../services/export_service.dart';
import '../../../../services/database_backup_service.dart';
import '../../../../features/work_types/presentation/pages/work_type_selection_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoading = true;
  final UserRepository _userRepository = UserRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userRepository.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToExcel() async {
    final success = await ExportService.exportToExcel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Экспорт в Excel завершён' : 'Ошибка экспорта',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _exportDatabase() async {
    await DatabaseBackupService.exportDatabase(context);
  }

  Future<void> _importDatabase() async {
    final success = await DatabaseBackupService.importDatabase(context);
    if (success && mounted) {
      _loadUser();
    }
  }

  Future<void> _editWorkTypes() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => WorkTypeSelectionScreen(
          initialSelection: _user?.selectedWorkTypes ?? [],
        ),
      ),
    );

    if (result != null && mounted && _user != null) {
      final updatedUser = _user!.copyWith(
        selectedWorkTypes: result,
        updatedAt: DateTime.now(),
      );
      await _userRepository.updateUser(updatedUser);
      setState(() => _user = updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ниши обновлены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesign.statusCancelled,
              foregroundColor: Colors.white,
            ),
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
      return const Center(child: Text('Данные пользователя не найдены'));
    }

    final dateFormat = DateFormat('dd.MM.yyyy', 'ru');

    return ListView(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      children: [
        // Аватар и имя
        Container(
          decoration: AppDesign.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing24),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppDesign.primaryButtonGradient,
                    boxShadow: AppDesign.primaryButtonShadow,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppDesign.cardBackground,
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: AppDesign.deepSteelBlue,
                    ),
                  ),
                ),
                const SizedBox(height: AppDesign.spacing16),
                Text(
                  _user!.fullName ?? 'Пользователь',
                  style: AppDesign.titleStyle,
                ),
                const SizedBox(height: AppDesign.spacing8),
                Text(
                  _user!.phone,
                  style: AppDesign.bodyStyle.copyWith(
                    color: AppDesign.midBlueGray,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDesign.spacing16),

        // Информация
        Container(
          decoration: AppDesign.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Информация', style: AppDesign.subtitleStyle),
                const SizedBox(height: AppDesign.spacing16),
                _InfoRow(
                  icon: Icons.phone,
                  label: 'Телефон',
                  value: _user!.phone,
                ),
                AppDesign.separator(),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'ФИО',
                  value: _user!.fullName ?? 'Не указано',
                ),
                AppDesign.separator(),
                _InfoRow(
                  icon: Icons.event_available,
                  label: 'Дата согласия',
                  value: dateFormat.format(_user!.consentDate),
                ),
                AppDesign.separator(),
                _InfoRow(
                  icon: Icons.file_copy,
                  label: 'Версия согласия',
                  value: _user!.consentVersion,
                ),
                AppDesign.separator(),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Дата регистрации',
                  value: dateFormat.format(_user!.createdAt),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDesign.spacing16),

        // Мои ниши
        Container(
          decoration: AppDesign.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppDesign.accentTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(
                              AppDesign.radiusListItem,
                            ),
                          ),
                          child: const Icon(
                            Icons.work,
                            color: AppDesign.accentTeal,
                          ),
                        ),
                        const SizedBox(width: AppDesign.spacing12),
                        Text('Мои ниши', style: AppDesign.subtitleStyle),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _editWorkTypes,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Изменить'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spacing12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _user!.selectedWorkTypes.map((type) {
                    final wt = WorkType.values.firstWhere(
                      (e) => e.checklistFile == type,
                      orElse: () => WorkType.windows,
                    );
                    return Chip(
                      label: Text(
                        wt.title,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppDesign.accentTeal.withOpacity(0.12),
                      side: const BorderSide(
                        color: AppDesign.accentTeal,
                        width: 1.5,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                if (_user!.selectedWorkTypes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Ни одна ниша не выбрана. Нажмите "Изменить" для выбора.',
                      style: AppDesign.captionStyle,
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDesign.spacing16),

        // Настройки уведомлений
        Container(
          decoration: AppDesign.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      color: AppDesign.accentTeal,
                    ),
                    const SizedBox(width: AppDesign.spacing8),
                    Text('Уведомления', style: AppDesign.subtitleStyle),
                  ],
                ),
                const SizedBox(height: AppDesign.spacing16),
                _InfoRow(
                  icon: Icons.alarm,
                  label: 'За 1 час до замера',
                  value: 'Локальное ✓',
                ),
                AppDesign.separator(),
                _InfoRow(
                  icon: Icons.alarm,
                  label: 'За 30 мин до замера',
                  value: 'Локальное ✓',
                ),
                AppDesign.separator(),
                _InfoRow(
                  icon: Icons.sms,
                  label: 'Клиенту за 24 часа',
                  value: 'SMS (настр.)',
                ),
                AppDesign.separator(),
                _InfoRow(
                  icon: Icons.sms,
                  label: 'Клиенту за 2 часа',
                  value: 'SMS (настр.)',
                ),
                const SizedBox(height: AppDesign.spacing12),
                Text(
                  'Для SMS-уведомлений укажите API ключ в настройках приложения.',
                  style: AppDesign.captionStyle.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDesign.spacing16),
        Container(
          decoration: AppDesign.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('О приложении', style: AppDesign.subtitleStyle),
                const SizedBox(height: AppDesign.spacing16),
                _InfoRow(
                  icon: Icons.info_outline,
                  label: 'Версия',
                  value: '1.0.0',
                ),
                AppDesign.separator(),
                _InfoRow(
                  icon: Icons.business,
                  label: 'Разработчик',
                  value: 'MESTRO',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDesign.spacing24),

        // Управление данными
        Container(
          decoration: AppDesign.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Управление данными', style: AppDesign.subtitleStyle),
                const SizedBox(height: AppDesign.spacing16),
                // Экспорт в Excel
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppDesign.accentTeal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        AppDesign.radiusListItem,
                      ),
                    ),
                    child: const Icon(
                      Icons.table_chart,
                      color: AppDesign.accentTeal,
                    ),
                  ),
                  title: const Text('Экспорт в Excel'),
                  subtitle: const Text('Выгрузка заявок с ценами'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportToExcel,
                ),
                AppDesign.separator(),
                // Резервная копия
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppDesign.deepSteelBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        AppDesign.radiusListItem,
                      ),
                    ),
                    child: const Icon(
                      Icons.cloud_upload,
                      color: AppDesign.deepSteelBlue,
                    ),
                  ),
                  title: const Text('Резервная копия'),
                  subtitle: const Text('Экспорт базы данных'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportDatabase,
                ),
                AppDesign.separator(),
                // Восстановление
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppDesign.midBlueGray.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        AppDesign.radiusListItem,
                      ),
                    ),
                    child: const Icon(
                      Icons.cloud_download,
                      color: AppDesign.midBlueGray,
                    ),
                  ),
                  title: const Text('Восстановить из копии'),
                  subtitle: const Text('Импорт базы данных'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importDatabase,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDesign.spacing24),

        // Кнопка выхода
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppDesign.statusCancelled),
            label: const Text(
              'Выйти из аккаунта',
              style: TextStyle(color: AppDesign.statusCancelled, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppDesign.statusCancelled, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radiusButton),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDesign.spacing16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppDesign.midBlueGray),
          const SizedBox(width: AppDesign.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppDesign.captionStyle),
                const SizedBox(height: AppDesign.spacing4),
                Text(value, style: AppDesign.bodyStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
