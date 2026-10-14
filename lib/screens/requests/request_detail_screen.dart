import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'create_request_screen.dart';
import 'request_card.dart';

class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final r = state.requestById(requestId);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          message: 'Demande introuvable.',
        ),
      );
    }
    final user = state.user!;
    final isClient = r.clientId == user.id;
    final isMyAgency =
        r.companyId != null && r.companyId == state.myCompany?.id;
    final canSeeContact = isClient || isMyAgency;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Demande de location')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CarImage(height: 150, category: r.category),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(r.carWanted, style: AppTheme.display(fontSize: 22)),
              ),
              StatusPill.request(r.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${r.category.label} · ${r.city} · ${requestDates(r)}',
            style: TextStyle(color: muted),
          ),
          if (r.note != null) ...[
            const SizedBox(height: 8),
            Text('« ${r.note} »'),
          ],
          const SizedBox(height: 16),
          PricingBreakdown(pricing: r.pricing),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: UserAvatar(
                    name: canSeeContact ? r.clientName : r.maskedClientName,
                  ),
                  title: Text(
                    canSeeContact ? r.clientName : r.maskedClientName,
                  ),
                  subtitle: Text(
                    canSeeContact && r.clientPhone != null
                        ? r.clientPhone!
                        : 'Contact visible par l\'agence qui prend la demande',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.confirmation_number_outlined),
                  title: Text('Code ${r.referralCode}'),
                  subtitle: Text('Ambassadeur : ${r.ambassadorName}'),
                ),
                if (r.companyName != null)
                  ListTile(
                    leading: const Icon(Icons.store_mall_directory_outlined),
                    title: Text(r.companyName!),
                    subtitle: Text(
                      r.rentedCar == null
                          ? 'Prise en charge le ${Fmt.longDate(r.claimedAt!)}'
                          : '${r.rentedCar!.model}'
                                '${r.rentedCar!.plate == null ? '' : ' · ${r.rentedCar!.plate}'}'
                                ' · ${Fmt.dinars(r.rentedCar!.finalPriceDt)}',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Timeline(request: r),
          const SizedBox(height: 16),
          ..._actions(context, state, r, isClient, isMyAgency),
        ],
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    AppState state,
    RentalRequest r,
    bool isClient,
    bool isMyAgency,
  ) {
    if (isClient && r.status == RequestStatus.awaitingPayment) {
      return [
        FilledButton(
          onPressed: () async {
            final error = await state.payPrepayment(r.id);
            if (context.mounted) {
              showSnack(
                context,
                error ?? 'Acompte payé ✅',
                error: error != null,
              );
            }
          },
          child: Text(
            'Payer ${Fmt.dinars(r.pricing.prepaymentDt)} avec Click to Pay',
          ),
        ),
        TextButton(
          onPressed: () => state.cancelUnpaidRequest(r.id),
          child: const Text('Annuler la demande'),
        ),
      ];
    }
    if (r.status == RequestStatus.open && state.canTakeRequests) {
      return [
        FilledButton.icon(
          icon: const Icon(Icons.handshake_outlined),
          label: const Text('Prendre en charge'),
          onPressed: () => claimWithConfirm(context, r),
        ),
      ];
    }
    if (isMyAgency && r.status == RequestStatus.claimed) {
      return [
        if (r.clientPhone != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Appeler'),
                  onPressed: () =>
                      _launch(Uri(scheme: 'tel', path: r.clientPhone)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                  label: const Text('WhatsApp'),
                  onPressed: () => _launch(
                    Uri.https(
                      'wa.me',
                      '/${r.clientPhone!.replaceAll(RegExp(r'[^0-9]'), '')}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('complete-request'),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Marquer comme louée'),
          onPressed: () => _complete(context, state, r),
        ),
      ];
    }
    return const [];
  }

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _complete(
    BuildContext context,
    AppState state,
    RentalRequest r,
  ) async {
    final car = await showModalBottomSheet<RentedCar>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CompleteSheet(request: r),
    );
    if (car == null || !context.mounted) return;
    final error = state.completeRequest(r.id, car);
    showSnack(context, error ?? 'Location terminée ✅', error: error != null);
  }
}

class _CompleteSheet extends StatefulWidget {
  const _CompleteSheet({required this.request});
  final RentalRequest request;

  @override
  State<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<_CompleteSheet> {
  final _form = GlobalKey<FormState>();
  late final _model = TextEditingController(text: widget.request.carWanted);
  final _plate = TextEditingController();
  late final _price = TextEditingController(
    text: widget.request.pricing.amountDueDt.toStringAsFixed(3),
  );

  @override
  void dispose() {
    _model.dispose();
    _plate.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Voiture louée', style: AppTheme.display(fontSize: 20)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
              decoration: const InputDecoration(labelText: 'Modèle'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _plate,
              decoration: const InputDecoration(
                labelText: 'Immatriculation (optionnel)',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) =>
                  (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0
                  ? 'Montant invalide'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Prix final payé par le client (DT)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('complete-confirm'),
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                Navigator.of(context).pop(
                  RentedCar(
                    model: _model.text.trim(),
                    plate: _plate.text.trim().isEmpty
                        ? null
                        : _plate.text.trim(),
                    finalPriceDt: double.parse(
                      _price.text.replaceAll(',', '.'),
                    ),
                  ),
                );
              },
              child: const Text('Confirmer la location'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.request});
  final RentalRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final steps = [
      ('Demande créée', r.createdAt),
      ('Acompte payé (Click to Pay)', r.paidAt),
      ('Prise en charge par une agence', r.claimedAt),
      ('Voiture louée', r.completedAt),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (final (label, date) in steps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      date == null
                          ? Icons.radio_button_unchecked
                          : Icons.check_circle_rounded,
                      size: 20,
                      color: date == null ? null : AppTheme.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(label)),
                    if (date != null)
                      Text(
                        Fmt.shortDate(date),
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
