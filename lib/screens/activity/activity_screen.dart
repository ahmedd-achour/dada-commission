import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// Activité: "Mes clients" (referrals and their coins) and "Défis"
/// (monthly challenge, badges, ranking).
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Activité', style: AppTheme.display(fontSize: 22)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mes clients'),
              Tab(text: 'Défis & classement'),
            ],
          ),
        ),
        body: const TabBarView(children: [_ClientsTab(), _ChallengesTab()]),
      ),
    );
  }
}

class _ClientsTab extends StatelessWidget {
  const _ClientsTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final stats = state.stats;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(value: stats.clicks, label: 'clics'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(value: stats.bookings, label: 'réservations'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(value: stats.completed, label: 'terminées'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Mes clients récents'),
        if (state.referrals.isEmpty)
          const EmptyState(
            icon: Icons.people_outline,
            message: 'Partagez votre code pour obtenir vos premiers clients.',
          )
        else
          Card(
            child: Column(
              children: [
                for (final (i, r) in state.referrals.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 72),
                  _ReferralTile(referral: r),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Les noms sont cachés pour protéger la vie privée des clients. '
                    'Les coins arrivent 7 jours après le retour de la voiture.',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Text('$value', style: AppTheme.display(fontSize: 28)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ReferralTile extends StatelessWidget {
  const _ReferralTile({required this.referral});
  final Referral referral;

  @override
  Widget build(BuildContext context) {
    final r = referral;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final detail = switch (r.status) {
      ReferralStatus.booked when r.startDate != null =>
        'réservée pour le ${Fmt.shortDate(r.startDate!)}',
      ReferralStatus.cancelled => 'annulée par le client',
      ReferralStatus.refunded => 'location remboursée',
      ReferralStatus.returned when r.coinsAvailableAt != null =>
        'coins le ${Fmt.shortDate(r.coinsAvailableAt!)}',
      _ => '${r.rentalDays} jours · ${r.carModel}',
    };
    final coinsLabel = switch (r.status) {
      ReferralStatus.validated => Fmt.signedCoins(r.coins),
      ReferralStatus.cancelled || ReferralStatus.refunded => Fmt.coins(0),
      _ => '≈ ${Fmt.coins(r.coins)} en attente',
    };

    return ListTile(
      leading: UserAvatar(name: r.customerMaskedName),
      title: Text(
        r.customerMaskedName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('$detail · via ${r.source.label}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StatusPill.referral(r.status),
          const SizedBox(height: 4),
          Text(
            coinsLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: r.status == ReferralStatus.validated
                  ? AppTheme.success
                  : muted,
            ),
          ),
        ],
      ),
      onTap: () => _showBreakdown(context, r),
    );
  }

  void _showBreakdown(BuildContext context, Referral r) {
    final c = r.commission;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Calcul de la commission',
                style: AppTheme.display(fontSize: 20),
              ),
              const SizedBox(height: 12),
              _Line(
                '${r.customerMaskedName} loue ${r.rentalDays} jours',
                '${r.rentalDays} × ${Fmt.price(r.pricePerDay)} = ${Fmt.dinars(c.grossDt)}',
              ),
              _Line('Remise client', '−${Fmt.dinars(c.discountDt)}'),
              _Line('Montant payé', Fmt.dinars(c.netDt)),
              _Line(
                'Votre part (${Fmt.percent(c.rate)})',
                Fmt.dinars(c.commissionDt),
              ),
              const Divider(),
              _Line('En Dada Coins', Fmt.coins(c.coins), bold: true),
              if (r.status.earnsNothing)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Location annulée ou remboursée : pas de coins.'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
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

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final challenge = state.challenge;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (challenge != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppTheme.radius + 4),
              border: Border.all(color: scheme.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(challenge.description),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: challenge.ratio,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${challenge.progress} sur ${challenge.target} · '
                  'fin le ${Fmt.shortDate(challenge.endsAt)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const SectionTitle('Mes badges'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [for (final b in state.badges) _BadgeView(badge: b)],
        ),
        const SizedBox(height: 24),
        const SectionTitle('Classement du mois'),
        Card(
          child: Column(
            children: [
              for (final e in state.leaderboard)
                Container(
                  decoration: e.isMe
                      ? BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                          border: Border.all(color: scheme.primary),
                        )
                      : null,
                  child: ListTile(
                    leading: SizedBox(
                      width: 28,
                      child: Text(
                        '${e.rank}',
                        style: AppTheme.display(fontSize: 18),
                      ),
                    ),
                    title: Text(
                      e.displayName,
                      style: TextStyle(
                        fontWeight: e.isMe ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    trailing: Text('${e.completedRentals} locations'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'On affiche les rangs, jamais les gains des autres.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BadgeView extends StatelessWidget {
  const _BadgeView({required this.badge});
  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = badge.earned ? scheme.primary : scheme.outlineVariant;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badge.earned ? scheme.primaryContainer : null,
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            badge.shortLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: badge.earned ? scheme.onPrimaryContainer : scheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(badge.label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
