import '../models/app_user.dart';

/// Thrown while a sign-in provider is not wired yet.
class AuthNotAvailableException implements Exception {
  AuthNotAvailableException(this.provider);
  final AuthProviderType provider;

  @override
  String toString() =>
      'Connexion ${provider.label} bientôt disponible. Utilisez le mode invité.';
}

/// Sign-in entry points. Only Facebook, Google and WhatsApp are planned.
///
/// To implement later:
/// - Google: `google_sign_in` -> `GoogleAuthProvider.credential` ->
///   `FirebaseAuth.signInWithCredential`.
/// - Facebook: `flutter_facebook_auth` -> `FacebookAuthProvider.credential`.
/// - WhatsApp: not a Firebase provider. Send an OTP through the WhatsApp
///   Business API from a Cloud Function, verify it server-side and return a
///   Firebase custom token (`signInWithCustomToken`).
/// After the first sign-in, a Cloud Function creates `users/{uid}`,
/// `wallets/{uid}` and reserves a unique `referralCodes/{code}`.
class AuthService {
  Future<void> signInWithGoogle() async =>
      throw AuthNotAvailableException(AuthProviderType.google);

  Future<void> signInWithFacebook() async =>
      throw AuthNotAvailableException(AuthProviderType.facebook);

  Future<void> signInWithWhatsApp() async =>
      throw AuthNotAvailableException(AuthProviderType.whatsapp);
}
