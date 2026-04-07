import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

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
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет чек-листов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Чек-листы для замеров появятся здесь',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checklistFiles.length,
      itemBuilder: (context, index) {
        final fileName = _checklistFiles[index];
        final title = fileName.replaceAll('.json', '').replaceAll('_', ' ');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment_outlined, color: Colors.orange),
            ),
            title: Text(
              title.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(fileName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Чек-лист: $title')),
              );
            },
          ),
        );
      },
    );
  }
}
