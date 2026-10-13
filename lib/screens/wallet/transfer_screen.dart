import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// Send Dada Coins to another account, addressed by its code.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _code.addListener(_refresh);
    _amount.addListener(_refresh);
  }

  void _refresh() => setState(() => _error = null);

  @override
  void dispose() {
    _code.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _amountValue => int.tryParse(_amount.text) ?? 0;

  Future<void> _submit(AppState state, AppUser? recipient) async {
    final user = state.user!;
    final error =
        CoinTransfer.validate(
          amount: _amountValue,
          balance: state.wallet.balance,
          fromCode: user.referralCode,
          toCode: _code.text,
        ) ??
        (recipient == null ? 'Aucun compte avec ce code.' : null);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le transfert'),
        content: Text(
          'Envoyer ${Fmt.coins(_amountValue)} à ${recipient!.displayName} '
          '(${recipient.referralCode}) ?\nCette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = state.transferCoins(
      toCode: _code.text,
      amount: _amountValue,
      note: _note.text,
    );
    if (result != null) {
      setState(() => _error = result);
      return;
    }
    Navigator.of(context).pop();
    showSnack(
      context,
      '${Fmt.coins(_amountValue)} envoyés à ${recipient!.displayName} ✅',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final recipient = state.findUserByCode(_code.text);
    final typedCode = _code.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Envoyer des coins')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Solde disponible'),
              trailing: Text(
                Fmt.coins(state.wallet.balance),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('transfer-code'),
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              _UpperCaseFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Code du destinataire',
              hintText: 'ex. SARA11',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 8),
          if (recipient != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(name: recipient.displayName),
              title: Text(recipient.displayName),
              subtitle: Text(recipient.headline),
              trailing: const Icon(
                Icons.verified_rounded,
                color: AppTheme.success,
              ),
            )
          else if (typedCode)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Aucun compte avec ce code.',
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final u in state.directory)
                ActionChip(
                  avatar: UserAvatar(name: u.displayName, radius: 12),
                  label: Text(u.displayName.split(' ').first),
                  onPressed: () => _code.text = u.referralCode,
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('transfer-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Montant',
              suffixText: 'DC',
              prefixIcon: const Icon(Icons.toll_outlined),
              helperText: _amountValue > 0
                  ? '≈ ${Fmt.dinars(Fmt.coinsToDinars(_amountValue))} · '
                        '$kCoinsPerDinar DC = 1 DT'
                  : 'Minimum $kMinTransferCoins DC',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final v in const [50, 100, 200, 500])
                ChoiceChip(
                  label: Text('$v'),
                  selected: _amountValue == v,
                  onSelected: (_) => _amount.text = '$v',
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _note,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Message (optionnel)',
              prefixIcon: Icon(Icons.chat_bubble_outline),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('transfer-submit'),
            onPressed: () => _submit(state, recipient),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
