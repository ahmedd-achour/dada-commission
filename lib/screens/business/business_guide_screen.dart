import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../requests/create_request_screen.dart';
import '../setup/account_setup_screen.dart';

/// In-app guide for rent-car companies: how the prepaid-request hub brings
/// them customers for free.
class BusinessGuideScreen extends StatelessWidget {
  const BusinessGuideScreen({super.key, this.showCta = true});

  /// Hidden when opened from inside the setup wizard.
  final bool showCta;

  @override
  Widget build(BuildContext context) {
    final example = RequestPricing.fromAmountDue(700);

    return Scaffold(
      appBar: AppBar(title: const Text('Guide agences')),
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
                        'Des clients sûrs, gratuitement',
                        style: AppTheme.display(
                          fontSize: 21,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chaque demande du hub a déjà été prépayée à '
                        '${Fmt.percent(kPrepaymentRate)} par le client. Vous '
                        'la prenez, vous louez, vous encaissez le reste.',
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
          for (final (i, (title, body)) in _steps.indexed)
            _StepTile(number: i + 1, title: title, body: body),
          const SizedBox(height: 12),
          const SectionTitle('Exemple : Mercedes Classe G, 3 jours'),
          PricingBreakdown(pricing: example),
          const SizedBox(height: 8),
          Text(
            'L\'agence n\'a rien payé pour ce client : elle encaisse '
            '${Fmt.dinars(example.agencyDt)}. L\'acompte de '
            '${Fmt.dinars(example.prepaymentDt)} reste à Dada, qui verse '
            '${Fmt.coins(example.ambassadorCoins)} à l\'ambassadeur.',
          ),
          const SizedBox(height: 20),
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
              label: const Text('Créer mon compte agence'),
              onPressed: () {
                final state = AppScope.read(context);
                if (state.myCompany != null) {
                  showSnack(context, 'Votre agence est déjà inscrite.');
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
      'Créez un compte « Agence »',
      'Fiche de l\'agence, documents, conditions. Gratuit.',
    ),
    (
      'Dada valide votre agence',
      'Après vérification des documents, vous voyez le bouton « Prendre en '
          'charge » sur les demandes.',
    ),
    (
      'Les clients publient leurs demandes',
      'Voiture voulue, dates, ville, prix annoncé, avec le code d\'un '
          'ambassadeur (−5 %) et 10 % d\'acompte payés par Click to Pay.',
    ),
    (
      'Vous prenez une demande',
      'Vous recevez le téléphone du client : appel ou WhatsApp en un clic.',
    ),
    (
      'Vous louez et encaissez 90 %',
      'Le client vous paie le reste à la remise de la voiture.',
    ),
    (
      'Vous marquez « louée »',
      'Avec la voiture louée et le prix final. La demande passe « terminée ».',
    ),
  ];

  static const _faq = [
    (
      'Combien ça coûte à l\'agence ?',
      'Rien. Les 10 % d\'acompte payés par le client financent l\'ambassadeur '
          '(8 %) et Dada (2 %). L\'acompte n\'est pas reversé à l\'agence.',
    ),
    (
      'Pourquoi les clients sont « sûrs » ?',
      'Parce qu\'ils ont déjà payé 10 % : une demande non payée n\'apparaît '
          'jamais dans le hub.',
    ),
    (
      'Et si je n\'ai pas la voiture demandée ?',
      'Ne prenez que les demandes que vous pouvez servir, ou proposez un '
          'équivalent au client avant de la prendre.',
    ),
    (
      'Qui voit le téléphone du client ?',
      'Seulement l\'agence qui prend la demande. Le hub affiche un nom masqué.',
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
