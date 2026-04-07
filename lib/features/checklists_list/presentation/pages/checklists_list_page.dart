import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../../utils/app_design.dart';

class ChecklistsListPage extends StatefulWidget {
  const ChecklistsListPage({super.key});

  @override
  State<ChecklistsListPage> createState() => _ChecklistsListPageState();
}

class _ChecklistsListPageState extends State<ChecklistsListPage> {
  List<String> _checklistFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  Future<void> _loadChecklists() async {
    try {
      // Загружаем список чек-листов из assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final checklists = manifestMap.keys
          .where((String key) => key.startsWith('assets/checklists/') && key.endsWith('.json'))
          .map((String key) => key.split('/').last)
          .toList();

      if (mounted) {
        setState(() {
          _checklistFiles = checklists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_checklistFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 80,
              color: AppDesign.warmTaupe,
            ),
            const SizedBox(height: AppDesign.spacing16),
            Text(
              'Нет чек-листов',
              style: AppDesign.subtitleStyle.copyWith(
                color: AppDesign.midBlueGray,
              ),
            ),
            const SizedBox(height: AppDesign.spacing8),
            Text(
              'Чек-листы для замеров появятся здесь',
              style: AppDesign.captionStyle,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      itemCount: _checklistFiles.length,
      itemBuilder: (context, index) {
        final fileName = _checklistFiles[index];
        final title = fileName.replaceAll('.json', '').replaceAll('_', ' ');

        return Container(
          margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
          decoration: AppDesign.cardDecoration,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Чек-лист: $title')),
                );
              },
              borderRadius: BorderRadius.circular(AppDesign.radiusCard),
              child: Padding(
                padding: const EdgeInsets.all(AppDesign.spacing16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDesign.spacing12),
                      decoration: BoxDecoration(
                        color: AppDesign.warmTaupe.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppDesign.radiusListItem),
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        color: AppDesign.warmTaupe,
                      ),
                    ),
                    const SizedBox(width: AppDesign.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
                            style: AppDesign.subtitleStyle,
                          ),
                          const SizedBox(height: AppDesign.spacing4),
                          Text(
                            fileName,
                            style: AppDesign.captionStyle,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppDesign.midBlueGray.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
