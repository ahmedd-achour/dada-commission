import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../business/business_guide_screen.dart';
import '../company/company_register_screen.dart';
import '../wallet/wallet_screen.dart' show TierProgressCard;
import 'edit_profile_screen.dart';

/// Profil: identity, code / link / QR, wallet summary and settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil', style: AppTheme.display(fontSize: 22)),
        actions: [
          IconButton(
            tooltip: 'Modifier le profil',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------------ identity
          Center(
            child: GestureDetector(
              onTap: () => _openEdit(context),
              child: Stack(
                children: [
                  MyAvatar(radius: 48, ring: AppTheme.tierColor(user.tier)),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primary,
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: AppTheme.display(fontSize: 26),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TierBadge(tier: user.tier),
              if (user.isGuest) ...[
                const SizedBox(width: 8),
                const Chip(
                  label: Text('Mode invité'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(user.bio!, textAlign: TextAlign.center),
          ],
          if (user.city != null) ...[
            const SizedBox(height: 4),
            Text(
              user.city!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),

          // ------------------------------------------------ code / link / QR
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Mon code',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.referralCode,
                    style: AppTheme.display(fontSize: 30),
                  ),
                  const SizedBox(height: 12),
                  ReferralQr(data: user.referralLink, size: 160),
                  const SizedBox(height: 12),
                  Text(
                    user.referralLink,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => copyText(context, user.referralCode),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Code'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => copyText(
                            context,
                            user.referralLink,
                            message: 'Lien copié : partagez-le sur WhatsApp, TikTok…',
                          ),
                          icon: const Icon(Icons.link_rounded, size: 18),
                          label: const Text('Lien'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------ wallet
          // Coin actions live in the Marketplace; this is just a shortcut.
          Card(
            child: ListTile(
              leading: Image.asset('assets/images/fluent/coin.png', width: 36),
              title: Text(
                Fmt.coins(state.wallet.balance),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: const Text('Mon portefeuille · envoyer, échanger'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                state.setTab(1);
              },
            ),
          ),
          const SizedBox(height: 16),
          if (user.role == UserRole.companyAdmin) ...[
            _BusinessCard(company: state.myCompany),
            const SizedBox(height: 16),
          ],
          TierProgressCard(user: user),
          const SizedBox(height: 20),

          // ------------------------------------------------ settings
          const SectionTitle('Paramètres'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Informations personnelles'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openEdit(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.store_mall_directory_outlined),
                  title: Text(
                    state.myCompany == null
                        ? 'Devenir entreprise partenaire'
                        : 'Espace entreprise',
                  ),
                  subtitle: Text(
                    state.myCompany == null
                        ? 'Guide pour les agences de location'
                        : state.myCompany!.status.label,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => state.myCompany == null
                          ? const BusinessGuideScreen()
                          : const CompanyRegisterScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Mode sombre'),
                  value: state.themeMode == ThemeMode.dark,
                  onChanged: (_) => state.toggleTheme(),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Comment ça marche'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showHowItWorks(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: scheme.error),
                  title: Text(
                    user.isGuest ? 'Quitter le mode invité' : 'Se déconnecter',
                    style: TextStyle(color: scheme.error),
                  ),
                  onTap: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    state.signOut();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Connecté via ${user.authProvider.label} · membre depuis '
            '${Fmt.longDate(user.createdAt)}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text('Comment ça marche', style: AppTheme.display(fontSize: 22)),
            const SizedBox(height: 12),
            const Text(
              '1. Partagez une voiture avec votre code, votre lien ou votre QR code.\n'
              '2. Votre client réserve et obtient −5 % sur sa première location.\n'
              '3. 7 jours après le retour de la voiture, vous recevez vos Dada Coins.\n'
              '4. Échangez-les dans la boutique ou envoyez-les à un autre compte.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Vos niveaux',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final t in AmbassadorTier.values)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: TierBadge(tier: t, dense: true),
                title: Text(
                  '${Fmt.percent(t.commissionRate)} de chaque location',
                ),
                subtitle: Text(
                  t.minCompletedRentals == 0
                      ? 'pour commencer'
                      : 'dès ${t.minCompletedRentals} locations sur 3 mois',
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Les règles',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Pas d\'auto-parrainage (même téléphone, même CIN ou même carte).\n'
              '• Seules les locations terminées et payées rapportent des coins.\n'
              '• Location remboursée = coins repris.\n'
              '• Un compte par personne, dès 18 ans.\n'
              '• Publications honnêtes : « #sponsorisé » sur les vidéos.\n'
              '• 10 DC = 1 DT en cadeaux. Les coins expirent après 12 mois.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.company});
  final RentalCompany? company;

  @override
  Widget build(BuildContext context) {
    final c = company;
    final approved = c?.isApproved ?? false;
    return Card(
      child: ListTile(
        leading: Image.asset('assets/images/fluent/company.png', width: 36),
        title: Text(
          c?.name ?? 'Mon entreprise',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          c == null
              ? 'Dossier à compléter'
              : '${c.status.label} · '
                    '${c.documents.length}/${CompanyDocumentType.values.length} documents',
        ),
        trailing: StatusPill(
          label: approved ? 'Active' : 'À suivre',
          color: approved ? AppTheme.success : AppTheme.warning,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CompanyRegisterScreen()),
        ),
      ),
    );
  }
}
