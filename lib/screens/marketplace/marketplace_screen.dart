import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../company/company_register_screen.dart';
import '../home/share_car_screen.dart';
import '../wallet/wallet_screen.dart';

/// Marketplace: the Dada shop (spend coins) and the cars of every registered
/// rent-car company (share them to earn coins).
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Marketplace', style: AppTheme.display(fontSize: 22)),
          actions: [
            CoinChip(
              coins: state.wallet.balance,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
            ),
            const SizedBox(width: 16),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Boutique Dada'),
              Tab(text: 'Voitures'),
            ],
          ),
        ),
        body: const TabBarView(children: [_ShopTab(), _CarsTab()]),
      ),
    );
  }
}

// ------------------------------------------------------------------ shop

class _ShopTab extends StatefulWidget {
  const _ShopTab();

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  RewardCategory? _category;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final rewards = state.rewards
        .where(
          (r) => r.isActive && (_category == null || r.category == _category),
        )
        .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                _FilterChip(
                  label: 'Tout',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in RewardCategory.values)
                  _FilterChip(
                    label: c.label,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.builder(
            itemCount: rewards.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 236,
            ),
            itemBuilder: (context, i) => _RewardCard(
              reward: rewards[i],
              affordable: rewards[i].priceCoins <= state.wallet.balance,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Prix : 1 DT = 10 coins. Les cadeaux sont préparés par l\'équipe '
              'Dada ; vous recevez un code par SMS ou une livraison.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

IconData rewardIcon(RewardCategory c) => switch (c) {
  RewardCategory.voucher => Icons.confirmation_number_outlined,
  RewardCategory.phone => Icons.smartphone_rounded,
  RewardCategory.tablet => Icons.tablet_mac_rounded,
  RewardCategory.rental => Icons.directions_car_outlined,
  RewardCategory.topUp => Icons.sim_card_outlined,
  RewardCategory.leisure => Icons.headphones_rounded,
};

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward, required this.affordable});
  final Reward reward;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRewardSheet(context, reward),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  rewardIcon(reward.category),
                  size: 44,
                  color: scheme.outline,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                reward.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                Fmt.coins(reward.priceCoins),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: affordable
                    ? FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 34),
                        ),
                        onPressed: () => _showRewardSheet(context, reward),
                        child: const Text('Échanger'),
                      )
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                        ),
                        onPressed: () => _showRewardSheet(context, reward),
                        child: const Text('Voir'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showRewardSheet(BuildContext context, Reward reward) {
  final state = AppScope.read(context);
  final balance = state.wallet.balance;
  final missing = reward.priceCoins - balance;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(rewardIcon(reward.category), size: 56),
            const SizedBox(height: 12),
            Text(
              reward.title,
              textAlign: TextAlign.center,
              style: AppTheme.display(fontSize: 22),
            ),
            Text(
              '${Fmt.coins(reward.priceCoins)} · valeur ${Fmt.price(reward.valueDt)}',
              textAlign: TextAlign.center,
            ),
            if (reward.description != null) ...[
              const SizedBox(height: 8),
              Text(reward.description!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            const Text(
              'Comment ça marche',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '1. Vous confirmez : vos coins sont réservés.\n'
              '2. L\'équipe Dada prépare la commande.\n'
              '3. Vous recevez un code par SMS, passez en agence ou êtes livré.',
            ),
            if (reward.requiresIdCheck) ...[
              const SizedBox(height: 8),
              const Text(
                'Cadeau de plus de 5 000 DC : une photo de votre CIN est demandée une seule fois.',
                style: TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            if (missing > 0)
              OutlinedButton(
                onPressed: null,
                child: Text('Il vous manque ${Fmt.coins(missing)}'),
              )
            else
              FilledButton(
                onPressed: () {
                  final error = state.redeem(reward);
                  Navigator.of(sheetContext).pop();
                  showSnack(
                    context,
                    error ?? '${reward.title} : coins réservés ✅',
                    error: error != null,
                  );
                },
                child: Text('Échanger ${Fmt.coins(reward.priceCoins)}'),
              ),
          ],
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------------ cars

class _CarsTab extends StatefulWidget {
  const _CarsTab();

  @override
  State<_CarsTab> createState() => _CarsTabState();
}

class _CarsTabState extends State<_CarsTab> {
  String? _companyId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final companies = state.approvedCompanies;
    final approvedIds = companies.map((c) => c.id).toSet();
    final cars = state.cars
        .where(
          (c) =>
              approvedIds.contains(c.companyId) &&
              (_companyId == null || c.companyId == _companyId),
        )
        .toList();
    final myCompany = state.myCompany;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              _FilterChip(
                label: 'Toutes les agences',
                selected: _companyId == null,
                onTap: () => setState(() => _companyId = null),
              ),
              for (final c in companies)
                _FilterChip(
                  label: c.name,
                  selected: _companyId == c.id,
                  onTap: () => setState(() => _companyId = c.id),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.store_mall_directory_outlined),
              title: Text(
                myCompany == null
                    ? 'Vous êtes une agence de location ?'
                    : myCompany.name,
              ),
              subtitle: Text(
                myCompany == null
                    ? 'Inscrivez-vous et recevez des clients grâce aux ambassadeurs.'
                    : 'Statut : ${myCompany.status.label}',
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
        const SizedBox(height: 8),
        for (final car in cars)
          _CarTile(car: car, rate: state.user!.tier.commissionRate),
      ],
    );
  }
}

class _CarTile extends StatelessWidget {
  const _CarTile({required this.car, required this.rate});
  final Car car;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final perDay = CommissionCalculator.compute(
      days: 1,
      pricePerDay: car.pricePerDay,
      tierRate: rate,
    );
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: CarImage(height: 80, category: car.category),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.model,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${car.category.label} · ${car.seats} places · ${car.transmission.label}',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    Text(
                      '${car.companyName} · ${car.city}',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Fmt.price(car.pricePerDay)} / jour · '
                      '+${Fmt.coins(perDay.coins)} / jour loué',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Partager',
                icon: const Icon(Icons.share_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ShareCarScreen(car: car)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
