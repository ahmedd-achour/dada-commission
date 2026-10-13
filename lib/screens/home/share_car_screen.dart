import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';
import 'create_post_screen.dart';

/// "Partager une voiture": code, link, QR code and share targets.
class ShareCarScreen extends StatelessWidget {
  const ShareCarScreen({super.key, required this.car});
  final Car car;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user!;
    final scheme = Theme.of(context).colorScheme;
    final link = '${user.referralLink}?car=${car.id}';
    final example = CommissionCalculator.compute(
      days: 3,
      pricePerDay: car.pricePerDay,
      tierRate: user.tier.commissionRate,
    );
    final caption =
        '${car.model} à ${Fmt.price(car.pricePerDay)}/jour chez '
        '${car.companyName}. Réservez avec mon code ${user.referralCode} : −5 % 👉 $link';

    return Scaffold(
      appBar: AppBar(title: const Text('Partager une voiture')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: CarImage(
                      height: 90,
                      category: car.category,
                      imageUrl: car.imageUrl,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.model,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${car.category.label} · ${Fmt.price(car.pricePerDay)} / jour',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Votre part : ${Fmt.percent(user.tier.commissionRate)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '≈ ${Fmt.coins(example.coins)} pour 3 jours',
                          style: TextStyle(color: scheme.primary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Mon code'),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: scheme.primary, width: 1.5),
                    color: scheme.primaryContainer.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    user.referralCode,
                    style: AppTheme.display(
                      fontSize: 22,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => copyText(context, user.referralCode),
                child: const Text('Copier'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionTitle('Mon lien'),
          Card(
            child: ListTile(
              title: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => copyText(context, link),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Partager sur'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ShareTarget(
                'TikTok',
                FontAwesomeIcons.tiktok,
                caption,
                link,
                ShareTarget.tiktok,
              ),
              _ShareTarget(
                'Instagram',
                FontAwesomeIcons.instagram,
                caption,
                link,
                ShareTarget.instagram,
              ),
              _ShareTarget(
                'WhatsApp',
                FontAwesomeIcons.whatsapp,
                caption,
                link,
                ShareTarget.whatsapp,
              ),
              _ShareTarget(
                'Facebook',
                FontAwesomeIcons.facebookF,
                caption,
                link,
                ShareTarget.facebook,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionTitle('QR code'),
          Center(child: ReferralQr(data: link, size: 170)),
          const SizedBox(height: 8),
          Text(
            'À poser à l\'accueil ou à montrer : le client scanne et réserve avec votre code.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Modèles prêts à publier'),
          Row(
            children: [
              Expanded(
                child: _TemplateTile(
                  icon: Icons.play_circle_outline,
                  label: 'Vidéo 9:16',
                  onTap: () =>
                      showSnack(context, 'Modèles vidéo bientôt disponibles.'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TemplateTile(
                  icon: Icons.crop_square_rounded,
                  label: 'Post dans le fil',
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => CreatePostScreen(car: car),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget(
    this.label,
    this.icon,
    this.caption,
    this.link,
    this.target,
  );
  final String label;
  final FaIconData icon;
  final String caption;
  final String link;
  final ShareTarget target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        // TikTok / Instagram open through the share sheet; copy the caption
        // too so it can be pasted under a video.
        if (target == ShareTarget.tiktok || target == ShareTarget.instagram) {
          await copyText(
            context,
            caption,
            message: 'Légende copiée : collez-la sous votre vidéo $label.',
          );
        }
        await const ShareService().share(
          text: caption,
          link: link,
          target: target,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.surfaceContainerHighest,
              child: FaIcon(icon, size: 20, color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
