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
  String? _uploadFolderId;
  String? _activeDropFolderId;
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
    final folders = appState.noteFolders;
    final folderById = {for (final folder in folders) folder.id: folder};

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
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final looseNotes = notes.where((note) => note.folderId == null).toList();

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
                colors: [
                  Color(0xFFF7F2EA),
                  Color(0xFFE8F1F8),
                  Color(0xFFF6ECE4)
                ],
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
                          constraints:
                              BoxConstraints(maxWidth: maxContentWidth),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        decoration:
                                            _fieldDecoration('File name'),
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
                                        decoration:
                                            _fieldDecoration('Keywords'),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String?>(
                                        value: _uploadFolderId,
                                        decoration: _fieldDecoration(
                                            'Folder (optional)'),
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('No folder'),
                                          ),
                                          ...folders.map(
                                            (folder) =>
                                                DropdownMenuItem<String?>(
                                              value: folder.id,
                                              child: Text(folder.name),
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _uploadFolderId = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _pickFile,
                                              icon:
                                                  const Icon(Icons.attach_file),
                                              label: const Text(
                                                  'Pick File (PDF/Image/Doc)'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    const Color(0xFF355B77),
                                                side: const BorderSide(
                                                    color: Color(0xFFC9D8E7)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 13),
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
                                          DropdownMenuItem(
                                              value: 'PDF', child: Text('PDF')),
                                          DropdownMenuItem(
                                              value: 'Image',
                                              child: Text('Image')),
                                          DropdownMenuItem(
                                              value: 'Document',
                                              child: Text('Document')),
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
                                          onPressed: () => _uploadPickedNote(
                                              folderId: _uploadFolderId),
                                          icon: const Icon(Icons.upload_file),
                                          label: const Text('Upload'),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            backgroundColor:
                                                const Color(0xFF2F6F8F),
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
                                        value: subjectOptions
                                                .contains(_subjectFilter)
                                            ? _subjectFilter
                                            : 'All',
                                        decoration:
                                            _fieldDecoration('Subject Filter'),
                                        items: subjectOptions
                                            .map((item) => DropdownMenuItem(
                                                value: item, child: Text(item)))
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
                              _entryAnim(
                                delay: 90,
                                child: _sectionCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Folders',
                                              style: GoogleFonts.nunito(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF2D3C57),
                                              ),
                                            ),
                                          ),
                                          FilledButton.icon(
                                            onPressed: _showCreateFolderDialog,
                                            icon: const Icon(Icons
                                                .create_new_folder_outlined),
                                            label: const Text('Create Folder'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (folders.isEmpty)
                                        Text(
                                          'No folders yet. Create one and drag notes into it.',
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF506A83),
                                          ),
                                        )
                                      else
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: folders.map((folder) {
                                            final folderNotes = notes
                                                .where((item) =>
                                                    item.folderId == folder.id)
                                                .toList();
                                            final isActive =
                                                _activeDropFolderId ==
                                                    folder.id;

                                            return DragTarget<NoteItem>(
                                              onWillAcceptWithDetails: (_) {
                                                setState(() {
                                                  _activeDropFolderId =
                                                      folder.id;
                                                });
                                                return true;
                                              },
                                              onLeave: (_) {
                                                if (_activeDropFolderId ==
                                                    folder.id) {
                                                  setState(() {
                                                    _activeDropFolderId = null;
                                                  });
                                                }
                                              },
                                              onAcceptWithDetails:
                                                  (details) async {
                                                await context
                                                    .read<AppState>()
                                                    .moveNoteToFolder(
                                                      noteId: details.data.id,
                                                      folderId: folder.id,
                                                    );
                                                if (!mounted) {
                                                  return;
                                                }
                                                setState(() {
                                                  _activeDropFolderId = null;
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Moved ${details.data.name} to ${folder.name}.',
                                                    ),
                                                  ),
                                                );
                                              },
                                              builder: (context, candidateData,
                                                  rejectedData) {
                                                final isHovered = isActive ||
                                                    candidateData.isNotEmpty;
                                                return AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 220),
                                                  width: isMobile
                                                      ? double.infinity
                                                      : 280,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    color: isHovered
                                                        ? const Color(
                                                            0xFFDDF0FC)
                                                        : Colors.white
                                                            .withValues(
                                                                alpha: 0.85),
                                                    border: Border.all(
                                                      color: isHovered
                                                          ? const Color(
                                                              0xFF3C84AD)
                                                          : const Color(
                                                              0xFFCADBE8),
                                                      width: isHovered ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    onTap: () =>
                                                        _openFolderSheet(
                                                            folder),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .folder_copy_rounded,
                                                                color: Color(
                                                                    0xFF2F6F8F),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  folder.name,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      GoogleFonts
                                                                          .nunito(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900,
                                                                    color: const Color(
                                                                        0xFF2F4762),
                                                                  ),
                                                                ),
                                                              ),
                                                              PopupMenuButton<
                                                                  String>(
                                                                onSelected:
                                                                    (value) async {
                                                                  if (value ==
                                                                      'open') {
                                                                    _openFolderSheet(
                                                                        folder);
                                                                  }
                                                                  if (value ==
                                                                      'rename') {
                                                                    await _showRenameFolderDialog(
                                                                        folder);
                                                                  }
                                                                  if (value ==
                                                                      'delete') {
                                                                    await context
                                                                        .read<
                                                                            AppState>()
                                                                        .deleteNoteFolder(
                                                                            folder.id);
                                                                  }
                                                                },
                                                                itemBuilder:
                                                                    (context) =>
                                                                        const [
                                                                  PopupMenuItem(
                                                                    value:
                                                                        'open',
                                                                    child: Text(
                                                                        'Open'),
                                                                  ),
                                                                  PopupMenuItem(
                                                                    value:
                                                                        'rename',
                                                                    child: Text(
                                                                        'Rename'),
                                                                  ),
                                                                  PopupMenuItem(
                                                                    value:
                                                                        'delete',
                                                                    child: Text(
                                                                        'Delete'),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 6),
                                                          Text(
                                                            '${folderNotes.length} item(s)',
                                                            style: GoogleFonts
                                                                .nunito(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: const Color(
                                                                  0xFF5B768E),
                                                            ),
                                                          ),
                                                          if (isHovered) ...[
                                                            const SizedBox(
                                                                height: 7),
                                                            Text(
                                                              'Drop to move note here',
                                                              style: GoogleFonts
                                                                  .nunito(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color: const Color(
                                                                    0xFF2F6F8F),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }).toList(),
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
                                      leading: const Icon(
                                          Icons.info_outline_rounded),
                                      title: Text(
                                        'No uploaded files yet.',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                ),
                              if (looseNotes.isNotEmpty)
                                _entryAnim(
                                  delay: 120,
                                  child: _sectionCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Unsorted Notes (Drag into folders)',
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF2D3C57),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...looseNotes.map(
                                          (note) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Draggable<NoteItem>(
                                              data: note,
                                              dragAnchorStrategy:
                                                  pointerDragAnchorStrategy,
                                              feedback: Material(
                                                color: Colors.transparent,
                                                child: ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                    maxWidth: 360,
                                                  ),
                                                  child: _noteTile(
                                                    note,
                                                    folderById,
                                                    compact: true,
                                                  ),
                                                ),
                                              ),
                                              childWhenDragging: Opacity(
                                                opacity: 0.36,
                                                child:
                                                    _noteTile(note, folderById),
                                              ),
                                              child: MouseRegion(
                                                cursor: SystemMouseCursors.grab,
                                                child:
                                                    _noteTile(note, folderById),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (looseNotes.isEmpty && notes.isNotEmpty)
                                _entryAnim(
                                  delay: 140,
                                  child: _sectionCard(
                                    child: Text(
                                      'All filtered notes are organized in folders. Open any folder to manage or download files.',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF4E667D),
                                      ),
                                    ),
                                  ),
                                ),
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

  Future<void> _uploadPickedNote({String? folderId}) async {
    if (_nameController.text.trim().isEmpty || _pickedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a file and add a file name.')),
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
          folderId: folderId,
        );

    if (error != null) {
      if (!mounted) {
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
      _uploadFolderId = folderId;
    });
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          folderId == null
              ? 'Note uploaded successfully.'
              : 'Note uploaded to selected folder.',
        ),
      ),
    );
  }

  Widget _noteTile(
    NoteItem note,
    Map<String, NoteFolder> folderById, {
    bool compact = false,
  }) {
    final folderName = note.folderId == null
        ? 'No folder'
        : (folderById[note.folderId!]?.name ?? 'Folder');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFFD2E0EC)),
      ),
      child: ListTile(
        dense: compact,
        leading: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFE9F3FB),
          ),
          child: Icon(
            note.type == 'Image'
                ? Icons.image_outlined
                : Icons.description_outlined,
            color: const Color(0xFF355B77),
          ),
        ),
        title: Text(
          note.name,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${note.subject} • ${note.year} • ${note.type}\n$folderName',
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
            if (value == 'remove-folder') {
              await context.read<AppState>().moveNoteToFolder(noteId: note.id);
            }
            if (value == 'delete' && mounted) {
              await context.read<AppState>().deleteNote(note.id);
            }
          },
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'download', child: Text('Download')),
            ];
            if (note.folderId != null) {
              items.add(
                const PopupMenuItem(
                  value: 'remove-folder',
                  child: Text('Remove from folder'),
                ),
              );
            }
            items.add(
                const PopupMenuItem(value: 'delete', child: Text('Delete')));
            return items;
          },
        ),
      ),
    );
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final error =
                  await context.read<AppState>().addNoteFolder(controller.text);
              if (!context.mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              if (error != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameFolderDialog(NoteFolder folder) async {
    final controller = TextEditingController(text: folder.name);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppState>().renameNoteFolder(
                    folderId: folder.id,
                    newName: controller.text,
                  );
              if (!context.mounted) {
                return;
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFolderSheet(NoteFolder folder) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (context, controller) {
            return Consumer<AppState>(
              builder: (context, appState, _) {
                final folderNotes = appState.notes
                    .where((note) => note.folderId == folder.id)
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final folderById = {
                  for (final item in appState.noteFolders) item.id: item,
                };

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F8FC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      Center(
                        child: Container(
                          height: 5,
                          width: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB9CAD8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              folderById[folder.id]?.name ?? folder.name,
                              style: GoogleFonts.nunito(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2D3C57),
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _showFolderUploadDialog(folder.id),
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Upload'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap any file to open it. Use download for image/file export.',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF587187),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (folderNotes.isEmpty)
                        _sectionCard(
                          child: Text(
                            'Folder is empty. Upload directly here or drag notes into this folder.',
                            style:
                                GoogleFonts.nunito(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ...folderNotes.map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _noteTile(note, folderById),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showFolderUploadDialog(String folderId) async {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final yearController = TextEditingController(text: '2026');
    final keywordsController = TextEditingController();
    String selectedType = 'Document';
    String? pickedName;
    Uint8List? pickedBytes;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Upload Into Folder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'File name'),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: yearController,
                  decoration: const InputDecoration(labelText: 'Year'),
                ),
                TextField(
                  controller: keywordsController,
                  decoration: const InputDecoration(labelText: 'Keywords'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                    DropdownMenuItem(value: 'Image', child: Text('Image')),
                    DropdownMenuItem(
                        value: 'Document', child: Text('Document')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      withData: true,
                      allowedExtensions: [
                        'pdf',
                        'png',
                        'jpg',
                        'jpeg',
                        'doc',
                        'docx',
                        'txt'
                      ],
                    );
                    if (result == null || result.files.isEmpty) {
                      return;
                    }
                    final file = result.files.single;
                    if (file.bytes == null) {
                      return;
                    }
                    setDialogState(() {
                      pickedName = file.name;
                      pickedBytes = file.bytes;
                      selectedType = _inferTypeFromFileName(file.name);
                      if (nameController.text.trim().isEmpty) {
                        nameController.text = file.name;
                      }
                    });
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pick File'),
                ),
                if (pickedName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Selected: $pickedName',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
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
                if (pickedBytes == null || nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please choose a file and name.')),
                  );
                  return;
                }
                final error = await context.read<AppState>().uploadNote(
                      name: nameController.text.trim(),
                      subject: subjectController.text.trim().isEmpty
                          ? 'General'
                          : subjectController.text.trim(),
                      year: yearController.text.trim().isEmpty
                          ? '2026'
                          : yearController.text.trim(),
                      type: selectedType,
                      keywords: keywordsController.text.trim(),
                      fileBytes: pickedBytes!,
                      originalFileName:
                          pickedName ?? nameController.text.trim(),
                      folderId: folderId,
                    );
                if (!context.mounted) {
                  return;
                }
                if (error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  String _inferTypeFromFileName(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.pdf')) {
      return 'PDF';
    }
    if (lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg')) {
      return 'Image';
    }
    return 'Document';
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
    String? folderId = note.folderId;

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
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: folderId,
                  decoration: const InputDecoration(labelText: 'Folder'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No folder'),
                    ),
                    ...appState.noteFolders.map(
                      (folder) => DropdownMenuItem<String?>(
                        value: folder.id,
                        child: Text(folder.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      folderId = value;
                    });
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
                  folderId: folderId,
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
