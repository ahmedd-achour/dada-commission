import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../business/business_guide_screen.dart';
import '../setup/account_setup_screen.dart';

/// "Espace entreprise": follow the company file, send missing documents.
/// Registration itself happens in the account-setup wizard.
class CompanyRegisterScreen extends StatelessWidget {
  const CompanyRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final company = AppScope.of(context).myCompany;
    return Scaffold(
      appBar: AppBar(title: const Text('Espace entreprise')),
      body: company == null
          ? const _NoCompany()
          : _CompanyFile(company: company),
    );
  }
}

class _NoCompany extends StatelessWidget {
  const _NoCompany();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Image.asset('assets/images/fluent/company.png', height: 110),
        const SizedBox(height: 16),
        Text(
          'Aucune entreprise inscrite',
          textAlign: TextAlign.center,
          style: AppTheme.display(fontSize: 22),
        ),
        const SizedBox(height: 8),
        const Text(
          'Créez un compte entreprise pour publier vos voitures et recevoir '
          'des clients grâce aux ambassadeurs.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const AccountSetupScreen(initialRole: UserRole.companyAdmin),
            ),
          ),
          child: const Text('Créer mon compte entreprise'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const BusinessGuideScreen(showCta: false),
            ),
          ),
          child: const Text('Lire le guide'),
        ),
      ],
    );
  }
}

class _CompanyFile extends StatelessWidget {
  const _CompanyFile({required this.company});
  final RentalCompany company;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final approved = company.isApproved;
    final color = switch (company.status) {
      CompanyStatus.approved => AppTheme.success,
      CompanyStatus.rejected || CompanyStatus.suspended => AppTheme.danger,
      _ => AppTheme.warning,
    };
    final message = switch (company.status) {
      CompanyStatus.draft =>
        'Il manque des documents. Envoyez-les pour lancer la vérification.',
      CompanyStatus.pending =>
        'Dossier complet ✅ L\'équipe Dada vérifie vos informations. Vous serez '
            'notifié dès la validation.',
      CompanyStatus.approved =>
        'Votre agence est visible dans la marketplace. Ajoutez vos voitures '
            'depuis l\'espace agence (bientôt).',
      CompanyStatus.rejected =>
        company.rejectionReason ?? 'Dossier refusé. Contactez l\'équipe Dada.',
      CompanyStatus.suspended => 'Compte suspendu. Contactez l\'équipe Dada.',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GradientCard(
          child: Row(
            children: [
              Image.asset('assets/images/fluent/company.png', width: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: AppTheme.display(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    Text('${company.city} · ${company.fleetSize} voitures'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            StatusPill(label: company.status.label, color: color),
            const Spacer(),
            Text(
              'Demande du ${Fmt.longDate(company.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(message),
        const SizedBox(height: 20),
        const SectionTitle('Documents'),
        Card(
          child: Column(
            children: [
              for (final t in CompanyDocumentType.values)
                _DocTile(
                  type: t,
                  status: company.documentStatus(t),
                  onSend: () {
                    state.submitCompanyDocument(t);
                    showSnack(context, '${t.label} : envoyé ✅');
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Informations'),
        Card(
          child: Column(
            children: [
              _Info(
                Icons.badge_outlined,
                'Matricule fiscal',
                company.taxRegistrationNumber,
              ),
              if (company.rneNumber != null && company.rneNumber!.isNotEmpty)
                _Info(Icons.numbers_rounded, 'RNE', company.rneNumber!),
              if (company.address != null)
                _Info(Icons.place_outlined, 'Adresse', company.address!),
              _Info(Icons.phone_outlined, 'Téléphone', company.phone),
              if (company.contactName != null)
                _Info(Icons.person_outline, 'Contact', company.contactName!),
              _Info(
                Icons.handshake_outlined,
                'Accord de commission',
                company.agreementAcceptedAt == null
                    ? 'Non accepté'
                    : 'Accepté le ${Fmt.longDate(company.agreementAcceptedAt!)}',
              ),
            ],
          ),
        ),
        if (!approved) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BusinessGuideScreen(showCta: false),
              ),
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Relire le guide entreprise'),
          ),
        ],
      ],
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.type,
    required this.status,
    required this.onSend,
  });
  final CompanyDocumentType type;
  final DocumentStatus status;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final missing = status == DocumentStatus.missing;
    return ListTile(
      leading: Icon(
        missing ? Icons.description_outlined : Icons.check_circle_rounded,
        color: switch (status) {
          DocumentStatus.missing => null,
          DocumentStatus.rejected => AppTheme.danger,
          _ => AppTheme.success,
        },
      ),
      title: Text(type.label),
      subtitle: Text(status.label),
      trailing: missing
          ? TextButton(onPressed: onSend, child: const Text('Envoyer'))
          : null,
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      ListTile(leading: Icon(icon), title: Text(label), subtitle: Text(value));
}
