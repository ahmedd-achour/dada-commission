import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../business/business_guide_screen.dart';

/// Account setup, required before using the app:
/// 1. account type (ambassador, partner venue, rent-car company)
/// 2. profile
/// 3. company file + 4. documents (companies only)
/// 5. rules / commission agreement.
///
/// Shown by the auth gate after the first sign-in, or pushed from the
/// business guide to turn an existing account into a company account.
class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key, this.initialRole});

  final UserRole? initialRole;

  /// Lets the user photograph/choose a document; true when one was picked.
  /// Uploading to Storage comes with the real backend. Overridable in tests.
  static Future<bool> Function(CompanyDocumentType type) pickDocument =
      _pickFromGallery;

  static Future<bool> _pickFromGallery(CompanyDocumentType type) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return file != null;
    } catch (_) {
      // No picker on this platform (e.g. web preview): accept in demo mode.
      return true;
    }
  }

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

enum _Step { type, profile, company, documents, agreement }

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final _profileForm = GlobalKey<FormState>();
  final _companyForm = GlobalKey<FormState>();

  late UserRole _role;
  int _index = 0;
  bool _accepted = false;

  late final _name = TextEditingController();
  late final _phone = TextEditingController();
  late final _city = TextEditingController();
  late final _venue = TextEditingController();
  DateTime? _birthDate;

  final _companyName = TextEditingController();
  final _tax = TextEditingController();
  final _rne = TextEditingController();
  final _address = TextEditingController();
  final _companyPhone = TextEditingController();
  final _contact = TextEditingController();
  final _fleet = TextEditingController();
  final Set<CompanyDocumentType> _docs = {};

  @override
  void initState() {
    super.initState();
    final u = AppScope.read(context).user!;
    _role = widget.initialRole ?? u.role;
    _name.text = u.displayName;
    _phone.text = u.phone ?? '';
    _city.text = u.city ?? '';
    _venue.text = u.venueName ?? '';
    _birthDate = u.birthDate;
    _contact.text = u.displayName;
    _companyPhone.text = u.phone ?? '';
    if (widget.initialRole != null) _index = 1;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _city, _venue, _companyName, _tax, _rne, //
      _address, _companyPhone, _contact, _fleet,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isCompany => _role == UserRole.companyAdmin;

  List<_Step> get _steps => [
    _Step.type,
    _Step.profile,
    if (_isCompany) ...[_Step.company, _Step.documents],
    _Step.agreement,
  ];

  _Step get _step => _steps[_index];

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  void _next() {
    switch (_step) {
      case _Step.profile:
        if (!_profileForm.currentState!.validate()) return;
        if (_role == UserRole.ambassador) {
          final b = _birthDate;
          if (b == null) {
            showSnack(
              context,
              'Indiquez votre date de naissance.',
              error: true,
            );
            return;
          }
          final age = AppUser.ageBetween(b, DateTime.now());
          if (age < kMinAmbassadorAge) {
            showSnack(
              context,
              'Il faut avoir au moins $kMinAmbassadorAge ans pour devenir ambassadeur.',
              error: true,
            );
            return;
          }
        }
      case _Step.company:
        if (!_companyForm.currentState!.validate()) return;
      case _Step.agreement:
        _finish();
        return;
      case _Step.type:
      case _Step.documents:
        break;
    }
    setState(() => _index++);
  }

  void _back() {
    if (_index == 0 || (widget.initialRole != null && _index == 1)) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    setState(() => _index--);
  }

  void _finish() {
    if (!_accepted) {
      showSnack(context, 'Acceptez les règles pour continuer.', error: true);
      return;
    }
    final state = AppScope.read(context);
    if (_isCompany) {
      state.registerCompany(
        name: _companyName.text,
        taxRegistrationNumber: _tax.text,
        rneNumber: _rne.text,
        city: _city.text,
        address: _address.text,
        phone: _companyPhone.text,
        contactName: _contact.text,
        fleetSize: int.tryParse(_fleet.text) ?? 0,
        documents: _docs,
        agreementAccepted: true,
      );
    }
    state.completeSetup(
      role: _role,
      displayName: _name.text,
      phone: _phone.text,
      city: _city.text,
      birthDate: _birthDate,
      venueName: _role == UserRole.partner ? _venue.text : null,
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
    showSnack(
      context,
      _isCompany
          ? 'Compte entreprise créé ✅ Notre équipe vérifie votre dossier.'
          : 'Bienvenue sur Dada Commission 🎉',
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 90),
      lastDate: now,
      helpText: 'Date de naissance',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _addDocument(CompanyDocumentType type) async {
    final added = await AccountSetupScreen.pickDocument(type);
    if (added && mounted) setState(() => _docs.add(type));
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: _index == 0 && !Navigator.of(context).canPop()
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        title: Text(_titleFor(_step)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_index + 1) / steps.length,
            minHeight: 4,
            color: AppTheme.green,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    _Step.type => _typeStep(),
                    _Step.profile => _profileStep(),
                    _Step.company => _companyStep(),
                    _Step.documents => _documentsStep(),
                    _Step.agreement => _agreementStep(),
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Text(
                    'Étape ${_index + 1}/${steps.length}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('setup-next'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(150, 52),
                    ),
                    onPressed: _next,
                    child: Text(
                      _step == _Step.agreement ? 'Terminer' : 'Continuer',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(_Step s) => switch (s) {
    _Step.type => 'Créer mon compte',
    _Step.profile => 'Mon profil',
    _Step.company => 'Mon entreprise',
    _Step.documents => 'Documents',
    _Step.agreement => _isCompany ? 'Accord de commission' : 'Les règles',
  };

  // ------------------------------------------------------------------ steps

  Widget _typeStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Quel compte voulez-vous créer ?',
          style: AppTheme.display(fontSize: 22),
        ),
        const SizedBox(height: 4),
        const Text('Vous pourrez demander un changement plus tard.'),
        const SizedBox(height: 16),
        _TypeCard(
          key: const Key('type-ambassador'),
          image: 'assets/images/fluent/money_bag.png',
          title: 'Ambassadeur',
          subtitle:
              'Je partage des voitures avec mon code et je gagne des Dada '
              'Coins sur chaque location. Dès 18 ans.',
          selected: _role == UserRole.ambassador,
          onTap: () => setState(() => _role = UserRole.ambassador),
        ),
        _TypeCard(
          key: const Key('type-partner'),
          image: 'assets/images/fluent/gift.png',
          title: 'Partenaire (hôtel, agence, commerce)',
          subtitle:
              'Je pose un QR code à mon accueil : mes clients réservent, '
              'mon établissement gagne des coins.',
          selected: _role == UserRole.partner,
          onTap: () => setState(() => _role = UserRole.partner),
        ),
        _TypeCard(
          key: const Key('type-company'),
          image: 'assets/images/fluent/company.png',
          title: 'Entreprise de location de voitures',
          subtitle:
              'Je rejoins le hub : les ambassadeurs m\'apportent des clients, '
              'je ne paie une commission que sur les locations terminées.',
          selected: _role == UserRole.companyAdmin,
          onTap: () => setState(() => _role = UserRole.companyAdmin),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const BusinessGuideScreen(showCta: false),
            ),
          ),
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('Lire le guide entreprise'),
        ),
      ],
    );
  }

  Widget _profileStep() {
    return Form(
      key: _profileForm,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _isCompany ? 'Le responsable du compte' : 'Parlez-nous de vous',
            style: AppTheme.display(fontSize: 22),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            validator: _required,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Un compte par numéro de téléphone.',
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
          if (_role == UserRole.partner) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _venue,
              validator: _required,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'établissement',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
          ],
          if (_role == UserRole.ambassador) ...[
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  prefixIcon: Icon(Icons.cake_outlined),
                  helperText: 'Il faut avoir 18 ans ou plus.',
                ),
                child: Text(
                  _birthDate == null ? 'Choisir' : Fmt.longDate(_birthDate!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _companyStep() {
    return Form(
      key: _companyForm,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Votre agence', style: AppTheme.display(fontSize: 22)),
          const SizedBox(height: 4),
          const Text(
            'Ces informations apparaissent sur vos voitures et servent à '
            'vérifier votre entreprise.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _companyName,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Nom commercial',
              prefixIcon: Icon(Icons.store_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tax,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Matricule fiscal',
              hintText: '1234567/A/M/000',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rne,
            decoration: const InputDecoration(
              labelText: 'Identifiant RNE (optionnel)',
              prefixIcon: Icon(Icons.numbers_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Adresse de l\'agence',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _companyPhone,
            validator: _required,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone de l\'agence',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contact,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Gérant / personne de contact',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fleet,
            validator: _required,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nombre de voitures',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentsStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Vos documents', style: AppTheme.display(fontSize: 22)),
        const SizedBox(height: 4),
        const Text(
          'Une photo lisible de chaque document. Vous pouvez aussi les '
          'envoyer plus tard depuis l\'espace entreprise : votre dossier '
          'reste « incomplet » en attendant.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              for (final t in CompanyDocumentType.values)
                ListTile(
                  leading: Icon(
                    _docs.contains(t)
                        ? Icons.check_circle_rounded
                        : Icons.description_outlined,
                    color: _docs.contains(t) ? AppTheme.success : null,
                  ),
                  title: Text(t.label),
                  trailing: _docs.contains(t)
                      ? const Text('Ajouté')
                      : TextButton(
                          onPressed: () => _addDocument(t),
                          child: const Text('Ajouter'),
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${_docs.length}/${CompanyDocumentType.values.length} documents',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _agreementStep() {
    final example = CommissionCalculator.compute(
      days: 3,
      pricePerDay: 150,
      tierRate: AmbassadorTier.gold.commissionRate,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isCompany ? 'Comment vous payez' : 'Comment vous gagnez',
                style: AppTheme.display(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _isCompany
                    ? 'Rien à l\'inscription. Pour chaque location terminée et '
                          'payée venue d\'un code, vous versez la part de '
                          'l\'ambassadeur (8 à 20 % selon son niveau). Le client '
                          'a −5 % sur sa première location.'
                    : 'De 8 à 20 % de chaque location payée par vos clients, '
                          'en Dada Coins (10 DC = 1 DT), 7 jours après le '
                          'retour de la voiture.',
              ),
              const SizedBox(height: 12),
              Text(
                'Exemple : 3 jours × 150 DT − 5 % = '
                '${Fmt.dinars(example.netDt)} → part Or 16 % = '
                '${Fmt.dinars(example.commissionDt)} = '
                '${Fmt.coins(example.coins)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Les règles'),
        Text(
          _isCompany
              ? '• Commission due uniquement sur les locations terminées et payées.\n'
                    '• Location remboursée = commission annulée.\n'
                    '• Prix affichés honnêtes, identiques à ceux de l\'agence.\n'
                    '• Paiement des commissions à Dada chaque mois.\n'
                    '• Votre agence est visible après validation des documents.'
              : '• Pas d\'auto-parrainage (même téléphone, CIN ou carte).\n'
                    '• Un compte par personne.\n'
                    '• Coins seulement pour une location terminée et payée.\n'
                    '• Location remboursée = coins repris.\n'
                    '• « #sponsorisé » sur vos vidéos.',
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          key: const Key('setup-accept'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _accepted,
          onChanged: (v) => setState(() => _accepted = v ?? false),
          title: Text(
            _isCompany
                ? 'J\'accepte l\'accord de commission Dada Commission.'
                : 'J\'accepte les règles du programme.',
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String image;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.6)
            : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Image.asset(image, width: 52, height: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
