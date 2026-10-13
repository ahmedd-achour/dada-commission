import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';
import '../../widgets/user_sheet.dart';
import 'comments_sheet.dart';
import 'share_car_screen.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final isMine = post.authorId == state.user?.id;
    final car = state.carById(post.carId);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.surfaceContainerHighest, width: 8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            leading: isMine
                ? const MyAvatar(radius: 21)
                : UserAvatar(name: post.authorName, radius: 21),
            title: Text(
              post.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              [
                post.authorHeadline,
                Fmt.timeAgo(post.createdAt),
                if (post.isSponsored) 'Sponsorisé',
              ].join(' · '),
              style: TextStyle(fontSize: 12, color: muted),
            ),
            trailing: post.type == PostType.challenge
                ? const Icon(Icons.emoji_events_outlined, color: AppTheme.green)
                : null,
            onTap: isMine ? null : () => _openAuthor(context, state),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text(
              post.text,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ),
          if (post.hasCar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CarImage(
                    label: post.carModel,
                    category: car?.category,
                    imageUrl: car?.imageUrl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (post.carPricePerDay != null)
                        '${Fmt.price(post.carPricePerDay!)} / jour',
                      ?post.carCompanyName,
                    ].join(' · '),
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (post.referralCode != null)
                    FilledButton.tonal(
                      onPressed: () => showBookWithCodeSheet(context, post),
                      child: Text('Réserver avec ${post.referralCode}'),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Icon(Icons.favorite, size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${post.likeCount}',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => showCommentsSheet(context, post),
                    child: Text(
                      '${post.commentCount} commentaires · ${post.shareCount} partages',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16, indent: 16, endIndent: 16),
          Row(
            children: [
              _Action(
                icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                label: "J'aime",
                color: post.likedByMe ? scheme.primary : null,
                onTap: () => state.toggleLike(post.id),
              ),
              _Action(
                icon: Icons.mode_comment_outlined,
                label: 'Commenter',
                onTap: () => showCommentsSheet(context, post),
              ),
              _Action(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: () => _share(context, state, car),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _openAuthor(BuildContext context, AppState state) {
    for (final u in state.directory) {
      if (u.id == post.authorId) {
        showUserSheet(context, u);
        return;
      }
    }
  }

  /// Sharing always uses the current user's own code, so they earn on it.
  /// Shared links always carry the current user's code, so they earn on it.
  void _share(BuildContext context, AppState state, Car? car) {
    final user = state.user!;
    final link = car == null
        ? user.referralLink
        : '${user.referralLink}?car=${car.id}';
    final text = car == null
        ? '${post.text}\n\nRejoignez Dada Commission avec mon code '
              '${user.referralCode} 👉 $link'
        : '${car.model} à ${Fmt.price(car.pricePerDay)}/jour chez '
              '${car.companyName}. Réservez avec mon code '
              '${user.referralCode} : −5 % 👉 $link';
    const service = ShareService();

    Future<void> go(ShareTarget target) async {
      Navigator.of(context).pop();
      state.registerShare(post.id);
      await service.share(text: text, link: link, target: target);
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Partager',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (car != null)
              ListTile(
                leading: const Icon(Icons.qr_code_2_rounded),
                title: const Text('Partager avec mon code et QR'),
                subtitle: Text(
                  'Gagnez ${Fmt.percent(user.tier.commissionRate)} '
                  'de chaque location',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  state.registerShare(post.id);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ShareCarScreen(car: car)),
                  );
                },
              ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: AppTheme.whatsapp,
              ),
              title: const Text('WhatsApp'),
              onTap: () => go(ShareTarget.whatsapp),
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.facebookF,
                color: AppTheme.facebook,
              ),
              title: const Text('Facebook'),
              onTap: () => go(ShareTarget.facebook),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Autres applications…'),
              onTap: () => go(ShareTarget.other),
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: const Text('Copier le lien'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                state.registerShare(post.id);
                copyText(context, link, message: 'Lien copié : $link');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        icon: Icon(icon, size: 20, color: c),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: c),
        ),
      ),
    );
  }
}

/// What a customer sees when tapping "Réserver avec CODE".
void showBookWithCodeSheet(BuildContext context, Post post) {
  const days = 3;
  final price = post.carPricePerDay ?? 0;
  final gross = price * days;
  final net = gross * (1 - kCustomerDiscountRate);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              post.carModel ?? 'Voiture',
              style: AppTheme.display(fontSize: 22),
            ),
            Text(post.carCompanyName ?? ''),
            const SizedBox(height: 16),
            _PriceRow('Prix', '${Fmt.price(price)} / jour'),
            _PriceRow('$days jours', Fmt.dinars(gross)),
            _PriceRow(
              'Code ${post.referralCode} (−${Fmt.percent(kCustomerDiscountRate)})',
              '−${Fmt.dinars(gross - net)}',
            ),
            const Divider(),
            _PriceRow('Total', Fmt.dinars(net), bold: true),
            const SizedBox(height: 8),
            Text(
              'La remise s\'applique à votre première location avec un code.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                copyText(
                  context,
                  post.referralCode!,
                  message:
                      'Réservation en ligne bientôt disponible. '
                      'Code ${post.referralCode} copié.',
                );
              },
              child: Text('Réserver avec ${post.referralCode}'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
