import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F2FF), Color(0xFFEFF8FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
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
                        onSwitch: () => setState(() => showLogin = false),
                      )
                    : _SignUpCard(
                        key: const ValueKey('signup'),
                        onSwitch: () => setState(() => showLogin = true),
                      ),
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

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Welcome Back',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idController,
                decoration:
                    const InputDecoration(labelText: 'Phone number or Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() != true) {
                            return;
                          }
                          setState(() {
                            _busy = true;
                          });
                          final error = context.read<AppState>().login(
                                identifier: _idController.text,
                                password: _passwordController.text,
                              );
                          setState(() {
                            _busy = false;
                          });
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                  icon: const Icon(Icons.login),
                  label: Text(_busy ? 'Please wait...' : 'Login'),
                ),
              ),
              TextButton(
                onPressed: widget.onSwitch,
                child: const Text('No account? Sign up'),
              ),
            ],
          ),
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
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
              const SizedBox(height: 8),
              TextFormField(
                controller: _collegeController,
                decoration: const InputDecoration(labelText: 'College name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() != true) {
                            return;
                          }
                          setState(() {
                            _busy = true;
                          });
                          final error = context.read<AppState>().signUp(
                                name: _nameController.text,
                                phone: _phoneController.text,
                                college: _collegeController.text,
                                password: _passwordController.text,
                              );
                          setState(() {
                            _busy = false;
                          });
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(error)));
                            return;
                          }
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Signup successful. Please login to continue.',
                              ),
                            ),
                          );
                          widget.onSwitch();
                        },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(_busy ? 'Please wait...' : 'Sign Up'),
                ),
              ),
              TextButton(
                onPressed: widget.onSwitch,
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
