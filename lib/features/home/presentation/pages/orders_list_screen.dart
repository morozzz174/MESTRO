import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../models/order.dart';
import '../../../../utils/app_design.dart';
import '../../../../screens/checklist_screen.dart';

/// Экран списка заявок с фильтрацией по статусу
class OrdersListScreen extends StatefulWidget {
  final OrderStatus? initialStatus;

  const OrdersListScreen({super.key, this.initialStatus});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  OrderStatus? _filterStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filterStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          // Кнопка смены статуса (если есть выбранный фильтр)
          if (_filterStatus != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => setState(() => _filterStatus = null),
              tooltip: 'Сбросить фильтр',
            ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по клиенту или адресу...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Кнопки-фильтры статусов
          _buildStatusFilters(),

          const Divider(height: 1),

          // Список заявок
          Expanded(
            child: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is OrderLoaded) {
                  final filteredOrders = _filterOrders(state.orders);

                  if (filteredOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет заявок',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Создайте первую заявку',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _OrderCard(
                        order: order,
                        onTap: () => _openOrder(order),
                        onStatusChange: () => _showStatusChangeDialog(order),
                      );
                    },
                  );
                }

                return const Center(child: Text('Загрузка...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    if (_filterStatus != null) {
      return 'Заявки: ${_filterStatus!.label}';
    }
    return 'Все заявки';
  }

  Widget _buildStatusFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Все',
            isSelected: _filterStatus == null,
            color: AppDesign.deepSteelBlue,
            onTap: () => setState(() => _filterStatus = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Новые',
            isSelected: _filterStatus == OrderStatus.newOrder,
            color: AppDesign.statusNew,
            onTap: () => setState(() => _filterStatus = OrderStatus.newOrder),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'В работе',
            isSelected: _filterStatus == OrderStatus.inProgress,
            color: AppDesign.statusInProgress,
            onTap: () => setState(
              () => _filterStatus = OrderStatus.inProgress,
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Завершены',
            isSelected: _filterStatus == OrderStatus.completed,
            color: AppDesign.statusCompleted,
            onTap: () => setState(() => _filterStatus = OrderStatus.completed),
          ),
        ],
      ),
    );
  }

  List<Order> _filterOrders(List<Order> orders) {
    var result = orders;

    // Фильтр по статусу
    if (_filterStatus != null) {
      result = result.where((o) => o.status == _filterStatus).toList();
    }

    // Поиск
    if (_searchQuery.isNotEmpty) {
      result = result.where((order) {
        final searchLower = _searchQuery.toLowerCase();
        return order.clientName.toLowerCase().contains(searchLower) ||
            order.address.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Сортировка: новые сверху
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }

  void _openOrder(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChecklistScreen(order: order),
      ),
    );
  }

  void _showStatusChangeDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить статус'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values.map((status) {
            final isCurrentStatus = order.status == status;
            return ListTile(
              leading: Icon(
                isCurrentStatus ? Icons.check_circle : Icons.circle_outlined,
                color: isCurrentStatus
                    ? _getStatusColor(status)
                    : Colors.grey,
              ),
              title: Text(
                status.label,
                style: TextStyle(
                  fontWeight: isCurrentStatus ? FontWeight.bold : null,
                  color: isCurrentStatus ? _getStatusColor(status) : null,
                ),
              ),
              trailing: isCurrentStatus
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeOrderStatus(order, status);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _changeOrderStatus(Order order, OrderStatus newStatus) {
    final updatedOrder = order.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    context.read<OrderBloc>().add(UpdateOrder(updatedOrder));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус изменён на "${newStatus.label}"'),
          backgroundColor: _getStatusColor(newStatus),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return AppDesign.statusNew;
      case OrderStatus.inProgress:
        return AppDesign.statusInProgress;
      case OrderStatus.completed:
        return AppDesign.statusCompleted;
      case OrderStatus.cancelled:
        return AppDesign.statusCancelled;
    }
  }
}

/// Кнопка-фильтр статуса
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

/// Карточка заявки
class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final VoidCallback onStatusChange;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(order.status).withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок: клиент + статус
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Кнопка смены статуса
                  IconButton(
                    icon: Icon(
                      Icons.swap_horiz,
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                    onPressed: onStatusChange,
                    tooltip: 'Изменить статус',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Адрес
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address,
                      style: TextStyle(color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Дата + тип работ + статус
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(order.date),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.build, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.workType.title,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: order.status),
                ],
              ),

              // Стоимость (если есть)
              if (order.estimatedCost != null && order.estimatedCost! > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${_formatCurrency(order.estimatedCost!)} ₽',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.accentTeal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(date.year, date.month, date.day);

    if (orderDate == today) {
      return 'Сегодня';
    } else if (orderDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера';
    } else if (orderDate == today.add(const Duration(days: 1))) {
      return 'Завтра';
    }

    final months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}к';
    }
    return amount.toStringAsFixed(0);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return AppDesign.statusNew;
      case OrderStatus.inProgress:
        return AppDesign.statusInProgress;
      case OrderStatus.completed:
        return AppDesign.statusCompleted;
      case OrderStatus.cancelled:
        return AppDesign.statusCancelled;
    }
  }
}

/// Чип статуса
class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case OrderStatus.newOrder:
        return AppDesign.statusNew;
      case OrderStatus.inProgress:
        return AppDesign.statusInProgress;
      case OrderStatus.completed:
        return AppDesign.statusCompleted;
      case OrderStatus.cancelled:
        return AppDesign.statusCancelled;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case OrderStatus.newOrder:
        return Icons.fiber_new;
      case OrderStatus.inProgress:
        return Icons.pending;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}
