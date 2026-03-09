import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';

class UploadNotesPage extends StatefulWidget {
  const UploadNotesPage({super.key, this.initialSubject});

  final String? initialSubject;

  @override
  State<UploadNotesPage> createState() => _UploadNotesPageState();
}

class _UploadNotesPageState extends State<UploadNotesPage> {
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _yearController = TextEditingController();
  final _keywordsController = TextEditingController();

  String _selectedType = 'PDF';
  String _search = '';
  String _subjectFilter = 'All';
  String? _pickedPath;
  String? _pickedName;

  @override
  void initState() {
    super.initState();
    _subjectFilter = widget.initialSubject ?? 'All';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _yearController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final subjectOptions = ['All', ...appState.subjectCounts.keys];

    final notes = appState.notes.where((note) {
      final query = _search.toLowerCase();
      final matchesFilter =
          _subjectFilter == 'All' || note.subject == _subjectFilter;
      if (!matchesFilter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final value = '${note.name} ${note.year} ${note.subject} ${note.keywords}'
          .toLowerCase();
      return value.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Notes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Add notes / PDF / documents',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'File name'),
          ),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(labelText: 'Year'),
          ),
          TextField(
            controller: _keywordsController,
            decoration: const InputDecoration(labelText: 'Keywords'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pick File (PDF/Image/Doc)'),
                ),
              ),
            ],
          ),
          if (_pickedName != null) ...[
            const SizedBox(height: 6),
            Text(
              'Selected: $_pickedName',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedType,
            items: const [
              DropdownMenuItem(value: 'PDF', child: Text('PDF')),
              DropdownMenuItem(value: 'Image', child: Text('Image')),
              DropdownMenuItem(value: 'Document', child: Text('Document')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              if (_nameController.text.trim().isEmpty || _pickedPath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Pick a file and add a file name.')),
                );
                return;
              }
              context.read<AppState>().addNote(
                    name: _nameController.text.trim(),
                    subject: _subjectController.text.trim().isEmpty
                        ? 'General'
                        : _subjectController.text.trim(),
                    year: _yearController.text.trim().isEmpty
                        ? '2026'
                        : _yearController.text.trim(),
                    type: _selectedType,
                    keywords: _keywordsController.text.trim(),
                    localPath: _pickedPath,
                  );
              _nameController.clear();
              _subjectController.clear();
              _yearController.clear();
              _keywordsController.clear();
              setState(() {
                _pickedPath = null;
                _pickedName = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note uploaded and listed under subject.'),
                ),
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: subjectOptions.contains(_subjectFilter)
                ? _subjectFilter
                : 'All',
            decoration: const InputDecoration(labelText: 'Subject Filter'),
            items: subjectOptions
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _subjectFilter = value;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search by name / year / keyword',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
          ),
          const SizedBox(height: 12),
          ...notes.map(
            (note) => Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(note.name),
                subtitle: Text(
                  '${note.subject} • ${note.year} • ${note.type}\n${note.keywords}\n${note.localPath ?? 'No file path'}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _showEditNoteDialog(context, note.id);
                    }
                    if (value == 'delete' && context.mounted) {
                      context.read<AppState>().deleteNote(note.id);
                    }
                    if (value == 'more' && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'More options for ${note.name} coming soon.')),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                    PopupMenuItem(value: 'more', child: Text('More Options')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'txt'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    String? fileRef;
    if (kIsWeb) {
      fileRef = 'web://${file.name}';
    } else {
      fileRef = file.path;
    }

    if (fileRef == null || fileRef.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access selected file data.')),
      );
      return;
    }

    final lowerName = file.name.toLowerCase();
    String inferredType = 'Document';
    if (lowerName.endsWith('.pdf')) {
      inferredType = 'PDF';
    } else if (lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg')) {
      inferredType = 'Image';
    }

    setState(() {
      _pickedPath = fileRef;
      _pickedName = file.name;
      _selectedType = inferredType;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = file.name;
      }
    });
  }

  Future<void> _showEditNoteDialog(BuildContext context, String noteId) async {
    final appState = context.read<AppState>();
    final note = appState.notes.firstWhere((item) => item.id == noteId);

    final nameController = TextEditingController(text: note.name);
    final subjectController = TextEditingController(text: note.subject);
    final yearController = TextEditingController(text: note.year);
    final keywordsController = TextEditingController(text: note.keywords);
    String type = note.type;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'File name')),
                TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Subject')),
                TextField(
                    controller: yearController,
                    decoration: const InputDecoration(labelText: 'Year')),
                TextField(
                    controller: keywordsController,
                    decoration: const InputDecoration(labelText: 'Keywords')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                    DropdownMenuItem(value: 'Image', child: Text('Image')),
                    DropdownMenuItem(
                        value: 'Document', child: Text('Document')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        type = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                appState.updateNote(
                  id: noteId,
                  name: nameController.text.trim().isEmpty
                      ? note.name
                      : nameController.text.trim(),
                  subject: subjectController.text.trim().isEmpty
                      ? note.subject
                      : subjectController.text.trim(),
                  year: yearController.text.trim().isEmpty
                      ? note.year
                      : yearController.text.trim(),
                  type: type,
                  keywords: keywordsController.text.trim(),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
