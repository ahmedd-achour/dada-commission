import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'request_card.dart';

/// Client posts a rental request with an ambassador's code, then prepays
/// 10 % through Click to Pay. Only prepaid requests reach the feed.
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  final _car = TextEditingController();
  final _city = TextEditingController();
  final _price = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  CarCategory _category = CarCategory.citadine;
  // Default: tomorrow, 3 days.
  DateTimeRange? _dates = () {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day + 1);
    return DateTimeRange(start: start, end: start.add(const Duration(days: 3)));
  }();
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    final u = AppScope.read(context).user!;
    _city.text = u.city ?? '';
    _phone.text = u.phone ?? '';
    for (final c in [_code, _price]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_code, _car, _city, _price, _phone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _listPrice =>
      double.tryParse(_price.text.replaceAll(',', '.').trim()) ?? 0;

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dates,
      helpText: 'Dates de location',
    );
    if (picked != null) setState(() => _dates = picked);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final dates = _dates;
    if (dates == null) {
      showSnack(context, 'Choisissez les dates de location.', error: true);
      return;
    }
    final state = AppScope.read(context);
    final error = state.validateRequest(
      code: _code.text,
      startDate: dates.start,
      endDate: dates.end,
      listPriceDt: _listPrice,
    );
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    final request = state.createRequest(
      code: _code.text,
      carWanted: _car.text,
      category: _category,
      city: _city.text,
      startDate: dates.start,
      endDate: dates.end,
      listPriceDt: _listPrice,
      phone: _phone.text,
      note: _note.text,
    );
    setState(() => _paying = true);
    final payError = await state.payPrepayment(request.id);
    if (!mounted) return;
    setState(() => _paying = false);
    if (payError != null) {
      showSnack(context, 'Paiement non abouti : $payError', error: true);
      return;
    }
    Navigator.of(context).pop();
    openRequest(context, request.id);
    showSnack(
      context,
      'Acompte payé ✅ Votre demande est visible par les agences.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ambassador = state.findUserByCode(_code.text);
    final scheme = Theme.of(context).colorScheme;
    final pricing = _listPrice > 0
        ? RequestPricing.fromListPrice(_listPrice)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle demande')),
      body: AbsorbPointer(
        absorbing: _paying,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('request-code'),
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  _UpperCase(),
                ],
                decoration: InputDecoration(
                  labelText: 'Code ambassadeur',
                  hintText: 'ex. YASMINE20',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  helperText:
                      ambassador != null && ambassador.id != state.user!.id
                      ? '${ambassador.displayName} · −${Fmt.percent(kCustomerDiscountRate)} pour vous'
                      : 'Le code vous donne −${Fmt.percent(kCustomerDiscountRate)}.',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('request-car'),
                controller: _car,
                validator: _required,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Voiture souhaitée',
                  hintText: 'ex. Mercedes-Benz Classe G',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in CarCategory.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                validator: _required,
                decoration: const InputDecoration(
                  labelText: 'Ville de prise en charge',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                key: const Key('request-dates'),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                onTap: _pickDates,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Dates',
                    prefixIcon: Icon(Icons.date_range_outlined),
                  ),
                  child: Text(
                    _dates == null
                        ? 'Choisir'
                        : '${Fmt.shortDate(_dates!.start)} → '
                              '${Fmt.shortDate(_dates!.end)} · '
                              '${_dates!.duration.inDays} jours',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('request-price'),
                controller: _price,
                validator: _required,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Prix total annoncé par l\'agence (DT)',
                  helperText: 'Avant la remise du code.',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                validator: _required,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Votre téléphone',
                  helperText:
                      'Visible uniquement par l\'agence qui prend la demande.',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Précisions (optionnel)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              if (pricing != null) ...[
                const SizedBox(height: 8),
                PricingBreakdown(pricing: pricing),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('request-pay'),
                onPressed: _submit,
                icon: _paying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_outline_rounded),
                label: Text(
                  pricing == null
                      ? 'Payer l\'acompte avec Click to Pay'
                      : 'Payer ${Fmt.dinars(pricing.prepaymentDt)} avec Click to Pay',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'L\'acompte de ${Fmt.percent(kPrepaymentRate)} garantit votre '
                'demande. Il n\'est pas remboursé si vous ne venez pas chercher '
                'la voiture.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Who gets what, for a given price.
class PricingBreakdown extends StatelessWidget {
  const PricingBreakdown({
    super.key,
    required this.pricing,
    this.showAmbassador = true,
  });
  final RequestPricing pricing;
  final bool showAmbassador;

  @override
  Widget build(BuildContext context) {
    final p = pricing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _Line('Prix annoncé', Fmt.dinars(p.listPriceDt)),
            _Line(
              'Remise code −${Fmt.percent(kCustomerDiscountRate)}',
              '−${Fmt.dinars(p.discountDt)}',
            ),
            _Line('Total client', Fmt.dinars(p.amountDueDt), bold: true),
            const Divider(),
            _Line(
              'Acompte ${Fmt.percent(kPrepaymentRate)} (Click to Pay → Dada)',
              Fmt.dinars(p.prepaymentDt),
              color: AppTheme.blue,
              bold: true,
            ),
            _Line(
              'À payer à l\'agence (${Fmt.percent(1 - kPrepaymentRate)})',
              Fmt.dinars(p.agencyDt),
            ),
            if (showAmbassador) ...[
              const Divider(),
              _Line(
                'Ambassadeur ${Fmt.percent(kAmbassadorRate)} (immédiat)',
                Fmt.coins(p.ambassadorCoins),
                color: AppTheme.success,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false, this.color});
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
