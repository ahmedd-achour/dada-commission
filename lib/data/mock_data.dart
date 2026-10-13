import '../core/constants.dart';
import '../models/models.dart';

/// Demo content for guest mode, built around the concept's example
/// (Yasmine, Gold level, 184 DC after a 684 DC commission and a 50 DT voucher).
/// Replace with Firestore reads once authentication is wired.
class MockData {
  MockData(this.now);

  final DateTime now;

  DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
      now.subtract(Duration(days: days, hours: hours, minutes: minutes));

  static DateTime _expiry(DateTime earnedAt) => DateTime(
    earnedAt.year,
    earnedAt.month + kCoinsExpiryMonths,
    earnedAt.day,
  );

  late final AppUser guest = AppUser(
    id: 'u_yasmine',
    displayName: 'Yasmine B.',
    bio: 'Créatrice TikTok · road trips en Tunisie 🚗',
    city: 'Tunis',
    phone: '+216 22 345 678',
    authProvider: AuthProviderType.guest,
    referralCode: 'YASMINE20',
    tier: AmbassadorTier.gold,
    completedRentals3m: 10,
    isIdVerified: true,
    createdAt: _ago(days: 120),
  );

  late final List<AppUser> otherUsers = [
    AppUser(
      id: 'u_dada',
      displayName: 'Dada Rent Car',
      role: UserRole.companyAdmin,
      authProvider: AuthProviderType.google,
      referralCode: 'DADA',
      companyId: 'c_dada',
      city: 'Tunis',
      createdAt: _ago(days: 400),
    ),
    AppUser(
      id: 'u_sara',
      displayName: 'Sara K.',
      authProvider: AuthProviderType.facebook,
      referralCode: 'SARA11',
      tier: AmbassadorTier.gold,
      completedRentals3m: 11,
      city: 'Sousse',
      createdAt: _ago(days: 90),
    ),
    AppUser(
      id: 'u_amine',
      displayName: 'Amine B.',
      authProvider: AuthProviderType.google,
      referralCode: 'AMINE14',
      tier: AmbassadorTier.gold,
      completedRentals3m: 14,
      city: 'Sfax',
      createdAt: _ago(days: 200),
    ),
    AppUser(
      id: 'u_karim',
      displayName: 'Karim M.',
      authProvider: AuthProviderType.whatsapp,
      referralCode: 'KARIM05',
      tier: AmbassadorTier.silver,
      completedRentals3m: 4,
      bio: 'Étudiant · lien envoyé sur WhatsApp',
      city: 'Tunis',
      createdAt: _ago(days: 45),
    ),
    AppUser(
      id: 'u_mehdi',
      displayName: 'Hôtel Les Pins',
      role: UserRole.partner,
      authProvider: AuthProviderType.google,
      referralCode: 'LESPINS',
      city: 'Hammamet',
      createdAt: _ago(days: 60),
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

  late final List<Car> cars = [
    const Car(
      id: 'car_picanto',
      companyId: 'c_dada',
      companyName: 'Dada Rent Car',
      model: 'Kia Picanto',
      category: CarCategory.citadine,
      pricePerDay: 150,
      city: 'Tunis',
      seats: 4,
    ),
    const Car(
      id: 'car_clio',
      companyId: 'c_dada',
      companyName: 'Dada Rent Car',
      model: 'Renault Clio 5',
      category: CarCategory.compacte,
      pricePerDay: 170,
      city: 'Tunis',
    ),
    const Car(
      id: 'car_3008',
      companyId: 'c_dada',
      companyName: 'Dada Rent Car',
      model: 'Peugeot 3008',
      category: CarCategory.suv,
      pricePerDay: 280,
      city: 'Tunis',
      transmission: Transmission.automatic,
    ),
    const Car(
      id: 'car_doblo',
      companyId: 'c_dada',
      companyName: 'Dada Rent Car',
      model: 'Fiat Doblò',
      category: CarCategory.utilitaire,
      pricePerDay: 190,
      city: 'Ben Arous',
      seats: 2,
    ),
    const Car(
      id: 'car_i10',
      companyId: 'c_sahara',
      companyName: 'Sahara Cars',
      model: 'Hyundai i10',
      category: CarCategory.citadine,
      pricePerDay: 120,
      city: 'Djerba',
      seats: 4,
    ),
    const Car(
      id: 'car_golf',
      companyId: 'c_sahara',
      companyName: 'Sahara Cars',
      model: 'Volkswagen Golf 8',
      category: CarCategory.berline,
      pricePerDay: 220,
      city: 'Djerba',
      transmission: Transmission.automatic,
    ),
  ];

  late final List<Post> posts = [
    Post(
      id: 'p1',
      authorId: guest.id,
      authorName: guest.displayName,
      authorTier: guest.tier,
      type: PostType.carPromo,
      text:
          '3 jours à Hammamet à 150 DT/jour.\n'
          'Réservez avec mon code YASMINE20 : −5 % 🌊 #sponsorisé',
      carId: 'car_picanto',
      carModel: 'Kia Picanto',
      carPricePerDay: 150,
      carCompanyName: 'Dada Rent Car',
      referralCode: guest.referralCode,
      isSponsored: true,
      likeCount: 48,
      commentCount: 6,
      shareCount: 12,
      createdAt: _ago(hours: 2),
    ),
    Post(
      id: 'p2',
      authorId: 'u_dada',
      authorName: 'Dada Rent Car',
      authorRole: UserRole.companyAdmin,
      type: PostType.challenge,
      text:
          "🏆 Défi d'octobre : 5 locations terminées = +500 DC !\n"
          'Fin le 31 octobre. Partagez vos codes 🚀',
      likeCount: 132,
      commentCount: 21,
      shareCount: 40,
      createdAt: _ago(hours: 6),
    ),
    Post(
      id: 'p3',
      authorId: 'u_sara',
      authorName: 'Sara K.',
      authorTier: AmbassadorTier.gold,
      type: PostType.status,
      text:
          'Mon 11e client ce mois-ci 🎉 Merci à tous ceux qui ont réservé '
          'avec SARA11 !',
      likeCount: 27,
      commentCount: 4,
      createdAt: _ago(hours: 9),
    ),
    Post(
      id: 'p4',
      authorId: 'u_amine',
      authorName: 'Amine B.',
      authorTier: AmbassadorTier.gold,
      type: PostType.carPromo,
      text: 'SUV automatique pour un week-end en famille. Code AMINE14 = −5 %',
      carId: 'car_3008',
      carModel: 'Peugeot 3008',
      carPricePerDay: 280,
      carCompanyName: 'Dada Rent Car',
      referralCode: 'AMINE14',
      likeCount: 19,
      commentCount: 2,
      shareCount: 3,
      createdAt: _ago(days: 1, hours: 3),
    ),
    Post(
      id: 'p5',
      authorId: 'u_mehdi',
      authorName: 'Hôtel Les Pins',
      authorRole: UserRole.partner,
      type: PostType.carPromo,
      text:
          'Nos clients peuvent réserver une voiture directement depuis la '
          'réception grâce au QR code 📍 Hammamet',
      carId: 'car_i10',
      carModel: 'Hyundai i10',
      carPricePerDay: 120,
      carCompanyName: 'Sahara Cars',
      referralCode: 'LESPINS',
      likeCount: 11,
      createdAt: _ago(days: 2),
    ),
  ];

  late final List<Referral> referrals = [
    Referral(
      id: 'r1',
      ambassadorId: guest.id,
      referralCode: guest.referralCode,
      companyId: 'c_dada',
      carId: 'car_picanto',
      carModel: 'Citadine',
      customerMaskedName: Referral.maskName('Sami'),
      rentalDays: 3,
      pricePerDay: 150,
      commissionRate: AmbassadorTier.gold.commissionRate,
      status: ReferralStatus.validated,
      bookedAt: _ago(days: 16),
      startDate: _ago(days: 13),
      returnedAt: _ago(days: 10),
    ),
    Referral(
      id: 'r2',
      ambassadorId: guest.id,
      referralCode: guest.referralCode,
      companyId: 'c_dada',
      carId: 'car_clio',
      carModel: 'Compacte',
      customerMaskedName: Referral.maskName('Maha'),
      source: ReferralSource.link,
      rentalDays: 2,
      pricePerDay: 170,
      commissionRate: AmbassadorTier.gold.commissionRate,
      status: ReferralStatus.booked,
      bookedAt: _ago(days: 1),
      startDate: now.add(Duration(days: (DateTime.saturday - now.weekday) % 7)),
    ),
    Referral(
      id: 'r3',
      ambassadorId: guest.id,
      referralCode: guest.referralCode,
      companyId: 'c_sahara',
      carId: 'car_i10',
      carModel: 'Citadine',
      customerMaskedName: Referral.maskName('Rachid'),
      source: ReferralSource.qr,
      rentalDays: 4,
      pricePerDay: 120,
      commissionRate: AmbassadorTier.gold.commissionRate,
      status: ReferralStatus.cancelled,
      bookedAt: _ago(days: 5),
    ),
  ];

  final ReferralStats stats = const ReferralStats(
    clicks: 120,
    bookings: 3,
    completed: 1,
  );

  late final Wallet wallet = Wallet(
    userId: guest.id,
    balance: 184,
    lifetimeEarned: 734,
    updatedAt: _ago(days: 2),
  );

  late final List<CoinTransaction> transactions = [
    CoinTransaction(
      id: 't4',
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
      id: 't3',
      userId: guest.id,
      amount: 50,
      type: CoinTransactionType.transferIn,
      title: 'Reçu de Karim M.',
      counterpartyId: 'u_karim',
      counterpartyName: 'Karim M.',
      createdAt: _ago(days: 3),
      expiresAt: _expiry(_ago(days: 3)),
    ),
    CoinTransaction(
      id: 't2',
      userId: guest.id,
      amount: -500,
      type: CoinTransactionType.redemption,
      title: "Bon d'achat",
      subtitle: 'supermarché, 50 DT',
      createdAt: _ago(days: 2, hours: 5),
    ),
    CoinTransaction(
      id: 't1',
      userId: guest.id,
      amount: 684,
      type: CoinTransactionType.commission,
      title: 'Commission location',
      subtitle: '3 jours via YASMINE20',
      referralId: 'r1',
      createdAt: _ago(days: 3, hours: 1),
      expiresAt: _expiry(_ago(days: 3)),
    ),
  ];

  final List<Reward> rewards = const [
    Reward(
      id: 'rw_v20',
      title: "Bon d'achat 20 DT",
      category: RewardCategory.voucher,
      priceCoins: 200,
      description: 'Grandes surfaces partenaires.',
    ),
    Reward(
      id: 'rw_v50',
      title: "Bon d'achat 50 DT",
      category: RewardCategory.voucher,
      priceCoins: 500,
      description: 'Grandes surfaces partenaires.',
    ),
    Reward(
      id: 'rw_v100',
      title: "Bon d'achat 100 DT",
      category: RewardCategory.voucher,
      priceCoins: 1000,
      description: 'Grandes surfaces partenaires.',
    ),
    Reward(
      id: 'rw_phone',
      title: 'Smartphone',
      category: RewardCategory.phone,
      priceCoins: 9000,
      stock: 5,
      description: 'Smartphone milieu de gamme, garantie 1 an.',
    ),
    Reward(
      id: 'rw_tablet',
      title: 'Tablette',
      category: RewardCategory.tablet,
      priceCoins: 6000,
      stock: 3,
      description: 'Tablette 10 pouces.',
    ),
    Reward(
      id: 'rw_day',
      title: '1 jour de location',
      category: RewardCategory.rental,
      priceCoins: 1500,
      description: 'Une journée offerte chez Dada Rent Car.',
    ),
    Reward(
      id: 'rw_upgrade',
      title: 'Voiture plus grande',
      category: RewardCategory.rental,
      priceCoins: 800,
      description: 'Surclassement sur votre prochaine location.',
    ),
    Reward(
      id: 'rw_topup',
      title: 'Recharge 10 DT',
      category: RewardCategory.topUp,
      priceCoins: 100,
      description: 'Recharge téléphone ou internet mobile.',
    ),
    Reward(
      id: 'rw_buds',
      title: 'Écouteurs sans fil',
      category: RewardCategory.leisure,
      priceCoins: 1200,
    ),
    Reward(
      id: 'rw_fuel',
      title: 'Bon carburant 30 DT',
      category: RewardCategory.leisure,
      priceCoins: 300,
    ),
  ];

  late final Challenge challenge = Challenge(
    id: 'ch_oct',
    title: "Défi d'octobre",
    description: '5 locations terminées = +500 DC',
    target: 5,
    bonusCoins: 500,
    progress: 2,
    startsAt: DateTime(now.year, now.month, 1),
    endsAt: DateTime(now.year, now.month + 1, 0),
  );

  final List<AchievementBadge> badges = const [
    AchievementBadge(
      id: 'b1',
      label: '1er client',
      shortLabel: '1',
      earned: true,
    ),
    AchievementBadge(
      id: 'b10',
      label: '10 clients',
      shortLabel: '10',
      earned: true,
    ),
    AchievementBadge(
      id: 'bv',
      label: 'Vérifiée',
      shortLabel: '✓',
      earned: true,
    ),
    AchievementBadge(id: 'b50', label: '50 clients', shortLabel: '50'),
  ];

  late final List<LeaderboardEntry> leaderboard = [
    const LeaderboardEntry(
      rank: 1,
      userId: 'u_amine',
      displayName: 'Amine B.',
      completedRentals: 14,
    ),
    const LeaderboardEntry(
      rank: 2,
      userId: 'u_sara',
      displayName: 'Sara K.',
      completedRentals: 11,
    ),
    LeaderboardEntry(
      rank: 3,
      userId: guest.id,
      displayName: 'Vous (Yasmine)',
      completedRentals: 10,
      isMe: true,
    ),
    const LeaderboardEntry(
      rank: 4,
      userId: 'u_karim',
      displayName: 'Karim M.',
      completedRentals: 4,
    ),
  ];
}
