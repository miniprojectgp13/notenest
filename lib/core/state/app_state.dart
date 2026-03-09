import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/group_item.dart';
import '../models/link_item.dart';
import '../models/note_item.dart';
import '../models/todo_task.dart';
import '../models/user_profile.dart';

class StudentAuthUser {
  StudentAuthUser({
    required this.name,
    required this.phone,
    required this.college,
    required this.password,
  });

  final String name;
  final String phone;
  final String college;
  final String password;
}

class AppState extends ChangeNotifier {
  AppState()
      : profile = UserProfile(
          name: 'naja',
          bio: 'Focused on smart revision',
          emoji: '🤓',
          uniqueId: _createUniqueId(),
          additionalNote: 'Semester 6',
          extraFields: [
            ProfileField(label: 'College', value: 'CSE Department')
          ],
        );

  static final Random _random = Random();

  UserProfile profile;

  final List<TodoTask> _tasks = [
    TodoTask(
      id: _newId('TASK'),
      title: 'DBMS assignment 4',
      subject: 'DBMS',
      type: 'Assignment',
      dateTime: DateTime.now().add(const Duration(hours: 4)),
      status: TaskStatus.inProgress,
    ),
    TodoTask(
      id: _newId('TASK'),
      title: 'Operating systems notes cleanup',
      subject: 'Operating Systems',
      type: 'Subject To-Do',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      status: TaskStatus.notCompleted,
    ),
  ];

  final List<NoteItem> _notes = [
    NoteItem(
      id: _newId('NOTE'),
      name: 'DBMS Unit 2 Summary',
      subject: 'DBMS',
      year: '2026',
      type: 'PDF',
      keywords: 'dbms,normalization',
      createdAt: DateTime.now(),
      localPath: null,
    ),
    NoteItem(
      id: _newId('NOTE'),
      name: 'Maths Integration Practice',
      subject: 'Mathematics',
      year: '2025',
      type: 'Image',
      keywords: 'integration,calculus',
      createdAt: DateTime.now(),
      localPath: null,
    ),
  ];

  final List<GroupItem> _groups = [
    GroupItem(
      id: _newId('GRP'),
      name: 'OS Study Crew',
      members: [
        GroupMember(name: 'Arun', uniqueId: 'NN-A12F4D'),
        GroupMember(name: 'Bala', uniqueId: 'NN-B45K8S'),
        GroupMember(name: 'Chitra', uniqueId: 'NN-C98P2X'),
      ],
      messages: [
        ChatMessage(
          sender: 'NN-A12F4D',
          content: 'Upload unit-3 notes please.',
          sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
      attachments: [],
    ),
  ];

  final Map<String, List<ChatMessage>> _directChats = {};
  final Map<String, String> _directChatNames = {};

  final List<UrlFolder> _urlFolders = [
    UrlFolder(
      id: _newId('FOLDER'),
      name: 'General',
      subFolders: [
        UrlSubFolder(id: _newId('SUB'), name: 'Important'),
      ],
    ),
  ];

  final List<SavedUrlItem> _savedUrls = [];

  final List<StudentAuthUser> _users = [];
  StudentAuthUser? _currentUser;

  bool get isLoggedIn => _currentUser != null;
  StudentAuthUser? get currentUser => _currentUser;

  List<TodoTask> get tasks => List.unmodifiable(_tasks);
  List<NoteItem> get notes => List.unmodifiable(_notes);
  List<GroupItem> get groups => List.unmodifiable(_groups);
  List<UrlFolder> get urlFolders => List.unmodifiable(_urlFolders);
  List<SavedUrlItem> get savedUrls => List.unmodifiable(_savedUrls);

  List<ChatMessage> directMessagesFor(String uniqueId) {
    return List.unmodifiable(_directChats[uniqueId] ?? []);
  }

  List<String> get directChatIds {
    final ids = _directChats.keys.toList();
    ids.sort((a, b) {
      final aList = _directChats[a] ?? [];
      final bList = _directChats[b] ?? [];
      final aTime = aList.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : aList.last.sentAt;
      final bTime = bList.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : bList.last.sentAt;
      return bTime.compareTo(aTime);
    });
    return ids;
  }

  String directChatDisplayName(String uniqueId) {
    return _directChatNames[uniqueId] ?? uniqueId;
  }

  String? signUp({
    required String name,
    required String phone,
    required String college,
    required String password,
  }) {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    final cleanCollege = college.trim();

    if (cleanName.isEmpty ||
        cleanPhone.isEmpty ||
        cleanCollege.isEmpty ||
        password.trim().isEmpty) {
      return 'Please fill all fields.';
    }

    if (!RegExp(r'^\d{10}$').hasMatch(cleanPhone)) {
      return 'Phone must be 10 digits.';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    final exists = _users.any(
      (user) =>
          user.phone == cleanPhone ||
          user.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (exists) {
      return 'User with same name or phone already exists.';
    }

    final user = StudentAuthUser(
      name: cleanName,
      phone: cleanPhone,
      college: cleanCollege,
      password: password,
    );
    _users.add(user);
    notifyListeners();
    return null;
  }

  String? login({required String identifier, required String password}) {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty || password.trim().isEmpty) {
      return 'Enter name/phone and password.';
    }

    final user = _users.where((entry) {
      final byPhone = entry.phone == cleanId;
      final byName = entry.name.toLowerCase() == cleanId.toLowerCase();
      return byPhone || byName;
    }).toList();

    if (user.isEmpty) {
      return 'User not found. Please sign up first.';
    }
    if (user.first.password != password) {
      return 'Incorrect password.';
    }

    _currentUser = user.first;
    profile.name = user.first.name;
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  List<TodoTask> byStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  int get completedCount => byStatus(TaskStatus.completed).length;
  int get inProgressCount => byStatus(TaskStatus.inProgress).length;
  int get notCompletedCount => byStatus(TaskStatus.notCompleted).length;

  int get healthScore {
    if (_tasks.isEmpty) {
      return 100;
    }
    final int score =
        ((completedCount * 100 + inProgressCount * 55) / _tasks.length).round();
    return score.clamp(0, 100);
  }

  Map<String, int> get subjectCounts {
    final Map<String, int> counts = {};
    for (final note in _notes) {
      counts[note.subject] = (counts[note.subject] ?? 0) + 1;
    }
    return counts;
  }

  void updateProfile({
    required String name,
    required String bio,
    required String emoji,
    required String additionalNote,
    required List<ProfileField> extraFields,
  }) {
    profile
      ..name = name
      ..bio = bio
      ..emoji = emoji
      ..additionalNote = additionalNote
      ..extraFields = extraFields;
    notifyListeners();
  }

  Future<String> downloadProfileAsJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/notenest_profile_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = await File(path).create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(profile.toJson()),
    );
    return path;
  }

  void regenerateUniqueId() {
    profile.uniqueId = _createUniqueId();
    notifyListeners();
  }

  void addTask({
    required String title,
    required String subject,
    required String type,
    required DateTime dateTime,
  }) {
    _tasks.insert(
      0,
      TodoTask(
        id: _newId('TASK'),
        title: title,
        subject: subject,
        type: type,
        dateTime: dateTime,
      ),
    );
    notifyListeners();
  }

  void setTaskStatus(String id, TaskStatus status) {
    final task = _tasks.firstWhere((item) => item.id == id);
    task.status = status;
    notifyListeners();
  }

  void addNote({
    required String name,
    required String subject,
    required String year,
    required String type,
    required String keywords,
    String? localPath,
  }) {
    _notes.insert(
      0,
      NoteItem(
        id: _newId('NOTE'),
        name: name,
        subject: subject,
        year: year,
        type: type,
        keywords: keywords,
        createdAt: DateTime.now(),
        localPath: localPath,
      ),
    );
    notifyListeners();
  }

  List<NoteItem> notesForSubject(String subject) {
    return _notes.where((note) => note.subject == subject).toList();
  }

  void updateNote({
    required String id,
    required String name,
    required String subject,
    required String year,
    required String type,
    required String keywords,
  }) {
    final note = _notes.firstWhere((item) => item.id == id);
    note
      ..name = name
      ..subject = subject
      ..year = year
      ..type = type
      ..keywords = keywords;
    notifyListeners();
  }

  void deleteNote(String id) {
    _notes.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void renameSubject({required String oldName, required String newName}) {
    for (final note in _notes) {
      if (note.subject == oldName) {
        note.subject = newName;
      }
    }
    notifyListeners();
  }

  void deleteSubject(String subject) {
    _notes.removeWhere((note) => note.subject == subject);
    notifyListeners();
  }

  void addGroup({required String name, required List<GroupMember> members}) {
    _groups.insert(
      0,
      GroupItem(
        id: _newId('GRP'),
        name: name,
        members: members,
        messages: [],
        attachments: [],
      ),
    );
    notifyListeners();
  }

  void renameGroup({required String groupId, required String newName}) {
    final group = _groups.firstWhere((item) => item.id == groupId);
    group.name = newName;
    notifyListeners();
  }

  void addMemberToGroup({
    required String groupId,
    required String name,
    required String uniqueId,
  }) {
    final group = _groups.firstWhere((item) => item.id == groupId);
    final exists = group.members.any(
      (member) => member.uniqueId.toUpperCase() == uniqueId.toUpperCase(),
    );
    if (exists) {
      return;
    }
    group.members.add(GroupMember(name: name, uniqueId: uniqueId));
    notifyListeners();
  }

  void sendGroupMessage({
    required String groupId,
    required String sender,
    required String content,
    bool isMine = true,
    String? attachmentName,
    String? attachmentRef,
    String? attachmentType,
  }) {
    final group = _groups.firstWhere((item) => item.id == groupId);
    group.messages.add(
      ChatMessage(
        sender: sender,
        content: content,
        sentAt: DateTime.now(),
        isMine: isMine,
        attachmentName: attachmentName,
        attachmentRef: attachmentRef,
        attachmentType: attachmentType,
      ),
    );
    notifyListeners();
  }

  void addGroupAttachment({
    required String groupId,
    required String fileName,
    required String fileRef,
    required String fileType,
    required String sentBy,
  }) {
    final group = _groups.firstWhere((item) => item.id == groupId);
    group.attachments.insert(
      0,
      GroupAttachment(
        id: _newId('GFILE'),
        fileName: fileName,
        fileRef: fileRef,
        fileType: fileType,
        sentBy: sentBy,
        sentAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void sendDirectMessage({
    required String targetUniqueId,
    String? targetName,
    required String sender,
    required String content,
    bool isMine = true,
    String? attachmentName,
    String? attachmentRef,
    String? attachmentType,
  }) {
    final messages = _directChats.putIfAbsent(targetUniqueId, () => []);
    if (targetName != null && targetName.trim().isNotEmpty) {
      _directChatNames[targetUniqueId] = targetName.trim();
    }
    messages.add(
      ChatMessage(
        sender: sender,
        content: content,
        sentAt: DateTime.now(),
        isMine: isMine,
        attachmentName: attachmentName,
        attachmentRef: attachmentRef,
        attachmentType: attachmentType,
      ),
    );
    notifyListeners();
  }

  void addUrlFolder(String name) {
    final clean = name.trim();
    if (clean.isEmpty) {
      return;
    }
    _urlFolders
        .add(UrlFolder(id: _newId('FOLDER'), name: clean, subFolders: []));
    notifyListeners();
  }

  void renameUrlFolder({required String folderId, required String newName}) {
    final clean = newName.trim();
    if (clean.isEmpty) {
      return;
    }
    final folder = _urlFolders.firstWhere((item) => item.id == folderId);
    folder.name = clean;
    notifyListeners();
  }

  void deleteUrlFolder(String folderId) {
    _urlFolders.removeWhere((item) => item.id == folderId);
    _savedUrls.removeWhere((item) => item.folderId == folderId);
    notifyListeners();
  }

  void addUrlSubFolder({required String folderId, required String name}) {
    final clean = name.trim();
    if (clean.isEmpty) {
      return;
    }
    final folder = _urlFolders.firstWhere((item) => item.id == folderId);
    folder.subFolders.add(UrlSubFolder(id: _newId('SUB'), name: clean));
    notifyListeners();
  }

  void saveUrl({
    required String url,
    required String folderId,
    String? subFolderId,
    required String content,
  }) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      return;
    }
    _savedUrls.insert(
      0,
      SavedUrlItem(
        id: _newId('URL'),
        url: cleanUrl,
        folderId: folderId,
        subFolderId: subFolderId,
        content: content.trim().isEmpty ? cleanUrl : content.trim(),
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void updateSavedUrl({
    required String id,
    required String url,
    required String content,
    required String folderId,
    String? subFolderId,
  }) {
    final item = _savedUrls.firstWhere((entry) => entry.id == id);
    item
      ..url = url.trim()
      ..content = content.trim().isEmpty ? url.trim() : content.trim()
      ..folderId = folderId
      ..subFolderId = subFolderId;
    notifyListeners();
  }

  void deleteSavedUrl(String id) {
    _savedUrls.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  List<String> globalSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return [];
    }

    final List<String> results = [];

    for (final note in _notes) {
      final value =
          '${note.name} ${note.subject} ${note.year} ${note.keywords} ${note.localPath ?? ''}'
              .toLowerCase();
      if (value.contains(q)) {
        results.add('Note: ${note.name} (${note.subject})');
      }
    }

    for (final task in _tasks) {
      final value = '${task.title} ${task.subject} ${task.type}'.toLowerCase();
      if (value.contains(q)) {
        results.add('Task: ${task.title} [${task.subject}]');
      }
    }

    for (final group in _groups) {
      final memberText = group.members
          .map((member) => '${member.name} ${member.uniqueId}')
          .join(' ');
      final value = '${group.name} ${group.id} $memberText'.toLowerCase();
      if (value.contains(q)) {
        results.add('Group: ${group.name} (${group.id})');
      }
    }

    final profileValue =
        '${profile.name} ${profile.bio} ${profile.uniqueId}'.toLowerCase();
    if (profileValue.contains(q)) {
      results.add('Profile: ${profile.name} (${profile.uniqueId})');
    }

    return results;
  }

  static String _newId(String prefix) {
    final int seed =
        DateTime.now().microsecondsSinceEpoch + _random.nextInt(9999);
    return '$prefix-${seed.toRadixString(36).toUpperCase()}';
  }

  static String _createUniqueId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code =
        List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
    return 'NN-$code';
  }
}
