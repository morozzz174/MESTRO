import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../models/order.dart';
import '../../../../../screens/checklist_screen.dart';
import '../../../../../utils/app_design.dart';

class DayEventsList extends StatelessWidget {
  final List<Order> orders;
  final DateTime selectedDay;
  final ValueChanged<int>? onNavigate;

  const DayEventsList({
    super.key,
    required this.orders,
    required this.selectedDay,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyDay(selectedDay: selectedDay, onNavigate: onNavigate);
    }

    final dateFormat = DateFormat('HH:mm', 'ru');
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    final sortedOrders = List<Order>.from(orders)
      ..sort((a, b) {
        final aTime = a.appointmentDate ?? a.date;
        final bTime = b.appointmentDate ?? b.date;
        return aTime.compareTo(bTime);
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Замеры (${sortedOrders.length})',
                style: AppDesign.subtitleStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedOrders.length,
            itemBuilder: (context, index) {
              final order = sortedOrders[index];
              final time = order.appointmentDate ?? order.date;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChecklistScreen(order: order),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppDesign.deepSteelBlue.withOpacity(
                                    0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  dateFormat.format(time),
                                  style: AppDesign.captionStyle.copyWith(
                                    color: AppDesign.deepSteelBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.clientName,
                                  style: AppDesign.subtitleStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _StatusBadge(status: order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 14,
                                color: AppDesign.midBlueGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.workType.title,
                                style: AppDesign.captionStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppDesign.midBlueGray,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppDesign.captionStyle,
                                ),
                              ),
                            ],
                          ),
                          if (order.clientPhone != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: AppDesign.midBlueGray,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.clientPhone!,
                                  style: AppDesign.captionStyle,
                                ),
                              ],
                            ),
                          ],
                          if (order.estimatedCost != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesign.accentTeal.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                currencyFormat.format(order.estimatedCost),
                                style: AppDesign.captionStyle.copyWith(
                                  color: AppDesign.accentTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppDesign.getOrderStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: AppDesign.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<int>? onNavigate;

  const _EmptyDay({required this.selectedDay, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM', 'ru');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppDesign.warmTaupe),
            const SizedBox(height: 16),
            Text(
              'Нет замеров на ${dateFormat.format(selectedDay)}',
              textAlign: TextAlign.center,
              style: AppDesign.bodyStyle.copyWith(color: AppDesign.midBlueGray),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onNavigate != null ? () => onNavigate!(0) : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Создать замер'),
            ),
          ],
        ),
      ),
    );
  }
}
