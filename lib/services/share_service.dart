import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where a referral can be shared.
enum ShareTarget { whatsapp, facebook, tiktok, instagram, other }

/// Opens the right app for each network, falling back to the system share
/// sheet (TikTok and Instagram have no web "share text" link, so they always
/// go through the share sheet, where the user picks the app).
class ShareService {
  const ShareService();

  Future<void> share({
    required String text,
    required String link,
    ShareTarget target = ShareTarget.other,
  }) async {
    final opened = switch (target) {
      ShareTarget.whatsapp => await _open(
        Uri.https('wa.me', '/', {'text': text}),
      ),
      ShareTarget.facebook => await _open(
        Uri.https('www.facebook.com', '/sharer/sharer.php', {'u': link}),
      ),
      _ => false,
    };
    if (!opened) {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'Dada Commission'),
      );
    }
  }

  Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
