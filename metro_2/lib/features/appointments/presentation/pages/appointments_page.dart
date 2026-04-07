import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../models/order.dart';
import '../../../../screens/checklist_screen.dart';
import '../../../../features/floor_plan/presentation/pages/floor_plan_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterWorkType;
  OrderStatus? _filterStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OrderLoaded) {
          // Фильтрация
          var filtered = state.orders;

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filtered = filtered.where((o) {
              return o.clientName.toLowerCase().contains(query) ||
                  o.address.toLowerCase().contains(query);
            }).toList();
          }

          if (_filterWorkType != null) {
            filtered = filtered
                .where((o) => o.workType.checklistFile == _filterWorkType)
                .toList();
          }

          if (_filterStatus != null) {
            filtered = filtered
                .where((o) => o.status == _filterStatus)
                .toList();
          }

          if (filtered.isEmpty && state.orders.isEmpty) {
            return const _EmptyAppointments();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Ничего не найдено',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filterWorkType = null;
                        _filterStatus = null;
                        _searchController.clear();
                      });
                    },
                    child: const Text('Сбросить фильтры'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Поиск и фильтры
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    // Поле поиска
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск по имени или адресу...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Фильтры
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterWorkType,
                            decoration: InputDecoration(
                              hintText: 'Тип работ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Все типы'),
                              ),
                              ...WorkType.values.map(
                                (wt) => DropdownMenuItem(
                                  value: wt.checklistFile,
                                  child: Text(wt.title),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _filterWorkType = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<OrderStatus>(
                            value: _filterStatus,
                            decoration: InputDecoration(
                              hintText: 'Статус',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Все статусы'),
                              ),
                              ...OrderStatus.values.map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _filterStatus = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_searchQuery.isNotEmpty ||
                        _filterWorkType != null ||
                        _filterStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Text(
                              'Найдено: ${filtered.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _filterWorkType = null;
                                  _filterStatus = null;
                                  _searchController.clear();
                                });
                              },
                              child: const Text('Сбросить'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Список
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<OrderBloc>().add(LoadOrders());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return _AppointmentCard(
                        order: order,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChecklistScreen(order: order),
                            ),
                          );
                        },
                        onViewFloorPlan: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FloorPlanPage(order: order),
                            ),
                          );
                        },
                        onCall: () => _callClient(order.clientPhone),
                        onNavigate: () => _navigateToAddress(order),
                        onDuplicate: () => _duplicateOrder(order),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }

        if (state is OrderError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<OrderBloc>().add(LoadOrders());
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Позвонить клиенту
  Future<void> _callClient(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Номер телефона не указан')));
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть телефон')),
        );
      }
    }
  }

  /// Открыть адрес в картах
  Future<void> _navigateToAddress(Order order) async {
    final address = order.address;
    if (address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Адрес не указан')));
      return;
    }
    // geo:0,0?q=ADDRESS
    final uri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // fallback: открыть в браузере Google Maps
      final browserUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
      if (await canLaunchUrl(browserUri)) {
        await launchUrl(browserUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Дублировать заявку
  Future<void> _duplicateOrder(Order order) async {
    final now = DateTime.now();
    final newOrder = order.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: now,
      createdAt: now,
      updatedAt: now,
      status: OrderStatus.newOrder,
      checklistData: {},
      estimatedCost: null,
    );

    if (mounted) {
      context.read<OrderBloc>().add(CreateOrder(newOrder));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заявка для "${order.clientName}" скопирована')),
      );
    }
  }
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет замеров',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Заявки появятся здесь',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final VoidCallback onViewFloorPlan;
  final VoidCallback onCall;
  final VoidCallback onNavigate;
  final VoidCallback onDuplicate;

  const _AppointmentCard({
    required this.order,
    required this.onTap,
    required this.onViewFloorPlan,
    required this.onCall,
    required this.onNavigate,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.clientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.workType.title,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  // Кнопка навигации
                  IconButton(
                    icon: const Icon(Icons.directions, size: 20),
                    onPressed: onNavigate,
                    tooltip: 'Маршрут',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(order.date),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              // Быстрые действия
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewFloorPlan,
                      icon: const Icon(Icons.design_services, size: 16),
                      label: const Text('План'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Позвонить'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDuplicate,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Копия'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.newOrder:
        color = Colors.blue;
        break;
      case OrderStatus.inProgress:
        color = Colors.orange;
        break;
      case OrderStatus.completed:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        status.label,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
