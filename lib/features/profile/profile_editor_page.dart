import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_profile.dart';
import '../../core/state/app_state.dart';

class ProfileEditorPage extends StatefulWidget {
  const ProfileEditorPage({super.key});

  @override
  State<ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _addMoreController;
  late List<ProfileField> _fields;

  final List<String> emojis = const [
    '😀',
    '🤓',
    '🥳',
    '😎',
    '🧠',
    '📚',
    '🔥',
    '⭐',
    '🚀',
    '💡',
    '🎯',
    '😊',
  ];

  String selectedEmoji = '🤓';

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _nameController = TextEditingController(text: profile.name);
    _bioController = TextEditingController(text: profile.bio);
    _addMoreController = TextEditingController(text: profile.additionalNote);
    selectedEmoji = profile.emoji;
    _fields =
        profile.extraFields
            .map(
              (field) => ProfileField(label: field.label, value: field.value),
            )
            .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _addMoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile Card')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addMoreController,
              decoration: const InputDecoration(labelText: 'Add more'),
            ),
            const SizedBox(height: 12),
            const Text('Select emoji'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children:
                  emojis
                      .map(
                        (emoji) => ChoiceChip(
                          label: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          selected: selectedEmoji == emoji,
                          onSelected: (_) {
                            setState(() {
                              selectedEmoji = emoji;
                            });
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Custom Fields',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _fields.add(ProfileField(label: 'New Field', value: ''));
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            ..._fields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: field.label,
                        decoration: const InputDecoration(
                          labelText: 'Field name',
                        ),
                        onChanged: (value) => field.label = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: field.value,
                        decoration: const InputDecoration(
                          labelText: 'Field value',
                        ),
                        onChanged: (value) => field.value = value,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _fields.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Unique ID: ${appState.profile.uniqueId}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: () => appState.regenerateUniqueId(),
              icon: const Icon(Icons.autorenew),
              label: const Text('Regenerate Unique ID'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) {
                  return;
                }
                appState.updateProfile(
                  name: _nameController.text.trim(),
                  bio: _bioController.text.trim(),
                  emoji: selectedEmoji,
                  additionalNote: _addMoreController.text.trim(),
                  extraFields:
                      _fields
                          .where((field) => field.label.trim().isNotEmpty)
                          .toList(),
                );
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Saved and shown on home page.'),
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Profile Card'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final path = await appState.downloadProfileAsJson();
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Downloaded to: $path')));
              },
              icon: const Icon(Icons.download_for_offline_outlined),
              label: const Text('Download This Item'),
            ),
          ],
        ),
      ),
    );
  }
}
