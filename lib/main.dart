import 'package:dada_commission/app.dart';
import 'package:dada_commission/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Guest mode runs on mock data, so the app stays usable without Firebase
    // (e.g. on desktop targets that have no Firebase options yet).
    debugPrint('Firebase init skipped: $e');
  }
  runApp(const DadaApp());
}
