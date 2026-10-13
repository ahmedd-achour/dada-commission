import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'transfer_screen.dart';

/// "Mon portefeuille": balance, pending coins, level, actions and history.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user!;
    final wallet = state.wallet;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon portefeuille'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TierBadge(tier: user.tier),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BalanceCard(wallet: wallet, expected: state.expectedCoins),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WalletAction(
                  icon: Icons.send_rounded,
                  label: 'Envoyer',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TransferScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WalletAction(
                  icon: Icons.qr_code_rounded,
                  label: 'Recevoir',
                  onTap: () => showReceiveSheet(context, user),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WalletAction(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Boutique',
                  onTap: () {
                    state.setTab(1);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TierProgressCard(user: user),
          const SizedBox(height: 20),
          const SectionTitle('Historique'),
          if (state.transactions.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'Aucun mouvement pour le moment.',
            )
          else
            Card(
              child: Column(
                children: [
                  for (final (i, t) in state.transactions.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 72),
                    TransactionTile(transaction: t),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Les coins expirent $kCoinsExpiryMonths mois après le gain. '
            'Ce sont des points cadeaux : ils ne se retirent pas en argent.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.wallet, this.expected = 0});
  final Wallet wallet;
  final int expected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radius + 4),
        border: Border.all(color: scheme.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coins disponibles',
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 6),
          Text(
            Fmt.coins(wallet.balance),
            style: AppTheme.display(
              fontSize: 40,
              color: scheme.onPrimaryContainer,
            ),
          ),
          Text(
            '≈ ${Fmt.dinars(wallet.balanceDt)} en cadeaux',
            style: TextStyle(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'En attente : ${Fmt.coins(wallet.pendingBalance)}'
            '${expected > 0 ? ' · à venir : ${Fmt.coins(expected)}' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class TierProgressCard extends StatelessWidget {
  const TierProgressCard({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final next = user.tier.next;
    final color = AppTheme.tierColor(user.tier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Niveau ${user.tier.label} · ${Fmt.percent(user.tier.commissionRate)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: user.tier.progressFor(user.completedRentals3m),
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              next == null
                  ? 'Niveau maximum atteint 💎'
                  : '${user.completedRentals3m} locations sur '
                        '${next.minCompletedRentals} pour passer ${next.label} '
                        '(${Fmt.percent(next.commissionRate)})',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});
  final CoinTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (t.type) {
      CoinTransactionType.commission => Icons.directions_car_outlined,
      CoinTransactionType.challengeBonus => Icons.emoji_events_outlined,
      CoinTransactionType.redemption => Icons.card_giftcard_outlined,
      CoinTransactionType.transferIn => Icons.call_received_rounded,
      CoinTransactionType.transferOut => Icons.call_made_rounded,
      CoinTransactionType.reversal => Icons.undo_rounded,
      CoinTransactionType.expiry => Icons.hourglass_bottom_rounded,
      CoinTransactionType.adjustment => Icons.tune_rounded,
    };
    final pending = t.status == CoinTransactionStatus.pending;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(icon, color: scheme.onSurfaceVariant, size: 20),
      ),
      title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        [
          ?t.subtitle,
          Fmt.shortDate(t.createdAt),
          if (pending) 'en attente',
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        Fmt.signedCoins(t.amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: pending
              ? AppTheme.warning
              : t.isCredit
              ? AppTheme.success
              : scheme.onSurface,
        ),
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the user's code + QR so someone else can send them coins.
void showReceiveSheet(BuildContext context, AppUser user) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recevoir des coins', style: AppTheme.display(fontSize: 20)),
            const SizedBox(height: 6),
            const Text(
              'Partagez votre code : l\'expéditeur le saisit dans « Envoyer ».',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ReferralQr(data: user.referralCode, size: 170),
            const SizedBox(height: 12),
            Text(user.referralCode, style: AppTheme.display(fontSize: 26)),
            TextButton.icon(
              onPressed: () => copyText(context, user.referralCode),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copier le code'),
            ),
          ],
        ),
      ),
    ),
  );
}
