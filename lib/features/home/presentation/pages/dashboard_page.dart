import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../database/database_helper.dart';
import '../../../../models/user.dart';
import '../../../price_list/presentation/pages/price_list_screen.dart';

class DashboardPage extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const DashboardPage({super.key, required this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await DatabaseHelper().getCurrentUser();
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
        padding: const EdgeInsets.all(16),
        children: [
          // Приветствие
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          size: 28,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user?.fullName ?? 'Пользователь',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              today,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Добро пожаловать в MESTRO! '
                    'Управляйте замерами, клиентами и чек-листами в одном месте.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.assignment_outlined,
                    label: 'Всего заявок',
                    value: totalOrders.toString(),
                    color: Colors.blue,
                  ),
                  _StatCard(
                    icon: Icons.fiber_new,
                    label: 'Новые',
                    value: newOrders.toString(),
                    color: Colors.orange,
                  ),
                  _StatCard(
                    icon: Icons.pending,
                    label: 'В работе',
                    value: inProgress.toString(),
                    color: Colors.purple,
                  ),
                  _StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Завершены',
                    value: completed.toString(),
                    color: Colors.green,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Быстрые действия
          const Text(
            'Быстрые действия',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _QuickActionTile(
                  icon: Icons.add_circle_outline,
                  title: 'Новая заявка',
                  subtitle: 'Создать заявку на замер',
                  color: Colors.blue,
                  onTap: () {
                    widget.onNavigate(1); // Замеры
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                _QuickActionTile(
                  icon: Icons.meeting_room_outlined,
                  title: 'Мои замеры',
                  subtitle: 'Просмотр списка замеров',
                  color: Colors.teal,
                  onTap: () {
                    widget.onNavigate(1); // Замеры
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                _QuickActionTile(
                  icon: Icons.price_change,
                  title: 'Прайс-лист',
                  subtitle: 'Управление ценами',
                  color: Colors.deepOrange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PriceListScreen(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                _QuickActionTile(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Чек-листы',
                  subtitle: 'Шаблоны и отчёты',
                  color: Colors.orange,
                  onTap: () {
                    widget.onNavigate(3); // Чек-листы
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
