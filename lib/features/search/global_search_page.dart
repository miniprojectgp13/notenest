import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final results = context.watch<AppState>().globalSearch(query);

    return Scaffold(
      appBar: AppBar(title: const Text('Search In NoteNest')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search photo, files, keyword, unique ID...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.search_outlined),
                      title: Text(results[index]),
                      subtitle: const Text('Tap to navigate in future version'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
