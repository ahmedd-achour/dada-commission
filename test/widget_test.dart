import 'package:dada_commission/app.dart';
import 'package:dada_commission/core/theme.dart';
import 'package:dada_commission/data/app_state.dart';
import 'package:dada_commission/models/models.dart';
import 'package:dada_commission/screens/setup/account_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    AppTheme.useGoogleFonts = false;
    AccountSetupScreen.pickDocument = (_) async => true;
  });

  Future<AppState> openGuest(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final state = AppState();
    await tester.pumpWidget(DadaApp(state: state));
    expect(find.text('Continuer avec Google'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guest-sign-in')));
    await tester.pumpAndSettle();
    expect(find.text('Quel compte voulez-vous créer ?'), findsOneWidget);
    return state;
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('setup-next')));
    await tester.pumpAndSettle();
  }

  Future<void> acceptAndFinish(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('setup-accept')));
    await tester.pumpAndSettle();
    await next(tester);
  }

  /// Guest sign-in + ambassador setup (profile is pre-filled).
  Future<AppState> signInAsAmbassador(WidgetTester tester) async {
    final state = await openGuest(tester);
    await tester.tap(find.byKey(const Key('type-ambassador')));
    await next(tester); // -> profile
    await next(tester); // -> rules
    await acceptAndFinish(tester);
    expect(state.user!.setupComplete, isTrue);
    return state;
  }

  testWidgets('setup is required, then every tab renders', (tester) async {
    await signInAsAmbassador(tester);
    expect(find.text('Dada Commission'), findsOneWidget);
    expect(find.text('Réserver avec YASMINE20'), findsOneWidget);

    await tester.tap(find.text('Marketplace').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wallet-panel')), findsOneWidget);
    expect(find.text('Boutique Dada'), findsOneWidget);

    await tester.tap(find.text('Activité').last);
    await tester.pumpAndSettle();
    expect(find.text('Mes clients récents'), findsOneWidget);

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('YASMINE20'), findsWidgets);
  });

  testWidgets('rules must be accepted to finish setup', (tester) async {
    final state = await openGuest(tester);
    await next(tester);
    await next(tester);
    await next(tester); // "Terminer" without accepting
    expect(state.user!.setupComplete, isFalse);
    expect(find.textContaining('Acceptez les règles'), findsOneWidget);
  });

  testWidgets('business account setup creates a company file', (tester) async {
    final state = await openGuest(tester);
    await tester.tap(find.byKey(const Key('type-company')));
    await tester.pumpAndSettle();
    await next(tester); // -> profile
    await next(tester); // -> company form

    Future<void> fill(String label, String value) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    await fill('Nom commercial', 'Medina Location');
    await fill('Matricule fiscal', '1234567/A/M/000');
    await fill('Adresse de l\'agence', 'Avenue Habib Bourguiba, Sousse');
    await fill('Nombre de voitures', '12');
    await tester.pumpAndSettle();
    await next(tester); // -> documents

    await tester.tap(find.text('Ajouter').first);
    await tester.pumpAndSettle();
    expect(find.text('Ajouté'), findsOneWidget);
    await next(tester); // -> agreement
    await acceptAndFinish(tester);

    expect(state.user!.role, UserRole.companyAdmin);
    expect(state.myCompany!.name, 'Medina Location');
    expect(state.myCompany!.status, CompanyStatus.draft);
    expect(state.myCompany!.documents, hasLength(1));
  });

  testWidgets('social sign-in buttons explain they are not wired yet', (
    tester,
  ) async {
    await tester.pumpWidget(DadaApp(state: AppState()));
    await tester.tap(find.text('Continuer avec WhatsApp'));
    await tester.pump();
    expect(find.textContaining('bientôt disponible'), findsOneWidget);
  });

  testWidgets('comment on a post', (tester) async {
    final state = await signInAsAmbassador(tester);
    await tester.tap(find.text('Commenter').first);
    await tester.pumpAndSettle();
    expect(find.text('Commentaires (2)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('comment-field')), 'Top !');
    await tester.pump();
    await tester.tap(find.byKey(const Key('comment-send')));
    await tester.pumpAndSettle();

    expect(find.text('Commentaires (3)'), findsOneWidget);
    expect(find.text('Top !'), findsOneWidget);
    expect(state.posts.first.commentCount, 3);
  });

  testWidgets('send coins from the marketplace wallet', (tester) async {
    final state = await signInAsAmbassador(tester);
    await tester.tap(find.text('Marketplace').last);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('wallet-panel')),
        matching: find.text('Envoyer'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('transfer-code')), 'sara11');
    await tester.enterText(find.byKey(const Key('transfer-amount')), '100');
    await tester.pumpAndSettle();
    expect(find.text('Sara K.'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('transfer-submit')));
    await tester.tap(find.byKey(const Key('transfer-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Envoyer').last);
    await tester.pumpAndSettle();

    expect(state.wallet.balance, 84);
    expect(find.textContaining('envoyés à Sara K.'), findsOneWidget);
  });
}
