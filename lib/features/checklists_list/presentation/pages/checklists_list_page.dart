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
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final checklists = manifestMap.keys
          .where(
            (String key) =>
                key.startsWith('assets/checklists/') && key.endsWith('.json'),
          )
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: AppDesign.spacing4),
            Text(
              'Нет чек-листов',
              style: AppDesign.subtitleStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppDesign.spacing2),
            Text(
              'Чек-листы для замеров появятся здесь',
              style: AppDesign.captionStyle,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppDesign.spacing4),
      itemCount: _checklistFiles.length,
      itemBuilder: (context, index) {
        final fileName = _checklistFiles[index];
        final title = fileName.replaceAll('.json', '').replaceAll('_', ' ');

        return Container(
          margin: EdgeInsets.only(bottom: AppDesign.spacing3),
          decoration: AppDesign.cardDecoration(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Чек-лист: $title')));
              },
              borderRadius: BorderRadius.circular(AppDesign.radiusCard),
              child: Padding(
                padding: EdgeInsets.all(AppDesign.spacing4),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppDesign.spacing3),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                          AppDesign.radiusListItem,
                        ),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: AppDesign.spacing4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title
                                .split(' ')
                                .map(
                                  (word) =>
                                      word[0].toUpperCase() + word.substring(1),
                                )
                                .join(' '),
                            style: AppDesign.subtitleStyle,
                          ),
                          SizedBox(height: AppDesign.spacing1),
                          Text(fileName, style: AppDesign.captionStyle),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.6),
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
