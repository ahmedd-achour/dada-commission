import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/app_state.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    final u = state.user!;
    _name = TextEditingController(text: u.displayName);
    _bio = TextEditingController(text: u.bio ?? '');
    _city = TextEditingController(text: u.city ?? '');
    _phone = TextEditingController(text: u.phone ?? '');
    _photo = state.photoBytes;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _photo = bytes);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Impossible d\'ouvrir la galerie : $e', error: true);
    }
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    AppScope.read(context).updateProfile(
      displayName: _name.text,
      bio: _bio.text,
      city: _city.text,
      phone: _phone.text,
      newPhoto: _photo,
    );
    Navigator.of(context).pop();
    showSnack(context, 'Profil mis à jour ✅');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Enregistrer')),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    UserAvatar(name: _name.text, bytes: _photo, radius: 52),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: scheme.primary,
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _pickPhoto,
                child: const Text('Changer la photo'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom affiché',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Au moins 2 caractères'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bio,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.short_text_rounded),
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(
                labelText: 'Ville',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }
}
