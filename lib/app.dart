import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';

class NoteNestApp extends StatelessWidget {
  const NoteNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'NoteNest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Consumer<AppState>(
          builder: (context, appState, _) {
            if (appState.isLoggedIn) {
              return const HomePage();
            }
            return const AuthPage();
          },
        ),
      ),
    );
  }
}
