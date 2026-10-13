import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, this.car});

  /// Pre-selected car (when coming from "Partager une voiture").
  final Car? car;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _text = TextEditingController();
  Car? _car;
  bool _sponsored = false;

  @override
  void initState() {
    super.initState();
    _car = widget.car;
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _publish() {
    final state = AppScope.read(context);
    var text = _text.text.trim();
    if (_sponsored && !text.contains('#sponsorisé')) text = '$text #sponsorisé';
    state.publishPost(text: text, car: _car, sponsored: _sponsored);
    Navigator.of(context).pop();
    showSnack(context, 'Publication en ligne ✅');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user!;
    final canPublish = _text.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une publication'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: canPublish ? _publish : null,
              child: const Text('Publier'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const MyAvatar(radius: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TierBadge(tier: user.tier, dense: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            autofocus: widget.car == null,
            minLines: 4,
            maxLines: 10,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'Quoi de neuf ?'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Car?>(
            initialValue: _car,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Joindre une voiture (optionnel)',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            items: [
              const DropdownMenuItem<Car?>(value: null, child: Text('Aucune')),
              for (final c in state.cars)
                DropdownMenuItem<Car?>(
                  value: c,
                  child: Text(
                    '${c.model} · ${Fmt.price(c.pricePerDay)}/j · ${c.companyName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (c) => setState(() => _car = c),
          ),
          if (_car != null) ...[
            const SizedBox(height: 12),
            CarImage(height: 130, label: _car!.model, category: _car!.category),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: null,
              child: Text('Réserver avec ${user.referralCode}'),
            ),
            const SizedBox(height: 4),
            Text(
              'Vos lecteurs réservent avec votre code et obtiennent −5 %.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sponsored,
            onChanged: (v) => setState(() => _sponsored = v),
            title: const Text('Contenu sponsorisé'),
            subtitle: const Text(
              'Obligatoire pour les créateurs : ajoute « #sponsorisé ».',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Ajouter photo / vidéo'),
            onTap: () =>
                showSnack(context, 'Envoi de médias bientôt disponible.'),
          ),
        ],
      ),
    );
  }
}
