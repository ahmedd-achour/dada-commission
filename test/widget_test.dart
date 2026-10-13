import 'package:dada_commission/app.dart';
import 'package:dada_commission/core/theme.dart';
import 'package:dada_commission/data/app_state.dart';
import 'package:dada_commission/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => AppTheme.useGoogleFonts = false);

  Future<AppState> signInAsGuest(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final state = AppState();
    await tester.pumpWidget(DadaApp(state: state));
    expect(find.text('Continuer avec Google'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guest-sign-in')));
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('guest mode opens the feed and every tab renders', (
    tester,
  ) async {
    await signInAsGuest(tester);
    expect(find.text('Dada Commission'), findsOneWidget);
    expect(find.text('Réserver avec YASMINE20'), findsOneWidget);

    await tester.tap(find.text('Marketplace').last);
    await tester.pumpAndSettle();
    expect(find.text('Boutique Dada'), findsOneWidget);

    await tester.tap(find.text('Activité').last);
    await tester.pumpAndSettle();
    expect(find.text('Mes clients récents'), findsOneWidget);

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('YASMINE20'), findsWidgets);
  });

  testWidgets('social sign-in buttons explain they are not wired yet', (
    tester,
  ) async {
    await tester.pumpWidget(DadaApp(state: AppState()));
    await tester.tap(find.text('Continuer avec WhatsApp'));
    await tester.pump();
    expect(find.textContaining('bientôt disponible'), findsOneWidget);
  });

  testWidgets('send coins from the profile', (tester) async {
    final state = await signInAsGuest(tester);
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();

    final send = find.widgetWithText(OutlinedButton, 'Envoyer');
    await tester.scrollUntilVisible(
      send,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ProfileScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(send);
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
