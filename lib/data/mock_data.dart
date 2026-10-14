import '../core/formatters.dart';
import '../models/models.dart';

/// Demo content for guest mode. The guest is Yasmine, an ambassador whose
/// code YASMINE20 brought three prepaid requests (one of them the Mercedes
/// G-Class example: 700 DT due -> 70 DT prepaid -> 560 DC for Yasmine).
/// Replace with Firestore reads once authentication is wired.
class MockData {
  MockData(this.now);

  final DateTime now;

  DateTime _ago({int days = 0, int hours = 0}) =>
      now.subtract(Duration(days: days, hours: hours));

  DateTime _in(int days) =>
      DateTime(now.year, now.month, now.day).add(Duration(days: days));

  late final AppUser guest = AppUser(
    id: 'u_yasmine',
    displayName: 'Yasmine B.',
    bio: 'Créatrice TikTok · road trips en Tunisie 🚗',
    city: 'Tunis',
    phone: '+216 22 345 678',
    authProvider: AuthProviderType.guest,
    referralCode: 'YASMINE20',
    isIdVerified: true,
    birthDate: DateTime(2001, 5, 14),
    createdAt: _ago(days: 120),
  );

  late final List<AppUser> otherUsers = [
    AppUser(
      id: 'u_sara',
      displayName: 'Sara K.',
      authProvider: AuthProviderType.facebook,
      referralCode: 'SARA11',
      city: 'Sousse',
      setupComplete: true,
      createdAt: _ago(days: 90),
    ),
    AppUser(
      id: 'u_amine',
      displayName: 'Amine B.',
      authProvider: AuthProviderType.google,
      referralCode: 'AMINE14',
      city: 'Sfax',
      setupComplete: true,
      createdAt: _ago(days: 200),
    ),
    AppUser(
      id: 'u_karim',
      displayName: 'Karim M.',
      authProvider: AuthProviderType.whatsapp,
      referralCode: 'KARIM05',
      city: 'Tunis',
      setupComplete: true,
      createdAt: _ago(days: 45),
    ),
    AppUser(
      id: 'u_mehdi',
      displayName: 'Hôtel Les Pins',
      role: UserRole.partner,
      authProvider: AuthProviderType.google,
      referralCode: 'LESPINS',
      venueName: 'Hôtel Les Pins',
      city: 'Hammamet',
      setupComplete: true,
      createdAt: _ago(days: 60),
    ),
    AppUser(
      id: 'u_dada',
      displayName: 'Dada Rent Car',
      role: UserRole.companyAdmin,
      authProvider: AuthProviderType.google,
      referralCode: 'DADA',
      companyId: 'c_dada',
      city: 'Tunis',
      setupComplete: true,
      createdAt: _ago(days: 400),
    ),
  ];

  late final List<RentalCompany> companies = [
    RentalCompany(
      id: 'c_dada',
      name: 'Dada Rent Car',
      ownerUid: 'u_dada',
      city: 'Tunis',
      phone: '+216 70 000 000',
      taxRegistrationNumber: '1234567/A/M/000',
      fleetSize: 85,
      isFlagship: true,
      status: CompanyStatus.approved,
      createdAt: _ago(days: 400),
    ),
    RentalCompany(
      id: 'c_sahara',
      name: 'Sahara Cars',
      ownerUid: 'u_sahara',
      city: 'Djerba',
      phone: '+216 75 000 000',
      taxRegistrationNumber: '7654321/B/M/000',
      fleetSize: 32,
      status: CompanyStatus.approved,
      createdAt: _ago(days: 30),
    ),
  ];

  late final List<RentalRequest> requests = [
    RentalRequest(
      id: 'rq1',
      referralCode: 'YASMINE20',
      ambassadorId: guest.id,
      ambassadorName: guest.displayName,
      clientId: 'c_sami',
      clientName: 'Sami Ben Ali',
      clientPhone: '+216 98 111 222',
      carWanted: 'Mercedes-Benz Classe G',
      category: CarCategory.luxe,
      city: 'Tunis',
      startDate: _in(3),
      endDate: _in(6),
      note: 'Pour un mariage, livraison à l\'hôtel si possible.',
      // 700 DT after the −5 % code discount.
      listPriceDt: 736.842,
      status: RequestStatus.open,
      paymentId: 'pay_rq1',
      paidAt: _ago(hours: 2),
      createdAt: _ago(hours: 2),
    ),
    RentalRequest(
      id: 'rq4',
      referralCode: 'SARA11',
      ambassadorId: 'u_sara',
      ambassadorName: 'Sara K.',
      clientId: 'c_leila',
      clientName: 'Leïla Trabelsi',
      clientPhone: '+216 55 444 333',
      carWanted: 'Peugeot 3008 automatique',
      category: CarCategory.suv,
      city: 'Tunis',
      startDate: _in(5),
      endDate: _in(10),
      listPriceDt: 1400,
      status: RequestStatus.open,
      paymentId: 'pay_rq4',
      paidAt: _ago(hours: 5),
      createdAt: _ago(hours: 5),
    ),
    RentalRequest(
      id: 'rq2',
      referralCode: 'YASMINE20',
      ambassadorId: guest.id,
      ambassadorName: guest.displayName,
      clientId: 'c_maha',
      clientName: 'Maha Jlassi',
      clientPhone: '+216 20 555 666',
      carWanted: 'Kia Picanto ou équivalent',
      category: CarCategory.citadine,
      city: 'Sousse',
      startDate: _in(1),
      endDate: _in(5),
      listPriceDt: 600,
      status: RequestStatus.claimed,
      paymentId: 'pay_rq2',
      paidAt: _ago(days: 1),
      companyId: 'c_dada',
      companyName: 'Dada Rent Car',
      claimedAt: _ago(hours: 20),
      createdAt: _ago(days: 1),
    ),
    RentalRequest(
      id: 'rq5',
      referralCode: 'KARIM05',
      ambassadorId: 'u_karim',
      ambassadorName: 'Karim M.',
      clientId: 'c_omar',
      clientName: 'Omar Gharbi',
      clientPhone: '+216 23 777 888',
      carWanted: 'Hyundai i10',
      category: CarCategory.citadine,
      city: 'Djerba',
      startDate: _in(2),
      endDate: _in(4),
      listPriceDt: 240,
      status: RequestStatus.open,
      paymentId: 'pay_rq5',
      paidAt: _ago(days: 1, hours: 4),
      createdAt: _ago(days: 1, hours: 4),
    ),
    RentalRequest(
      id: 'rq3',
      referralCode: 'YASMINE20',
      ambassadorId: guest.id,
      ambassadorName: guest.displayName,
      clientId: 'c_rachid',
      clientName: 'Rachid Mansour',
      clientPhone: '+216 50 999 000',
      carWanted: 'Renault Clio ou similaire',
      category: CarCategory.compacte,
      city: 'Hammamet',
      startDate: _ago(days: 6),
      endDate: _ago(days: 3),
      listPriceDt: 450,
      status: RequestStatus.completed,
      paymentId: 'pay_rq3',
      paidAt: _ago(days: 9),
      companyId: 'c_sahara',
      companyName: 'Sahara Cars',
      claimedAt: _ago(days: 8),
      rentedCar: const RentedCar(
        model: 'Renault Clio 5',
        plate: '215 TU 4321',
        finalPriceDt: 427.5,
      ),
      completedAt: _ago(days: 3),
      createdAt: _ago(days: 9),
    ),
    RentalRequest(
      id: 'rq6',
      referralCode: 'LESPINS',
      ambassadorId: 'u_mehdi',
      ambassadorName: 'Hôtel Les Pins',
      clientId: 'c_nour',
      clientName: 'Nour Haddad',
      clientPhone: '+216 52 123 456',
      carWanted: 'Volkswagen Golf 8',
      category: CarCategory.berline,
      city: 'Hammamet',
      startDate: _ago(days: 4),
      endDate: _ago(days: 1),
      listPriceDt: 660,
      status: RequestStatus.completed,
      paymentId: 'pay_rq6',
      paidAt: _ago(days: 6),
      companyId: 'c_dada',
      companyName: 'Dada Rent Car',
      claimedAt: _ago(days: 6),
      rentedCar: const RentedCar(model: 'Volkswagen Golf 8', finalPriceDt: 627),
      completedAt: _ago(days: 1),
      createdAt: _ago(days: 6),
    ),
  ];

  /// Yasmine's ledger: one 8 % earning per paid request with her code, plus
  /// a transfer in and out.
  late final List<CoinTransaction> transactions = [
    for (final r in requests.where((r) => r.ambassadorId == guest.id))
      CoinTransaction(
        id: 't_${r.id}',
        userId: guest.id,
        amount: r.pricing.ambassadorCoins,
        type: CoinTransactionType.referralEarning,
        title: 'Gain parrainage · ${r.maskedClientName}',
        subtitle:
            '${r.carWanted} · acompte ${Fmt.dinars(r.pricing.prepaymentDt)}',
        requestId: r.id,
        createdAt: r.paidAt!,
      ),
    CoinTransaction(
      id: 't_out',
      userId: guest.id,
      amount: -50,
      type: CoinTransactionType.transferOut,
      title: 'Envoyé à Sara K.',
      subtitle: 'Merci pour le coup de main !',
      counterpartyId: 'u_sara',
      counterpartyName: 'Sara K.',
      createdAt: _ago(days: 2),
    ),
    CoinTransaction(
      id: 't_in',
      userId: guest.id,
      amount: 50,
      type: CoinTransactionType.transferIn,
      title: 'Reçu de Karim M.',
      counterpartyId: 'u_karim',
      counterpartyName: 'Karim M.',
      createdAt: _ago(days: 3),
    ),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  late final Wallet wallet = Wallet(
    userId: guest.id,
    balance: transactions.fold(0, (sum, t) => sum + t.amount),
    lifetimeEarned: transactions
        .where((t) => t.type == CoinTransactionType.referralEarning)
        .fold(0, (sum, t) => sum + t.amount),
    updatedAt: _ago(hours: 2),
  );
}
