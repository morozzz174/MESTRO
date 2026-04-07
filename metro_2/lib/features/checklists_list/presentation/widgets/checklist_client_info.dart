import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/order.dart';
import '../../../../utils/app_design.dart';

/// Секция информации о клиенте в чек-листе
class ChecklistClientInfo extends StatelessWidget {
  final Order order;
  final ValueChanged<Order> onOrderChanged;

  const ChecklistClientInfo({
    super.key,
    required this.order,
    required this.onOrderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDesign.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Информация о клиенте', style: AppDesign.subtitleStyle),
            const SizedBox(height: AppDesign.spacing12),
            TextFormField(
              initialValue: order.clientName.isEmpty ? null : order.clientName,
              decoration: const InputDecoration(
                labelText: 'Имя клиента',
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (value) {
                onOrderChanged(order.copyWith(clientName: value));
              },
            ),
            const SizedBox(height: AppDesign.spacing12),
            TextFormField(
              initialValue: order.address.isEmpty ? null : order.address,
              decoration: const InputDecoration(
                labelText: 'Адрес',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              onChanged: (value) {
                onOrderChanged(order.copyWith(address: value));
              },
            ),
            const SizedBox(height: AppDesign.spacing12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: order.date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  onOrderChanged(order.copyWith(date: date));
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата замера',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('dd.MM.yyyy', 'ru').format(order.date)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
