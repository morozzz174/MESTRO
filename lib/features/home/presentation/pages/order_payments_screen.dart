import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../database/database_helper.dart';
import '../../../../models/order.dart';
import '../../../../utils/app_design.dart';

/// Экран истории платежей заявки
class OrderPaymentsScreen extends StatefulWidget {
  final Order order;

  const OrderPaymentsScreen({super.key, required this.order});

  @override
  State<OrderPaymentsScreen> createState() => _OrderPaymentsScreenState();
}

class _OrderPaymentsScreenState extends State<OrderPaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper();
    final payments = await db.getPaymentsForOrder(widget.order.id);
    setState(() {
      _payments = payments;
      _isLoading = false;
    });
  }

  Future<void> _addPayment() async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    DateTime selectedDate = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Добавить платеж'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Сумма
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Сумма',
                    hintText: '0',
                    suffixText: '₽',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Описание
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    hintText: 'За что оплата (например: аванс 50%)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Дата
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Дата: ${dateFormat.format(selectedDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          setDialogState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time?.hour ?? 12,
                              time?.minute ?? 0,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Введите корректную сумму'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final amount = double.parse(amountController.text);
    final description = descController.text.trim();

    try {
      final db = DatabaseHelper();
      await db.insertPayment({
        'id': const Uuid().v4(),
        'order_id': widget.order.id,
        'amount': amount,
        'payment_date': selectedDate.toIso8601String(),
        'description': description.isEmpty ? null : description,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Платеж ${currencyFormat.format(amount)} добавлен'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPayments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePayment(Map<String, dynamic> payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить платеж?'),
        content: Text(
          'Удалить платеж на сумму ${currencyFormat.format(payment['amount'])}?\n'
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final db = DatabaseHelper();
      await db.deletePayment(payment['id'] as String, widget.order.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Платеж удален'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPayments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatedCost = widget.order.estimatedCost ?? 0;
    final paidAmount = widget.order.paidAmount ?? 0;
    final debt = estimatedCost - paidAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Платежи: ${widget.order.clientName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Финансовая сводка
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppDesign.deepSteelBlue,
                  AppDesign.deepSteelBlue.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _FinanceItem(
                      icon: Icons.calculate,
                      label: 'Стоимость',
                      value: currencyFormat.format(estimatedCost),
                      color: Colors.white,
                    ),
                    _FinanceItem(
                      icon: Icons.check_circle,
                      label: 'Оплачено',
                      value: currencyFormat.format(paidAmount),
                      color: Colors.greenAccent,
                    ),
                    _FinanceItem(
                      icon: debt > 0 ? Icons.warning : Icons.check_circle,
                      label: debt > 0 ? 'Долг' : 'Переплата',
                      value: currencyFormat.format(debt.abs()),
                      color: debt > 0 ? Colors.redAccent : Colors.greenAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Прогресс-бар оплаты
                LinearProgressIndicator(
                  value: estimatedCost > 0 ? (paidAmount / estimatedCost).clamp(0.0, 1.0) : 0,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text(
                  estimatedCost > 0
                      ? 'Оплачено ${(paidAmount / estimatedCost * 100).toStringAsFixed(0)}%'
                      : 'Нет стоимости',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Список платежей
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет платежей',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Нажмите + чтобы добавить',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return _PaymentCard(
                            payment: payment,
                            onDelete: () => _deletePayment(payment),
                            currencyFormat: currencyFormat,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPayment,
        backgroundColor: AppDesign.accentTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// Финансовый элемент
class _FinanceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _FinanceItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Карточка платежа
class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onDelete;
  final NumberFormat currencyFormat;

  const _PaymentCard({
    required this.payment,
    required this.onDelete,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');
    final amount = payment['amount'] as double;
    final date = DateTime.parse(payment['payment_date'] as String);
    final description = payment['description'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.payment,
            color: Colors.green,
            size: 24,
          ),
        ),
        title: Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateFormat.format(date),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Удалить платеж',
        ),
      ),
    );
  }
}
