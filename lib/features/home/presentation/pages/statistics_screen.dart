import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../database/database_helper.dart';
import '../../../../models/order.dart';
import '../../../../utils/app_design.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Order> _allOrders = [];
  final CurrencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();
      final orders = await db.getAllOrders();
      final paymentStats = await db.getPaymentStatistics();

      int totalOrders = orders.length;
      int newOrders = orders
          .where((o) => o.status == OrderStatus.newOrder)
          .length;
      int inProgress = orders
          .where((o) => o.status == OrderStatus.inProgress)
          .length;
      int completed = orders
          .where((o) => o.status == OrderStatus.completed)
          .length;
      int cancelled = orders
          .where((o) => o.status == OrderStatus.cancelled)
          .length;

      double totalEstimated = orders
          .where((o) => o.status != OrderStatus.cancelled)
          .fold(0.0, (sum, o) => sum + (o.estimatedCost ?? 0));
      double totalPaid = orders.fold(
        0.0,
        (sum, o) => sum + (o.paidAmount ?? 0),
      );
      double totalDebt = totalEstimated - totalPaid;

      final Map<String, int> workTypeCount = {};
      final Map<String, double> workTypeRevenue = {};
      for (final order in orders) {
        if (order.status == OrderStatus.cancelled) continue;
        final type = order.workType.title;
        workTypeCount[type] = (workTypeCount[type] ?? 0) + 1;
        workTypeRevenue[type] =
            (workTypeRevenue[type] ?? 0) + (order.estimatedCost ?? 0);
      }

      final Map<String, double> clientRevenue = {};
      for (final order in orders) {
        if (order.status == OrderStatus.cancelled) continue;
        clientRevenue[order.clientName] =
            (clientRevenue[order.clientName] ?? 0) + (order.estimatedCost ?? 0);
      }
      final topClients = clientRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _allOrders = orders;
        _stats = {
          'totalOrders': totalOrders,
          'newOrders': newOrders,
          'inProgress': inProgress,
          'completed': completed,
          'cancelled': cancelled,
          'totalEstimated': totalEstimated,
          'totalPaid': totalPaid,
          'totalDebt': totalDebt,
          'workTypeCount': workTypeCount,
          'workTypeRevenue': workTypeRevenue,
          'topClients': topClients.take(5).toList(),
          'paymentStats': paymentStats,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: 'Заявки по статусам',
              icon: Icons.pie_chart,
              child: _buildOrderStats(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Финансы',
              icon: Icons.attach_money,
              child: _buildFinancials(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'По видам работ',
              icon: Icons.work,
              child: _buildWorkTypeStats(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Топ клиенты',
              icon: Icons.people,
              child: _buildTopClients(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Платежи',
              icon: Icons.payment,
              child: _buildPaymentStats(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppDesign.deepSteelBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppDesign.deepSteelBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Text(title, style: AppDesign.subtitleStyle),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStats() {
    final total = _stats['totalOrders'] as int;
    final newCount = _stats['newOrders'] as int;
    final inProgress = _stats['inProgress'] as int;
    final completed = _stats['completed'] as int;
    final cancelled = _stats['cancelled'] as int;

    return Column(
      children: [
        _StatusRow(
          label: 'Всего заявок',
          count: total,
          color: AppDesign.deepSteelBlue,
          icon: Icons.assignment,
        ),
        const Divider(),
        _StatusRow(
          label: 'Новые',
          count: newCount,
          percentage: total > 0 ? (newCount / total * 100) : 0,
          color: AppDesign.statusNew,
          icon: Icons.fiber_new,
        ),
        const Divider(),
        _StatusRow(
          label: 'В работе',
          count: inProgress,
          percentage: total > 0 ? (inProgress / total * 100) : 0,
          color: AppDesign.statusInProgress,
          icon: Icons.pending,
        ),
        const Divider(),
        _StatusRow(
          label: 'Завершены',
          count: completed,
          percentage: total > 0 ? (completed / total * 100) : 0,
          color: AppDesign.statusCompleted,
          icon: Icons.check_circle,
        ),
        const Divider(),
        _StatusRow(
          label: 'Отменены',
          count: cancelled,
          percentage: total > 0 ? (cancelled / total * 100) : 0,
          color: AppDesign.statusCancelled,
          icon: Icons.cancel,
        ),
      ],
    );
  }

  Widget _buildFinancials() {
    final totalEstimated = _stats['totalEstimated'] as double;
    final totalPaid = _stats['totalPaid'] as double;
    final totalDebt = _stats['totalDebt'] as double;
    final paymentCount = (_stats['paymentStats'] as Map)['paymentCount'] as int;

    return Column(
      children: [
        _FinanceCard(
          label: 'Общая сумма (завершённые)',
          value: totalEstimated,
          color: AppDesign.deepSteelBlue,
          icon: Icons.calculate,
        ),
        const SizedBox(height: 12),
        _FinanceCard(
          label: 'Оплачено',
          value: totalPaid,
          color: Colors.green,
          icon: Icons.check_circle,
        ),
        const SizedBox(height: 12),
        _FinanceCard(
          label: 'Долг клиентов',
          value: totalDebt,
          color: totalDebt > 0 ? Colors.red : Colors.green,
          icon: totalDebt > 0 ? Icons.warning : Icons.check_circle,
        ),
        const SizedBox(height: 12),
        _FinanceCard(
          label: 'Кол-во платежей',
          value: paymentCount.toDouble(),
          color: AppDesign.accentTeal,
          icon: Icons.receipt_long,
          isCurrency: false,
        ),
      ],
    );
  }

  Widget _buildWorkTypeStats() {
    final workTypeCount = _stats['workTypeCount'] as Map<String, int>;
    final workTypeRevenue = _stats['workTypeRevenue'] as Map<String, double>;

    if (workTypeCount.isEmpty) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(16), child: Text('Нет данных')),
      );
    }

    final entries = workTypeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries.map((entry) {
        final type = entry.key;
        final count = entry.value;
        final revenue = workTypeRevenue[type] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(type, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                child: Text(
                  '$count заяв.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  CurrencyFormat.format(revenue),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.deepSteelBlue,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopClients() {
    final topClients = _stats['topClients'] as List<MapEntry<String, double>>;

    if (topClients.isEmpty) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(16), child: Text('Нет данных')),
      );
    }

    return Column(
      children: topClients.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final client = entry.value.key;
        final revenue = entry.value.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: index <= 3
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: index <= 3 ? Colors.amber.shade700 : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  client,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormat.format(revenue),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppDesign.deepSteelBlue,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentStats() {
    final paymentStats = _stats['paymentStats'] as Map<String, dynamic>;
    final totalPaid = paymentStats['totalPaid'] as double;
    final avgPayment = paymentStats['avgPayment'] as double;
    final monthlyPayments = paymentStats['monthlyPayments'] as List;

    final months = [
      '',
      'Янв',
      'Фев',
      'Мар',
      'Апр',
      'Май',
      'Июн',
      'Июл',
      'Авг',
      'Сен',
      'Окт',
      'Ноя',
      'Дек',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  CurrencyFormat.format(totalPaid),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Всего оплачено',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  CurrencyFormat.format(avgPayment),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.accentTeal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Средний платёж',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        if (monthlyPayments.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Платежи по месяцам (текущий год):',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ...monthlyPayments.map((payment) {
            final monthNum = payment['month'] as int;
            final amount = payment['amount'] as double;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(months[monthNum], style: const TextStyle(fontSize: 12)),
                  Text(
                    CurrencyFormat.format(amount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final double? percentage;
  final Color color;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.count,
    this.percentage,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (percentage != null)
                Text(
                  ' (${percentage!.toStringAsFixed(0)}%)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
          if (percentage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(
                value: percentage! / 100,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
        ],
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool isCurrency;

  const _FinanceCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                isCurrency
                    ? currencyFormat.format(value)
                    : value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
