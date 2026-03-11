import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/note_item.dart';
import '../../core/models/user_profile.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/web_file_utils_stub.dart'
  if (dart.library.html) '../../core/utils/web_file_utils_web.dart';
import '../calendar/calendar_page.dart';
import '../groups/groups_page.dart';
import '../links/links_page.dart';
import '../notes/upload_notes_page.dart';
import '../profile/profile_editor_page.dart';
import '../search/global_search_page.dart';
import '../todo/todo_board_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  bool _showContent = false;
  late final AnimationController _bgController;
  String? _avatarFuturePath;
  Future<String?>? _avatarUrlFuture;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          final driftA = math.sin(t * math.pi * 2) * 18;
          final driftB = math.cos(t * math.pi * 2) * 14;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7F3EB), Color(0xFFEAF2F8), Color(0xFFF4ECE6)],
                stops: [0.05, 0.5, 1],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80 + driftA,
                  left: -50,
                  child: _bgGlow(250, const Color(0xFFE8C7A0)),
                ),
                Positioned(
                  right: -70,
                  top: 100 - driftB,
                  child: _bgGlow(290, const Color(0xFFB9DBEE)),
                ),
                Positioned(
                  left: 120 + driftB,
                  bottom: -120,
                  child: _bgGlow(320, const Color(0xFFD8C3ED)),
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 14),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFDDE2EA)),
                            ),
                            child: Row(
                              children: [
                                Transform.translate(
                                  offset: Offset(math.sin(t * math.pi * 8) * 3, 0),
                                  child: Transform.rotate(
                                    angle: math.sin(t * math.pi * 6) * 0.05,
                                    child: Container(
                                      height: isMobile ? 46 : 54,
                                      width: isMobile ? 46 : 54,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF1E7A7A), Color(0xFF6CA9E4)],
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x2A1E7A7A),
                                            blurRadius: 14,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.auto_stories_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'NoteNest',
                                  style: GoogleFonts.fredoka(
                                    fontSize: isMobile ? 28 : 34,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2B3552),
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  onPressed: _signOut,
                                  icon: const Icon(Icons.logout_rounded, size: 18),
                                  label: const Text('Sign Out'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF3E4D68),
                                    backgroundColor: Colors.white.withValues(alpha: 0.65),
                                    side: const BorderSide(color: Color(0xFFD2DBE7)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _entryAnim(
                          delay: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 700),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF355F8B), Color(0xFF4E9EB8), Color(0xFF6AB9B1)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2A355F8B),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hi, ${profile.name}',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '${profile.bio} ${profile.emoji}',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'ID: ${profile.uniqueId}',
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFFDDF4FF),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showProfilePhotoPreview(appState, profile),
                                  child: _profileAvatar(appState, profile, size: 52),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: isMobile
                              ? ListView(
                                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                                  children: [
                                    SizedBox(
                                      height: 380,
                                      child: _entryAnim(
                                        delay: 70,
                                        child: _leftPanel(context),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 148,
                                      child: _entryAnim(
                                        delay: 120,
                                        child: _actionCard(
                                          title: 'New To-do',
                                          subtitle: 'Plan your work',
                                          icon: Icons.check_circle_outline,
                                          colors: const [
                                            Color(0xFF9A86FF),
                                            Color(0xFF7E6DF2),
                                          ],
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const TodoBoardPage(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 148,
                                      child: _entryAnim(
                                        delay: 170,
                                        child: _actionCard(
                                          title: 'Upload Notes',
                                          subtitle: 'Go to notes tab',
                                          icon: Icons.upload_file_rounded,
                                          colors: const [
                                            Color(0xFF8FC5FF),
                                            Color(0xFF75B6F5),
                                          ],
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const UploadNotesPage(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 148,
                                      child: _entryAnim(
                                        delay: 220,
                                        child: _actionCard(
                                          title: 'Create Group',
                                          subtitle: 'Make a study group',
                                          icon: Icons.group_add_rounded,
                                          colors: const [
                                            Color(0xFF95D7E7),
                                            Color(0xFF6CBFD5),
                                          ],
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const GroupsPage(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: isTablet ? 5 : 6,
                                      child: _entryAnim(
                                        delay: 70,
                                        child: _leftPanel(context),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: isTablet ? 4 : 5,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: _entryAnim(
                                              delay: 120,
                                              child: _actionCard(
                                                title: 'New To-do',
                                                subtitle: 'Plan your work',
                                                icon: Icons.check_circle_outline,
                                                colors: const [
                                                  Color(0xFF9A86FF),
                                                  Color(0xFF7E6DF2),
                                                ],
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const TodoBoardPage(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: _entryAnim(
                                              delay: 170,
                                              child: _actionCard(
                                                title: 'Upload Notes',
                                                subtitle: 'Go to notes tab',
                                                icon: Icons.upload_file_rounded,
                                                colors: const [
                                                  Color(0xFF8FC5FF),
                                                  Color(0xFF75B6F5),
                                                ],
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const UploadNotesPage(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: _entryAnim(
                                              delay: 220,
                                              child: _actionCard(
                                                title: 'Create Group',
                                                subtitle: 'Make a study group',
                                                icon: Icons.group_add_rounded,
                                                colors: const [
                                                  Color(0xFF95D7E7),
                                                  Color(0xFF6CBFD5),
                                                ],
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const GroupsPage(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
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
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFEAF0F6),
        indicatorColor: const Color(0xFFD2E4F3),
        selectedIndex: currentIndex,
        onDestinationSelected: (value) {
          setState(() {
            currentIndex = value;
          });
          if (value == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LinksPage()),
            );
          }
          if (value == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarPage()),
            );
          }
          if (value == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditorPage()),
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.link_outlined),
            label: 'Links',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _leftPanel(BuildContext context) {
    final appState = context.watch<AppState>();
    final uploadedNotes = appState.notes
        .where((note) => note.localPath != null && note.localPath!.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5DEE8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A26465A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlobalSearchPage()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFEFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4DEE9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Color(0xFF3E5F79)),
                  const SizedBox(width: 6),
                  Text(
                    'Search subjects',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF43526A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFDFEFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4DEE9)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.folder_copy_outlined),
                    title: Text('My Files'),
                  ),
                  if (uploadedNotes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text('No uploaded files yet.'),
                    ),
                  ...uploadedNotes.map(
                    (note) => InkWell(
                      onTap: () => _openUploadedFile(note),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(_iconForFileType(note.type), size: 19),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    note.name,
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${note.subject} • ${note.year} • ${note.type}',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'open') {
                                  await _openUploadedFile(note);
                                }
                                if (value == 'download') {
                                  await _downloadUploadedFile(note);
                                }
                                if (value == 'delete') {
                                  await context.read<AppState>().deleteNote(note.id);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                    value: 'open', child: Text('Open File')),
                                PopupMenuItem(
                                    value: 'download', child: Text('Download')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Delete File')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForFileType(String type) {
    final normalized = type.toLowerCase();
    if (normalized == 'pdf') {
      return Icons.picture_as_pdf_outlined;
    }
    if (normalized == 'image') {
      return Icons.image_outlined;
    }
    return Icons.description_outlined;
  }

  Future<void> _signOut() async {
    await context.read<AppState>().logout();
  }

  Future<void> _openUploadedFile(NoteItem note) async {
    final storedPath = note.localPath;
    if (storedPath == null || storedPath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file found for this note.')),
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
        const SnackBar(content: Text('Could not open this file.')),
      );
    }
  }

  Future<void> _downloadUploadedFile(NoteItem note) async {
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
        const SnackBar(content: Text('Could not download this file.')),
      );
    }
  }

  Widget _profileAvatar(AppState appState, UserProfile profile, {double size = 38}) {
    final avatarPath = (profile.avatarPath ?? '').trim();
    if (avatarPath.isEmpty) {
      return Container(
        height: size,
        width: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Color(0x19000000),
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: _avatarLetter(profile.name),
      );
    }

    final avatarFuture = _avatarUrlFor(appState, profile.avatarPath);
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Color(0x19000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<String?>(
        future: avatarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _avatarLetter(profile.name);
          }
          final avatarUrl = snapshot.data;
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            return ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return _avatarLetter(profile.name);
                },
                errorBuilder: (context, error, stackTrace) =>
                    _avatarLetter(profile.name),
              ),
            );
          }
          return _avatarLetter(profile.name);
        },
      ),
    );
  }

  Widget _avatarLetter(String name) {
    final trimmed = name.trim();
    final match = RegExp(r'[A-Za-z0-9]').firstMatch(trimmed);
    final letter = match == null ? 'N' : match.group(0)!.toUpperCase();
    return Center(
      child: Text(
        letter,
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF3C3361),
        ),
      ),
    );
  }

  Future<String?> _avatarUrlFor(AppState appState, String? avatarPath) {
    final path = (avatarPath ?? '').trim();
    if (path.isEmpty) {
      _avatarFuturePath = null;
      _avatarUrlFuture = Future.value(null);
      return _avatarUrlFuture!;
    }
    if (_avatarUrlFuture != null && _avatarFuturePath == path) {
      return _avatarUrlFuture!;
    }
    _avatarFuturePath = path;
    _avatarUrlFuture = appState.createFileAccessUrl(path);
    return _avatarUrlFuture!;
  }

  Future<void> _showProfilePhotoPreview(
    AppState appState,
    UserProfile profile,
  ) async {
    final avatarUrl = await _avatarUrlFor(appState, profile.avatarPath);
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final imageSize = size.width < 560 ? size.width * 0.72 : 420.0;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 28,
                      color: Color(0x42000000),
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _avatarLetter(profile.name),
                        )
                      : _avatarLetter(profile.name),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                label: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: colors),
            boxShadow: const [
              BoxShadow(
                blurRadius: 16,
                color: Color(0x1F4A4388),
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFE9F8FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _entryAnim({required Widget child, required int delay}) {
    return AnimatedSlide(
      duration: Duration(milliseconds: 520 + delay),
      offset: _showContent ? Offset.zero : const Offset(0, 0.08),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 480 + delay),
        opacity: _showContent ? 1 : 0,
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }

  Widget _bgGlow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

}
