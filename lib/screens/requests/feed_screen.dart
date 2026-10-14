import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'create_request_screen.dart';
import 'request_card.dart';

enum _Filter {
  open('Ouvertes'),
  claimed('Prises'),
  completed('Terminées'),
  all('Toutes');

  const _Filter(this.label);
  final String label;

  bool accepts(RentalRequest r) => switch (this) {
    _Filter.open => r.status == RequestStatus.open,
    _Filter.claimed => r.status == RequestStatus.claimed,
    _Filter.completed => r.status == RequestStatus.completed,
    _Filter.all => true,
  };
}

/// Accueil: the hub of prepaid rental requests. Clients post what they want
/// (with an ambassador's code and a 10 % prepayment); agencies take them.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  _Filter _filter = _Filter.open;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user!;
    final requests = state.publicRequests.where(_filter.accepts).toList();
    final isAgency = user.role == UserRole.companyAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dada Commission', style: AppTheme.display(fontSize: 22)),
        actions: [
          CoinChip(coins: state.wallet.balance, onTap: () => state.setTab(1)),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: isAgency
          ? null
          : FloatingActionButton.extended(
              key: const Key('new-request'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvelle demande'),
            ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _Banner(
              user: user,
              openCount: state.publicRequests
                  .where((r) => r.status == RequestStatus.open)
                  .length,
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (requests.isEmpty)
            const EmptyState(
              icon: Icons.directions_car_outlined,
              message: 'Aucune demande ici pour le moment.',
            )
          else
            for (final r in requests) RequestCard(request: r),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.user, required this.openCount});
  final AppUser user;
  final int openCount;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (user.role) {
      UserRole.companyAdmin => (
        '$openCount demande${openCount > 1 ? 's' : ''} prépayée${openCount > 1 ? 's' : ''}',
        'Chaque client a déjà payé ${Fmt.percent(kPrepaymentRate)} : prenez '
            'la demande et encaissez les 90 % restants.',
      ),
      UserRole.client => (
        'Louez avec −${Fmt.percent(kCustomerDiscountRate)}',
        'Publiez votre demande avec le code d\'un ambassadeur et un acompte '
            'de ${Fmt.percent(kPrepaymentRate)} : les agences viennent à vous.',
      ),
      _ => (
        'Code ${user.referralCode}',
        'Chaque client qui prépaie avec votre code vous rapporte '
            '${Fmt.percent(kAmbassadorRate)} en Dada Coins, tout de suite.',
      ),
    };
    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.display(fontSize: 19, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            user.role == UserRole.companyAdmin
                ? 'assets/images/fluent/company.png'
                : 'assets/images/fluent/coin.png',
            width: 52,
          ),
        ],
      ),
    );
  }
}
