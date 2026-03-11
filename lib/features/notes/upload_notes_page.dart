import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/note_item.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/web_file_utils_stub.dart'
  if (dart.library.html) '../../core/utils/web_file_utils_web.dart';

class UploadNotesPage extends StatefulWidget {
  const UploadNotesPage({super.key, this.initialSubject});

  final String? initialSubject;

  @override
  State<UploadNotesPage> createState() => _UploadNotesPageState();
}

class _UploadNotesPageState extends State<UploadNotesPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _yearController = TextEditingController();
  final _keywordsController = TextEditingController();

  String _selectedType = 'PDF';
  String _search = '';
  String _subjectFilter = 'All';
  String? _pickedName;
  Uint8List? _pickedBytes;
  bool _showContent = false;
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _subjectFilter = widget.initialSubject ?? 'All';
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showContent = true;
      });
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
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
      if (note.localPath == null || note.localPath!.trim().isEmpty) {
        return false;
      }
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
      appBar: AppBar(
        title: Text(
          'Upload Notes',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
        foregroundColor: const Color(0xFF2E3C54),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          final driftA = math.sin(t * math.pi * 2) * 12;
          final driftB = math.cos(t * math.pi * 2) * 10;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7F2EA), Color(0xFFE8F1F8), Color(0xFFF6ECE4)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80 + driftA,
                  right: -40,
                  child: _bgGlow(250, const Color(0xFFB2D9EA)),
                ),
                Positioned(
                  left: -70,
                  bottom: -120 + driftB,
                  child: _bgGlow(290, const Color(0xFFE5C5A3)),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isMobile = width < 760;
                      final isTablet = width >= 760 && width < 1120;
                      final maxContentWidth = isMobile
                          ? width
                          : isTablet
                              ? 980.0
                              : 1220.0;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContentWidth),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              isMobile ? 8 : 14,
                              8,
                              isMobile ? 8 : 14,
                              18,
                            ),
                            children: [
                      _entryAnim(
                        delay: 0,
                        child: _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add notes / PDF / documents',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: const Color(0xFF2D3C57),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _nameController,
                                decoration: _fieldDecoration('File name'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _subjectController,
                                decoration: _fieldDecoration('Subject'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _yearController,
                                decoration: _fieldDecoration('Year'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _keywordsController,
                                decoration: _fieldDecoration('Keywords'),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _pickFile,
                                      icon: const Icon(Icons.attach_file),
                                      label: const Text('Pick File (PDF/Image/Doc)'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF355B77),
                                        side: const BorderSide(color: Color(0xFFC9D8E7)),
                                        padding: const EdgeInsets.symmetric(vertical: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_pickedName != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Selected: $_pickedName',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2F4762),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: _selectedType,
                                decoration: _fieldDecoration('Type'),
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
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    if (_nameController.text.trim().isEmpty || _pickedBytes == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Pick a file and add a file name.')),
                                      );
                                      return;
                                    }
                                    final error = await context.read<AppState>().uploadNote(
                                          name: _nameController.text.trim(),
                                          subject: _subjectController.text.trim().isEmpty
                                              ? 'General'
                                              : _subjectController.text.trim(),
                                          year: _yearController.text.trim().isEmpty
                                              ? '2026'
                                              : _yearController.text.trim(),
                                          type: _selectedType,
                                          keywords: _keywordsController.text.trim(),
                                          fileBytes: _pickedBytes!,
                                          originalFileName: _pickedName ?? _nameController.text.trim(),
                                        );
                                    if (error != null) {
                                      if (!context.mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(error)));
                                      return;
                                    }
                                    _nameController.clear();
                                    _subjectController.clear();
                                    _yearController.clear();
                                    _keywordsController.clear();
                                    setState(() {
                                      _pickedName = null;
                                      _pickedBytes = null;
                                    });
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Note uploaded and listed under subject.'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: const Color(0xFF2F6F8F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _entryAnim(
                        delay: 60,
                        child: _sectionCard(
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: subjectOptions.contains(_subjectFilter)
                                    ? _subjectFilter
                                    : 'All',
                                decoration: _fieldDecoration('Subject Filter'),
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
                                decoration: _fieldDecoration(
                                  'Search by name / year / keyword',
                                  prefixIcon: const Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _search = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (notes.isEmpty)
                        _entryAnim(
                          delay: 100,
                          child: _sectionCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.info_outline_rounded),
                              title: Text(
                                'No uploaded files yet.',
                                style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ...notes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final note = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _entryAnim(
                            delay: 120 + (index * 35),
                            child: _sectionCard(
                              child: ListTile(
                                leading: Container(
                                  height: 38,
                                  width: 38,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color(0xFFE9F3FB),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: Color(0xFF355B77),
                                  ),
                                ),
                                title: Text(
                                  note.name,
                                  style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
                                ),
                                subtitle: Text(
                                  '${note.subject} • ${note.year} • ${note.type}\n${note.keywords}',
                                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                                ),
                                isThreeLine: true,
                                onTap: () => _openNoteFile(note.localPath),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _showEditNoteDialog(context, note.id);
                                    }
                                    if (value == 'download') {
                                      await _downloadNoteFile(note);
                                    }
                                    if (value == 'delete' && context.mounted) {
                                      await context.read<AppState>().deleteNote(note.id);
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
                                    PopupMenuItem(value: 'download', child: Text('Download')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    PopupMenuItem(value: 'more', child: Text('More Options')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD3DFEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A244C6E),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _fieldDecoration(String label, {Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.85),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD2DEEA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD2DEEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF5F8FB2), width: 1.4),
      ),
    );
  }

  Widget _entryAnim({required Widget child, required int delay}) {
    return AnimatedSlide(
      duration: Duration(milliseconds: 450 + delay),
      curve: Curves.easeOutCubic,
      offset: _showContent ? Offset.zero : const Offset(0, 0.06),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 380 + delay),
        curve: Curves.easeOut,
        opacity: _showContent ? 1 : 0,
        child: child,
      ),
    );
  }

  Widget _bgGlow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.34),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'txt'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
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
      _pickedName = file.name;
      _pickedBytes = bytes;
      _selectedType = inferredType;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = file.name;
      }
    });
  }

  Future<void> _openNoteFile(String? storedPath) async {
    if (storedPath == null || storedPath.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No uploaded file found for this note.')),
      );
      return;
    }

    final resolvedUrl =
        await context.read<AppState>().createFileAccessUrl(storedPath);
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load this file.')),
      );
      return;
    }

    bool launched;
    if (kIsWeb) {
      launched = openUrlInNewTab(resolvedUrl);
    } else {
      launched = await launchUrl(
        Uri.parse(resolvedUrl),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the selected file.')),
      );
    }
  }

  Future<void> _downloadNoteFile(NoteItem note) async {
    final storedPath = note.localPath;
    if (storedPath == null || storedPath.trim().isEmpty) {
      return;
    }

    final resolvedUrl =
        await context.read<AppState>().createFileAccessUrl(storedPath);
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not prepare download.')),
      );
      return;
    }

    bool launched;
    if (kIsWeb) {
      launched = await downloadUrlInBrowser(resolvedUrl, note.name);
    } else {
      launched = await launchUrl(
        Uri.parse(resolvedUrl),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not download the selected file.')),
      );
    }
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
              onPressed: () async {
                await appState.updateNote(
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
