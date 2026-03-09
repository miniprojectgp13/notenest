import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/group_item.dart';
import '../../core/state/app_state.dart';

enum ChatPanelMode { groups, personal }

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  ChatPanelMode mode = ChatPanelMode.groups;
  String? selectedGroupId;
  String? selectedDirectId;

  final TextEditingController _groupMessageController = TextEditingController();
  final TextEditingController _directMessageController =
      TextEditingController();

  @override
  void dispose() {
    _groupMessageController.dispose();
    _directMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final groups = appState.groups;

    if (groups.isNotEmpty && selectedGroupId == null) {
      selectedGroupId = groups.first.id;
    }

    if (appState.directChatIds.isNotEmpty && selectedDirectId == null) {
      selectedDirectId = appState.directChatIds.first;
    }

    final GroupItem? selectedGroup =
        groups.where((g) => g.id == selectedGroupId).isEmpty
            ? (groups.isEmpty ? null : groups.first)
            : groups.firstWhere((g) => g.id == selectedGroupId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Group & Chat',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Open Personal Chat',
            onPressed: () => _openDirectChatDialog(context),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.icon(
              onPressed: () => _showCreateGroupDialog(context),
              icon: const Icon(Icons.group_add),
              label: const Text('Create Group'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F4FF), Color(0xFFF0EEF8)],
          ),
        ),
        child: Row(
          children: [
            _leftPanel(context),
            const VerticalDivider(width: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                child: mode == ChatPanelMode.groups
                    ? (selectedGroup == null
                        ? const Center(child: Text('Create your first group'))
                        : _groupChatArea(context, selectedGroup))
                    : _personalChatArea(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftPanel(BuildContext context) {
    final appState = context.watch<AppState>();
    final groups = appState.groups;
    final directIds = appState.directChatIds;

    return Container(
      width: 260,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9D1F8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Groups'),
                    selected: mode == ChatPanelMode.groups,
                    onSelected: (_) {
                      setState(() {
                        mode = ChatPanelMode.groups;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Personal'),
                    selected: mode == ChatPanelMode.personal,
                    onSelected: (_) {
                      setState(() {
                        mode = ChatPanelMode.personal;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: mode == ChatPanelMode.groups
                ? ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final isSelected = selectedGroupId == group.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: _leftItem(
                          isSelected: isSelected,
                          title: group.name,
                          subtitle:
                              '${group.members.length} members • ${group.id}',
                          onTap: () {
                            setState(() {
                              selectedGroupId = group.id;
                              mode = ChatPanelMode.groups;
                            });
                          },
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: directIds.length,
                    itemBuilder: (context, index) {
                      final id = directIds[index];
                      final messages = appState.directMessagesFor(id);
                      final preview = messages.isEmpty
                          ? 'No messages yet'
                          : messages.last.content;
                      final isSelected = selectedDirectId == id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: _leftItem(
                          isSelected: isSelected,
                          title: appState.directChatDisplayName(id),
                          subtitle: '$id\n$preview',
                          onTap: () {
                            setState(() {
                              selectedDirectId = id;
                              mode = ChatPanelMode.personal;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _leftItem({
    required bool isSelected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected ? const Color(0xFFEAE3FF) : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B79FF)
                  : const Color(0x00FFFFFF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4B4474)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7E74AF),
                    fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupChatArea(BuildContext context, GroupItem group) {
    final appState = context.watch<AppState>();

    return Column(
      key: ValueKey('group-${group.id}'),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
                colors: [Color(0xFFECE8FF), Color(0xFFE7F2FF)]),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 3),
                    Text(
                      group.members
                          .map((m) => '${m.name} (${m.uniqueId})')
                          .join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF645D8A)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit Group Name',
                onPressed: () => _showRenameGroupDialog(context, group),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Add Member',
                onPressed: () => _showAddMemberDialog(context, group.id),
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            ],
          ),
        ),
        if (group.attachments.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              itemCount: group.attachments.length,
              itemBuilder: (context, index) {
                final a = group.attachments[index];
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EEFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8CFFC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file_rounded, size: 17),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(a.fileName,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text('${a.fileType} • ${a.sentBy}',
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: group.messages.length,
            itemBuilder: (context, index) {
              final message = group.messages[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 260),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                      offset: Offset((1 - value) * 18, 0), child: child),
                ),
                child: Align(
                  alignment: message.isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: message.isMine
                          ? const Color(0xFFDDE9FF)
                          : const Color(0xFFF5F2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: message.isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(message.content),
                        if (message.attachmentName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _attachmentChip(
                              message.attachmentName!,
                              message.attachmentType ?? 'File',
                            ),
                          ),
                        Text(
                          '${message.sender} • ${DateFormat('h:mm a').format(message.sentAt)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        if (message.isMine)
                          const Icon(Icons.done_all_rounded,
                              size: 14, color: Color(0xFF2F8DFF)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _pickAndShareGroupFile(group.id),
                icon: const Icon(Icons.attach_file_rounded),
                tooltip: 'Share file/document',
              ),
              IconButton(
                onPressed: () =>
                    _showEmojiPicker(context, _groupMessageController),
                icon: const Icon(Icons.emoji_emotions_outlined),
                tooltip: 'Emoji',
              ),
              Expanded(
                child: TextField(
                  controller: _groupMessageController,
                  decoration:
                      const InputDecoration(hintText: 'Message in group...'),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12)),
                onPressed: () {
                  final content = _groupMessageController.text.trim();
                  if (content.isEmpty) {
                    return;
                  }
                  appState.sendGroupMessage(
                    groupId: group.id,
                    sender: appState.profile.uniqueId,
                    content: content,
                    isMine: true,
                  );
                  _groupMessageController.clear();
                },
                child: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _personalChatArea(BuildContext context) {
    final appState = context.watch<AppState>();
    final id = selectedDirectId;
    if (id == null) {
      return const Center(child: Text('Open personal chat with unique ID'));
    }
    final messages = appState.directMessagesFor(id);

    return Column(
      key: ValueKey('direct-$id'),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
                colors: [Color(0xFFEFF3FF), Color(0xFFF3EEFF)]),
          ),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person_outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appState.directChatDisplayName(id),
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
                    Text(id,
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6C6496))),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final m = messages[index];
              return Align(
                alignment:
                    m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: m.isMine
                        ? const Color(0xFFDDE9FF)
                        : const Color(0xFFF4F0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: m.isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(m.content),
                      if (m.attachmentName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _attachmentChip(
                            m.attachmentName!,
                            m.attachmentType ?? 'File',
                          ),
                        ),
                      Text(DateFormat('h:mm a').format(m.sentAt),
                          style: const TextStyle(fontSize: 11)),
                      if (m.isMine)
                        const Icon(Icons.done_all_rounded,
                            size: 14, color: Color(0xFF2F8DFF)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _pickAndSendDirectFile(id),
                icon: const Icon(Icons.attach_file_rounded),
                tooltip: 'Share file/image',
              ),
              IconButton(
                onPressed: () =>
                    _showEmojiPicker(context, _directMessageController),
                icon: const Icon(Icons.emoji_emotions_outlined),
                tooltip: 'Emoji',
              ),
              Expanded(
                child: TextField(
                  controller: _directMessageController,
                  decoration: const InputDecoration(
                      hintText: 'Send private message...'),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12)),
                onPressed: () {
                  final content = _directMessageController.text.trim();
                  if (content.isEmpty) {
                    return;
                  }
                  appState.sendDirectMessage(
                    targetUniqueId: id,
                    sender: appState.profile.uniqueId,
                    content: content,
                    isMine: true,
                  );
                  _directMessageController.clear();
                },
                child: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final List<TextEditingController> memberNameControllers = [
      TextEditingController()
    ];
    final List<TextEditingController> memberIdControllers = [
      TextEditingController()
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Group'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Group Name'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Members (Name + Unique ID)'),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                memberNameControllers
                                    .add(TextEditingController());
                                memberIdControllers
                                    .add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      for (int i = 0; i < memberNameControllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: memberNameControllers[i],
                                  decoration:
                                      const InputDecoration(labelText: 'Name'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: memberIdControllers[i],
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                      labelText: 'Unique ID'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final groupName = nameController.text.trim();
                    if (groupName.isEmpty) {
                      return;
                    }
                    final members = <GroupMember>[];
                    for (int i = 0; i < memberNameControllers.length; i++) {
                      final name = memberNameControllers[i].text.trim();
                      final id =
                          memberIdControllers[i].text.trim().toUpperCase();
                      if (name.isNotEmpty && id.isNotEmpty) {
                        members.add(GroupMember(name: name, uniqueId: id));
                      }
                    }
                    context
                        .read<AppState>()
                        .addGroup(name: groupName, members: members);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    for (final c in memberNameControllers) {
      c.dispose();
    }
    for (final c in memberIdControllers) {
      c.dispose();
    }
  }

  Future<void> _showRenameGroupDialog(
      BuildContext context, GroupItem group) async {
    final controller = TextEditingController(text: group.name);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Group name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                return;
              }
              context
                  .read<AppState>()
                  .renameGroup(groupId: group.id, newName: newName);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _showAddMemberDialog(
      BuildContext context, String groupId) async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Member name'),
            ),
            TextField(
              controller: idController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Unique ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final id = idController.text.trim().toUpperCase();
              if (name.isEmpty || id.isEmpty) {
                return;
              }
              context
                  .read<AppState>()
                  .addMemberToGroup(groupId: groupId, name: name, uniqueId: id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    nameController.dispose();
    idController.dispose();
  }

  Future<void> _openDirectChatDialog(BuildContext context) async {
    final idController = TextEditingController();
    final nameController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start Personal Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Student Name'),
            ),
            TextField(
              controller: idController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Student Unique ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final id = idController.text.trim().toUpperCase();
              final name = nameController.text.trim();
              if (id.isEmpty) {
                return;
              }
              context.read<AppState>().sendDirectMessage(
                    targetUniqueId: id,
                    targetName: name,
                    sender: context.read<AppState>().profile.uniqueId,
                    content: 'Hi $name',
                    isMine: true,
                  );
              setState(() {
                selectedDirectId = id;
                mode = ChatPanelMode.personal;
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );

    idController.dispose();
    nameController.dispose();
  }

  Future<void> _pickAndShareGroupFile(String groupId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    final appState = context.read<AppState>();

    final file = result.files.single;
    final fileRef =
        kIsWeb ? 'web://${file.name}' : (file.path ?? 'unknown://file');
    final lower = file.name.toLowerCase();
    String fileType = 'Document';
    if (lower.endsWith('.pdf')) {
      fileType = 'PDF';
    } else if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) {
      fileType = 'Image';
    }

    appState.addGroupAttachment(
      groupId: groupId,
      fileName: file.name,
      fileRef: fileRef,
      fileType: fileType,
      sentBy: appState.profile.uniqueId,
    );

    appState.sendGroupMessage(
      groupId: groupId,
      sender: appState.profile.uniqueId,
      content: 'Shared $fileType',
      isMine: true,
      attachmentName: file.name,
      attachmentRef: fileRef,
      attachmentType: fileType,
    );
  }

  Future<void> _pickAndSendDirectFile(String targetId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final appState = context.read<AppState>();
    final file = result.files.single;
    final fileRef =
        kIsWeb ? 'web://${file.name}' : (file.path ?? 'unknown://file');
    final lower = file.name.toLowerCase();
    String fileType = 'Document';
    if (lower.endsWith('.pdf')) {
      fileType = 'PDF';
    } else if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) {
      fileType = 'Image';
    }

    appState.sendDirectMessage(
      targetUniqueId: targetId,
      sender: appState.profile.uniqueId,
      content: 'Shared $fileType',
      isMine: true,
      attachmentName: file.name,
      attachmentRef: fileRef,
      attachmentType: fileType,
    );
  }

  Future<void> _showEmojiPicker(
    BuildContext context,
    TextEditingController controller,
  ) async {
    const emojis = [
      '😀',
      '😎',
      '🤓',
      '🔥',
      '💯',
      '📚',
      '📝',
      '✅',
      '⏳',
      '🎯',
      '👍',
      '🙏',
      '😂',
      '🥳',
      '❤️',
      '🚀',
    ];

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: emojis
                  .map(
                    (emoji) => InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        _insertEmoji(controller, emoji);
                        Navigator.pop(sheetContext);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  void _insertEmoji(TextEditingController controller, String emoji) {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) {
      controller.text = '$text$emoji';
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
      return;
    }
    final nextText = text.replaceRange(selection.start, selection.end, emoji);
    final nextOffset = selection.start + emoji.length;
    controller.text = nextText;
    controller.selection = TextSelection.collapsed(offset: nextOffset);
  }

  Widget _attachmentChip(String name, String type) {
    final icon = type == 'Image'
        ? Icons.image_outlined
        : type == 'PDF'
            ? Icons.picture_as_pdf_outlined
            : Icons.insert_drive_file_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x14000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
