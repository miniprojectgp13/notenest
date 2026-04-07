import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_item.dart';
import '../models/link_item.dart';
import '../models/note_item.dart';
import '../models/todo_task.dart';
import '../models/user_profile.dart';
import '../utils/web_file_utils_stub.dart'
    if (dart.library.html) '../utils/web_file_utils_web.dart';

class StudentAuthUser {
  StudentAuthUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.college,
  });

  final String id;
  final String name;
  final String phone;
  final String college;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'college': college,
    };
  }

  factory StudentAuthUser.fromJson(Map<String, dynamic> json) {
    return StudentAuthUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      college: json['college'] as String? ?? '',
    );
  }
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
            ProfileField(label: 'College', value: 'CSE Department'),
          ],
          avatarPath: null,
        );

  static const String _currentUserKey = 'current_user_v1';
  static const String _storageBucket = 'notenest-uploads';
  static final Random _random = Random();

  SupabaseClient get _supabase => Supabase.instance.client;

  UserProfile profile;

  final List<TodoTask> _tasks = [];

  final List<NoteItem> _notes = [];
  final List<NoteFolder> _noteFolders = [];
  final List<GroupItem> _groups = [];
  final Map<String, List<ChatMessage>> _directChats = {};
  final Map<String, String> _directChatNames = {};
  final List<UrlFolder> _urlFolders = [];
  final List<SavedUrlItem> _savedUrls = [];

  StudentAuthUser? _currentUser;
  bool _authReady = false;
  bool _loadingData = false;
  bool _schemaReady = true;

  bool get isLoggedIn => _currentUser != null;
  StudentAuthUser? get currentUser => _currentUser;
  bool get authReady => _authReady;
  bool get isLoadingData => _loadingData;

  List<TodoTask> get tasks => List.unmodifiable(_tasks);
  List<NoteItem> get notes => List.unmodifiable(_notes);
  List<NoteFolder> get noteFolders => List.unmodifiable(_noteFolders);
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

  Future<void> initAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_currentUserKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _currentUser = StudentAuthUser.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          profile.name = _currentUser!.name;
          await _loadAllUserData();
        }
      }
    } catch (_) {
      await _clearSession();
    }

    _authReady = true;
    notifyListeners();
  }

  Future<void> _persistCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser == null) {
      await prefs.remove(_currentUserKey);
      return;
    }
    await prefs.setString(_currentUserKey, jsonEncode(_currentUser!.toJson()));
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    _notes.clear();
    _noteFolders.clear();
    _groups.clear();
    _directChats.clear();
    _directChatNames.clear();
    _urlFolders.clear();
    _savedUrls.clear();
    profile = UserProfile(
      name: 'naja',
      bio: 'Focused on smart revision',
      emoji: '🤓',
      uniqueId: _createUniqueId(),
      additionalNote: 'Semester 6',
      extraFields: [
        ProfileField(label: 'College', value: 'CSE Department'),
      ],
      avatarPath: null,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<String?> signUp({
    required String name,
    required String phone,
    required String college,
    required String password,
  }) async {
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

    try {
      await _supabase.rpc(
        'register_student_user',
        params: {
          'p_username': cleanName,
          'p_phone': cleanPhone,
          'p_college': cleanCollege,
          'p_password': password,
        },
      );
      return null;
    } on PostgrestException catch (error) {
      final msg = error.message.toLowerCase();
      if (msg.contains('same name or phone already exists') ||
          msg.contains('already exists')) {
        return 'Username or phone number already exists.';
      }
      return error.message.isNotEmpty
          ? error.message
          : 'Unable to sign up now. Please try again.';
    } catch (_) {
      return 'Unable to sign up now. Please try again.';
    }
  }

  Future<String?> login({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty || password.trim().isEmpty) {
      return 'Enter name/phone and password.';
    }

    try {
      final data = await _supabase.rpc(
        'login_student_user',
        params: {
          'p_identifier': cleanId,
          'p_password': password,
        },
      );
      if (data == null || data is! Map) {
        return 'Login failed. Please try again.';
      }

      _currentUser = StudentAuthUser.fromJson(Map<String, dynamic>.from(data));
      await _persistCurrentUser();
      await _loadAllUserData();
      notifyListeners();
      return null;
    } on PostgrestException catch (error) {
      final msg = error.message.toLowerCase();
      if (msg.contains('user not found')) {
        return 'User not found.';
      }
      if (msg.contains('incorrect password') ||
          msg.contains('invalid login credentials')) {
        return 'Incorrect password or username.';
      }
      return error.message.isNotEmpty
          ? error.message
          : 'Unable to login now. Please try again.';
    } catch (_) {
      return 'Unable to login now. Please try again.';
    }
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _loadAllUserData() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    _loadingData = true;
    notifyListeners();

    try {
      _schemaReady = await _checkSchemaReady();
      if (!_schemaReady) {
        return;
      }
      await Future.wait([
        _runLoadSafely(_loadProfile),
        _runLoadSafely(_loadNoteFolders),
        _runLoadSafely(_loadNotes),
        _runLoadSafely(_loadLinks),
        _runLoadSafely(_loadGroups),
        _runLoadSafely(_loadDirectChats),
      ]);
    } finally {
      _loadingData = false;
      notifyListeners();
    }
  }

  Future<bool> _checkSchemaReady() async {
    try {
      // Check both tables that are required for core functionality.
      await _supabase.from('notes').select('id').limit(1);
      await _supabase.from('note_folders').select('id').limit(1);
      await _supabase.from('url_folders').select('id').limit(1);
      return true;
    } on PostgrestException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static String _friendlyDbError(dynamic error) {
    final msg = error is PostgrestException ? error.message : error.toString();
    if (msg.toLowerCase().contains('schema cache') ||
        msg.toLowerCase().contains('could not find')) {
      return 'Database tables not set up yet. Run supabase/schema.sql in your Supabase project, then restart the app.';
    }
    return msg;
  }

  Future<void> _runLoadSafely(Future<void> Function() loader) async {
    try {
      await loader();
    } on PostgrestException {
      return;
    } catch (_) {
      return;
    }
  }

  Future<void> _ensureRemoteProfile() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    await _supabase.from('user_profiles').upsert({
      'user_id': user.id,
      'bio': profile.bio,
      'emoji': profile.emoji,
      'unique_id': profile.uniqueId,
      'additional_note': profile.additionalNote,
      'extra_fields':
          profile.extraFields.map((field) => field.toJson()).toList(),
      'avatar_path': profile.avatarPath,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _loadProfile() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final data = await _supabase
        .from('user_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (data == null) {
      profile = UserProfile(
        name: user.name,
        bio: 'Focused on smart revision',
        emoji: '🤓',
        uniqueId: _createUniqueId(),
        additionalNote: 'Semester 6',
        extraFields: [
          ProfileField(label: 'College', value: user.college),
        ],
        avatarPath: null,
      );
      await _ensureRemoteProfile();
      return;
    }

    final mapped = Map<String, dynamic>.from(data);
    profile = UserProfile.fromJson({
      'name': user.name,
      'bio': mapped['bio'],
      'emoji': mapped['emoji'],
      'uniqueId': mapped['unique_id'],
      'additionalNote': mapped['additional_note'],
      'extraFields': mapped['extra_fields'],
      'avatarPath': mapped['avatar_path'],
    });
  }

  Future<void> _loadNotes() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final rows = await _supabase
        .from('notes')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    _notes
      ..clear()
      ..addAll(
        (rows as List).map(
          (entry) {
            final row = Map<String, dynamic>.from(entry);
            return NoteItem(
              id: row['id'] as String,
              name: row['name'] as String? ?? '',
              subject: row['subject'] as String? ?? 'General',
              year: row['year'] as String? ?? '2026',
              type: row['type'] as String? ?? 'Document',
              keywords: row['keywords'] as String? ?? '',
              createdAt:
                  DateTime.tryParse(row['created_at'] as String? ?? '') ??
                      DateTime.now(),
              folderId: row['folder_id'] as String?,
              localPath: row['file_path'] as String?,
            );
          },
        ),
      );
  }

  Future<void> _loadNoteFolders() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final rows = await _supabase
        .from('note_folders')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    _noteFolders
      ..clear()
      ..addAll(
        (rows as List).map(
          (entry) {
            final row = Map<String, dynamic>.from(entry);
            return NoteFolder(
              id: row['id'] as String,
              name: row['name'] as String? ?? '',
              createdAt:
                  DateTime.tryParse(row['created_at'] as String? ?? '') ??
                      DateTime.now(),
            );
          },
        ),
      );
  }

  Future<void> _loadLinks() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final folderRows = await _supabase
        .from('url_folders')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    final folders = <UrlFolder>[];
    final folderIds = <String>[];
    for (final entry in folderRows as List) {
      final row = Map<String, dynamic>.from(entry);
      final id = row['id'] as String;
      folderIds.add(id);
      folders.add(UrlFolder(
          id: id, name: row['name'] as String? ?? '', subFolders: []));
    }

    if (folderIds.isNotEmpty) {
      final subRows = await _supabase
          .from('url_subfolders')
          .select()
          .inFilter('folder_id', folderIds)
          .order('created_at');
      for (final entry in subRows as List) {
        final row = Map<String, dynamic>.from(entry);
        final folder =
            folders.where((item) => item.id == row['folder_id']).firstOrNull;
        if (folder == null) {
          continue;
        }
        folder.subFolders.add(
          UrlSubFolder(
            id: row['id'] as String,
            name: row['name'] as String? ?? '',
          ),
        );
      }
    }

    final urlRows = await _supabase
        .from('saved_urls')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    _urlFolders
      ..clear()
      ..addAll(folders);
    _savedUrls
      ..clear()
      ..addAll(
        (urlRows as List).map(
          (entry) {
            final row = Map<String, dynamic>.from(entry);
            return SavedUrlItem(
              id: row['id'] as String,
              url: row['url'] as String? ?? '',
              folderId: row['folder_id'] as String,
              subFolderId: row['subfolder_id'] as String?,
              content: row['content'] as String? ?? '',
              createdAt:
                  DateTime.tryParse(row['created_at'] as String? ?? '') ??
                      DateTime.now(),
            );
          },
        ),
      );
  }

  Future<void> _loadGroups() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final groupRows = await _supabase
        .from('study_groups')
        .select()
        .eq('owner_user_id', user.id)
        .order('created_at');

    final groups = <GroupItem>[];
    final groupIds = <String>[];
    for (final entry in groupRows as List) {
      final row = Map<String, dynamic>.from(entry);
      final id = row['id'] as String;
      groupIds.add(id);
      groups.add(
        GroupItem(
          id: id,
          name: row['name'] as String? ?? '',
          photoPath: row['photo_path'] as String?,
          members: [],
          messages: [],
          attachments: [],
        ),
      );
    }

    if (groupIds.isNotEmpty) {
      final memberRows = await _supabase
          .from('group_members')
          .select()
          .inFilter('group_id', groupIds)
          .order('added_at');
      for (final entry in memberRows as List) {
        final row = Map<String, dynamic>.from(entry);
        final group =
            groups.where((item) => item.id == row['group_id']).firstOrNull;
        if (group == null) {
          continue;
        }
        group.members.add(
          GroupMember(
            name: row['name'] as String? ?? '',
            uniqueId: row['unique_id'] as String? ?? '',
          ),
        );
      }

      final attachmentRows = await _supabase
          .from('group_attachments')
          .select()
          .inFilter('group_id', groupIds)
          .order('sent_at', ascending: false);
      for (final entry in attachmentRows as List) {
        final row = Map<String, dynamic>.from(entry);
        final group =
            groups.where((item) => item.id == row['group_id']).firstOrNull;
        if (group == null) {
          continue;
        }
        group.attachments.add(
          GroupAttachment(
            id: row['id'] as String,
            fileName: row['file_name'] as String? ?? '',
            fileRef: row['file_ref'] as String? ?? '',
            fileType: row['file_type'] as String? ?? 'Document',
            sentBy: row['sent_by'] as String? ?? '',
            sentAt: DateTime.tryParse(row['sent_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      }

      final messageRows = await _supabase
          .from('group_messages')
          .select()
          .inFilter('group_id', groupIds)
          .order('sent_at');
      for (final entry in messageRows as List) {
        final row = Map<String, dynamic>.from(entry);
        final group =
            groups.where((item) => item.id == row['group_id']).firstOrNull;
        if (group == null) {
          continue;
        }
        group.messages.add(
          ChatMessage(
            id: row['id'] as String?,
            sender: row['sender_unique_id'] as String? ?? '',
            content: row['content'] as String? ?? '',
            sentAt: DateTime.tryParse(row['sent_at'] as String? ?? '') ??
                DateTime.now(),
            isMine: row['is_mine'] as bool? ?? false,
            attachmentName: row['attachment_name'] as String?,
            attachmentRef: row['attachment_ref'] as String?,
            attachmentType: row['attachment_type'] as String?,
          ),
        );
      }
    }

    _groups
      ..clear()
      ..addAll(groups);
  }

  Future<void> _loadDirectChats() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final chatRows = await _supabase
        .from('direct_chats')
        .select()
        .eq('owner_user_id', user.id)
        .order('created_at');

    final chatIds = <String>[];
    final chatKeyById = <String, String>{};
    _directChats.clear();
    _directChatNames.clear();

    for (final entry in chatRows as List) {
      final row = Map<String, dynamic>.from(entry);
      final chatId = row['id'] as String;
      final targetId = row['target_unique_id'] as String? ?? '';
      chatIds.add(chatId);
      chatKeyById[chatId] = targetId;
      _directChats[targetId] = [];
      final targetName = row['target_name'] as String?;
      if (targetName != null && targetName.trim().isNotEmpty) {
        _directChatNames[targetId] = targetName.trim();
      }
    }

    if (chatIds.isEmpty) {
      return;
    }

    final messageRows = await _supabase
        .from('direct_messages')
        .select()
        .inFilter('chat_id', chatIds)
        .order('sent_at');

    for (final entry in messageRows as List) {
      final row = Map<String, dynamic>.from(entry);
      final targetId = chatKeyById[row['chat_id'] as String? ?? ''];
      if (targetId == null) {
        continue;
      }
      _directChats.putIfAbsent(targetId, () => []).add(
            ChatMessage(
              id: row['id'] as String?,
              sender: row['sender_unique_id'] as String? ?? '',
              content: row['content'] as String? ?? '',
              sentAt: DateTime.tryParse(row['sent_at'] as String? ?? '') ??
                  DateTime.now(),
              isMine: row['is_mine'] as bool? ?? false,
              attachmentName: row['attachment_name'] as String?,
              attachmentRef: row['attachment_ref'] as String?,
              attachmentType: row['attachment_type'] as String?,
            ),
          );
    }
  }

  int get completedCount => byStatus(TaskStatus.completed).length;
  int get inProgressCount => byStatus(TaskStatus.inProgress).length;
  int get notCompletedCount => byStatus(TaskStatus.notCompleted).length;

  List<TodoTask> byStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  int get healthScore {
    if (_tasks.isEmpty) {
      return 100;
    }
    final score =
        ((completedCount * 100 + inProgressCount * 55) / _tasks.length).round();
    return score.clamp(0, 100);
  }

  Map<String, int> get subjectCounts {
    final counts = <String, int>{};
    for (final note in _notes) {
      counts[note.subject] = (counts[note.subject] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String college,
    required String bio,
    required String emoji,
    required String additionalNote,
    required List<ProfileField> extraFields,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final cleanPhone = phone.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(cleanPhone)) {
      throw Exception('Phone must be 10 digits.');
    }

    try {
      await _supabase.rpc(
        'update_student_account',
        params: {
          'p_user_id': user.id,
          'p_username': name,
          'p_phone': cleanPhone,
          'p_college': college,
        },
      );
    } on PostgrestException catch (error) {
      final msg = error.message.toLowerCase();
      if (msg.contains('function') && msg.contains('update_student_account')) {
        throw Exception(
            'Database update is pending. Run supabase/schema.sql once, then retry.');
      }
      throw Exception(error.message.isEmpty
          ? 'Unable to update account settings right now.'
          : error.message);
    }

    await _supabase.from('user_profiles').upsert({
      'user_id': user.id,
      'bio': bio,
      'emoji': emoji,
      'unique_id': profile.uniqueId,
      'additional_note': additionalNote,
      'extra_fields': extraFields.map((field) => field.toJson()).toList(),
      'avatar_path': profile.avatarPath,
      'updated_at': DateTime.now().toIso8601String(),
    });

    _currentUser = StudentAuthUser(
      id: user.id,
      name: name,
      phone: cleanPhone,
      college: college,
    );
    await _persistCurrentUser();

    profile
      ..name = name
      ..bio = bio
      ..emoji = emoji
      ..additionalNote = additionalNote
      ..extraFields = extraFields;
    notifyListeners();
  }

  Future<String> downloadProfileAsJson() async {
    final jsonText =
        const JsonEncoder.withIndent('  ').convert(profile.toJson());
    if (kIsWeb) {
      final bytes = Uint8List.fromList(utf8.encode(jsonText));
      final objectUrl = createObjectUrlFromBytes(bytes, 'application/json');
      if (objectUrl == null || objectUrl.isEmpty) {
        throw Exception('Unable to prepare browser download.');
      }
      final fileName =
          'notenest_profile_${DateTime.now().millisecondsSinceEpoch}.json';
      final ok = await downloadUrlInBrowser(objectUrl, fileName);
      if (!ok) {
        throw Exception('Unable to download profile JSON in browser.');
      }
      return 'Browser download started.';
    }

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/notenest_profile_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = await File(path).create(recursive: true);
    await file.writeAsString(jsonText);
    return path;
  }

  Future<void> regenerateUniqueId() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    profile.uniqueId = _createUniqueId();
    await _supabase.from('user_profiles').upsert({
      'user_id': user.id,
      'bio': profile.bio,
      'emoji': profile.emoji,
      'unique_id': profile.uniqueId,
      'additional_note': profile.additionalNote,
      'extra_fields':
          profile.extraFields.map((field) => field.toJson()).toList(),
      'avatar_path': profile.avatarPath,
      'updated_at': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return 'Please login first.';
    }
    if (currentPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      return 'Enter current and new password.';
    }
    if (newPassword.length < 6) {
      return 'New password must be at least 6 characters.';
    }

    try {
      await _supabase.rpc(
        'change_student_password',
        params: {
          'p_user_id': user.id,
          'p_current_password': currentPassword,
          'p_new_password': newPassword,
        },
      );
      return null;
    } on PostgrestException catch (error) {
      return error.message.isEmpty
          ? 'Unable to change password now.'
          : error.message;
    } catch (_) {
      return 'Unable to change password now.';
    }
  }

  Future<String?> uploadProfilePhoto({
    required Uint8List fileBytes,
    required String originalFileName,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return 'Please login first.';
    }
    if (!_schemaReady) {
      return 'Database tables not set up yet. Run supabase/schema.sql in your Supabase project, then restart the app.';
    }

    final storagePath = _buildStoragePath('user_photos', originalFileName);
    try {
      await _supabase.storage.from(_storageBucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _mimeTypeFromName(originalFileName),
            ),
          );

      await _supabase.from('user_profiles').upsert({
        'user_id': user.id,
        'bio': profile.bio,
        'emoji': profile.emoji,
        'unique_id': profile.uniqueId,
        'additional_note': profile.additionalNote,
        'extra_fields':
            profile.extraFields.map((field) => field.toJson()).toList(),
        'avatar_path': storagePath,
        'updated_at': DateTime.now().toIso8601String(),
      });

      profile.avatarPath = storagePath;
      notifyListeners();
      return null;
    } on StorageException catch (error) {
      if (error.message.toLowerCase().contains('bucket not found')) {
        return 'Storage bucket missing. Run the latest supabase/schema.sql once.';
      }
      if (error.message.toLowerCase().contains('row-level security policy')) {
        return 'Storage policy blocked upload. Run the storage policy SQL fix once in Supabase.';
      }
      return error.message;
    } on PostgrestException catch (error) {
      return _friendlyDbError(error);
    } catch (_) {
      return 'Unable to upload profile photo right now.';
    }
  }

  Future<String?> deleteProfilePhoto() async {
    final user = _currentUser;
    if (user == null) {
      return 'Please login first.';
    }
    if (!_schemaReady) {
      return 'Database tables not set up yet. Run supabase/schema.sql in your Supabase project, then restart the app.';
    }

    final oldPath = (profile.avatarPath ?? '').trim();

    try {
      if (oldPath.isNotEmpty &&
          !oldPath.startsWith('http://') &&
          !oldPath.startsWith('https://')) {
        try {
          await _supabase.storage.from(_storageBucket).remove([oldPath]);
        } catch (_) {
          // Keep deletion resilient: clear profile reference even if storage cleanup fails.
        }
      }

      await _supabase.from('user_profiles').upsert({
        'user_id': user.id,
        'bio': profile.bio,
        'emoji': profile.emoji,
        'unique_id': profile.uniqueId,
        'additional_note': profile.additionalNote,
        'extra_fields':
            profile.extraFields.map((field) => field.toJson()).toList(),
        'avatar_path': null,
        'updated_at': DateTime.now().toIso8601String(),
      });

      profile.avatarPath = null;
      notifyListeners();
      return null;
    } on PostgrestException catch (error) {
      return _friendlyDbError(error);
    } catch (_) {
      return 'Unable to delete profile photo right now.';
    }
  }

  Future<String?> uploadGroupPhoto({
    required String groupId,
    required Uint8List fileBytes,
    required String originalFileName,
  }) async {
    final user = _currentUser;
    if (user == null) return 'Please login first.';
    final storagePath =
        _buildStoragePath('group_photos/$groupId', originalFileName);
    try {
      await _supabase.storage.from(_storageBucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _mimeTypeFromName(originalFileName),
            ),
          );
      await _supabase
          .from('study_groups')
          .update({'photo_path': storagePath}).eq('id', groupId);
      final group = _groups.where((g) => g.id == groupId).firstOrNull;
      if (group != null) group.photoPath = storagePath;
      notifyListeners();
      return null;
    } on StorageException catch (e) {
      if (e.message.toLowerCase().contains('bucket not found')) {
        return 'Storage bucket missing. Run the latest supabase/schema.sql once.';
      }
      return e.message;
    } on PostgrestException catch (e) {
      return _friendlyDbError(e);
    } catch (_) {
      return 'Unable to upload group photo.';
    }
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

  Future<String?> uploadNote({
    required String name,
    required String subject,
    required String year,
    required String type,
    required String keywords,
    required Uint8List fileBytes,
    required String originalFileName,
    String? folderId,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return 'Please login first.';
    }
    if (!_schemaReady) {
      return 'Database tables not set up yet. Run supabase/schema.sql in your Supabase project, then restart the app.';
    }

    final storagePath = _buildStoragePath('notes', originalFileName);
    try {
      await _supabase.storage.from(_storageBucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _mimeTypeFromName(originalFileName),
            ),
          );

      final inserted = await _supabase
          .from('notes')
          .insert({
            'user_id': user.id,
            'name': name,
            'subject': subject,
            'year': year,
            'type': type,
            'keywords': keywords,
            'folder_id': folderId,
            'file_path': storagePath,
            'file_name': originalFileName,
          })
          .select()
          .single();

      final row = Map<String, dynamic>.from(inserted);
      _notes.insert(
        0,
        NoteItem(
          id: row['id'] as String,
          name: row['name'] as String? ?? name,
          subject: row['subject'] as String? ?? subject,
          year: row['year'] as String? ?? year,
          type: row['type'] as String? ?? type,
          keywords: row['keywords'] as String? ?? keywords,
          createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
              DateTime.now(),
          folderId: row['folder_id'] as String? ?? folderId,
          localPath: row['file_path'] as String? ?? storagePath,
        ),
      );
      notifyListeners();
      return null;
    } on StorageException catch (error) {
      if (error.message.toLowerCase().contains('bucket not found')) {
        return 'Storage bucket missing. Run the latest supabase/schema.sql once.';
      }
      if (error.message.toLowerCase().contains('row-level security policy')) {
        return 'Storage policy blocked upload. Run the storage policy SQL fix once in Supabase.';
      }
      return error.message;
    } on PostgrestException catch (error) {
      return _friendlyDbError(error);
    } catch (_) {
      return 'Unable to upload note right now.';
    }
  }

  List<NoteItem> notesForSubject(String subject) {
    return _notes.where((note) => note.subject == subject).toList();
  }

  Future<void> updateNote({
    required String id,
    required String name,
    required String subject,
    required String year,
    required String type,
    required String keywords,
    required String? folderId,
  }) async {
    await _supabase.from('notes').update({
      'name': name,
      'subject': subject,
      'year': year,
      'type': type,
      'keywords': keywords,
      'folder_id': folderId,
    }).eq('id', id);

    final note = _notes.firstWhere((item) => item.id == id);
    note
      ..name = name
      ..subject = subject
      ..year = year
      ..type = type
      ..keywords = keywords
      ..folderId = folderId;
    notifyListeners();
  }

  Future<String?> addNoteFolder(String name) async {
    final user = _currentUser;
    final clean = name.trim();
    if (user == null) {
      return 'Please login first.';
    }
    if (clean.isEmpty) {
      return 'Folder name is required.';
    }

    try {
      final inserted = await _supabase
          .from('note_folders')
          .insert({'user_id': user.id, 'name': clean})
          .select()
          .single();
      final row = Map<String, dynamic>.from(inserted);
      _noteFolders.insert(
        0,
        NoteFolder(
          id: row['id'] as String,
          name: row['name'] as String? ?? clean,
          createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
              DateTime.now(),
        ),
      );
      notifyListeners();
      return null;
    } on PostgrestException catch (error) {
      return _friendlyDbError(error);
    } catch (_) {
      return 'Unable to create folder right now.';
    }
  }

  Future<void> renameNoteFolder({
    required String folderId,
    required String newName,
  }) async {
    final clean = newName.trim();
    if (clean.isEmpty) {
      return;
    }
    await _supabase
        .from('note_folders')
        .update({'name': clean}).eq('id', folderId);
    final folder = _noteFolders.firstWhere((item) => item.id == folderId);
    folder.name = clean;
    notifyListeners();
  }

  Future<void> deleteNoteFolder(String folderId) async {
    await _supabase
        .from('notes')
        .update({'folder_id': null}).eq('folder_id', folderId);
    await _supabase.from('note_folders').delete().eq('id', folderId);
    for (final note in _notes.where((item) => item.folderId == folderId)) {
      note.folderId = null;
    }
    _noteFolders.removeWhere((item) => item.id == folderId);
    notifyListeners();
  }

  Future<void> moveNoteToFolder({
    required String noteId,
    String? folderId,
  }) async {
    await _supabase
        .from('notes')
        .update({'folder_id': folderId}).eq('id', noteId);
    final note = _notes.firstWhere((item) => item.id == noteId);
    note.folderId = folderId;
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    final note = _notes.where((item) => item.id == id).firstOrNull;
    if (note == null) {
      return;
    }
    final storagePath = note.localPath;
    await _supabase.from('notes').delete().eq('id', id);
    if (storagePath != null && storagePath.trim().isNotEmpty) {
      try {
        await _supabase.storage.from(_storageBucket).remove([storagePath]);
      } catch (_) {}
    }
    _notes.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<String?> createFileAccessUrl(String storagePath) async {
    final cleanPath = storagePath.trim();
    if (cleanPath.isEmpty) {
      return null;
    }
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    final normalizedPath =
        cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath;
    try {
      return await _supabase.storage
          .from(_storageBucket)
          .createSignedUrl(normalizedPath, 3600);
    } catch (_) {
      return null;
    }
  }

  Future<GroupItem?> addGroup({
    required String name,
    required List<GroupMember> members,
  }) async {
    final user = _currentUser;
    if (user == null || name.trim().isEmpty) {
      return null;
    }

    final inserted = await _supabase
        .from('study_groups')
        .insert({'owner_user_id': user.id, 'name': name.trim()})
        .select()
        .single();
    final row = Map<String, dynamic>.from(inserted);
    final group = GroupItem(
      id: row['id'] as String,
      name: row['name'] as String? ?? name.trim(),
      photoPath: null,
      members: List<GroupMember>.from(members),
      messages: [],
      attachments: [],
    );
    _groups.insert(0, group);

    for (final member in members) {
      await _supabase.from('group_members').insert({
        'group_id': group.id,
        'name': member.name,
        'unique_id': member.uniqueId,
      });
    }
    notifyListeners();
    return group;
  }

  Future<void> renameGroup(
      {required String groupId, required String newName}) async {
    if (newName.trim().isEmpty) {
      return;
    }
    await _supabase
        .from('study_groups')
        .update({'name': newName.trim()}).eq('id', groupId);
    final group = _groups.firstWhere((item) => item.id == groupId);
    group.name = newName.trim();
    notifyListeners();
  }

  Future<bool> addMemberToGroup({
    required String groupId,
    required String name,
    required String uniqueId,
  }) async {
    final group = _groups.firstWhere((item) => item.id == groupId);
    final exists = group.members.any(
      (member) => member.uniqueId.toUpperCase() == uniqueId.toUpperCase(),
    );
    if (exists) {
      return false;
    }

    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'name': name,
      'unique_id': uniqueId,
    });
    group.members.add(GroupMember(name: name, uniqueId: uniqueId));
    notifyListeners();
    return true;
  }

  Future<bool> removeMemberFromGroup({
    required String groupId,
    required String uniqueId,
  }) async {
    final group = _groups.where((item) => item.id == groupId).firstOrNull;
    if (group == null) {
      return false;
    }

    await _supabase
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('unique_id', uniqueId);

    group.members.removeWhere(
      (member) => member.uniqueId.toUpperCase() == uniqueId.toUpperCase(),
    );
    notifyListeners();
    return true;
  }

  Future<void> deleteGroup(String groupId) async {
    final group = _groups.where((item) => item.id == groupId).firstOrNull;
    if (group == null) {
      return;
    }

    final refs = group.attachments
        .map((attachment) => attachment.fileRef.trim())
        .where((ref) => ref.isNotEmpty)
        .toList();

    if (refs.isNotEmpty) {
      try {
        await _supabase.storage.from(_storageBucket).remove(refs);
      } catch (_) {}
    }

    await _supabase.from('study_groups').delete().eq('id', groupId);
    _groups.removeWhere((item) => item.id == groupId);
    notifyListeners();
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String sender,
    required String content,
    bool isMine = true,
    String? attachmentName,
    String? attachmentRef,
    String? attachmentType,
  }) async {
    final inserted = await _supabase
        .from('group_messages')
        .insert({
          'group_id': groupId,
          'sender_unique_id': sender,
          'content': content,
          'is_mine': isMine,
          'attachment_name': attachmentName,
          'attachment_ref': attachmentRef,
          'attachment_type': attachmentType,
        })
        .select()
        .single();

    final row = Map<String, dynamic>.from(inserted);
    final group = _groups.firstWhere((item) => item.id == groupId);
    group.messages.add(
      ChatMessage(
        id: row['id'] as String?,
        sender: row['sender_unique_id'] as String? ?? sender,
        content: row['content'] as String? ?? content,
        sentAt: DateTime.tryParse(row['sent_at'] as String? ?? '') ??
            DateTime.now(),
        isMine: row['is_mine'] as bool? ?? isMine,
        attachmentName: row['attachment_name'] as String?,
        attachmentRef: row['attachment_ref'] as String?,
        attachmentType: row['attachment_type'] as String?,
      ),
    );
    notifyListeners();
  }

  Future<void> deleteGroupMessage({
    required String groupId,
    required String messageId,
  }) async {
    final group = _groups.where((item) => item.id == groupId).firstOrNull;
    if (group == null) {
      return;
    }

    final target =
        group.messages.where((item) => item.id == messageId).firstOrNull;
    if (target == null) {
      return;
    }

    final attachmentRef = (target.attachmentRef ?? '').trim();
    await _supabase.from('group_messages').delete().eq('id', messageId);
    group.messages.removeWhere((item) => item.id == messageId);

    if (attachmentRef.isNotEmpty) {
      try {
        await _supabase.storage.from(_storageBucket).remove([attachmentRef]);
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> clearGroupChat(String groupId) async {
    final group = _groups.where((item) => item.id == groupId).firstOrNull;
    if (group == null) {
      return;
    }

    final attachmentRefs = group.attachments
        .map((item) => item.fileRef.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    await _supabase.from('group_messages').delete().eq('group_id', groupId);
    await _supabase.from('group_attachments').delete().eq('group_id', groupId);

    if (attachmentRefs.isNotEmpty) {
      try {
        await _supabase.storage.from(_storageBucket).remove(attachmentRefs);
      } catch (_) {}
    }

    group.messages.clear();
    group.attachments.clear();
    notifyListeners();
  }

  Future<GroupAttachment?> addGroupAttachment({
    required String groupId,
    required String fileName,
    required Uint8List fileBytes,
    required String fileType,
    required String sentBy,
  }) async {
    final storagePath = _buildStoragePath('group_attachments', fileName);
    try {
      await _supabase.storage.from(_storageBucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _mimeTypeFromName(fileName),
            ),
          );

      final inserted = await _supabase
          .from('group_attachments')
          .insert({
            'group_id': groupId,
            'file_name': fileName,
            'file_ref': storagePath,
            'file_type': fileType,
            'sent_by': sentBy,
          })
          .select()
          .single();

      final row = Map<String, dynamic>.from(inserted);
      final attachment = GroupAttachment(
        id: row['id'] as String,
        fileName: row['file_name'] as String? ?? fileName,
        fileRef: row['file_ref'] as String? ?? storagePath,
        fileType: row['file_type'] as String? ?? fileType,
        sentBy: row['sent_by'] as String? ?? sentBy,
        sentAt: DateTime.tryParse(row['sent_at'] as String? ?? '') ??
            DateTime.now(),
      );

      final group = _groups.firstWhere((item) => item.id == groupId);
      group.attachments.insert(0, attachment);
      notifyListeners();
      return attachment;
    } catch (_) {
      return null;
    }
  }

  Future<void> sendDirectMessage({
    required String targetUniqueId,
    String? targetName,
    required String sender,
    required String content,
    bool isMine = true,
    String? attachmentName,
    String? attachmentRef,
    String? attachmentType,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final chat = await _ensureDirectChat(
      targetUniqueId: targetUniqueId,
      targetName: targetName,
    );

    final inserted = await _supabase
        .from('direct_messages')
        .insert({
          'chat_id': chat['id'],
          'sender_unique_id': sender,
          'content': content,
          'is_mine': isMine,
          'attachment_name': attachmentName,
          'attachment_ref': attachmentRef,
          'attachment_type': attachmentType,
        })
        .select()
        .single();

    if (targetName != null && targetName.trim().isNotEmpty) {
      _directChatNames[targetUniqueId] = targetName.trim();
    }

    final row = Map<String, dynamic>.from(inserted);
    _directChats.putIfAbsent(targetUniqueId, () => []).add(
          ChatMessage(
            id: row['id'] as String?,
            sender: row['sender_unique_id'] as String? ?? sender,
            content: row['content'] as String? ?? content,
            sentAt: DateTime.tryParse(row['sent_at'] as String? ?? '') ??
                DateTime.now(),
            isMine: row['is_mine'] as bool? ?? isMine,
            attachmentName: row['attachment_name'] as String?,
            attachmentRef: row['attachment_ref'] as String?,
            attachmentType: row['attachment_type'] as String?,
          ),
        );
    notifyListeners();
  }

  Future<ChatMessage> uploadDirectAttachment({
    required String targetUniqueId,
    String? targetName,
    required String sender,
    required String fileName,
    required Uint8List fileBytes,
    required String fileType,
  }) async {
    final storagePath = _buildStoragePath('direct_attachments', fileName);
    await _supabase.storage.from(_storageBucket).uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _mimeTypeFromName(fileName),
          ),
        );

    await sendDirectMessage(
      targetUniqueId: targetUniqueId,
      targetName: targetName,
      sender: sender,
      content: 'Shared $fileType',
      isMine: true,
      attachmentName: fileName,
      attachmentRef: storagePath,
      attachmentType: fileType,
    );

    return _directChats[targetUniqueId]!.last;
  }

  Future<Map<String, dynamic>> _ensureDirectChat({
    required String targetUniqueId,
    String? targetName,
  }) async {
    final user = _currentUser!;
    final existing = await _supabase
        .from('direct_chats')
        .select()
        .eq('owner_user_id', user.id)
        .eq('target_unique_id', targetUniqueId)
        .maybeSingle();

    if (existing != null) {
      return Map<String, dynamic>.from(existing);
    }

    final inserted = await _supabase
        .from('direct_chats')
        .insert({
          'owner_user_id': user.id,
          'target_unique_id': targetUniqueId,
          'target_name': targetName,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(inserted);
  }

  Future<void> addUrlFolder(String name) async {
    final user = _currentUser;
    final clean = name.trim();
    if (user == null || clean.isEmpty) {
      return;
    }

    final inserted = await _supabase
        .from('url_folders')
        .insert({'user_id': user.id, 'name': clean})
        .select()
        .single();

    _urlFolders.add(
      UrlFolder(
        id: (inserted as Map<String, dynamic>)['id'] as String,
        name: clean,
        subFolders: [],
      ),
    );
    notifyListeners();
  }

  Future<void> renameUrlFolder(
      {required String folderId, required String newName}) async {
    final clean = newName.trim();
    if (clean.isEmpty) {
      return;
    }
    await _supabase
        .from('url_folders')
        .update({'name': clean}).eq('id', folderId);
    final folder = _urlFolders.firstWhere((item) => item.id == folderId);
    folder.name = clean;
    notifyListeners();
  }

  Future<void> deleteUrlFolder(String folderId) async {
    await _supabase.from('url_folders').delete().eq('id', folderId);
    _urlFolders.removeWhere((item) => item.id == folderId);
    _savedUrls.removeWhere((item) => item.folderId == folderId);
    notifyListeners();
  }

  Future<void> addUrlSubFolder(
      {required String folderId, required String name}) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      return;
    }
    final inserted = await _supabase
        .from('url_subfolders')
        .insert({'folder_id': folderId, 'name': clean})
        .select()
        .single();
    final folder = _urlFolders.firstWhere((item) => item.id == folderId);
    folder.subFolders.add(
      UrlSubFolder(
        id: (inserted as Map<String, dynamic>)['id'] as String,
        name: clean,
      ),
    );
    notifyListeners();
  }

  Future<void> saveUrl({
    required String url,
    required String folderId,
    String? subFolderId,
    required String content,
  }) async {
    final user = _currentUser;
    final cleanUrl = url.trim();
    if (user == null || cleanUrl.isEmpty) {
      return;
    }

    final inserted = await _supabase
        .from('saved_urls')
        .insert({
          'user_id': user.id,
          'folder_id': folderId,
          'subfolder_id': subFolderId,
          'url': cleanUrl,
          'content': content.trim().isEmpty ? cleanUrl : content.trim(),
        })
        .select()
        .single();

    final row = Map<String, dynamic>.from(inserted);
    _savedUrls.insert(
      0,
      SavedUrlItem(
        id: row['id'] as String,
        url: row['url'] as String? ?? cleanUrl,
        folderId: row['folder_id'] as String,
        subFolderId: row['subfolder_id'] as String?,
        content: row['content'] as String? ?? cleanUrl,
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> updateSavedUrl({
    required String id,
    required String url,
    required String content,
    required String folderId,
    String? subFolderId,
  }) async {
    await _supabase.from('saved_urls').update({
      'url': url.trim(),
      'content': content.trim().isEmpty ? url.trim() : content.trim(),
      'folder_id': folderId,
      'subfolder_id': subFolderId,
    }).eq('id', id);

    final item = _savedUrls.firstWhere((entry) => entry.id == id);
    item
      ..url = url.trim()
      ..content = content.trim().isEmpty ? url.trim() : content.trim()
      ..folderId = folderId
      ..subFolderId = subFolderId;
    notifyListeners();
  }

  Future<void> deleteSavedUrl(String id) async {
    await _supabase.from('saved_urls').delete().eq('id', id);
    _savedUrls.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  List<String> globalSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return [];
    }

    final results = <String>[];

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

    for (final url in _savedUrls) {
      final value = '${url.url} ${url.content}'.toLowerCase();
      if (value.contains(q)) {
        results.add('URL: ${url.url}');
      }
    }

    final profileValue =
        '${profile.name} ${profile.bio} ${profile.uniqueId}'.toLowerCase();
    if (profileValue.contains(q)) {
      results.add('Profile: ${profile.name} (${profile.uniqueId})');
    }

    return results;
  }

  String _buildStoragePath(String folder, String originalFileName) {
    final userId = _currentUser?.id ?? 'anonymous';
    final safeName = _sanitizeFileName(originalFileName);
    return '$userId/$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _mimeTypeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.txt')) {
      return 'text/plain';
    }
    if (lower.endsWith('.doc')) {
      return 'application/msword';
    }
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  static String _newId(String prefix) {
    final seed = DateTime.now().microsecondsSinceEpoch + _random.nextInt(9999);
    return '$prefix-${seed.toRadixString(36).toUpperCase()}';
  }

  static String _createUniqueId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code =
        List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
    return 'NN-$code';
  }
}
