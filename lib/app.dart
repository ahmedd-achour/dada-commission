import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/app_state.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/main_shell.dart';

class DadaApp extends StatefulWidget {
  const DadaApp({super.key, this.state});

  /// Injected in tests; created internally otherwise.
  final AppState? state;

  @override
  State<DadaApp> createState() => _DadaAppState();
}

class _DadaAppState extends State<DadaApp> {
  late final AppState _state = widget.state ?? AppState();

  @override
  void dispose() {
    if (widget.state == null) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) => MaterialApp(
          title: 'Dada Commission',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _state.themeMode,
          // One stable MaterialApp; auth branching happens below the
          // Navigator (swapping `home` would not reset the cached route).
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final signedIn = AppScope.of(context).isSignedIn;
    return signedIn ? const MainShell() : const SignInScreen();
  }
}
