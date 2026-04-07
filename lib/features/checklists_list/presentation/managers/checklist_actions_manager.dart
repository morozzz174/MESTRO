import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../bloc/checklist_bloc.dart';
import '../../../../models/order.dart';
import '../../../../models/checklist_config.dart';
import '../../../../utils/app_design.dart';
import '../../../../utils/condition_evaluator.dart';
import '../../../../utils/cost_calculator.dart';
import '../../../../utils/pdf_generator.dart';

/// Менеджер действий чек-листа: сохранение, расчёт, PDF
class ChecklistActionsManager {
  final BuildContext context;
  Order order;

  ChecklistActionsManager({
    required this.context,
    required this.order,
  });

  /// Валидация и сохранение заявки
  Future<bool> saveOrder() async {
    final state = context.read<ChecklistBloc>().state;
    if (state is ChecklistLoaded) {
      final errors = ConditionEvaluator.validateRequiredFields(
        state.config.fields,
        state.formData,
      );
      if (errors.isNotEmpty) {
        _showErrorSnackBar(
          'Заполните обязательные поля: ${errors.join(', ')}',
        );
        return false;
      }

      order = order.copyWith(
        checklistData: Map<String, dynamic>.from(state.formData),
        updatedAt: DateTime.now(),
      );
    }

    if (order.clientName.isEmpty) {
      _showErrorSnackBar('Введите имя клиента');
      return false;
    }

    context.read<OrderBloc>().add(UpdateOrder(order));
    _showSuccessSnackBar('Заявка сохранена');
    return true;
  }

  /// Расчёт стоимости
  Future<num?> calculateCost(ChecklistConfig config) async {
    final state = context.read<ChecklistBloc>().state;
    if (state is! ChecklistLoaded) return null;

    final cost = CostCalculator.calculate(order, config);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Расчёт стоимости'),
        content: Text(
          'Предварительная стоимость работ:\n\n'
          '${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(cost)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Применить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      order = order.copyWith(estimatedCost: cost, updatedAt: DateTime.now());
      context.read<OrderBloc>().add(UpdateOrder(order));
      return cost;
    }
    return null;
  }

  /// Генерация PDF
  Future<void> generatePdf() async {
    final state = context.read<ChecklistBloc>().state;
    if (state is ChecklistLoaded) {
      order = order.copyWith(
        checklistData: state.formData,
        updatedAt: DateTime.now(),
      );
    }

    // Загружаем актуальные фото
    final orderBlocState = context.read<OrderBloc>().state;
    if (orderBlocState is OrderLoaded) {
      final freshOrder = orderBlocState.orders.firstWhere(
        (o) => o.id == order.id,
        orElse: () => order,
      );
      order = order.copyWith(photos: freshOrder.photos);
    }

    try {
      _showInfoSnackBar('Генерация PDF...');
      final file = await PdfGenerator.generateProposal(order);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Коммерческое предложение',
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Ошибка генерации PDF: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заявка сохранена')),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
