import 'package:dada_commission/core/formatters.dart';
import 'package:dada_commission/data/app_state.dart';
import 'package:dada_commission/models/models.dart';
import 'package:dada_commission/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingGateway implements PaymentGateway {
  @override
  Future<PaymentResult> pay({
    required int amountMillimes,
    required PaymentPurpose purpose,
    required String description,
  }) async => const PaymentResult.failure('Carte refusée');
}

void main() {
  const instant = DemoPaymentGateway(delay: Duration.zero);

  group('RequestPricing', () {
    test('matches the G-Class example: 700 DT due', () {
      final p = RequestPricing.fromAmountDue(700);
      expect(p.prepaymentDt, 70);
      expect(p.ambassadorDt, 56);
      expect(p.ambassadorCoins, 560);
      expect(p.dadaFeeDt, 14);
      expect(p.agencyDt, 630);
    });

    test('applies the −5 % code discount to the list price', () {
      final p = RequestPricing.fromListPrice(1000);
      expect(p.discountDt, 50);
      expect(p.amountDueDt, 950);
      expect(p.prepaymentDt, 95);
      expect(p.ambassadorCoins, 760);
      expect(p.prepaymentMillimes, p.ambassadorMillimes + p.dadaFeeMillimes);
    });

    test('ambassador coins are whole', () {
      final p = RequestPricing.fromListPrice(123.457);
      expect(p.ambassadorMillimes % 100, 0);
      expect(p.dadaFeeMillimes, greaterThanOrEqualTo(0));
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
  });

  group('AppState (guest mode)', () {
    late AppState state;
    setUp(() => state = AppState(payments: instant)..signInAsGuest());

    test('wallet equals the ledger and the G-Class earning is there', () {
      final ledger = state.transactions.fold<int>(0, (s, t) => s + t.amount);
      expect(state.wallet.balance, ledger);
      expect(
        state.transactions.any((t) => t.requestId == 'rq1' && t.amount == 560),
        isTrue,
      );
    });

    test('feed only shows prepaid requests', () {
      state.completeSetup(role: UserRole.client, displayName: 'Sami');
      state.createRequest(
        code: 'SARA11',
        carWanted: 'Clio',
        category: CarCategory.compacte,
        city: 'Tunis',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 4),
        listPriceDt: 300,
      );
      expect(state.publicRequests.every((r) => r.isPaid), isTrue);
    });

    test('own code is refused', () {
      final error = state.validateRequest(
        code: 'YASMINE20',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 3),
        listPriceDt: 300,
      );
      expect(error, contains('propre code'));
    });

    test('prepaying a request with my code credits 8 % at once', () async {
      final before = state.wallet.balance;
      final r = await state.simulateClientRequest();
      expect(r!.status, RequestStatus.open);
      expect(r.paidAt, isNotNull);
      expect(state.wallet.balance, before + r.pricing.ambassadorCoins);
      expect(state.payments.first.status, PaymentStatus.succeeded);
      expect(
        state.transactions.first.type,
        CoinTransactionType.referralEarning,
      );
    });

    test(
      'a failed payment leaves the request unpaid and coins untouched',
      () async {
        final failing = AppState(payments: _FailingGateway())..signInAsGuest();
        failing.completeSetup(role: UserRole.client, displayName: 'Sami');
        final r = failing.createRequest(
          code: 'SARA11',
          carWanted: 'Clio',
          category: CarCategory.compacte,
          city: 'Tunis',
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 4),
          listPriceDt: 300,
        );
        expect(await failing.payPrepayment(r.id), 'Carte refusée');
        expect(
          failing.requestById(r.id)!.status,
          RequestStatus.awaitingPayment,
        );
      },
    );

    test('only an approved agency can take and complete a request', () {
      expect(state.claimRequest('rq4'), isNotNull);
      state.registerCompany(
        name: 'Medina Location',
        taxRegistrationNumber: '123/A',
        city: 'Sousse',
        phone: '22000000',
        agreementAccepted: true,
      );
      state.completeSetup(role: UserRole.companyAdmin, displayName: 'Mehdi');
      expect(state.claimRequest('rq4'), isNotNull); // still pending
      state.demoApproveMyCompany();
      expect(state.claimRequest('rq4'), isNull);
      expect(state.requestById('rq4')!.status, RequestStatus.claimed);
      expect(state.claimRequest('rq4'), isNotNull); // already taken
      expect(
        state.completeRequest(
          'rq4',
          const RentedCar(model: 'Peugeot 3008', finalPriceDt: 1330),
        ),
        isNull,
      );
      expect(state.requestById('rq4')!.status, RequestStatus.completed);
      expect(state.myAgencyRequests.single.id, 'rq4');
    });

    test('company file becomes pending once every document is sent', () {
      state.registerCompany(
        name: 'Medina Location',
        taxRegistrationNumber: '123/A',
        city: 'Sousse',
        phone: '22000000',
        agreementAccepted: true,
      );
      expect(state.myCompany!.status, CompanyStatus.draft);
      for (final t in CompanyDocumentType.values) {
        state.submitCompanyDocument(t);
      }
      expect(state.myCompany!.status, CompanyStatus.pending);
    });

    test('transfer and coin purchase move the balance', () async {
      final start = state.wallet.balance;
      expect(state.transferCoins(toCode: 'sara11', amount: 100), isNull);
      expect(state.wallet.balance, start - 100);
      expect(await state.buyCoins(500), isNull);
      expect(state.wallet.balance, start + 400);
      expect(state.transactions.first.type, CoinTransactionType.purchase);
      expect(await state.buyCoins(50), isNotNull); // below minimum
    });
  });

  group('serialization', () {
    test('RentalRequest round-trips (phone kept out of the public doc)', () {
      final r = RentalRequest(
        id: 'r',
        referralCode: 'YASMINE20',
        ambassadorId: 'u_y',
        ambassadorName: 'Yasmine B.',
        clientId: 'c',
        clientName: 'Sami Ben Ali',
        clientPhone: '+216 98 111 222',
        carWanted: 'Classe G',
        category: CarCategory.luxe,
        city: 'Tunis',
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 23),
        listPriceDt: 736.842,
        status: RequestStatus.open,
        paidAt: DateTime(2026, 10, 14),
        createdAt: DateTime(2026, 10, 14),
      );
      final json = r.toJson();
      expect(json.containsKey('clientPhone'), isFalse);
      expect(json['ambassadorCoins'], 560);
      final back = RentalRequest.fromJson('r', json);
      expect(back.status, RequestStatus.open);
      expect(back.days, 3);
      expect(back.maskedClientName, 'S***i');
    });

    test('unknown enum values fall back to defaults', () {
      final t = CoinTransaction.fromJson('t', {'amount': 5, 'type': 'weird'});
      expect(t.type, CoinTransactionType.adjustment);
    });
  });

  test('Fmt formats coins and dinars the French way', () {
    expect(Fmt.coins(6000), '6 000 DC');
    expect(Fmt.dinars(68.4), '68,400 DT');
    expect(Fmt.signedCoins(560), '+560 DC');
  });
}
