import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// Lets another rent-car company join the platform. The request stays
/// "pending" until the Dada team approves it; then its cars show up in the
/// marketplace and ambassadors can share them.
class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _tax = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _fleet = TextEditingController();
  bool _accepted = false;

  @override
  void dispose() {
    for (final c in [_name, _tax, _city, _address, _phone, _email, _fleet]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (!_accepted) {
      showSnack(context, 'Acceptez les conditions du programme.', error: true);
      return;
    }
    AppScope.read(context).registerCompany(
      name: _name.text,
      taxRegistrationNumber: _tax.text,
      city: _city.text,
      phone: _phone.text,
      address: _address.text,
      email: _email.text,
      fleetSize: int.tryParse(_fleet.text) ?? 0,
    );
    showSnack(context, 'Demande envoyée ✅ L\'équipe Dada va la vérifier.');
  }

  @override
  Widget build(BuildContext context) {
    final company = AppScope.of(context).myCompany;
    return Scaffold(
      appBar: AppBar(title: const Text('Inscrire mon agence')),
      body: company != null
          ? _StatusView(company: company)
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Recevez des clients grâce aux ambassadeurs Dada.',
            style: AppTheme.display(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'Vous ne payez qu\'une commission sur les locations terminées et '
            'payées. Le client bénéficie de −5 % sur sa première location.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'agence',
              prefixIcon: Icon(Icons.store_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tax,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Matricule fiscal',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Ville',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Adresse (optionnel)',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            validator: _required,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixText: '+216 ',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail (optionnel)',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fleet,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nombre de véhicules',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _accepted,
            onChanged: (v) => setState(() => _accepted = v ?? false),
            title: const Text(
              'J\'accepte les règles du programme (commission sur locations '
              'terminées, remboursement = coins repris).',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            child: const Text('Envoyer la demande'),
          ),
        ],
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.company});
  final RentalCompany company;

  @override
  Widget build(BuildContext context) {
    final approved = company.isApproved;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          approved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
          size: 64,
          color: approved ? AppTheme.success : AppTheme.warning,
        ),
        const SizedBox(height: 16),
        Text(
          company.name,
          textAlign: TextAlign.center,
          style: AppTheme.display(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Center(
          child: StatusPill(
            label: company.status.label,
            color: approved ? AppTheme.success : AppTheme.warning,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Matricule fiscal'),
                subtitle: Text(company.taxRegistrationNumber),
              ),
              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Ville'),
                subtitle: Text(company.city),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Téléphone'),
                subtitle: Text(company.phone),
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Demande envoyée le'),
                subtitle: Text(Fmt.longDate(company.createdAt)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          approved
              ? 'Ajoutez vos voitures depuis l\'espace agence (bientôt).'
              : 'Nous vérifions vos informations. Vous serez notifié dès '
                    'la validation ; vos voitures apparaîtront alors dans la marketplace.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
