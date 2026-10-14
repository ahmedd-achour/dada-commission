import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'transfer_screen.dart';

enum _HistoryFilter {
  all('Tout'),
  earnings('Gains'),
  transfers('Transferts'),
  purchases('Achats');

  const _HistoryFilter(this.label);
  final String label;

  bool accepts(CoinTransaction t) => switch (this) {
    _HistoryFilter.all => true,
    _HistoryFilter.earnings => t.type == CoinTransactionType.referralEarning,
    _HistoryFilter.transfers =>
      t.type == CoinTransactionType.transferIn ||
          t.type == CoinTransactionType.transferOut,
    _HistoryFilter.purchases => t.type == CoinTransactionType.purchase,
  };
}

/// Wallet tab: Dada Coin balance and every coin action (send, receive, buy),
/// with the full history.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user!;
    final wallet = state.wallet;
    final history = state.transactions.where(_filter.accepts).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Wallet', style: AppTheme.display(fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GradientCard(
            key: const Key('wallet-panel'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/fluent/coin.png', width: 30),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Solde Dada Coins',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _Chip('10 DC = 1 DT'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  Fmt.coins(wallet.balance),
                  style: AppTheme.display(fontSize: 42, color: Colors.white),
                ),
                Text(
                  '≈ ${Fmt.dinars(wallet.balanceDt)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Gagnés ce mois',
                        value: Fmt.coins(state.earnedThisMonth),
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Gagnés au total',
                        value: Fmt.coins(wallet.lifetimeEarned),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Action(
                icon: Icons.send_rounded,
                label: 'Envoyer',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransferScreen()),
                ),
              ),
              _Action(
                icon: Icons.qr_code_rounded,
                label: 'Recevoir',
                onTap: () => showReceiveSheet(context, user),
              ),
              _Action(
                key: const Key('buy-coins'),
                icon: Icons.add_card_rounded,
                label: 'Acheter',
                onTap: () => showBuyCoinsSheet(context),
              ),
            ],
          ),
          if (user.role.earnsCommission) ...[
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bolt_rounded, color: AppTheme.green),
                title: Text(
                  '${Fmt.percent(kAmbassadorRate)} de chaque demande prépayée',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Crédités dès que le client paie son acompte avec le code '
                  '${user.referralCode}.',
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const SectionTitle('Historique'),
          Wrap(
            spacing: 8,
            children: [
              for (final f in _HistoryFilter.values)
                ChoiceChip(
                  label: Text(f.label),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'Aucun mouvement.',
            )
          else
            Card(
              child: Column(
                children: [
                  for (final (i, t) in history.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 72),
                    TransactionTile(transaction: t),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(icon, color: scheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
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
      CoinTransactionType.referralEarning => Icons.bolt_rounded,
      CoinTransactionType.transferIn => Icons.call_received_rounded,
      CoinTransactionType.transferOut => Icons.call_made_rounded,
      CoinTransactionType.purchase => Icons.add_card_rounded,
      CoinTransactionType.reversal => Icons.undo_rounded,
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

/// Buy Dada Coins with Click to Pay (10 DC = 1 DT).
void showBuyCoinsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _BuyCoinsSheet(),
  );
}

class _BuyCoinsSheet extends StatefulWidget {
  const _BuyCoinsSheet();

  @override
  State<_BuyCoinsSheet> createState() => _BuyCoinsSheetState();
}

class _BuyCoinsSheetState extends State<_BuyCoinsSheet> {
  final _amount = TextEditingController(text: '500');
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _coins => int.tryParse(_amount.text) ?? 0;

  Future<void> _buy() async {
    setState(() => _paying = true);
    final state = AppScope.read(context);
    final error = await state.buyCoins(_coins);
    if (!mounted) return;
    setState(() => _paying = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    final coins = _coins;
    Navigator.of(context).pop();
    showSnack(context, '${Fmt.coins(coins)} ajoutés à votre wallet ✅');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Acheter des Dada Coins', style: AppTheme.display(fontSize: 20)),
          const SizedBox(height: 12),
          TextField(
            key: const Key('buy-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Nombre de coins',
              suffixText: 'DC',
              helperText:
                  'Vous payez ${Fmt.dinars(Fmt.coinsToDinars(_coins))} · '
                  'minimum ${Fmt.coins(kMinCoinPurchase)}',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final v in const [100, 500, 1000, 5000])
                ChoiceChip(
                  label: Text(Fmt.coins(v)),
                  selected: _coins == v,
                  onSelected: (_) => _amount.text = '$v',
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('buy-confirm'),
            onPressed: _paying || _coins < kMinCoinPurchase ? null : _buy,
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(
              'Payer ${Fmt.dinars(Fmt.coinsToDinars(_coins))} avec Click to Pay',
            ),
          ),
        ],
      ),
    );
  }
}
