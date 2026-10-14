import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../models/models.dart';
import '../services/payment_service.dart';
import 'mock_data.dart';

/// App-wide session state.
///
/// For now everything is backed by [MockData] (guest mode). When auth lands,
/// the same public API is fed from Firestore streams and the money-moving
/// methods call Cloud Functions (payment confirmation, coin credit,
/// transfers) instead of editing lists.
class AppState extends ChangeNotifier {
  AppState({DateTime Function()? clock, PaymentGateway? payments})
    : _clock = clock ?? DateTime.now,
      _payments = payments ?? const DemoPaymentGateway();

  final DateTime Function() _clock;
  final PaymentGateway _payments;
  int _idSeq = 0;
  String _newId(String prefix) =>
      '${prefix}_${_clock().microsecondsSinceEpoch}_${_idSeq++}';

  AppUser? _user;
  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  /// Signed in but the onboarding wizard is not finished yet.
  bool get needsSetup => _user != null && !_user!.setupComplete;

  /// Locally picked avatar (uploaded to Storage once auth exists).
  Uint8List? photoBytes;

  ThemeMode themeMode = ThemeMode.light;

  /// Selected bottom-nav tab, so any screen can jump to another tab.
  int tabIndex = 0;

  late Wallet wallet;
  List<CoinTransaction> transactions = [];
  List<CoinTransfer> transfers = [];
  List<Payment> payments = [];
  List<RentalRequest> requests = [];
  List<RentalCompany> companies = [];
  List<AppUser> directory = [];

  // ---------------------------------------------------------------- session

  void signInAsGuest() {
    final mock = MockData(_clock());
    _user = mock.guest;
    wallet = mock.wallet;
    transactions = [...mock.transactions];
    transfers = [];
    payments = [];
    requests = [...mock.requests];
    companies = [...mock.companies];
    directory = [...mock.otherUsers];
    tabIndex = 0;
    notifyListeners();
  }

  void signOut() {
    _user = null;
    photoBytes = null;
    tabIndex = 0;
    notifyListeners();
  }

  void setTab(int index) {
    if (index == tabIndex) return;
    tabIndex = index;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ---------------------------------------------------------------- setup

  /// Finishes the onboarding wizard. For [UserRole.companyAdmin] call
  /// [registerCompany] first (the wizard does it on its business step).
  void completeSetup({
    required UserRole role,
    required String displayName,
    String? phone,
    String? city,
    DateTime? birthDate,
    String? venueName,
  }) {
    final u = _user;
    if (u == null) return;
    _user = u.copyWith(
      role: role,
      displayName: displayName.trim(),
      phone: phone?.trim(),
      city: city?.trim(),
      birthDate: birthDate,
      venueName: venueName?.trim(),
      setupComplete: true,
    );
    tabIndex = 0;
    notifyListeners();
  }

  // ---------------------------------------------------------------- profile

  void updateProfile({
    required String displayName,
    String? bio,
    String? city,
    String? phone,
    Uint8List? newPhoto,
  }) {
    final u = _user;
    if (u == null) return;
    _user = u.copyWith(
      displayName: displayName.trim(),
      bio: bio?.trim(),
      city: city?.trim(),
      phone: phone?.trim(),
    );
    if (newPhoto != null) photoBytes = newPhoto;
    notifyListeners();
  }

  // ---------------------------------------------------------------- lookups

  /// Any account (including the signed-in one) owning [code].
  AppUser? findUserByCode(String code) {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    if (_user?.referralCode == c) return _user;
    for (final u in directory) {
      if (u.referralCode == c) return u;
    }
    return null;
  }

  RentalRequest? requestById(String id) {
    for (final r in requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  RentalCompany? get myCompany {
    final u = _user;
    if (u == null) return null;
    for (final c in companies) {
      if (c.ownerUid == u.id) return c;
    }
    return null;
  }

  /// Only approved agencies can take requests.
  bool get canTakeRequests =>
      _user?.role == UserRole.companyAdmin && (myCompany?.isApproved ?? false);

  /// The feed: every prepaid request, newest first.
  List<RentalRequest> get publicRequests =>
      requests.where((r) => r.status.isPublic).toList()..sort(
        (a, b) => (b.paidAt ?? b.createdAt).compareTo(a.paidAt ?? a.createdAt),
      );

  /// Requests brought by the signed-in ambassador's code.
  List<RentalRequest> get myReferrals =>
      requests.where((r) => r.ambassadorId == _user?.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Requests the signed-in client created.
  List<RentalRequest> get myClientRequests =>
      requests.where((r) => r.clientId == _user?.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Requests the signed-in agency took.
  List<RentalRequest> get myAgencyRequests {
    final id = myCompany?.id;
    if (id == null) return const [];
    return requests.where((r) => r.companyId == id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Coins earned from referrals this calendar month.
  int get earnedThisMonth {
    final now = _clock();
    return transactions
        .where(
          (t) =>
              t.type == CoinTransactionType.referralEarning &&
              t.createdAt.year == now.year &&
              t.createdAt.month == now.month,
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  // ---------------------------------------------------------------- requests

  /// Checks a request before creating it. Returns an error or null.
  String? validateRequest({
    required String code,
    required DateTime startDate,
    required DateTime endDate,
    required double listPriceDt,
  }) {
    final ambassador = findUserByCode(code);
    if (code.trim().isEmpty) return 'Entrez le code d\'un ambassadeur.';
    if (ambassador == null) return 'Aucun ambassadeur avec ce code.';
    if (ambassador.id == _user?.id) {
      return 'Vous ne pouvez pas utiliser votre propre code.';
    }
    if (!ambassador.role.earnsCommission) {
      return 'Ce code n\'est pas un code ambassadeur.';
    }
    if (!endDate.isAfter(startDate)) {
      return 'La date de retour doit être après la date de départ.';
    }
    if (listPriceDt <= 0) return 'Indiquez le prix de la location.';
    return null;
  }

  /// Creates a request waiting for its 10 % prepayment.
  RentalRequest createRequest({
    required String code,
    required String carWanted,
    required CarCategory category,
    required String city,
    required DateTime startDate,
    required DateTime endDate,
    required double listPriceDt,
    String? phone,
    String? note,
    String? clientName,
  }) {
    final u = _user!;
    final ambassador = findUserByCode(code)!;
    final request = RentalRequest(
      id: _newId('rq'),
      referralCode: ambassador.referralCode,
      ambassadorId: ambassador.id,
      ambassadorName: ambassador.displayName,
      clientId: u.id,
      clientName: clientName ?? u.displayName,
      clientPhone: phone ?? u.phone,
      carWanted: carWanted.trim(),
      category: category,
      city: city.trim(),
      startDate: startDate,
      endDate: endDate,
      listPriceDt: listPriceDt,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      createdAt: _clock(),
    );
    requests = [request, ...requests];
    notifyListeners();
    return request;
  }

  /// Pays the 10 % prepayment with Click to Pay. On success the request opens
  /// in the feed and the ambassador receives 8 % in Dada Coins at once.
  /// Returns an error message or null.
  Future<String?> payPrepayment(String requestId) async {
    final r = requestById(requestId);
    if (r == null) return 'Demande introuvable.';
    if (r.isPaid) return null;
    final pricing = r.pricing;
    final result = await _payments.pay(
      amountMillimes: pricing.prepaymentMillimes,
      purpose: PaymentPurpose.prepayment,
      description: 'Acompte 10 % · ${r.carWanted}',
    );
    if (!result.succeeded) return result.error ?? 'Paiement refusé.';

    final now = _clock();
    final payment = Payment(
      id: _newId('pay'),
      userId: r.clientId,
      purpose: PaymentPurpose.prepayment,
      amountMillimes: pricing.prepaymentMillimes,
      status: PaymentStatus.succeeded,
      requestId: r.id,
      providerOrderId: result.orderId,
      createdAt: now,
      confirmedAt: now,
    );
    payments = [payment, ...payments];
    _replace(
      r.copyWith(
        status: RequestStatus.open,
        paymentId: payment.id,
        paidAt: now,
      ),
    );
    // Server-side this happens in the same transaction as the payment.
    if (r.ambassadorId == _user?.id) {
      _credit(
        pricing.ambassadorCoins,
        CoinTransactionType.referralEarning,
        title: 'Gain parrainage · ${r.maskedClientName}',
        subtitle:
            '${r.carWanted} · acompte ${Fmt.dinars(pricing.prepaymentDt)}',
        requestId: r.id,
      );
    }
    notifyListeners();
    return null;
  }

  /// Unpaid requests can be dropped; a paid prepayment is not refundable.
  void cancelUnpaidRequest(String requestId) {
    final r = requestById(requestId);
    if (r == null || r.isPaid) return;
    _replace(r.copyWith(status: RequestStatus.cancelled));
    notifyListeners();
  }

  /// An approved agency takes an open request and gets the client's phone.
  String? claimRequest(String requestId) {
    final r = requestById(requestId);
    final c = myCompany;
    if (r == null) return 'Demande introuvable.';
    if (!canTakeRequests || c == null) {
      return 'Seules les agences validées peuvent prendre une demande.';
    }
    if (r.status != RequestStatus.open) return 'Demande déjà prise.';
    _replace(
      r.copyWith(
        status: RequestStatus.claimed,
        companyId: c.id,
        companyName: c.name,
        claimedAt: _clock(),
      ),
    );
    notifyListeners();
    return null;
  }

  /// The agency that took the request marks it rented.
  String? completeRequest(String requestId, RentedCar car) {
    final r = requestById(requestId);
    if (r == null) return 'Demande introuvable.';
    if (r.status != RequestStatus.claimed || r.companyId != myCompany?.id) {
      return 'Seule l\'agence qui a pris la demande peut la terminer.';
    }
    _replace(
      r.copyWith(
        status: RequestStatus.completed,
        rentedCar: car,
        completedAt: _clock(),
      ),
    );
    notifyListeners();
    return null;
  }

  /// Guest demo for ambassadors: a fake client books with your code and
  /// prepays, so you can watch the coins arrive.
  Future<RentalRequest?> simulateClientRequest() async {
    final u = _user;
    if (u == null) return null;
    final now = _clock();
    final start = DateTime(now.year, now.month, now.day + 2);
    final request = RentalRequest(
      id: _newId('rq'),
      referralCode: u.referralCode,
      ambassadorId: u.id,
      ambassadorName: u.displayName,
      clientId: 'demo_client',
      clientName: 'Client Démo',
      clientPhone: '+216 99 000 000',
      carWanted: 'Volkswagen Polo',
      category: CarCategory.citadine,
      city: u.city ?? 'Tunis',
      startDate: start,
      endDate: start.add(const Duration(days: 3)),
      listPriceDt: 480,
      createdAt: now,
    );
    requests = [request, ...requests];
    final error = await payPrepayment(request.id);
    return error == null ? requestById(request.id) : null;
  }

  // ---------------------------------------------------------------- wallet

  /// Sends coins to the account owning [toCode]. Returns an error message,
  /// or null on success. Server-side this is a callable Cloud Function.
  String? transferCoins({
    required String toCode,
    required int amount,
    String? note,
  }) {
    final u = _user;
    if (u == null) return 'Connectez-vous pour envoyer des coins.';
    final error = CoinTransfer.validate(
      amount: amount,
      balance: wallet.balance,
      fromCode: u.referralCode,
      toCode: toCode,
    );
    if (error != null) return error;
    final recipient = findUserByCode(toCode);
    if (recipient == null || recipient.id == u.id) {
      return 'Aucun compte avec ce code.';
    }

    final transfer = CoinTransfer(
      id: _newId('tr'),
      fromUserId: u.id,
      fromName: u.displayName,
      toUserId: recipient.id,
      toName: recipient.displayName,
      toReferralCode: recipient.referralCode,
      amount: amount,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      status: TransferStatus.completed,
      createdAt: _clock(),
    );
    transfers = [transfer, ...transfers];
    _credit(
      -amount,
      CoinTransactionType.transferOut,
      title: 'Envoyé à ${recipient.displayName}',
      subtitle: transfer.note,
      transferId: transfer.id,
      counterpartyId: recipient.id,
      counterpartyName: recipient.displayName,
    );
    notifyListeners();
    return null;
  }

  /// Buys Dada Coins with Click to Pay (10 DC = 1 DT).
  Future<String?> buyCoins(int coins) async {
    final u = _user;
    if (u == null) return 'Connectez-vous pour acheter des coins.';
    if (coins < kMinCoinPurchase) {
      return 'Minimum ${Fmt.coins(kMinCoinPurchase)}.';
    }
    final millimes = coins * (1000 ~/ kCoinsPerDinar);
    final result = await _payments.pay(
      amountMillimes: millimes,
      purpose: PaymentPurpose.coinPurchase,
      description: 'Achat de ${Fmt.coins(coins)}',
    );
    if (!result.succeeded) return result.error ?? 'Paiement refusé.';
    final now = _clock();
    final payment = Payment(
      id: _newId('pay'),
      userId: u.id,
      purpose: PaymentPurpose.coinPurchase,
      amountMillimes: millimes,
      status: PaymentStatus.succeeded,
      providerOrderId: result.orderId,
      createdAt: now,
      confirmedAt: now,
    );
    payments = [payment, ...payments];
    _credit(
      coins,
      CoinTransactionType.purchase,
      title: 'Achat de coins',
      subtitle: 'Click to Pay · ${Fmt.dinars(millimes / 1000)}',
      paymentId: payment.id,
    );
    notifyListeners();
    return null;
  }

  void _credit(
    int amount,
    CoinTransactionType type, {
    required String title,
    String? subtitle,
    String? requestId,
    String? transferId,
    String? paymentId,
    String? counterpartyId,
    String? counterpartyName,
  }) {
    final u = _user!;
    wallet = wallet.copyWith(
      balance: wallet.balance + amount,
      lifetimeEarned: type == CoinTransactionType.referralEarning
          ? wallet.lifetimeEarned + amount
          : null,
    );
    transactions = [
      CoinTransaction(
        id: _newId('t'),
        userId: u.id,
        amount: amount,
        type: type,
        title: title,
        subtitle: subtitle,
        requestId: requestId,
        transferId: transferId,
        paymentId: paymentId,
        counterpartyId: counterpartyId,
        counterpartyName: counterpartyName,
        createdAt: _clock(),
      ),
      ...transactions,
    ];
  }

  void _replace(RentalRequest updated) {
    requests = [for (final r in requests) r.id == updated.id ? updated : r];
  }

  // ---------------------------------------------------------------- companies

  void registerCompany({
    required String name,
    required String taxRegistrationNumber,
    required String city,
    required String phone,
    String? address,
    String? email,
    String? contactName,
    String? rneNumber,
    int fleetSize = 0,
    Set<CompanyDocumentType> documents = const {},
    bool agreementAccepted = false,
  }) {
    final u = _user;
    if (u == null) return;
    final now = _clock();
    final docs = [
      for (final t in documents)
        CompanyDocument(
          type: t,
          status: DocumentStatus.submitted,
          submittedAt: now,
        ),
    ];
    final complete = documents.length == CompanyDocumentType.values.length;
    final company = RentalCompany(
      id: _newId('c'),
      name: name.trim(),
      ownerUid: u.id,
      city: city.trim(),
      phone: phone.trim(),
      address: address?.trim(),
      email: email?.trim(),
      taxRegistrationNumber: taxRegistrationNumber.trim(),
      contactName: contactName?.trim(),
      rneNumber: rneNumber?.trim(),
      fleetSize: fleetSize,
      documents: docs,
      agreementAcceptedAt: agreementAccepted ? now : null,
      status: complete && agreementAccepted
          ? CompanyStatus.pending
          : CompanyStatus.draft,
      createdAt: now,
    );
    companies = [...companies.where((c) => c.ownerUid != u.id), company];
    _user = u.copyWith(companyId: company.id);
    notifyListeners();
  }

  /// Marks one more paper as sent; the file is pending once all are in.
  void submitCompanyDocument(CompanyDocumentType type) {
    final c = myCompany;
    if (c == null) return;
    final docs = [
      ...c.documents.where((d) => d.type != type),
      CompanyDocument(
        type: type,
        status: DocumentStatus.submitted,
        submittedAt: _clock(),
      ),
    ];
    final complete = CompanyDocumentType.values.every(
      (t) => docs.any((d) => d.type == t),
    );
    _replaceCompany(
      c.copyWith(
        documents: docs,
        status: complete && c.agreementAcceptedAt != null
            ? CompanyStatus.pending
            : c.status,
      ),
    );
    notifyListeners();
  }

  /// Guest demo only: what the Dada team does after checking the documents.
  void demoApproveMyCompany() {
    final c = myCompany;
    if (c == null || !(_user?.isGuest ?? false)) return;
    _replaceCompany(c.copyWith(status: CompanyStatus.approved));
    notifyListeners();
  }

  void _replaceCompany(RentalCompany updated) {
    companies = [for (final x in companies) x.id == updated.id ? updated : x];
  }
}

/// Exposes [AppState] to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  /// Subscribes the caller to changes.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// One-off access (callbacks) without subscribing.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
