import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool showLogin = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final pulse = Curves.easeInOut.transform(
            (math.sin(_controller.value * math.pi * 2) + 1) / 2,
          );

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF3EEE7),
                  Color(0xFFE7F1F6),
                  Color(0xFFF6E9E1),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80 + (pulse * 20),
                  left: -50,
                  child: _GlowOrb(
                    size: 240,
                    color: const Color(0xFFFFC98B).withValues(alpha: 0.38),
                  ),
                ),
                Positioned(
                  right: -70,
                  top: 90 - (pulse * 22),
                  child: _GlowOrb(
                    size: 280,
                    color: const Color(0xFF8CC7D8).withValues(alpha: 0.34),
                  ),
                ),
                Positioned(
                  bottom: -120,
                  left: 50 + (pulse * 18),
                  child: _GlowOrb(
                    size: 300,
                    color: const Color(0xFF9E8BFF).withValues(alpha: 0.22),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 920;
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1080),
                            child: isWide
                                ? Row(
                                    children: [
                                      Expanded(child: _HeroPanel(pulse: pulse)),
                                      const SizedBox(width: 28),
                                      SizedBox(
                                        width: 430,
                                        child: _AuthShell(
                                          showLogin: showLogin,
                                          onModeChanged: (value) {
                                            setState(() {
                                              showLogin = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _HeroPanel(pulse: pulse, compact: true),
                                      const SizedBox(height: 22),
                                      _AuthShell(
                                        showLogin: showLogin,
                                        onModeChanged: (value) {
                                          setState(() {
                                            showLogin = value;
                                          });
                                        },
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
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.pulse, this.compact = false});

  final double pulse;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, compact ? 0 : (pulse * 6 - 3)),
      child: Container(
        padding: EdgeInsets.all(compact ? 22 : 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          color: Colors.white.withValues(alpha: 0.48),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 40,
              offset: Offset(0, 16),
              color: Color(0x1A514A7F),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E7A7A), Color(0xFF6CA9E4)],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NoteNest',
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2F3458),
                      ),
                    ),
                    Text(
                      'Study cloud for notes, links, groups, and chats',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF66708F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: compact ? 18 : 28),
            Text(
              'One login. Your files, images, links, group chats, and private messages stay with you.',
              style: GoogleFonts.nunito(
                fontSize: compact ? 24 : 34,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2E3250),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Built for students who want notes that feel alive: upload once, download anytime, chat in groups, and reopen the app days later without losing context.',
              style: GoogleFonts.nunito(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF67708A),
              ),
            ),
            SizedBox(height: compact ? 18 : 26),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _FeaturePill(label: 'Cloud note vault', phase: 0.0),
                _FeaturePill(label: 'Download your uploads', phase: 0.25),
                _FeaturePill(label: 'Personal and group chat', phase: 0.5),
                _FeaturePill(label: 'Username or phone login', phase: 0.75),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({
    required this.showLogin,
    required this.onModeChanged,
  });

  final bool showLogin;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 40,
            offset: Offset(0, 18),
            color: Color(0x244B4A76),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFF1EEF7),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Login',
                    selected: showLogin,
                    onTap: () => onModeChanged(true),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ModeButton(
                    label: 'Sign Up',
                    selected: !showLogin,
                    onTap: () => onModeChanged(false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: showLogin
                ? _LoginCard(
                    key: const ValueKey('login'),
                    onSwitch: () => onModeChanged(false),
                  )
                : _SignUpCard(
                    key: const ValueKey('signup'),
                    onSwitch: () => onModeChanged(true),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF256D7B), Color(0xFF6C7EF6)],
                  )
                : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : const Color(0xFF6A6685),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard({required this.onSwitch, super.key});

  final VoidCallback onSwitch;

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  String? _loginError;
  int _errorTick = 0;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('login-form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: GoogleFonts.nunito(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2E3350),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Login using your username or phone number and continue where you left off.',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF707894),
            ),
          ),
          const SizedBox(height: 18),
          _GlassField(
            controller: _idController,
            icon: Icons.person_outline_rounded,
            label: 'Username or phone number',
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _GlassField(
            controller: _passwordController,
            icon: Icons.lock_outline_rounded,
            label: 'Password',
            obscureText: true,
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _loginError == null
                ? const SizedBox.shrink(key: ValueKey('no-login-error'))
                : _AnimatedInlineError(
                    key: ValueKey('login-error-$_errorTick'),
                    message: _loginError!,
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF255D78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _busy
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() != true) {
                        return;
                      }
                      setState(() {
                        _busy = true;
                        _loginError = null;
                      });
                      final error = await context.read<AppState>().login(
                            identifier: _idController.text,
                            password: _passwordController.text,
                          );
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _busy = false;
                      });
                      if (error != null) {
                        setState(() {
                          _loginError = error;
                          _errorTick++;
                        });
                      }
                    },
              icon: Icon(_busy ? Icons.hourglass_top_rounded : Icons.login),
              label: Text(_busy ? 'Checking access...' : 'Login'),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: widget.onSwitch,
              child: const Text('Create a new account'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedInlineError extends StatelessWidget {
  const _AnimatedInlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) {
        final shakeX = math.sin(t * math.pi * 6) * (1 - t) * 16;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(shakeX, 0),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE53935)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.error_outline_rounded,
                  color: Color(0xFFC62828), size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.nunito(
                  color: const Color(0xFFC62828),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignUpCard extends StatefulWidget {
  const _SignUpCard({required this.onSwitch, super.key});

  final VoidCallback onSwitch;

  @override
  State<_SignUpCard> createState() => _SignUpCardState();
}

class _SignUpCardState extends State<_SignUpCard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _collegeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  String? _signUpError;
  int _errorTick = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('signup-form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your cloud desk',
            style: GoogleFonts.nunito(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2E3350),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your notes, files, groups, links, and chats will be available the next time you return.',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF707894),
            ),
          ),
          const SizedBox(height: 18),
          _GlassField(
            controller: _nameController,
            icon: Icons.badge_outlined,
            label: 'Username',
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _GlassField(
            controller: _phoneController,
            icon: Icons.phone_outlined,
            label: 'Phone number',
            keyboardType: TextInputType.phone,
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
          const SizedBox(height: 12),
          _GlassField(
            controller: _collegeController,
            icon: Icons.school_outlined,
            label: 'College name',
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _GlassField(
            controller: _passwordController,
            icon: Icons.key_outlined,
            label: 'Password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (value.length < 6) {
                return 'Min 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _signUpError == null
                ? const SizedBox.shrink(key: ValueKey('no-signup-error'))
                : _AnimatedInlineError(
                    key: ValueKey('signup-error-$_errorTick'),
                    message: _signUpError!,
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6A67F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _busy
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() != true) {
                        return;
                      }
                      setState(() {
                        _busy = true;
                        _signUpError = null;
                      });
                      final error = await context.read<AppState>().signUp(
                            name: _nameController.text,
                            phone: _phoneController.text,
                            college: _collegeController.text,
                            password: _passwordController.text,
                          );
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _busy = false;
                      });
                      if (error != null) {
                        setState(() {
                          _signUpError = error;
                          _errorTick++;
                        });
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signup successful. Please login to continue.'),
                        ),
                      );
                      widget.onSwitch();
                    },
              icon: Icon(
                _busy ? Icons.hourglass_top_rounded : Icons.person_add_alt_1,
              ),
              label: Text(_busy ? 'Creating your space...' : 'Sign Up'),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: widget.onSwitch,
              child: const Text('Already have an account? Login'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String? Function(String?) validator;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF60708C)),
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE4E6EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF6A67F3), width: 1.4),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatefulWidget {
  const _FeaturePill({required this.label, this.phase = 0.0});

  final String label;
  final double phase;

  @override
  State<_FeaturePill> createState() => _FeaturePillState();
}

class _FeaturePillState extends State<_FeaturePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final dx =
            math.sin((_ctrl.value + widget.phase) * math.pi * 2) * 12;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.7),
          border: Border.all(color: const Color(0xFFE0DCEB)),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4D5474),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
