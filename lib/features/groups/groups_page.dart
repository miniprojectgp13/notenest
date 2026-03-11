import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/group_item.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/web_file_utils_stub.dart'
  if (dart.library.html) '../../core/utils/web_file_utils_web.dart';

enum ChatPanelMode { groups, personal }

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  static const List<String> _iconEmojis = [
    '📚',
    '🧠',
    '🚀',
    '🔥',
    '🎯',
    '💡',
    '📝',
    '🤝',
    '😎',
    '🎓',
    '✅',
    '🌟',
  ];

  ChatPanelMode mode = ChatPanelMode.groups;
  String? selectedGroupId;
  String? selectedDirectId;

  final TextEditingController _groupMessageController = TextEditingController();
  final TextEditingController _directMessageController =
      TextEditingController();

  bool _showChatMobile = false;
  final Map<String, Future<String?>> _groupPhotoFutures = {};

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
        child: LayoutBuilder(
          builder: (ctx, cs) {
            final isWide = cs.maxWidth > 620;
            final chatWidget = AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              child: mode == ChatPanelMode.groups
                  ? (selectedGroup == null
                      ? const Center(child: Text('Create your first group'))
                      : _groupChatArea(context, selectedGroup))
                  : _personalChatArea(context),
            );
            if (isWide) {
              return Row(
                children: [
                  SizedBox(width: 260, child: _leftPanel(context)),
                  const VerticalDivider(width: 1),
                  Expanded(child: chatWidget),
                ],
              );
            }
            if (_showChatMobile) {
              return Column(
                children: [
                  Container(
                    color: Colors.white.withValues(alpha: 0.6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showChatMobile = false),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    ),
                  ),
                  Expanded(child: chatWidget),
                ],
              );
            }
            return _leftPanel(context);
          },
        ),
      ),
    );
  }

  Widget _leftPanel(BuildContext context) {
    final appState = context.watch<AppState>();
    final groups = appState.groups;
    final directIds = appState.directChatIds;

    return Container(
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
                          title: _nameWithoutEmoji(group.name),
                          leading: _groupSidebarAvatar(group),
                          subtitle:
                              '${group.members.length} members • ${group.id}',
                          onTap: () {
                            setState(() {
                              selectedGroupId = group.id;
                              mode = ChatPanelMode.groups;
                              _showChatMobile = true;
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
                          leading: _sidebarLeadingBox('💬'),
                          subtitle: '$id\n$preview',
                          onTap: () {
                            setState(() {
                              selectedDirectId = id;
                              mode = ChatPanelMode.personal;
                              _showChatMobile = true;
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
    required Widget leading,
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
              Row(
                children: [
                  leading,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4B4474)),
                    ),
                  ),
                ],
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

  Widget _sidebarLeadingBox(String emoji) {
    return Container(
      height: 26,
      width: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 15)),
    );
  }

  Widget _groupSidebarAvatar(GroupItem group) {
    final path = (group.photoPath ?? '').trim();
    if (path.isEmpty) {
      return _sidebarLeadingBox(_emojiFromText(group.name));
    }

    return FutureBuilder<String?>(
      future: _groupPhotoFuture(path),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return _sidebarLeadingBox(_emojiFromText(group.name));
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 26,
            height: 26,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _sidebarLeadingBox(_emojiFromText(group.name)),
          ),
        );
      },
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
              GestureDetector(
                onTap: () => _pickGroupPhoto(context, group.id),
                child: Stack(
                  children: [
                    FutureBuilder<String?>(
                      future: _groupPhotoFuture(group.photoPath),
                      builder: (_, snap) {
                        final url = snap.data;
                        if (url != null && url.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url, width: 42, height: 42, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _groupEmojiBox(group),
                            ),
                          );
                        }
                        return _groupEmojiBox(group);
                      },
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6D60D8),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nameWithoutEmoji(group.name),
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
              IconButton(
                tooltip: 'Delete Group',
                onPressed: () => _confirmDeleteGroup(context, group),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
        if (group.members.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.members
                    .map(
                      (member) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(
                            _emojiFromText(member.name),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        label: Text(
                          '${_nameWithoutEmoji(member.name)} (${member.uniqueId})',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _confirmRemoveMember(
                          context: context,
                          groupId: group.id,
                          member: member,
                        ),
                      ),
                    )
                    .toList(),
              ),
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
                          IconButton(
                            tooltip: 'Open file',
                            onPressed: () async {
                              await _openSharedAttachment(
                                storageRef: a.fileRef,
                                fileName: a.fileName,
                                download: false,
                              );
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 17),
                          ),
                          IconButton(
                            tooltip: 'Download to device',
                            onPressed: () async {
                              await _openSharedAttachment(
                                storageRef: a.fileRef,
                                fileName: a.fileName,
                                download: true,
                              );
                            },
                            icon: const Icon(Icons.download_rounded, size: 18),
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
                                storageRef: message.attachmentRef,
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
                onPressed: () async {
                  final content = _groupMessageController.text.trim();
                  if (content.isEmpty) {
                    return;
                  }
                  await appState.sendGroupMessage(
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
                            storageRef: m.attachmentRef,
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
                onPressed: () async {
                  final content = _directMessageController.text.trim();
                  if (content.isEmpty) {
                    return;
                  }
                  await appState.sendDirectMessage(
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
    String selectedGroupEmoji = _iconEmojis.first;
    Uint8List? groupPhotoBytes;
    String? groupPhotoName;
    final List<TextEditingController> memberNameControllers = [
      TextEditingController()
    ];
    final List<TextEditingController> memberIdControllers = [
      TextEditingController()
    ];
    final List<String> memberEmojis = [_iconEmojis.first];

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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Group Icon',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _iconEmojis
                            .map(
                              (emoji) => ChoiceChip(
                                label: Text(emoji),
                                selected: selectedGroupEmoji == emoji,
                                onSelected: (_) {
                                  setState(() {
                                    selectedGroupEmoji = emoji;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFE8E2FF),
                              backgroundImage: groupPhotoBytes == null
                                  ? null
                                  : MemoryImage(groupPhotoBytes!),
                              child: groupPhotoBytes == null
                                  ? Text(
                                      selectedGroupEmoji,
                                      style: const TextStyle(fontSize: 20),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  withData: true,
                                );
                                if (result == null || result.files.isEmpty) {
                                  return;
                                }
                                final file = result.files.single;
                                if (file.bytes == null || file.bytes!.isEmpty) {
                                  return;
                                }
                                setState(() {
                                  groupPhotoBytes = file.bytes;
                                  groupPhotoName = file.name;
                                });
                              },
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: Text(
                                groupPhotoBytes == null
                                    ? 'Upload Group Photo'
                                    : 'Change Group Photo',
                              ),
                            ),
                            if (groupPhotoBytes != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Remove photo',
                                onPressed: () {
                                  setState(() {
                                    groupPhotoBytes = null;
                                    groupPhotoName = null;
                                  });
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ],
                        ),
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
                                memberEmojis.add(_iconEmojis.first);
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
                              SizedBox(
                                width: 70,
                                child: DropdownButtonFormField<String>(
                                  value: memberEmojis[i],
                                  items: _iconEmojis
                                      .map(
                                        (emoji) => DropdownMenuItem(
                                          value: emoji,
                                          child: Text(emoji),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() {
                                      memberEmojis[i] = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
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
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: 'Remove member row',
                                onPressed: memberNameControllers.length == 1
                                    ? null
                                    : () {
                                        setState(() {
                                          final nameController =
                                              memberNameControllers.removeAt(i);
                                          final idController =
                                              memberIdControllers.removeAt(i);
                                          memberEmojis.removeAt(i);
                                          nameController.dispose();
                                          idController.dispose();
                                        });
                                      },
                                icon: const Icon(Icons.remove_circle_outline),
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
                  onPressed: () async {
                    final groupName = nameController.text.trim();
                    if (groupName.isEmpty) {
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Enter group name.')),
                      );
                      return;
                    }
                    final members = <GroupMember>[];
                    final usedIds = <String>{};
                    for (int i = 0; i < memberNameControllers.length; i++) {
                      final name = memberNameControllers[i].text.trim();
                      final id =
                          memberIdControllers[i].text.trim().toUpperCase();
                      if (name.isNotEmpty && id.isNotEmpty) {
                        if (usedIds.contains(id)) {
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('Duplicate Unique ID: $id')),
                            );
                          }
                          return;
                        }
                        usedIds.add(id);
                        members.add(
                          GroupMember(
                            name: '${memberEmojis[i]} $name',
                            uniqueId: id,
                          ),
                        );
                      }
                    }
                    final appState = context.read<AppState>();
                    final created = await appState.addGroup(
                      name: '$selectedGroupEmoji $groupName',
                      members: members,
                    );
                    if (created == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Unable to create group.')),
                        );
                      }
                      return;
                    }

                    String? photoError;
                    if (groupPhotoBytes != null && groupPhotoName != null) {
                      photoError = await appState.uploadGroupPhoto(
                        groupId: created.id,
                        fileBytes: groupPhotoBytes!,
                        originalFileName: groupPhotoName!,
                      );
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }
                    Navigator.pop(dialogContext);
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      selectedGroupId = created.id;
                      mode = ChatPanelMode.groups;
                      _showChatMobile = true;
                    });
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          photoError ?? 'Group created successfully.',
                        ),
                        backgroundColor:
                            photoError == null ? null : Colors.redAccent,
                      ),
                    );
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
    final parsedGroup = _splitEmojiPrefix(group.name, fallback: _iconEmojis.first);
    final controller = TextEditingController(text: parsedGroup.$2);
    String selectedEmoji = parsedGroup.$1;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Group Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Group name'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _iconEmojis
                    .map(
                      (emoji) => ChoiceChip(
                        label: Text(emoji),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) {
                  return;
                }
                await context.read<AppState>().renameGroup(
                  groupId: group.id,
                  newName: '$selectedEmoji $newName',
                );
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _showAddMemberDialog(
      BuildContext context, String groupId) async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    String selectedEmoji = _iconEmojis.first;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _iconEmojis
                    .map(
                      (emoji) => ChoiceChip(
                        label: Text(emoji),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final id = idController.text.trim().toUpperCase();
                if (name.isEmpty || id.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Enter member name and unique ID.')),
                  );
                  return;
                }
                final added = await context.read<AppState>().addMemberToGroup(
                  groupId: groupId,
                  name: '$selectedEmoji $name',
                  uniqueId: id,
                );
                if (!mounted) {
                  return;
                }
                if (!added) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Member with ID $id already exists.')),
                  );
                  return;
                }
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Member added to group.')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
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
            onPressed: () async {
              final id = idController.text.trim().toUpperCase();
              final name = nameController.text.trim();
              if (id.isEmpty) {
                return;
              }
              await context.read<AppState>().sendDirectMessage(
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
              if (!dialogContext.mounted) {
                return;
              }
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
      withData: true,
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
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    final lower = file.name.toLowerCase();
    String fileType = 'Document';
    if (lower.endsWith('.pdf')) {
      fileType = 'PDF';
    } else if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) {
      fileType = 'Image';
    }

    final attachment = await appState.addGroupAttachment(
      groupId: groupId,
      fileName: file.name,
      fileBytes: bytes,
      fileType: fileType,
      sentBy: appState.profile.uniqueId,
    );

    if (attachment == null) {
      return;
    }

    await appState.sendGroupMessage(
      groupId: groupId,
      sender: appState.profile.uniqueId,
      content: 'Shared $fileType',
      isMine: true,
      attachmentName: file.name,
      attachmentRef: attachment.fileRef,
      attachmentType: fileType,
    );
  }

  Future<void> _pickAndSendDirectFile(String targetId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final appState = context.read<AppState>();
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    final lower = file.name.toLowerCase();
    String fileType = 'Document';
    if (lower.endsWith('.pdf')) {
      fileType = 'PDF';
    } else if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) {
      fileType = 'Image';
    }

    await appState.uploadDirectAttachment(
      targetUniqueId: targetId,
      sender: appState.profile.uniqueId,
      fileName: file.name,
      fileBytes: bytes,
      fileType: fileType,
    );
  }

  Future<void> _confirmDeleteGroup(BuildContext context, GroupItem group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Delete ${_nameWithoutEmoji(group.name)} and all its messages?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) {
      return;
    }

    await context.read<AppState>().deleteGroup(group.id);
    final groups = context.read<AppState>().groups;
    setState(() {
      selectedGroupId = groups.isEmpty ? null : groups.first.id;
    });
  }

  Future<void> _confirmRemoveMember({
    required BuildContext context,
    required String groupId,
    required GroupMember member,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${_nameWithoutEmoji(member.name)} from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    final removed = await context.read<AppState>().removeMemberFromGroup(
          groupId: groupId,
          uniqueId: member.uniqueId,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(
          removed
              ? 'Member removed from group.'
              : 'Unable to remove member right now.',
        ),
      ),
    );
  }

  String _emojiFromText(String text) {
    final value = text.trimLeft();
    if (value.isEmpty) {
      return '📚';
    }
    final first = String.fromCharCode(value.runes.first);
    return _iconEmojis.contains(first) ? first : '📚';
  }

  String _nameWithoutEmoji(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    final first = String.fromCharCode(trimmed.runes.first);
    if (_iconEmojis.contains(first)) {
      return trimmed.substring(first.length).trimLeft();
    }
    return trimmed;
  }

  (String, String) _splitEmojiPrefix(String text, {required String fallback}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return (fallback, '');
    }
    final first = String.fromCharCode(trimmed.runes.first);
    if (_iconEmojis.contains(first)) {
      return (first, trimmed.substring(first.length).trimLeft());
    }
    return (fallback, trimmed);
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

  Widget _attachmentChip(String name, String type, {String? storageRef}) {
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
          if (storageRef != null && storageRef.trim().isNotEmpty) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Open file',
              onPressed: () async {
                await _openSharedAttachment(
                  storageRef: storageRef,
                  fileName: name,
                  download: false,
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
            IconButton(
              tooltip: 'Download to device',
              onPressed: () async {
                await _openSharedAttachment(
                  storageRef: storageRef,
                  fileName: name,
                  download: true,
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ],
      ),
    );
  }

  Widget _groupEmojiBox(GroupItem group) {
    return Container(
      height: 42, width: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_emojiFromText(group.name), style: const TextStyle(fontSize: 23)),
    );
  }

  Future<String?> _groupPhotoFuture(String? path) {
    if (path == null || path.isEmpty) return Future.value(null);
    return _groupPhotoFutures.putIfAbsent(
      path,
      () => context.read<AppState>().createFileAccessUrl(path),
    );
  }

  Future<void> _pickGroupPhoto(BuildContext context, String groupId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final bytes = result.files.single.bytes;
    if (bytes == null || bytes.isEmpty) return;
    final oldGroup = context.read<AppState>().groups
        .where((g) => g.id == groupId)
        .firstOrNull;
    if (oldGroup?.photoPath != null) _groupPhotoFutures.remove(oldGroup!.photoPath);
    final error = await context.read<AppState>().uploadGroupPhoto(
      groupId: groupId,
      fileBytes: bytes,
      originalFileName: result.files.single.name,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Group photo updated!'),
      backgroundColor: error != null ? Colors.redAccent : null,
    ));
  }

  Future<void> _openSharedAttachment({
    required String storageRef,
    required String fileName,
    required bool download,
  }) async {
    if (storageRef.trim().isEmpty) {
      return;
    }

    final signedUrl =
        await context.read<AppState>().createFileAccessUrl(storageRef);
    if (!mounted) {
      return;
    }

    final resolvedUrl = signedUrl ?? storageRef;
    bool launched = false;
    if (kIsWeb) {
      launched = download
          ? await downloadUrlInBrowser(resolvedUrl, fileName)
          : openUrlInNewTab(resolvedUrl);
    } else {
      final uri = Uri.tryParse(resolvedUrl);
      if (uri != null) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not ${download ? 'download' : 'open'} $fileName.')),
      );
    }
  }
}
