import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../business/business_guide_screen.dart';
import '../company/company_register_screen.dart';
import '../home/share_car_screen.dart';
import '../wallet/transfer_screen.dart';
import '../wallet/wallet_screen.dart';

/// Marketplace: the wallet comes first (balance + every coin action), then
/// the Dada shop (spend coins) and the cars of every registered rent-car
/// company (share them to earn coins).
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Marketplace', style: AppTheme.display(fontSize: 22)),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: WalletPanel(),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeader(
                color: scheme.surface,
                tabBar: const TabBar(
                  tabs: [
                    Tab(text: 'Boutique Dada'),
                    Tab(text: 'Voitures à partager'),
                  ],
                ),
              ),
            ),
          ],
          body: const TabBarView(children: [_ShopTab(), _CarsTab()]),
        ),
      ),
    );
  }
}

class _TabBarHeader extends SliverPersistentHeaderDelegate {
  _TabBarHeader({required this.tabBar, required this.color});
  final TabBar tabBar;
  final Color color;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(color: color, child: tabBar);

  @override
  bool shouldRebuild(_TabBarHeader old) =>
      old.color != color || old.tabBar != tabBar;
}

/// The wallet, front and centre: balance, pending coins and all coin actions.
class WalletPanel extends StatelessWidget {
  const WalletPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user!;
    final wallet = state.wallet;
    final expected = state.expectedCoins;

    return GradientCard(
      key: const Key('wallet-panel'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/fluent/coin.png', width: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mon portefeuille Dada Coins',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${user.tier.label} · ${Fmt.percent(user.tier.commissionRate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Fmt.coins(wallet.balance),
            style: AppTheme.display(fontSize: 40, color: Colors.white),
          ),
          Text(
            '≈ ${Fmt.dinars(wallet.balanceDt)} en cadeaux · '
            'en attente ${Fmt.coins(wallet.pendingBalance)}'
            '${expected > 0 ? ' · à venir ${Fmt.coins(expected)}' : ''}',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PanelAction(
                icon: Icons.send_rounded,
                label: 'Envoyer',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransferScreen()),
                ),
              ),
              _PanelAction(
                icon: Icons.qr_code_rounded,
                label: 'Recevoir',
                onTap: () => showReceiveSheet(context, user),
              ),
              _PanelAction(
                icon: Icons.receipt_long_rounded,
                label: 'Historique',
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
              _PanelAction(
                icon: Icons.shopping_bag_outlined,
                label: 'Commandes',
                badge: state.redemptions.length,
                onTap: () => _showOrders(context, state),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrders(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: state.redemptions.isEmpty
            ? const EmptyState(
                icon: Icons.shopping_bag_outlined,
                message:
                    'Aucune commande. Échangez vos coins dans la boutique.',
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final r in state.redemptions)
                    ListTile(
                      leading: const Icon(Icons.card_giftcard_rounded),
                      title: Text(r.rewardTitle),
                      subtitle: Text(
                        '${r.status.label} · ${Fmt.shortDate(r.createdAt)}',
                      ),
                      trailing: Text(Fmt.coins(r.coins)),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  const _PanelAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                backgroundColor: AppTheme.green,
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Icon(icon, size: 20),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer.withValues(alpha: 0.5),
                      AppTheme.green.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppImage(
                  reward.imageUrl,
                  fallback: Icon(
                    rewardIcon(reward.category),
                    size: 44,
                    color: scheme.outline,
                  ),
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
            SizedBox(
              height: 96,
              child: AppImage(
                reward.imageUrl,
                fallback: Icon(rewardIcon(reward.category), size: 56),
              ),
            ),
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
                  builder: (_) => myCompany == null
                      ? const BusinessGuideScreen()
                      : const CompanyRegisterScreen(),
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
                child: CarImage(
                  height: 80,
                  category: car.category,
                  imageUrl: car.imageUrl,
                ),
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
