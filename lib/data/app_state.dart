import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/models.dart';
import 'mock_data.dart';

/// App-wide session state.
///
/// For now everything is backed by [MockData] (guest mode). When auth lands,
/// the same public API is fed from Firestore streams and the mutating methods
/// call Cloud Functions (transfers, redemptions) instead of editing lists.
class AppState extends ChangeNotifier {
  AppState({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  int _idSeq = 0;
  String _newId(String prefix) =>
      '${prefix}_${_clock().microsecondsSinceEpoch}_${_idSeq++}';

  AppUser? _user;
  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  /// Locally picked avatar (uploaded to Storage once auth exists).
  Uint8List? photoBytes;

  ThemeMode themeMode = ThemeMode.light;

  /// Selected bottom-nav tab, so any screen can jump to another tab.
  int tabIndex = 0;

  late Wallet wallet;
  List<CoinTransaction> transactions = [];
  List<CoinTransfer> transfers = [];
  List<Post> posts = [];
  List<Car> cars = [];
  List<RentalCompany> companies = [];
  List<AppUser> directory = [];
  List<Referral> referrals = [];
  ReferralStats stats = const ReferralStats();
  List<Reward> rewards = [];
  List<Redemption> redemptions = [];
  Challenge? challenge;
  List<AchievementBadge> badges = [];
  List<LeaderboardEntry> leaderboard = [];
  Map<String, List<Comment>> comments = {};

  /// Signed in but the onboarding wizard is not finished yet.
  bool get needsSetup => _user != null && !_user!.setupComplete;

  // ---------------------------------------------------------------- session

  void signInAsGuest() {
    final mock = MockData(_clock());
    _user = mock.guest;
    wallet = mock.wallet;
    transactions = [...mock.transactions];
    transfers = [];
    posts = [...mock.posts];
    cars = [...mock.cars];
    companies = [...mock.companies];
    directory = [...mock.otherUsers];
    referrals = [...mock.referrals];
    stats = mock.stats;
    rewards = [...mock.rewards];
    redemptions = [];
    challenge = mock.challenge;
    badges = [...mock.badges];
    leaderboard = [...mock.leaderboard];
    comments = {
      for (final e in mock.comments.entries) e.key: [...e.value],
    };
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

  AppUser? findUserByCode(String code) {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    for (final u in directory) {
      if (u.referralCode == c) return u;
    }
    return null;
  }

  Car? carById(String? id) {
    for (final c in cars) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Companies visible in the marketplace.
  List<RentalCompany> get approvedCompanies =>
      companies.where((c) => c.isApproved).toList();

  /// Company the current user registered, if any.
  RentalCompany? get myCompany {
    final u = _user;
    if (u == null) return null;
    for (final c in companies) {
      if (c.ownerUid == u.id) return c;
    }
    return null;
  }

  /// Coins of referrals not yet validated (booked, running or in the hold).
  int get expectedCoins => referrals
      .where(
        (r) =>
            r.status == ReferralStatus.booked ||
            r.status == ReferralStatus.inProgress ||
            r.status == ReferralStatus.returned,
      )
      .fold(0, (sum, r) => sum + r.coins);

  // ---------------------------------------------------------------- feed

  void toggleLike(String postId) {
    posts = [
      for (final p in posts)
        if (p.id == postId)
          p.copyWith(
            likedByMe: !p.likedByMe,
            likeCount: p.likeCount + (p.likedByMe ? -1 : 1),
          )
        else
          p,
    ];
    notifyListeners();
  }

  List<Comment> commentsFor(String postId) => comments[postId] ?? const [];

  /// Adds a comment and bumps the post's counter. Returns false when empty.
  bool addComment(String postId, String text) {
    final u = _user;
    final body = text.trim();
    if (u == null || body.isEmpty) return false;
    final comment = Comment(
      id: _newId('cm'),
      postId: postId,
      authorId: u.id,
      authorName: u.displayName,
      authorRole: u.role,
      text: body,
      createdAt: _clock(),
    );
    comments = {
      ...comments,
      postId: [...commentsFor(postId), comment],
    };
    posts = [
      for (final p in posts)
        if (p.id == postId) p.copyWith(commentCount: p.commentCount + 1) else p,
    ];
    notifyListeners();
    return true;
  }

  void registerShare(String postId) {
    posts = [
      for (final p in posts)
        if (p.id == postId) p.copyWith(shareCount: p.shareCount + 1) else p,
    ];
    notifyListeners();
  }

  void publishPost({required String text, Car? car, bool sponsored = false}) {
    final u = _user;
    if (u == null) return;
    posts = [
      Post(
        id: _newId('p'),
        authorId: u.id,
        authorName: u.displayName,
        authorRole: u.role,
        authorTier: u.tier,
        type: car == null ? PostType.status : PostType.carPromo,
        text: text.trim(),
        carId: car?.id,
        carModel: car?.model,
        carPricePerDay: car?.pricePerDay,
        carCompanyName: car?.companyName,
        referralCode: car == null ? null : u.referralCode,
        isSponsored: sponsored,
        createdAt: _clock(),
      ),
      ...posts,
    ];
    notifyListeners();
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
    if (recipient == null) return 'Aucun compte avec ce code.';

    final now = _clock();
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
      createdAt: now,
    );
    transfers = [transfer, ...transfers];
    wallet = wallet.copyWith(balance: wallet.balance - amount);
    transactions = [
      CoinTransaction(
        id: _newId('t'),
        userId: u.id,
        amount: -amount,
        type: CoinTransactionType.transferOut,
        title: 'Envoyé à ${recipient.displayName}',
        subtitle: transfer.note,
        transferId: transfer.id,
        counterpartyId: recipient.id,
        counterpartyName: recipient.displayName,
        createdAt: now,
      ),
      ...transactions,
    ];
    notifyListeners();
    return null;
  }

  /// Reserves coins for a reward. Returns an error message or null.
  String? redeem(Reward reward) {
    final u = _user;
    if (u == null) return 'Connectez-vous pour échanger vos coins.';
    if (!reward.inStock) return 'Ce cadeau est en rupture de stock.';
    if (reward.priceCoins > wallet.balance) return 'Solde insuffisant.';
    if (reward.requiresIdCheck && !u.isIdVerified) {
      return 'Envoyez une photo de votre CIN pour les cadeaux de plus de 5 000 DC.';
    }
    final now = _clock();
    final redemption = Redemption(
      id: _newId('rd'),
      userId: u.id,
      rewardId: reward.id,
      rewardTitle: reward.title,
      coins: reward.priceCoins,
      createdAt: now,
    );
    redemptions = [redemption, ...redemptions];
    wallet = wallet.copyWith(balance: wallet.balance - reward.priceCoins);
    transactions = [
      CoinTransaction(
        id: _newId('t'),
        userId: u.id,
        amount: -reward.priceCoins,
        type: CoinTransactionType.redemption,
        title: reward.title,
        subtitle: RedemptionStatus.reserved.label,
        redemptionId: redemption.id,
        createdAt: now,
      ),
      ...transactions,
    ];
    notifyListeners();
    return null;
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
    final now = _clock();
    final docs = [
      ...c.documents.where((d) => d.type != type),
      CompanyDocument(
        type: type,
        status: DocumentStatus.submitted,
        submittedAt: now,
      ),
    ];
    final complete = CompanyDocumentType.values.every(
      (t) => docs.any((d) => d.type == t),
    );
    final updated = RentalCompany(
      id: c.id,
      name: c.name,
      ownerUid: c.ownerUid,
      city: c.city,
      phone: c.phone,
      taxRegistrationNumber: c.taxRegistrationNumber,
      createdAt: c.createdAt,
      logoUrl: c.logoUrl,
      address: c.address,
      email: c.email,
      contactName: c.contactName,
      rneNumber: c.rneNumber,
      fleetSize: c.fleetSize,
      customerDiscountRate: c.customerDiscountRate,
      documents: docs,
      agreementAcceptedAt: c.agreementAcceptedAt,
      status: complete && c.agreementAcceptedAt != null
          ? CompanyStatus.pending
          : c.status,
    );
    companies = [for (final x in companies) x.id == c.id ? updated : x];
    notifyListeners();
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
