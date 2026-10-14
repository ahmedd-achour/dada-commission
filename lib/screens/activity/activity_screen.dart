import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../company/company_register_screen.dart';
import '../requests/create_request_screen.dart';
import '../requests/request_card.dart';

/// Activité, by role:
/// - ambassador / partner: requests brought by my code and coins earned;
/// - client: my requests;
/// - agency: requests I took.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final role = state.user!.role;
    return Scaffold(
      appBar: AppBar(
        title: Text('Activité', style: AppTheme.display(fontSize: 22)),
      ),
      body: switch (role) {
        UserRole.companyAdmin => const _AgencyActivity(),
        UserRole.client => const _ClientActivity(),
        _ => const _AmbassadorActivity(),
      },
    );
  }
}

class _AmbassadorActivity extends StatelessWidget {
  const _AmbassadorActivity();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mine = state.myReferrals.where((r) => r.isPaid).toList();
    final completed = mine
        .where((r) => r.status == RequestStatus.completed)
        .length;
    final earned = mine.fold(0, (s, r) => s + r.pricing.ambassadorCoins);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  value: '${mine.length}',
                  label: 'clients prépayés',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(value: '$completed', label: 'locations faites'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(value: Fmt.coins(earned), label: 'gagnés'),
              ),
            ],
          ),
        ),
        if (state.user!.isGuest)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: OutlinedButton.icon(
              key: const Key('simulate-client'),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Démo : un client prépaie avec mon code'),
              onPressed: () async {
                final r = await state.simulateClientRequest();
                if (context.mounted && r != null) {
                  showSnack(
                    context,
                    '+${Fmt.coins(r.pricing.ambassadorCoins)} reçus '
                    '(acompte de ${Fmt.dinars(r.pricing.prepaymentDt)}) ⚡',
                  );
                }
              },
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SectionTitle('Demandes avec mon code'),
        ),
        if (mine.isEmpty)
          const EmptyState(
            icon: Icons.share_outlined,
            message:
                'Partagez votre code : chaque client qui prépaie vous '
                'rapporte 8 % en Dada Coins.',
          )
        else
          for (final r in mine) RequestCard(request: r),
      ],
    );
  }
}

class _ClientActivity extends StatelessWidget {
  const _ClientActivity();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mine = state.myClientRequests;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nouvelle demande'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SectionTitle('Mes demandes'),
        ),
        if (mine.isEmpty)
          const EmptyState(
            icon: Icons.directions_car_outlined,
            message:
                'Aucune demande. Publiez la voiture que vous cherchez '
                'avec le code d\'un ambassadeur.',
          )
        else
          for (final r in mine) RequestCard(request: r),
      ],
    );
  }
}

class _AgencyActivity extends StatelessWidget {
  const _AgencyActivity();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mine = state.myAgencyRequests;
    final company = state.myCompany;
    final completed = mine
        .where((r) => r.status == RequestStatus.completed)
        .toList();
    final revenue = completed.fold<double>(
      0,
      (s, r) =>
          s +
          (r.rentedCar?.finalPriceDt ?? r.pricing.amountDueDt) *
              (1 - kPrepaymentRate),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (!state.canTakeRequests)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.hourglass_top_rounded),
                title: Text(
                  company == null
                      ? 'Aucune agence inscrite'
                      : 'Agence ${company.status.label.toLowerCase()}',
                ),
                subtitle: const Text(
                  'Vous pourrez prendre des demandes après la validation.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CompanyRegisterScreen(),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _Stat(value: '${mine.length}', label: 'demandes prises'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(value: '${completed.length}', label: 'louées'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  value: Fmt.price(revenue.roundToDouble()),
                  label: 'encaissés',
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SectionTitle('Mes demandes prises'),
        ),
        if (mine.isEmpty)
          const EmptyState(
            icon: Icons.handshake_outlined,
            message:
                'Prenez une demande dans l\'Accueil : le client a déjà '
                'payé 10 %.',
          )
        else
          for (final r in mine) RequestCard(request: r),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            FittedBox(
              child: Text(value, style: AppTheme.display(fontSize: 24)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
