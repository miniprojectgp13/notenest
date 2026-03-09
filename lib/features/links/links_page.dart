import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/link_item.dart';
import '../../core/state/app_state.dart';

class LinksPage extends StatefulWidget {
  const LinksPage({super.key});

  @override
  State<LinksPage> createState() => _LinksPageState();
}

class _LinksPageState extends State<LinksPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String? _selectedFolderId;
  String? _selectedSubFolderId;

  @override
  void dispose() {
    _urlController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final folders = appState.urlFolders;

    if (folders.isNotEmpty &&
        (_selectedFolderId == null ||
            folders.every((folder) => folder.id != _selectedFolderId))) {
      _selectedFolderId = folders.first.id;
      _selectedSubFolderId = null;
    }

    final selectedFolder = _selectedFolderId == null
        ? null
        : folders.firstWhere((item) => item.id == _selectedFolderId);

    final links = appState.savedUrls.where((item) {
      if (_selectedFolderId == null) {
        return true;
      }
      return item.folderId == _selectedFolderId;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Links Manager'),
        actions: [
          IconButton(
            onPressed:
                folders.isEmpty ? null : () => _showRenameFolderDialog(context),
            tooltip: 'Edit selected folder',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed:
                folders.isEmpty ? null : () => _deleteSelectedFolder(context),
            tooltip: 'Delete selected folder',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          if (isWide) {
            return Row(
              children: [
                SizedBox(
                    width: 360, child: _folderPanel(context, selectedFolder)),
                const VerticalDivider(width: 1),
                Expanded(child: _urlPanel(context, selectedFolder, links)),
              ],
            );
          }
          return Column(
            children: [
              _folderPanel(context, selectedFolder),
              const Divider(height: 1),
              Expanded(child: _urlPanel(context, selectedFolder, links)),
            ],
          );
        },
      ),
    );
  }

  Widget _folderPanel(BuildContext context, UrlFolder? selectedFolder) {
    final appState = context.watch<AppState>();
    final folders = appState.urlFolders;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F3FF), Color(0xFFF0F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Folder',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCreateFolderDialog(context),
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('New Folder'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selectedFolder == null
                      ? null
                      : () => _showCreateSubFolderDialog(
                          context, selectedFolder.id),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('New Subfolder'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedFolderId,
            decoration:
                const InputDecoration(labelText: 'Select existing folder'),
            items: folders
                .map((folder) => DropdownMenuItem(
                    value: folder.id, child: Text(folder.name)))
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedFolderId = value;
                _selectedSubFolderId = null;
              });
            },
          ),
          const SizedBox(height: 10),
          if (selectedFolder != null)
            DropdownButtonFormField<String?>(
              value: _selectedSubFolderId,
              decoration: const InputDecoration(
                  labelText: 'Select subfolder (optional)'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('No subfolder')),
                ...selectedFolder.subFolders.map(
                  (sub) => DropdownMenuItem<String?>(
                      value: sub.id, child: Text(sub.name)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubFolderId = value;
                });
              },
            ),
          const SizedBox(height: 12),
          const Text('Folders', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: folders.isEmpty
                  ? const Center(child: Text('Create a folder to start.'))
                  : ListView.builder(
                      key: ValueKey(folders.length),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        final selected = folder.id == _selectedFolderId;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFE8DEFF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF8D70F8)
                                  : const Color(0xFFD9D3EA),
                            ),
                          ),
                          child: ListTile(
                            title: Text(folder.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle:
                                Text('${folder.subFolders.length} subfolders'),
                            onTap: () {
                              setState(() {
                                _selectedFolderId = folder.id;
                                _selectedSubFolderId = null;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _urlPanel(BuildContext context, UrlFolder? selectedFolder,
      List<SavedUrlItem> links) {
    final appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF9A86FF), Color(0xFF6CC9D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x304A43A1),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'URL Upload Section',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedFolder == null
                      ? 'No folder selected'
                      : 'Selected folder: ${selectedFolder.name}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Paste URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Content / notes for URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: selectedFolder == null
                        ? null
                        : () {
                            final url = _urlController.text.trim();
                            if (url.isEmpty) {
                              return;
                            }
                            appState.saveUrl(
                              url: url,
                              folderId: selectedFolder.id,
                              subFolderId: _selectedSubFolderId,
                              content: _contentController.text,
                            );
                            _contentController.clear();
                            _urlController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'URL saved as content successfully.')),
                            );
                          },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save URL'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Saved URLs',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: links.isEmpty
                  ? const Center(child: Text('No URLs in selected folder.'))
                  : ListView.builder(
                      key: ValueKey('${_selectedFolderId}_${links.length}'),
                      itemCount: links.length,
                      itemBuilder: (context, index) {
                        final item = links[index];
                        final folder = appState.urlFolders
                            .firstWhere((f) => f.id == item.folderId);
                        String section = folder.name;
                        if (item.subFolderId != null) {
                          final sub = folder.subFolders
                              .where((s) => s.id == item.subFolderId)
                              .toList();
                          if (sub.isNotEmpty) {
                            section = '$section / ${sub.first.name}';
                          }
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(item.url,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '$section\n${item.content}\n${DateFormat('d MMM, h:mm a').format(item.createdAt)}',
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'copy') {
                                  await Clipboard.setData(
                                      ClipboardData(text: item.url));
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('URL copied.')),
                                  );
                                }
                                if (value == 'edit' && context.mounted) {
                                  _showEditUrlDialog(context, item);
                                }
                                if (value == 'delete' && context.mounted) {
                                  context
                                      .read<AppState>()
                                      .deleteSavedUrl(item.id);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                    value: 'copy', child: Text('Copy URL')),
                                PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<AppState>().addUrlFolder(controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateSubFolderDialog(
      BuildContext context, String folderId) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Subfolder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Subfolder name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context
                  .read<AppState>()
                  .addUrlSubFolder(folderId: folderId, name: controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameFolderDialog(BuildContext context) async {
    final appState = context.read<AppState>();
    if (_selectedFolderId == null) {
      return;
    }
    final folder =
        appState.urlFolders.firstWhere((item) => item.id == _selectedFolderId);
    final controller = TextEditingController(text: folder.name);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Folder Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              appState.renameUrlFolder(
                  folderId: folder.id, newName: controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedFolder(BuildContext context) async {
    if (_selectedFolderId == null) {
      return;
    }
    final appState = context.read<AppState>();
    final folder =
        appState.urlFolders.firstWhere((item) => item.id == _selectedFolderId);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete folder'),
        content: Text('Delete folder ${folder.name} and all URLs in it?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    appState.deleteUrlFolder(folder.id);
    setState(() {
      _selectedFolderId =
          appState.urlFolders.isEmpty ? null : appState.urlFolders.first.id;
      _selectedSubFolderId = null;
    });
  }

  Future<void> _showEditUrlDialog(
      BuildContext context, SavedUrlItem item) async {
    final appState = context.read<AppState>();
    final urlController = TextEditingController(text: item.url);
    final contentController = TextEditingController(text: item.content);

    String folderId = item.folderId;
    String? subFolderId = item.subFolderId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final folder =
              appState.urlFolders.firstWhere((f) => f.id == folderId);
          return AlertDialog(
            title: const Text('Edit Saved URL'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(labelText: 'URL'),
                  ),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: 'Content'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: folderId,
                    decoration: const InputDecoration(labelText: 'Folder'),
                    items: appState.urlFolders
                        .map((entry) => DropdownMenuItem(
                            value: entry.id, child: Text(entry.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        folderId = value;
                        subFolderId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: subFolderId,
                    decoration: const InputDecoration(labelText: 'Subfolder'),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('No subfolder')),
                      ...folder.subFolders.map(
                        (entry) => DropdownMenuItem<String?>(
                            value: entry.id, child: Text(entry.name)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        subFolderId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  appState.updateSavedUrl(
                    id: item.id,
                    url: urlController.text,
                    content: contentController.text,
                    folderId: folderId,
                    subFolderId: subFolderId,
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
