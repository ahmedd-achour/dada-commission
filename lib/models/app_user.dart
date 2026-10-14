import '../core/constants.dart';
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

/// What the account does in the app.
enum UserRole {
  /// Wants to rent a car: posts a request with an ambassador's code and
  /// prepays 10 %.
  client('Client'),

  /// Anyone 18+ who shares a code/link and earns 8 % in Dada Coins.
  ambassador('Ambassadeur'),

  /// A venue (hotel, agency…) with a QR code at the reception. Earns like an
  /// ambassador.
  partner('Partenaire'),

  /// Rent-car company: takes prepaid requests and rents the car.
  companyAdmin('Agence de location'),

  /// Dada team: approves agencies, handles disputes.
  staff('Équipe Dada');

  /// Has a code and earns coins when clients use it.
  bool get earnsCommission =>
      this == UserRole.ambassador || this == UserRole.partner;

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

  /// Set when the user owns/manages a rent-car company.
  final String? companyId;

  /// CIN checked once by the Dada team.
  final bool isIdVerified;
  final bool isBanned;
  final DateTime? birthDate;

  /// Partner venue (hotel, agency…) shown on the QR stand.
  final String? venueName;

  /// False until the onboarding wizard (account type + profile, and the
  /// company file for businesses) is finished. The app shows the wizard
  /// instead of the main tabs until then.
  final bool setupComplete;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.displayName,
    required this.authProvider,
    required this.referralCode,
    required this.createdAt,
    this.role = UserRole.ambassador,
    this.photoUrl,
    this.bio,
    this.city,
    this.phone,
    this.email,
    this.companyId,
    this.isIdVerified = false,
    this.isBanned = false,
    this.birthDate,
    this.venueName,
    this.setupComplete = false,
  });

  String get referralLink => '$kReferralBaseUrl$referralCode';

  bool get isGuest => authProvider == AuthProviderType.guest;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty).take(2).map((p) => p[0]);
    return letters.join().toUpperCase();
  }

  /// "Ambassadeur Or", "Agence de location"…
  String get headline => role.label;

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
    companyId: readNullableString(json['companyId']),
    isIdVerified: readBool(json['isIdVerified']),
    isBanned: readBool(json['isBanned']),
    birthDate: readDate(json['birthDate']),
    venueName: readNullableString(json['venueName']),
    setupComplete: readBool(json['setupComplete']),
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
    'companyId': companyId,
    'isIdVerified': isIdVerified,
    'isBanned': isBanned,
    'birthDate': writeDate(birthDate),
    'venueName': venueName,
    'setupComplete': setupComplete,
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
    String? companyId,
    bool? isIdVerified,
    DateTime? birthDate,
    String? venueName,
    bool? setupComplete,
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
    companyId: companyId ?? this.companyId,
    isIdVerified: isIdVerified ?? this.isIdVerified,
    isBanned: isBanned,
    birthDate: birthDate ?? this.birthDate,
    venueName: venueName ?? this.venueName,
    setupComplete: setupComplete ?? this.setupComplete,
    createdAt: createdAt,
  );

  /// Age in full years, or null when the birth date is unknown.
  int? ageOn(DateTime day) {
    final b = birthDate;
    return b == null ? null : ageBetween(b, day);
  }

  /// Age in full years of someone born on [birth], on [day].
  static int ageBetween(DateTime b, DateTime day) {
    var age = day.year - b.year;
    if (day.month < b.month || (day.month == b.month && day.day < b.day)) {
      age--;
    }
    return age;
  }
}
