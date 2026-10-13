import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../setup/account_setup_screen.dart';

/// In-app documentation for rent-car companies: how to open a business
/// account and join the commission hub.
class BusinessGuideScreen extends StatelessWidget {
  const BusinessGuideScreen({super.key, this.showCta = true});

  /// Hidden when opened from inside the setup wizard.
  final bool showCta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final example = CommissionCalculator.compute(
      days: 3,
      pricePerDay: 150,
      tierRate: AmbassadorTier.gold.commissionRate,
    );
    final agencyKeeps = example.netDt - example.commissionDt;

    return Scaffold(
      appBar: AppBar(title: const Text('Guide entreprise')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GradientCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Des locations en plus, sans pub à payer',
                        style: AppTheme.display(
                          fontSize: 21,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Les ambassadeurs Dada partagent vos voitures. '
                        'Vous ne payez que lorsqu\'une location est terminée '
                        'et payée.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset('assets/images/fluent/company.png', width: 72),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Comment ça marche'),
          ..._steps.indexed.map(
            (e) => _StepTile(number: e.$1 + 1, title: e.$2.$1, body: e.$2.$2),
          ),
          const SizedBox(height: 12),
          const SectionTitle('Documents à préparer'),
          Card(
            child: Column(
              children: [
                for (final t in CompanyDocumentType.values)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(t.label),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Ce que vous payez : un exemple'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Row(
                    'Sami loue 3 jours à 150 DT',
                    Fmt.dinars(example.grossDt),
                  ),
                  _Row(
                    'Remise client (code) −5 %',
                    '−${Fmt.dinars(example.discountDt)}',
                  ),
                  _Row('Sami paie', Fmt.dinars(example.netDt), bold: true),
                  const Divider(),
                  _Row(
                    'Part de l\'ambassadrice (niveau Or 16 %)',
                    Fmt.dinars(example.commissionDt),
                  ),
                  _Row('Il vous reste', Fmt.dinars(agencyKeeps), bold: true),
                  const SizedBox(height: 8),
                  Text(
                    'L\'ambassadrice reçoit ${Fmt.coins(example.coins)} '
                    '(10 DC = 1 DT), à dépenser dans la boutique Dada.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Questions fréquentes'),
          for (final (q, a) in _faq)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                q,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              expandedAlignment: Alignment.centerLeft,
              children: [Text(a)],
            ),
          if (showCta) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('guide-start-business'),
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Créer mon compte entreprise'),
              onPressed: () {
                final state = AppScope.read(context);
                if (state.myCompany != null) {
                  showSnack(context, 'Votre entreprise est déjà inscrite.');
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountSetupScreen(
                      initialRole: UserRole.companyAdmin,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  static const _steps = [
    (
      'Créez un compte « Entreprise »',
      'Connexion Facebook, Google ou WhatsApp, puis choisissez « Entreprise de '
          'location de voitures ».',
    ),
    (
      'Remplissez la fiche de votre agence',
      'Nom commercial, matricule fiscal, adresse, téléphone, taille de la flotte.',
    ),
    (
      'Envoyez vos documents',
      'Une photo de chaque document. Vous pouvez compléter plus tard.',
    ),
    (
      'Acceptez l\'accord de commission',
      'Commission seulement sur les locations terminées et payées.',
    ),
    (
      'L\'équipe Dada valide votre dossier',
      'Vous êtes notifié dès que votre agence est validée.',
    ),
    (
      'Ajoutez vos voitures et vos prix',
      'Elles apparaissent dans la marketplace : les ambassadeurs les partagent.',
    ),
    (
      'Recevez des clients',
      'Le client réserve avec un code (−5 %). Après le retour de la voiture, '
          'vous réglez la commission ; l\'ambassadeur reçoit ses Dada Coins.',
    ),
  ];

  static const _faq = [
    (
      'Combien coûte l\'inscription ?',
      'Rien. Vous payez uniquement une commission sur les locations terminées '
          'et payées venues d\'un ambassadeur.',
    ),
    (
      'Et si le client annule ou est remboursé ?',
      'Pas de commission. Si la commission était déjà comptée, elle est annulée '
          'et les coins sont repris à l\'ambassadeur.',
    ),
    (
      'Qui fixe le pourcentage ?',
      'Le niveau de l\'ambassadeur : Bronze 8 %, Argent 12 %, Or 16 %, '
          'Diamant 20 %. Le client a toujours −5 % sur sa première location.',
    ),
    (
      'Comment je règle les commissions ?',
      'Un relevé mensuel liste chaque location concernée. Vous réglez Dada, qui '
          'crédite les coins aux ambassadeurs.',
    ),
    (
      'Mes données sont-elles visibles ?',
      'Les ambassadeurs ne voient jamais le nom de vos clients, seulement '
          'l\'état de la réservation.',
    ),
  ];
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.body,
  });
  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppTheme.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
