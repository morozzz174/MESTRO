import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import 'checklist_screen.dart';

class WorkTypeScreen extends StatelessWidget {
  const WorkTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выберите тип работ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: WorkType.values.map((type) {
            return _WorkTypeCard(
              workType: type,
              onTap: () => _createOrder(context, type),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _createOrder(BuildContext context, WorkType workType) {
    final order = Order(
      id: const Uuid().v4(),
      clientName: '',
      address: '',
      date: DateTime.now(),
      workType: workType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChecklistScreen(order: order)));
  }
}

class _WorkTypeCard extends StatelessWidget {
  final WorkType workType;
  final VoidCallback onTap;

  const _WorkTypeCard({required this.workType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (workType) {
      case WorkType.windows:
        icon = Icons.window;
        break;
      case WorkType.doors:
        icon = Icons.door_front_door;
        break;
      case WorkType.airConditioners:
        icon = Icons.ac_unit;
        break;
      case WorkType.kitchens:
        icon = Icons.countertops;
        break;
      case WorkType.tiles:
        icon = Icons.grid_on;
        break;
      case WorkType.furniture:
        icon = Icons.chair;
        break;
      case WorkType.engineering:
        icon = Icons.plumbing;
        break;
      case WorkType.electrical:
        icon = Icons.electrical_services;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          workType.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
