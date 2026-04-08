import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../repositories/impl/user_repository_impl.dart';
import '../../../../models/user.dart';
import '../../../../utils/app_design.dart';
import '../../../price_list/presentation/pages/price_list_screen.dart';

class DashboardPage extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const DashboardPage({super.key, required this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? _user;
  final UserRepository _userRepository = UserRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userRepository.getCurrentUser();
    if (mounted) {
      setState(() => _user = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'ru');
    final today = dateFormat.format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrderBloc>().add(LoadOrders());
        await _loadUser();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppDesign.spacing20),
        children: [
          // Приветствие
          Container(
            decoration: AppDesign.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.all(AppDesign.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppDesign.primaryButtonGradient,
                          boxShadow: AppDesign.secondaryButtonShadow,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppDesign.cardBackground,
                          child: const Icon(
                            Icons.person,
                            size: 28,
                            color: AppDesign.deepSteelBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDesign.spacing16),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Переход в профиль
                            widget.onNavigate(3);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _user?.fullName ?? 'Пользователь',
                                        style: AppDesign.titleStyle,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right,
                                      color: AppDesign.midBlueGray.withOpacity(
                                        0.6,
                                      ),
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppDesign.spacing4),
                                Text(today, style: AppDesign.captionStyle),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesign.spacing16),
                  Text(
                    'Добро пожаловать в MESTRO! '
                    'Управляйте замерами, клиентами и чек-листами в одном месте.',
                    style: AppDesign.bodyStyle.copyWith(
                      color: AppDesign.midBlueGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDesign.spacing16),

          // Статистика
          BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              int totalOrders = 0;
              int newOrders = 0;
              int inProgress = 0;
              int completed = 0;

              if (state is OrderLoaded) {
                totalOrders = state.orders.length;
                newOrders = state.orders
                    .where((o) => o.status.name == 'newOrder')
                    .length;
                inProgress = state.orders
                    .where((o) => o.status.name == 'inProgress')
                    .length;
                completed = state.orders
                    .where((o) => o.status.name == 'completed')
                    .length;
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppDesign.spacing12,
                mainAxisSpacing: AppDesign.spacing12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.assignment_outlined,
                    label: 'Всего заявок',
                    value: totalOrders.toString(),
                    color: AppDesign.deepSteelBlue,
                  ),
                  _StatCard(
                    icon: Icons.fiber_new,
                    label: 'Новые',
                    value: newOrders.toString(),
                    color: AppDesign.accentTeal,
                  ),
                  _StatCard(
                    icon: Icons.pending,
                    label: 'В работе',
                    value: inProgress.toString(),
                    color: AppDesign.warmTaupe,
                  ),
                  _StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Завершены',
                    value: completed.toString(),
                    color: AppDesign.statusCompleted,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppDesign.spacing24),

          // Быстрые действия
          Text(
            'Быстрые действия',
            style: AppDesign.titleStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppDesign.spacing12),
          Container(
            decoration: AppDesign.cardDecoration,
            child: Column(
              children: [
                _QuickActionTile(
                  icon: Icons.add_circle_outline,
                  title: 'Новая заявка',
                  subtitle: 'Создать заявку на замер',
                  color: AppDesign.deepSteelBlue,
                  onTap: () {
                    widget.onNavigate(1); // Замеры
                  },
                ),
                AppDesign.separator(),
                _QuickActionTile(
                  icon: Icons.meeting_room_outlined,
                  title: 'Мои замеры',
                  subtitle: 'Просмотр списка замеров',
                  color: AppDesign.accentTeal,
                  onTap: () {
                    widget.onNavigate(1); // Замеры
                  },
                ),
                AppDesign.separator(),
                _QuickActionTile(
                  icon: Icons.price_change,
                  title: 'Прайс-лист',
                  subtitle: 'Управление ценами',
                  color: AppDesign.midBlueGray,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PriceListScreen(),
                      ),
                    );
                  },
                ),
                AppDesign.separator(),
                _QuickActionTile(
                  icon: Icons.design_services,
                  title: 'Планы помещений',
                  subtitle: 'Генерация и просмотр планов',
                  color: AppDesign.deepSteelBlue,
                  onTap: () {
                    // Переход на вкладку Замеры, где можно выбрать заявку и открыть план
                    widget.onNavigate(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Выберите замер → кнопка "План"'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDesign.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDesign.radiusListItem),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppDesign.titleStyle.copyWith(fontSize: 24)),
                Text(label, style: AppDesign.captionStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDesign.radiusListItem),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppDesign.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppDesign.subtitleStyle),
                    const SizedBox(height: AppDesign.spacing4),
                    Text(subtitle, style: AppDesign.captionStyle),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppDesign.midBlueGray.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
