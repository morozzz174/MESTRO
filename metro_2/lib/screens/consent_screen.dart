import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Согласие на обработку персональных данных')),
      body: FutureBuilder<String>(
        future: _loadConsentText(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки текста согласия:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final text = snapshot.data ?? '';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          );
        },
      ),
    );
  }

  Future<String> _loadConsentText() async {
    return await rootBundle.loadString('assets/consent_text.txt');
  }
}
