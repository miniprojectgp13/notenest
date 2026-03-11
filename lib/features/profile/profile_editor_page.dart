import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/user_profile.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/web_file_utils_stub.dart'
  if (dart.library.html) '../../core/utils/web_file_utils_web.dart';

class ProfileEditorPage extends StatefulWidget {
  const ProfileEditorPage({super.key});

  @override
  State<ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _collegeController;
  late TextEditingController _bioController;
  late TextEditingController _addMoreController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late List<ProfileField> _fields;

  final List<String> emojis = const [
    '😀',
    '🤓',
    '🥳',
    '😎',
    '🧠',
    '📚',
    '🔥',
    '⭐',
    '🚀',
    '💡',
    '🎯',
    '😊',
  ];

  String selectedEmoji = '🤓';
  late final AnimationController _bgController;
  bool _showContent = false;
  String? _avatarFuturePath;
  Future<String?>? _avatarUrlFuture;

  @override
  void initState() {
    super.initState();
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
    final profile = context.read<AppState>().profile;
    final user = context.read<AppState>().currentUser;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _collegeController = TextEditingController(text: user?.college ?? '');
    _bioController = TextEditingController(text: profile.bio);
    _addMoreController = TextEditingController(text: profile.additionalNote);
    selectedEmoji = profile.emoji;
    _fields =
        profile.extraFields
            .map(
              (field) => ProfileField(label: field.label, value: field.value),
            )
            .toList();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    _bioController.dispose();
    _addMoreController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile Card',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        foregroundColor: const Color(0xFF2E3C54),
        backgroundColor: const Color(0xFFEAF0F6),
      ),
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          final dx = math.sin(t * math.pi * 2) * 12;
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
                  left: -60 + dx,
                  bottom: -120,
                  child: _bgGlow(270, const Color(0xFFE2C4A2)),
                ),
                Positioned(
                  right: -70 - dx,
                  top: -90,
                  child: _bgGlow(300, const Color(0xFFB7DDED)),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
            _entryAnim(delay: 0, child: _buildAvatarSection(appState)),
            const SizedBox(height: 12),
            _entryAnim(
              delay: 40,
              child: _sectionCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Settings',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: const Color(0xFF2B3D58),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Username'),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Phone number'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                  return 'Enter 10-digit phone';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _collegeController,
              decoration: _inputDecoration('College name'),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bioController,
              decoration: _inputDecoration('Bio'),
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addMoreController,
              decoration: _inputDecoration('Add more'),
            ),
            const SizedBox(height: 12),
            Text(
              'Select emoji',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF344563),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  emojis
                      .map(
                        (emoji) => ChoiceChip(
                          label: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
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
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Custom Fields',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _fields.add(ProfileField(label: 'New Field', value: ''));
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            ..._fields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 620;
                    if (narrow) {
                      return Column(
                        children: [
                          TextFormField(
                            initialValue: field.label,
                            decoration: _inputDecoration('Field name'),
                            onChanged: (value) => field.label = value,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: field.value,
                            decoration: _inputDecoration('Field value'),
                            onChanged: (value) => field.value = value,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _fields.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: field.label,
                            decoration: _inputDecoration('Field name'),
                            onChanged: (value) => field.label = value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: field.value,
                            decoration: _inputDecoration('Field value'),
                            onChanged: (value) => field.value = value,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fields.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Unique ID: ${appState.profile.uniqueId}',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
            TextButton.icon(
              onPressed: () async {
                await appState.regenerateUniqueId();
              },
              icon: const Icon(Icons.autorenew),
              label: const Text('Regenerate Unique ID'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) {
                  return;
                }
                try {
                  await appState.updateProfile(
                    name: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    college: _collegeController.text.trim(),
                    bio: _bioController.text.trim(),
                    emoji: selectedEmoji,
                    additionalNote: _addMoreController.text.trim(),
                    extraFields:
                        _fields
                            .where((field) => field.label.trim().isNotEmpty)
                            .toList(),
                  );
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Settings saved.'),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Settings'),
            ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _entryAnim(delay: 80, child: _buildPasswordSection(appState)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
              color.withValues(alpha: 0.32),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(AppState appState) {
    final avatarPath = appState.profile.avatarPath;
    final isNarrow = MediaQuery.of(context).size.width < 780;
    return _sectionCard(
      padding: const EdgeInsets.all(14),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: isNarrow
            ? Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showProfilePhotoOptions(appState),
                        child: _avatarFutureView(appState, avatarPath),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _avatarText()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _uploadPhotoButton(appState)),
                      const SizedBox(width: 8),
                      Expanded(child: _downloadPhotoButton(appState)),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProfilePhotoOptions(appState),
                    child: _avatarFutureView(appState, avatarPath),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _avatarText()),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _uploadPhotoButton(appState),
                      const SizedBox(height: 8),
                      _downloadPhotoButton(appState),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPasswordSection(AppState appState) {
    return _sectionCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2E405C),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: _inputDecoration('Current password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: _inputDecoration('New password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: _inputDecoration('Confirm new password'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                final current = _currentPasswordController.text;
                final next = _newPasswordController.text;
                final confirm = _confirmPasswordController.text;

                if (next != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New password and confirm password must match.')),
                  );
                  return;
                }

                final error = await appState.changePassword(
                  currentPassword: current,
                  newPassword: next,
                );
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? 'Password changed successfully.')),
                );
                if (error == null) {
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                }
              },
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD2DDEA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD2DDEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5E91B5), width: 1.4),
      ),
    );
  }

  Widget _entryAnim({required Widget child, required int delay}) {
    return AnimatedSlide(
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      offset: _showContent ? Offset.zero : const Offset(0, 0.06),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 360 + delay),
        curve: Curves.easeOut,
        opacity: _showContent ? 1 : 0,
        child: child,
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(0),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        border: Border.all(color: const Color(0xFFD4DEEA)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2E4A62),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _avatarFutureView(AppState appState, String? avatarPath) {
    final path = (avatarPath ?? '').trim();
    if (path.isEmpty) {
      return _avatarPreview(
        name: appState.profile.name,
        imageUrl: null,
        radius: 28,
      );
    }

    final future = _avatarUrlFor(appState, avatarPath);
    return FutureBuilder<String?>(
      key: ValueKey(avatarPath ?? 'no-avatar'),
      future: future,
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 28,
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _avatarPreview(
          name: appState.profile.name,
          imageUrl: imageUrl,
          radius: 28,
        );
      },
    );
  }

  Widget _avatarText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          'Upload your user photo for home and settings avatar.',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _uploadPhotoButton(AppState appState) {
    return OutlinedButton.icon(
      onPressed: () => _handleUploadPhoto(appState),
      icon: const Icon(Icons.photo_camera_outlined),
      label: const Text('Upload'),
    );
  }

  Widget _downloadPhotoButton(AppState appState) {
    return OutlinedButton.icon(
      onPressed: () => _handleDownloadPhoto(appState),
      icon: const Icon(Icons.download_rounded),
      label: const Text('Download'),
    );
  }

  Future<void> _showProfilePhotoOptions(AppState appState) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final hasPhoto = (appState.profile.avatarPath ?? '').trim().isNotEmpty;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Upload Photo'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _handleUploadPhoto(appState);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Download Photo'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _handleDownloadPhoto(appState);
                },
              ),
              ListTile(
                enabled: hasPhoto,
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Delete Current Photo'),
                textColor: Colors.redAccent,
                onTap: hasPhoto
                    ? () async {
                        Navigator.pop(sheetContext);
                        await _handleDeletePhoto(appState);
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleUploadPhoto(AppState appState) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return;
    }

    final error = await appState.uploadProfilePhoto(
      fileBytes: bytes,
      originalFileName: file.name,
    );
    if (error == null) {
      setState(() {});
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Profile photo uploaded.')),
    );
  }

  Future<void> _handleDownloadPhoto(AppState appState) async {
    final avatarPath = appState.profile.avatarPath;
    if (avatarPath == null || avatarPath.trim().isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload profile photo first.')),
      );
      return;
    }

    final signedUrl = await appState.createFileAccessUrl(avatarPath);
    if (!context.mounted) {
      return;
    }
    if (signedUrl == null || signedUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not prepare photo download.')),
      );
      return;
    }

    final fileName = avatarPath.split('/').last;
    bool ok = false;
    if (kIsWeb) {
      ok = await downloadUrlInBrowser(signedUrl, fileName);
    } else {
      final uri = Uri.tryParse(signedUrl);
      if (uri != null) {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile photo download started.' : 'Could not download profile photo.',
        ),
      ),
    );
  }

  Future<void> _handleDeletePhoto(AppState appState) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Profile Photo'),
        content: const Text('Remove your current profile photo?'),
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
    if (ok != true) {
      return;
    }

    final error = await appState.deleteProfilePhoto();
    if (error == null) {
      setState(() {
        _avatarFuturePath = null;
        _avatarUrlFuture = Future.value(null);
      });
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Profile photo deleted.')),
    );
  }

  Widget _avatarPreview({
    required String name,
    required String? imageUrl,
    required double radius,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            imageUrl,
            height: radius * 2,
            width: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _avatarFallback(name),
          ),
        ),
      );
    }
    return CircleAvatar(radius: radius, child: _avatarFallback(name));
  }

  Widget _avatarFallback(String name) {
    final trimmed = name.trim();
    final match = RegExp(r'[A-Za-z0-9]').firstMatch(trimmed);
    final letter = match == null ? 'N' : match.group(0)!.toUpperCase();
    return Text(
      letter,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 20),
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
}
