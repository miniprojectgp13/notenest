import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
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

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F1FA), Color(0xFFF1F1F7), Color(0xFFEDE9F4)],
            stops: [0.02, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          'NoteNest',
                          style: GoogleFonts.fredoka(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF372C58),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileEditorPage(),
                              ),
                            );
                          },
                          child: Container(
                            height: 38,
                            width: 38,
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
                            child: Center(
                              child: Text(
                                profile.name.isEmpty
                                    ? 'N'
                                    : profile.name[0].toUpperCase(),
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF3C3361),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _entryAnim(
                    delay: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 650),
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A78FF), Color(0xFF66C8D4)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2B5D4ECF),
                            blurRadius: 16,
                            offset: Offset(0, 8),
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
                                    color: const Color(0xFFEDEAFF),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileEditorPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0x33FFFFFF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              'Edit',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _entryAnim(
                              delay: 70,
                              child: _leftPanel(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
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
                                          builder: (
                                            _,
                                          ) =>
                                              const TodoBoardPage(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                                          builder: (
                                            _,
                                          ) =>
                                              const UploadNotesPage(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                                          builder: (
                                            _,
                                          ) =>
                                              const GroupsPage(),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFEFE9F8),
        indicatorColor: const Color(0xFFDAD1FA),
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

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7D193), width: 1.4),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8D0BD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Search subjects',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8D0BD)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.folder_copy_outlined),
                    title: Text('My Subjects'),
                  ),
                  ...appState.subjectCounts.entries.map(
                    (entry) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.menu_book_outlined, size: 19),
                      title: Text(
                        entry.key,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${entry.value} Notes',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showRenameSubjectDialog(context, entry.key);
                          }
                          if (value == 'delete') {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete subject'),
                                content: Text(
                                    'Delete all notes under ${entry.key}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              context.read<AppState>().deleteSubject(entry.key);
                            }
                          }
                          if (value == 'more' && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'More options for ${entry.key} coming soon.')),
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'edit', child: Text('Edit Subject')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Delete Subject')),
                          PopupMenuItem(
                              value: 'more', child: Text('More Options')),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UploadNotesPage(initialSubject: entry.key),
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

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: colors),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                color: Color(0x1F4A4388),
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 29),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
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
      duration: Duration(milliseconds: 550 + delay),
      offset: _showContent ? Offset.zero : const Offset(0, 0.08),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 500 + delay),
        opacity: _showContent ? 1 : 0,
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }

  Future<void> _showRenameSubjectDialog(
      BuildContext context, String oldName) async {
    final controller = TextEditingController(text: oldName);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Subject Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Subject name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == oldName) {
                Navigator.pop(dialogContext);
                return;
              }
              context
                  .read<AppState>()
                  .renameSubject(oldName: oldName, newName: newName);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
