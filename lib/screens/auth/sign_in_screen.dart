import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// Sign-in with Facebook, Google or WhatsApp (to be wired), plus a guest mode
/// backed by mock data in the meantime.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _auth = AuthService();
  bool _busy = false;

  Future<void> _run(Future<void> Function() signIn) async {
    setState(() => _busy = true);
    try {
      await signIn();
    } on AuthNotAvailableException catch (e) {
      if (mounted) showSnack(context, e.toString());
    } catch (e) {
      if (mounted) showSnack(context, 'Connexion impossible : $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.8);

    // Full-bleed blue -> green "loading screen" look.
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const SizedBox(height: 24),
                      Text(
                        'Dada.',
                        style: AppTheme.display(
                          fontSize: 52,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Commission',
                        style: AppTheme.display(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Partagez une voiture, gagnez des Dada Coins, '
                        'échangez-les contre des cadeaux.',
                        style: AppTheme.body(fontSize: 15, color: muted),
                      ),
                      const SizedBox(height: 40),
                      _ProviderButton(
                        label: 'Continuer avec Facebook',
                        icon: FontAwesomeIcons.facebookF,
                        background: AppTheme.facebook,
                        foreground: Colors.white,
                        onPressed: _busy
                            ? null
                            : () => _run(_auth.signInWithFacebook),
                      ),
                      const SizedBox(height: 12),
                      _ProviderButton(
                        label: 'Continuer avec Google',
                        icon: FontAwesomeIcons.google,
                        background: Colors.white,
                        foreground: const Color(0xFF1F1F1F),
                        onPressed: _busy
                            ? null
                            : () => _run(_auth.signInWithGoogle),
                      ),
                      const SizedBox(height: 12),
                      _ProviderButton(
                        label: 'Continuer avec WhatsApp',
                        icon: FontAwesomeIcons.whatsapp,
                        background: AppTheme.whatsapp,
                        foreground: Colors.white,
                        onPressed: _busy
                            ? null
                            : () => _run(_auth.signInWithWhatsApp),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: muted)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('ou', style: TextStyle(color: muted)),
                          ),
                          Expanded(child: Divider(color: muted)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        key: const Key('guest-sign-in'),
                        onPressed: _busy
                            ? null
                            : () => AppScope.read(context).signInAsGuest(),
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Continuer en tant qu\'invité'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mode démo avec des données fictives.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body(fontSize: 12, color: muted),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      Text(
                        'Dès 18 ans. En continuant, vous acceptez les règles du '
                        'programme et notre politique de confidentialité.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final FaIconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 20, color: foreground),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
