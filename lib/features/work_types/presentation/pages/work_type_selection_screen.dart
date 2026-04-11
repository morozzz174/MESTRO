import 'package:flutter/material.dart';
import '../../../../models/order.dart';
import '../../../../utils/app_design.dart';

/// Экран выбора ниш (типов работ) мастера
class WorkTypeSelectionScreen extends StatefulWidget {
  final List<String> initialSelection;

  const WorkTypeSelectionScreen({super.key, this.initialSelection = const []});

  @override
  State<WorkTypeSelectionScreen> createState() =>
      _WorkTypeSelectionScreenState();
}

class _WorkTypeSelectionScreenState extends State<WorkTypeSelectionScreen> {
  late Set<String> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите ниши'),
        actions: [
          if (_selectedTypes.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedTypes.toList());
              },
              child: Text(
                'Готово (${_selectedTypes.length})',
                style: const TextStyle(
                  color: AppDesign.accentTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppDesign.warmTaupeBg,
            child: Text(
              'Выберите хотя бы одну нишу. Вы можете изменить выбор позже в профиле.',
              style: AppDesign.captionStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: WorkType.values.length,
              itemBuilder: (context, index) {
                final workType = WorkType.values[index];
                final isSelected = _selectedTypes.contains(
                  workType.checklistFile,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: AppDesign.accentTeal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(
                            AppDesign.radiusCard,
                          ),
                          border: Border.all(
                            color: AppDesign.accentTeal,
                            width: 2,
                          ),
                        )
                      : AppDesign.cardDecoration,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTypes.remove(workType.checklistFile);
                          } else {
                            _selectedTypes.add(workType.checklistFile);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(AppDesign.radiusCard),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              _getWorkTypeIcon(workType),
                              color: isSelected
                                  ? AppDesign.accentTeal
                                  : AppDesign.warmTaupe,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workType.title,
                                    style: AppDesign.subtitleStyle.copyWith(
                                      color: isSelected
                                          ? AppDesign.accentTeal
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppDesign.accentTeal
                                  : AppDesign.midBlueGray,
                            ),
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _selectedTypes.isEmpty
                ? null
                : () {
                    Navigator.of(context).pop(_selectedTypes.toList());
                  },
            style: AppDesign.primaryButtonStyle,
            child: Text(
              _selectedTypes.isEmpty
                  ? 'Выберите хотя бы одну нишу'
                  : 'Выбрано: ${_selectedTypes.length}',
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWorkTypeIcon(WorkType workType) {
    switch (workType) {
      case WorkType.windows:
        return Icons.window;
      case WorkType.doors:
        return Icons.door_front_door;
      case WorkType.airConditioners:
        return Icons.ac_unit;
      case WorkType.kitchens:
        return Icons.kitchen;
      case WorkType.tiles:
        return Icons.grid_on;
      case WorkType.furniture:
        return Icons.chair;
      case WorkType.engineering:
        return Icons.plumbing;
      case WorkType.electrical:
        return Icons.electrical_services;
      case WorkType.foundations:
        return Icons.foundation;
      case WorkType.houseConstruction:
        return Icons.home;
      case WorkType.wallsBox:
        return Icons.meeting_room;
      case WorkType.facades:
        return Icons.apartment;
      case WorkType.roofing:
        return Icons.roofing;
      case WorkType.metalStructures:
        return Icons.hardware;
      case WorkType.externalNetworks:
        return Icons.cable;
    }
  }
}
