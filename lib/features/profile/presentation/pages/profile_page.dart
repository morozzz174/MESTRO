import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../database/database_helper.dart';
import '../../../../models/user.dart';
import '../../../../models/order.dart';
import '../../../../repositories/impl/user_repository_impl.dart';
import '../../../../screens/registration_screen.dart';
import '../../../../utils/app_design.dart';
import '../../../../services/export_service.dart';
import '../../../../services/database_backup_service.dart';
import '../../../../features/work_types/presentation/pages/work_type_selection_screen.dart';
import '../../../../features/profile/presentation/pages/subscription_screen.dart';
import '../../../../services/subscription_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoading = true;
  final _subscriptionService = SubscriptionService();
  bool _isPremium = false;
  // removed

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await DatabaseHelper().getCurrentUser();
    if (mounted) {
      final isPrem = await _subscriptionService.isPremiumActive();
      setState(() {
        _user = user;
        _isLoading = false;
        _isPremium = isPrem;
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

  /// Показать диалог о необходимости Премиум
  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Требуется Премиум'),
          ],
        ),
        content: const Text(
          'Эта функция доступна только для подписчиков Премиум.\n\n'
          'Получите доступ ко всем возможностям приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Позже'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/subscription');
            },
            child: const Text('Оформить Премиум'),
          ),
        ],
      ),
    );
  }

  /// Смена аватара пользователя
  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile == null || !mounted) return;

    try {
      // Сохраняем аватар в директорию приложения
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = '${_user!.id}_avatar.jpg';
      final newAvatarPath = '${avatarDir.path}/$fileName';
      await File(pickedFile.path).copy(newAvatarPath);

      // Обновляем пользователя в БД
      final updatedUser = _user!.copyWith(
        avatarPath: newAvatarPath,
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper().updateUser(updatedUser);

      if (mounted) {
        setState(() => _user = updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фото обновлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
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
      await DatabaseHelper().updateUser(updatedUser);
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

  /// Редактирование имени пользователя
  Future<void> _editName() async {
    final controller = TextEditingController(text: _user?.fullName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить имя'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ФИО',
            hintText: 'Введите ваше имя',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted && _user != null) {
      final updatedUser = _user!.copyWith(
        fullName: newName,
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper().updateUser(updatedUser);
      setState(() => _user = updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Имя обновлено'),
            backgroundColor: Colors.green,
          ),
        );
}
  }

  /// Удаление аккаунта и всех данных (GDPR/Play Store compliance)
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление аккаунта'),
        content: const Text(
          'Все ваши данные будут удалены безвозвратно:\n\n'
          '• Заявки и замеры\n'
          '• Фото и аннотации\n'
          '• История платежей\n'
          '• Настройки и прайсы\n\n'
          'Это действие нельзя отменить.',
        ),
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
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final userRepo = UserRepositoryImpl();
      await userRepo.deleteUser();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RegistrationScreen()),
        (route) => false,
      );
    }
  }

  /// Выход из аккаунта (без удаления данных)
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
      padding: EdgeInsets.all(AppDesign.spacing4),
      children: [
        // Аватар и имя
        Container(
          decoration: AppDesign.cardDecoration(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDesign.spacing6),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _changeAvatar,
                  child: Stack(
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
                          backgroundImage:
                              _user!.avatarPath != null &&
                                  File(_user!.avatarPath!).existsSync()
                              ? FileImage(File(_user!.avatarPath!))
                              : null,
                          child:
                              _user?.avatarPath == null ||
                                  !File(_user!.avatarPath!).existsSync()
                              ? const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: AppDesign.deepSteelBlue,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppDesign.accentTeal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDesign.spacing2),
                Text(
                  'Нажмите чтобы изменить фото',
                  style: AppDesign.captionStyle,
                ),
                SizedBox(height: AppDesign.spacing4),
                Text(
                  _user!.fullName ?? 'Пользователь',
                  style: AppDesign.titleStyle,
                ),
                SizedBox(height: AppDesign.spacing2),
                Text(
                  _user!.phone,
                  style: AppDesign.bodyStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: AppDesign.spacing4),

        // Информация
        Container(
          decoration: AppDesign.cardDecoration(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDesign.spacing4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Информация', style: AppDesign.subtitleStyle),
                SizedBox(height: AppDesign.spacing4),
                _InfoRow(
                  icon: Icons.phone,
                  label: 'Телефон',
                  value: _user!.phone,
                ),
                AppDesign.separator(),
                ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text('ФИО', style: AppDesign.captionStyle),
                  subtitle: Text(_user!.fullName ?? 'Не указано'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: _editName,
                    tooltip: 'Изменить имя',
                  ),
                  onTap: _editName,
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

        SizedBox(height: AppDesign.spacing4),

        // Мои ниши
        Container(
          decoration: AppDesign.cardDecoration(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDesign.spacing4),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(
                              AppDesign.radiusListItem,
                            ),
                          ),
                          child: Icon(
                            Icons.work,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        SizedBox(width: AppDesign.spacing3),
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
                SizedBox(height: AppDesign.spacing3),
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
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

        SizedBox(height: AppDesign.spacing4),

        // Премиум подписка
        InkWell(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
          borderRadius: BorderRadius.circular(AppDesign.radiusCard),
          child: Container(
            decoration: BoxDecoration(
              color: _isPremium
                  ? const Color(0xFF4CAF50).withOpacity(0.08)
                  : AppDesign.primaryDark.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDesign.radiusCard),
              border: Border.all(
                color: _isPremium
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppDesign.spacing4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          (_isPremium
                                  ? const Color(0xFF4CAF50)
                                  : AppDesign.primaryDark)
                              .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(
                        AppDesign.radiusListItem,
                      ),
                    ),
                    child: Icon(
                      _isPremium ? Icons.workspace_premium : Icons.lock_outline,
                      color: _isPremium
                          ? const Color(0xFF4CAF50)
                          : Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: AppDesign.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPremium ? 'Премиум активен' : 'Премиум подписка',
                          style: AppDesign.subtitleStyle.copyWith(
                            color: _isPremium ? const Color(0xFF4CAF50) : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPremium
                              ? 'AI-ассистент • Умные рекомендации'
                              : 'Разблокировать AI-ассистента',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: AppDesign.spacing4),

        // Настройки уведомлений (только для премиума)
        GestureDetector(
          onTap: !_isPremium ? () => _showPremiumDialog(context) : null,
          child: Container(
            decoration: AppDesign.cardDecoration(
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            child: Padding(
              padding: EdgeInsets.all(AppDesign.spacing4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: _isPremium
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.grey,
                      ),
                      SizedBox(width: AppDesign.spacing2),
                      Text(
                        'Уведомления',
                        style: AppDesign.subtitleStyle.copyWith(
                          color: _isPremium ? null : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (!_isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Премиум',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppDesign.spacing4),
                  _InfoRow(
                    icon: Icons.alarm,
                    label: 'За 1 час до замера',
                    value: _isPremium ? 'Локальное ✓' : '—',
                    valueColor: _isPremium ? null : Colors.grey,
                  ),
                  AppDesign.separator(),
                  _InfoRow(
                    icon: Icons.alarm,
                    label: 'За 30 мин до замера',
                    value: _isPremium ? 'Локальное ✓' : '—',
                    valueColor: _isPremium ? null : Colors.grey,
                  ),
                  AppDesign.separator(),
                  _InfoRow(
                    icon: Icons.sms,
                    label: 'Клиенту за 24 часа',
                    value: _isPremium ? 'SMS (настр.)' : '—',
                    valueColor: _isPremium ? null : Colors.grey,
                  ),
                  AppDesign.separator(),
                  _InfoRow(
                    icon: Icons.sms,
                    label: 'Клиенту за 2 часа',
                    value: _isPremium ? 'SMS (настр.)' : '—',
                    valueColor: _isPremium ? null : Colors.grey,
                  ),
                  if (_isPremium) ...[
                    SizedBox(height: AppDesign.spacing3),
                    Text(
                      'Для SMS-уведомлений укажите API ключ в настройках приложения.',
                      style: AppDesign.captionStyle.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: AppDesign.spacing3),
                    Text(
                      'Доступно в Премиум подписке',
                      style: AppDesign.captionStyle.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: AppDesign.spacing4),
        Container(
          decoration: AppDesign.cardDecoration(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDesign.spacing4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('О приложении', style: AppDesign.subtitleStyle),
                SizedBox(height: AppDesign.spacing4),
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

        SizedBox(height: AppDesign.spacing6),

        // Управление данными
        Container(
          decoration: AppDesign.cardDecoration(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDesign.spacing4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Управление данными', style: AppDesign.subtitleStyle),
                SizedBox(height: AppDesign.spacing4),
                // Экспорт в Excel (только для премиума)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isPremium
                          ? Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        AppDesign.radiusListItem,
                      ),
                    ),
                    child: Icon(
                      Icons.table_chart,
                      color: _isPremium
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.grey,
                    ),
                  ),
                  title: Text(
                    'Экспорт в Excel',
                    style: TextStyle(color: _isPremium ? null : Colors.grey),
                  ),
                  subtitle: Text(
                    _isPremium
                        ? 'Выгрузка заявок с ценами'
                        : 'Доступно в Премиум',
                    style: TextStyle(color: _isPremium ? null : Colors.grey),
                  ),
                  trailing: Icon(
                    _isPremium ? Icons.chevron_right : Icons.lock,
                    color: _isPremium ? null : Colors.grey,
                  ),
                  onTap: _isPremium
                      ? _exportToExcel
                      : () => _showPremiumDialog(context),
                ),
                AppDesign.separator(),
                // Резервная копия (только для премиума)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isPremium
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        AppDesign.radiusListItem,
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_upload,
                      color: _isPremium
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  title: Text(
                    'Резервная копия',
                    style: TextStyle(color: _isPremium ? null : Colors.grey),
                  ),
                  subtitle: Text(
                    _isPremium ? 'Экспорт базы данных' : 'Доступно в Премиум',
                    style: TextStyle(color: _isPremium ? null : Colors.grey),
                  ),
                  trailing: Icon(
                    _isPremium ? Icons.chevron_right : Icons.lock,
                    color: _isPremium ? null : Colors.grey,
                  ),
                  onTap: _isPremium
                      ? _exportDatabase
                      : () => _showPremiumDialog(context),
                ),
                AppDesign.separator(),
                // Восстановление (только для премиума)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isPremium
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        AppDesign.radiusListItem,
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_download,
                      color: _isPremium
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Colors.grey,
                    ),
                  ),
                  title: Text(
                    'Восстановить из копии',
                    style: TextStyle(color: _isPremium ? null : Colors.grey),
                  ),
                  subtitle: Text(
                    _isPremium ? 'Импорт базы данных' : 'Доступно в Премиум',
                    style: TextStyle(color: _isPremium ? null : Colors.grey),
                  ),
                  trailing: Icon(
                    _isPremium ? Icons.chevron_right : Icons.lock,
                    color: _isPremium ? null : Colors.grey,
                  ),
                  onTap: _isPremium
                      ? _importDatabase
                      : () => _showPremiumDialog(context),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: AppDesign.spacing6),

        // Кнопка выхода
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              'Выйти из аккаунта',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radiusButton),
              ),
            ),
          ),
        ),
        SizedBox(height: AppDesign.spacing4),

        SizedBox(height: AppDesign.spacing4),

        // Кнопка удаления аккаунта
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _deleteAccount,
            icon: Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
            label: Text(
              'Удалить аккаунт',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radiusButton),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDesign.spacing2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppDesign.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppDesign.captionStyle),
                SizedBox(height: AppDesign.spacing1),
                Text(
                  value,
                  style: AppDesign.bodyStyle.copyWith(color: valueColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
