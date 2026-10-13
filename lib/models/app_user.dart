import '../core/constants.dart';
import 'ambassador_tier.dart';
import 'json_utils.dart';

/// How the account signed in. Only these three providers are planned;
/// [guest] is the temporary mock-data mode used until auth is wired.
enum AuthProviderType {
  google('Google'),
  facebook('Facebook'),
  whatsapp('WhatsApp'),
  guest('Invité');

  const AuthProviderType(this.label);
  final String label;
}

/// What the account does in the app ("Les acteurs" in the concept).
enum UserRole {
  /// Anyone 18+ who shares a code/link (Yasmine, Karim).
  ambassador('Ambassadeur'),

  /// A venue (hotel, agency…) with a QR code at the reception (Mehdi).
  partner('Partenaire'),

  /// Owner/manager of a rent-car company registered on the platform.
  companyAdmin('Agence de location'),

  /// Dada team: validates commissions, ships rewards (Leïla).
  staff('Équipe Dada');

  const UserRole(this.label);
  final String label;
}

/// Profile document: `users/{uid}`.
///
/// Balances live in `wallets/{uid}` (see wallet.dart), never here, so the
/// profile can be client-editable while the wallet stays server-only.
class AppUser {
  final String id;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final String? city;
  final String? phone;
  final String? email;
  final AuthProviderType authProvider;
  final UserRole role;

  /// Unique, uppercase code (e.g. `YASMINE20`). Also reserved in
  /// `referralCodes/{code}` -> `{uid}` so uniqueness can be enforced.
  final String referralCode;

  final AmbassadorTier tier;

  /// Completed rentals over the last 3 months (drives [tier]).
  final int completedRentals3m;

  /// Set when the user owns/manages a rent-car company.
  final String? companyId;

  /// CIN checked once (needed for rewards above 5 000 DC).
  final bool isIdVerified;
  final bool isBanned;
  final DateTime? birthDate;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.displayName,
    required this.authProvider,
    required this.referralCode,
    required this.createdAt,
    this.role = UserRole.ambassador,
    this.tier = AmbassadorTier.bronze,
    this.completedRentals3m = 0,
    this.photoUrl,
    this.bio,
    this.city,
    this.phone,
    this.email,
    this.companyId,
    this.isIdVerified = false,
    this.isBanned = false,
    this.birthDate,
  });

  String get referralLink => '$kReferralBaseUrl$referralCode';

  bool get isGuest => authProvider == AuthProviderType.guest;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty).take(2).map((p) => p[0]);
    return letters.join().toUpperCase();
  }

  /// "Ambassadeur Or", "Agence de location"…
  String get headline =>
      role == UserRole.ambassador ? '${role.label} ${tier.label}' : role.label;

  factory AppUser.fromJson(String id, Map<String, dynamic> json) => AppUser(
    id: id,
    displayName: readString(json['displayName'], 'Utilisateur'),
    photoUrl: readNullableString(json['photoUrl']),
    bio: readNullableString(json['bio']),
    city: readNullableString(json['city']),
    phone: readNullableString(json['phone']),
    email: readNullableString(json['email']),
    authProvider: readEnum(
      AuthProviderType.values,
      json['authProvider'],
      AuthProviderType.guest,
    ),
    role: readEnum(UserRole.values, json['role'], UserRole.ambassador),
    referralCode: readString(json['referralCode']).toUpperCase(),
    tier: readEnum(AmbassadorTier.values, json['tier'], AmbassadorTier.bronze),
    completedRentals3m: readInt(json['completedRentals3m']),
    companyId: readNullableString(json['companyId']),
    isIdVerified: readBool(json['isIdVerified']),
    isBanned: readBool(json['isBanned']),
    birthDate: readDate(json['birthDate']),
    createdAt: readDate(json['createdAt']) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'photoUrl': photoUrl,
    'bio': bio,
    'city': city,
    'phone': phone,
    'email': email,
    'authProvider': authProvider.name,
    'role': role.name,
    'referralCode': referralCode,
    'tier': tier.name,
    'completedRentals3m': completedRentals3m,
    'companyId': companyId,
    'isIdVerified': isIdVerified,
    'isBanned': isBanned,
    'birthDate': writeDate(birthDate),
    'createdAt': writeDate(createdAt),
  };

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    String? city,
    String? phone,
    String? email,
    UserRole? role,
    AmbassadorTier? tier,
    int? completedRentals3m,
    String? companyId,
    bool? isIdVerified,
  }) => AppUser(
    id: id,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    bio: bio ?? this.bio,
    city: city ?? this.city,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    authProvider: authProvider,
    role: role ?? this.role,
    referralCode: referralCode,
    tier: tier ?? this.tier,
    completedRentals3m: completedRentals3m ?? this.completedRentals3m,
    companyId: companyId ?? this.companyId,
    isIdVerified: isIdVerified ?? this.isIdVerified,
    isBanned: isBanned,
    birthDate: birthDate,
    createdAt: createdAt,
  );
}
