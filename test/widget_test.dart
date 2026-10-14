import 'package:dada_commission/app.dart';
import 'package:dada_commission/core/theme.dart';
import 'package:dada_commission/data/app_state.dart';
import 'package:dada_commission/models/models.dart';
import 'package:dada_commission/screens/requests/create_request_screen.dart';
import 'package:dada_commission/screens/setup/account_setup_screen.dart';
import 'package:dada_commission/services/payment_service.dart';
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

    final state = AppState(
      payments: const DemoPaymentGateway(delay: Duration.zero),
    );
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
    expect(find.text('Mercedes-Benz Classe G'), findsOneWidget);

    await tester.tap(find.text('Wallet').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wallet-panel')), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);

    await tester.tap(find.text('Activité').last);
    await tester.pumpAndSettle();
    expect(find.text('Demandes avec mon code'), findsOneWidget);

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
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('type-company'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
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

  testWidgets('client posts a request and prepays 10 %', (tester) async {
    final state = await openGuest(tester);
    await tester.tap(find.byKey(const Key('type-client')));
    await tester.pumpAndSettle();
    await next(tester); // -> profile
    await next(tester); // -> rules
    await acceptAndFinish(tester);
    expect(state.user!.role, UserRole.client);
    // Let the welcome snack bar go away (it floats over the FAB).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('new-request')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('request-code')), 'sara11');
    await tester.enterText(
      find.byKey(const Key('request-car')),
      'Mercedes-Benz Classe C',
    );
    final price = find.byKey(const Key('request-price'));
    await tester.scrollUntilVisible(
      price,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CreateRequestScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(price, '1000');
    await tester.pumpAndSettle();
    final pay = find.byKey(const Key('request-pay'));
    await tester.scrollUntilVisible(
      pay,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CreateRequestScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // 1000 − 5 % = 950 DT due, 95 DT prepaid.
    expect(find.text('Payer 95,000 DT avec Click to Pay'), findsOneWidget);
    await Scrollable.ensureVisible(tester.element(pay), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(pay);
    await tester.pumpAndSettle();

    final mine = state.myClientRequests.single;
    expect(mine.status, RequestStatus.open);
    expect(mine.ambassadorId, 'u_sara');
    expect(find.text('Demande de location'), findsOneWidget);
  });

  testWidgets('ambassador earns 8 % as soon as a client prepays', (
    tester,
  ) async {
    final state = await signInAsAmbassador(tester);
    final before = state.wallet.balance;
    await tester.tap(find.text('Activité').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('simulate-client')));
    await tester.pumpAndSettle();
    // 480 DT − 5 % = 456 DT due; 8 % = 36,480 DT -> 364 DC (whole coins).
    expect(state.wallet.balance, before + 364);
    expect(find.textContaining('+364 DC reçus'), findsOneWidget);
  });

  testWidgets('approved agency takes a request from the feed', (tester) async {
    final state = await openGuest(tester);
    state.registerCompany(
      name: 'Medina Location',
      taxRegistrationNumber: '123/A',
      city: 'Sousse',
      phone: '22000000',
      agreementAccepted: true,
    );
    state.completeSetup(role: UserRole.companyAdmin, displayName: 'Mehdi');
    state.demoApproveMyCompany();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('claim-rq1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Prendre'));
    await tester.pumpAndSettle();
    expect(state.requestById('rq1')!.status, RequestStatus.claimed);
    expect(state.requestById('rq1')!.companyName, 'Medina Location');
  });

  testWidgets('send coins from the wallet tab', (tester) async {
    final state = await signInAsAmbassador(tester);
    final before = state.wallet.balance;
    await tester.tap(find.text('Wallet').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Envoyer'));
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

    expect(state.wallet.balance, before - 100);
    expect(find.textContaining('envoyés à Sara K.'), findsOneWidget);
  });

  testWidgets('buy coins with Click to Pay', (tester) async {
    final state = await signInAsAmbassador(tester);
    final before = state.wallet.balance;
    await tester.tap(find.text('Wallet').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy-coins')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy-confirm')));
    await tester.pumpAndSettle();
    expect(state.wallet.balance, before + 500);
  });
}
