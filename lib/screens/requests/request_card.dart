import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'request_detail_screen.dart';

/// "12 oct. → 15 oct. · 3 jours"
String requestDates(RentalRequest r) =>
    '${Fmt.shortDate(r.startDate)} → ${Fmt.shortDate(r.endDate)} · '
    '${r.days} jour${r.days > 1 ? 's' : ''}';

/// A prepaid rental request, shown as a car-rental card (not a social post).
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request});
  final RentalRequest request;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final r = request;
    final p = r.pricing;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openRequest(context, r.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: CarImage(height: 74, category: r.category),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.carWanted,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.category.label} · ${r.city}',
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            requestDates(r),
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    StatusPill.request(r.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Figure(
                        label: 'Montant client',
                        value: Fmt.dinars(p.amountDueDt),
                      ),
                    ),
                    Expanded(
                      child: _Figure(
                        label: 'Acompte payé',
                        value: r.isPaid
                            ? '${Fmt.dinars(p.prepaymentDt)} ✓'
                            : 'en attente',
                        color: r.isPaid ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                    Expanded(
                      child: _Figure(
                        label: 'Reste à l\'agence',
                        value: Fmt.dinars(p.agencyDt),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    UserAvatar(name: r.maskedClientName, radius: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${r.maskedClientName} · code ${r.referralCode} · '
                        '${Fmt.timeAgo(r.paidAt ?? r.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (r.status == RequestStatus.claimed ||
                    r.status == RequestStatus.completed) ...[
                  const SizedBox(height: 8),
                  Text(
                    r.status == RequestStatus.completed
                        ? 'Louée chez ${r.companyName}'
                              '${r.rentedCar == null ? '' : ' · ${r.rentedCar!.model}'}'
                        : 'Prise en charge par ${r.companyName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (r.status == RequestStatus.open &&
                    state.canTakeRequests) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: Key('claim-${r.id}'),
                      icon: const Icon(Icons.handshake_outlined),
                      label: Text(
                        'Prendre en charge · ${Fmt.dinars(p.agencyDt)}',
                      ),
                      onPressed: () => claimWithConfirm(context, r),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

void openRequest(BuildContext context, String id) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: id)));
}

/// Agency takes an open request (after a confirmation).
Future<void> claimWithConfirm(BuildContext context, RentalRequest r) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Prendre cette demande ?'),
      content: Text(
        'Vous recevez le contact du client et vous vous engagez à lui proposer '
        '« ${r.carWanted} » du ${Fmt.shortDate(r.startDate)} au '
        '${Fmt.shortDate(r.endDate)}.\n\nVous encaissez '
        '${Fmt.dinars(r.pricing.agencyDt)} directement auprès du client. '
        'L\'acompte de 10 % reste à Dada.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Prendre'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final error = AppScope.read(context).claimRequest(r.id);
  showSnack(
    context,
    error ?? 'Demande prise ✅ Contactez le client.',
    error: error != null,
  );
}
