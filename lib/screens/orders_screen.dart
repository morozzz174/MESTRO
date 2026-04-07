import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../models/order.dart';
import '../utils/app_design.dart';
import 'work_type_screen.dart';
import 'checklist_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(AppDesign.appBarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppDesign.appBarGradient,
            boxShadow: AppDesign.appBarShadow,
          ),
          child: AppBar(title: const Text('Заявки')),
        ),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderLoaded) {
            if (state.orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: AppDesign.warmTaupe,
                    ),
                    const SizedBox(height: AppDesign.spacing16),
                    Text(
                      'Нет заявок',
                      style: AppDesign.subtitleStyle.copyWith(
                        color: AppDesign.midBlueGray,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spacing8),
                    Text(
                      'Нажмите + чтобы создать новую',
                      style: AppDesign.captionStyle,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<OrderBloc>().add(LoadOrders());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDesign.spacing16),
                itemCount: state.orders.length,
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  return _OrderCard(order: order);
                },
              ),
            );
          }

          if (state is OrderError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppDesign.statusCancelled,
                  ),
                  const SizedBox(height: AppDesign.spacing16),
                  Text(state.message, style: AppDesign.bodyStyle),
                  const SizedBox(height: AppDesign.spacing16),
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
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDesign.radiusButton),
          gradient: AppDesign.accentButtonGradient,
          boxShadow: AppDesign.fabShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WorkTypeScreen()));
            },
            borderRadius: BorderRadius.circular(AppDesign.radiusButton),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing16,
                vertical: AppDesign.spacing12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: AppDesign.spacing8),
                  Text(
                    'Новая заявка',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
      decoration: AppDesign.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChecklistScreen(order: order)),
            );
          },
          borderRadius: BorderRadius.circular(AppDesign.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.clientName,
                        style: AppDesign.subtitleStyle,
                      ),
                    ),
                    _StatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: AppDesign.spacing12),
                Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 16,
                      color: AppDesign.midBlueGray,
                    ),
                    const SizedBox(width: AppDesign.spacing8),
                    Text(
                      order.workType.title,
                      style: AppDesign.bodyStyle.copyWith(
                        color: AppDesign.midBlueGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spacing8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppDesign.midBlueGray,
                    ),
                    const SizedBox(width: AppDesign.spacing8),
                    Expanded(
                      child: Text(
                        order.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesign.bodyStyle.copyWith(
                          color: AppDesign.midBlueGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spacing8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppDesign.midBlueGray,
                    ),
                    const SizedBox(width: AppDesign.spacing8),
                    Text(
                      dateFormat.format(order.date),
                      style: AppDesign.captionStyle,
                    ),
                  ],
                ),
                if (order.estimatedCost != null) ...[
                  const SizedBox(height: AppDesign.spacing12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesign.spacing12,
                      vertical: AppDesign.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: AppDesign.accentTeal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDesign.radiusChip),
                    ),
                    child: Text(
                      currencyFormat.format(order.estimatedCost),
                      style: AppDesign.subtitleStyle.copyWith(
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
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppDesign.getOrderStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDesign.radiusPill),
        border: Border.all(color: color.withOpacity(0.4)),
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
