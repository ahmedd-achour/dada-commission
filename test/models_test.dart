import 'package:dada_commission/core/formatters.dart';
import 'package:dada_commission/data/app_state.dart';
import 'package:dada_commission/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommissionCalculator', () {
    test('matches the concept example (Yasmine, Gold, Sami 3 days)', () {
      final c = CommissionCalculator.compute(
        days: 3,
        pricePerDay: 150,
        tierRate: AmbassadorTier.gold.commissionRate,
      );
      expect(c.grossDt, 450);
      expect(c.netDt, 427.5);
      expect(c.commissionDt, 68.4);
      expect(c.coins, 684);
    });

    test('repeat customer: no discount, half rate', () {
      final c = CommissionCalculator.compute(
        days: 1,
        pricePerDay: 100,
        tierRate: 0.16,
        isRepeatCustomer: true,
      );
      expect(c.discountDt, 0);
      expect(c.rate, 0.08);
      expect(c.coins, 80);
    });

    test('cancelled referral earns nothing', () {
      final r = Referral(
        id: 'r',
        ambassadorId: 'a',
        referralCode: 'X',
        companyId: 'c',
        carId: 'car',
        carModel: 'm',
        customerMaskedName: 'S***i',
        rentalDays: 3,
        pricePerDay: 150,
        commissionRate: 0.16,
        status: ReferralStatus.cancelled,
        bookedAt: DateTime(2026),
      );
      expect(r.coins, 0);
    });
  });

  group('AmbassadorTier', () {
    test('levels follow completed rentals over 3 months', () {
      expect(AmbassadorTier.forCompletedRentals(0), AmbassadorTier.bronze);
      expect(AmbassadorTier.forCompletedRentals(3), AmbassadorTier.silver);
      expect(AmbassadorTier.forCompletedRentals(10), AmbassadorTier.gold);
      expect(AmbassadorTier.forCompletedRentals(24), AmbassadorTier.gold);
      expect(AmbassadorTier.forCompletedRentals(25), AmbassadorTier.diamond);
      expect(AmbassadorTier.diamond.next, isNull);
    });
  });

  group('CoinTransfer.validate', () {
    String? v({int amount = 100, int balance = 184, String to = 'SARA11'}) =>
        CoinTransfer.validate(
          amount: amount,
          balance: balance,
          fromCode: 'YASMINE20',
          toCode: to,
        );

    test('accepts a valid transfer', () => expect(v(), isNull));
    test('rejects self transfer', () => expect(v(to: 'yasmine20'), isNotNull));
    test('rejects below minimum', () => expect(v(amount: 5), isNotNull));
    test('rejects above balance', () => expect(v(amount: 185), isNotNull));
    test('rejects empty code', () => expect(v(to: ' '), isNotNull));
  });

  group('AppState (guest mode)', () {
    late AppState state;
    setUp(() => state = AppState()..signInAsGuest());

    test('loads the concept wallet', () {
      expect(state.user!.referralCode, 'YASMINE20');
      expect(state.wallet.balance, 184);
      final ledger = state.transactions.fold<int>(0, (s, t) => s + t.amount);
      expect(ledger, state.wallet.balance);
    });

    test('transfer debits the wallet and logs the ledger entry', () {
      expect(state.transferCoins(toCode: 'sara11', amount: 100), isNull);
      expect(state.wallet.balance, 84);
      expect(state.transactions.first.type, CoinTransactionType.transferOut);
      expect(state.transactions.first.amount, -100);
      expect(state.transfers.single.toUserId, 'u_sara');
    });

    test('transfer to an unknown code fails without side effects', () {
      expect(state.transferCoins(toCode: 'NOPE', amount: 50), isNotNull);
      expect(state.wallet.balance, 184);
    });

    test('redeem reserves coins', () {
      final topUp = state.rewards.firstWhere((r) => r.id == 'rw_topup');
      expect(state.redeem(topUp), isNull);
      expect(state.wallet.balance, 84);
      expect(state.redemptions.single.rewardId, 'rw_topup');
    });

    test('company registration is pending and hidden from marketplace', () {
      state.registerCompany(
        name: 'Medina Location',
        taxRegistrationNumber: '123/A',
        city: 'Sousse',
        phone: '22000000',
      );
      expect(state.myCompany!.status, CompanyStatus.pending);
      expect(
        state.approvedCompanies.any((c) => c.name == 'Medina Location'),
        isFalse,
      );
    });
  });

  group('serialization', () {
    test('AppUser round-trips', () {
      final u = AppUser(
        id: 'u1',
        displayName: 'Karim M.',
        authProvider: AuthProviderType.whatsapp,
        referralCode: 'karim05',
        tier: AmbassadorTier.silver,
        createdAt: DateTime(2026, 10, 1),
      );
      final back = AppUser.fromJson('u1', u.toJson());
      expect(back.referralCode, 'KARIM05');
      expect(back.tier, AmbassadorTier.silver);
      expect(back.authProvider, AuthProviderType.whatsapp);
      expect(back.createdAt, DateTime(2026, 10, 1));
      expect(back.referralLink, endsWith('/r/KARIM05'));
    });

    test('unknown enum values fall back to defaults', () {
      final w = CoinTransaction.fromJson('t', {'amount': 5, 'type': 'weird'});
      expect(w.type, CoinTransactionType.adjustment);
    });
  });

  group('Fmt', () {
    test('formats coins and dinars the French way', () {
      expect(Fmt.coins(6000), '6 000 DC');
      expect(Fmt.dinars(68.4), '68,400 DT');
      expect(Fmt.signedCoins(684), '+684 DC');
      expect(Fmt.signedCoins(-500), '−500 DC');
      expect(Referral.maskName('Sami'), 'S***i');
    });
  });
}
