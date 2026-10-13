import '../core/constants.dart';
import 'json_utils.dart';

/// How the customer reached the booking.
enum ReferralSource {
  code('Code'),
  link('Lien'),
  qr('QR code');

  const ReferralSource(this.label);
  final String label;
}

/// Lifecycle of a commission ("Quand les coins arrivent"):
/// booked -> inProgress -> returned (7-day hold, coins "en attente")
/// -> validated (coins available). Cancelled/refunded earn nothing.
enum ReferralStatus {
  booked('Réservée'),
  inProgress('En cours'),
  returned('En attente'),
  validated('Terminée'),
  cancelled('Annulée'),
  refunded('Remboursée');

  const ReferralStatus(this.label);
  final String label;

  bool get earnsNothing =>
      this == ReferralStatus.cancelled || this == ReferralStatus.refunded;
}

/// Result of [CommissionCalculator.compute], amounts in DT.
class CommissionBreakdown {
  final double grossDt;
  final double discountDt;
  final double netDt;
  final double rate;
  final double commissionDt;
  final int coins;

  const CommissionBreakdown({
    required this.grossDt,
    required this.discountDt,
    required this.netDt,
    required this.rate,
    required this.commissionDt,
    required this.coins,
  });
}

/// Single source of truth for the commission maths (mirrored server-side).
///
/// Works in millimes (1 DT = 1000) to avoid floating-point drift:
/// 3 × 150 DT = 450 DT, −5 % = 427,500 DT, 16 % = 68,400 DT = 684 coins.
class CommissionCalculator {
  CommissionCalculator._();

  static CommissionBreakdown compute({
    required int days,
    required double pricePerDay,
    required double tierRate,
    double discountRate = kCustomerDiscountRate,
    bool isRepeatCustomer = false,
  }) {
    final gross = days * (pricePerDay * 1000).round();
    // The discount only applies to a customer's first rental with a code.
    final discount = isRepeatCustomer ? 0 : (gross * discountRate).round();
    final net = gross - discount;
    final rate = isRepeatCustomer
        ? tierRate * kRepeatCustomerRateFactor
        : tierRate;
    final commission = (net * rate).round();
    const millimesPerCoin = 1000 ~/ kCoinsPerDinar;
    return CommissionBreakdown(
      grossDt: gross / 1000,
      discountDt: discount / 1000,
      netDt: net / 1000,
      rate: rate,
      commissionDt: commission / 1000,
      coins: commission ~/ millimesPerCoin,
    );
  }
}

/// A rental booked through an ambassador: `referrals/{id}`.
///
/// Written by the booking backend / Cloud Functions only. The customer's real
/// identity stays server-side; the ambassador sees [customerMaskedName].
class Referral {
  final String id;
  final String ambassadorId;
  final String referralCode;
  final String companyId;
  final String carId;
  final String carModel;
  final String customerMaskedName;
  final ReferralSource source;
  final int rentalDays;
  final double pricePerDay;
  final double discountRate;

  /// Ambassador's rate frozen at booking time.
  final double commissionRate;
  final bool isRepeatCustomer;
  final ReferralStatus status;
  final DateTime bookedAt;
  final DateTime? startDate;
  final DateTime? returnedAt;

  const Referral({
    required this.id,
    required this.ambassadorId,
    required this.referralCode,
    required this.companyId,
    required this.carId,
    required this.carModel,
    required this.customerMaskedName,
    required this.rentalDays,
    required this.pricePerDay,
    required this.commissionRate,
    required this.status,
    required this.bookedAt,
    this.source = ReferralSource.code,
    this.discountRate = kCustomerDiscountRate,
    this.isRepeatCustomer = false,
    this.startDate,
    this.returnedAt,
  });

  CommissionBreakdown get commission => CommissionCalculator.compute(
    days: rentalDays,
    pricePerDay: pricePerDay,
    tierRate: commissionRate,
    discountRate: discountRate,
    isRepeatCustomer: isRepeatCustomer,
  );

  /// Coins this referral is worth (0 when cancelled/refunded).
  int get coins => status.earnsNothing ? 0 : commission.coins;

  /// When the 7-day hold ends.
  DateTime? get coinsAvailableAt =>
      returnedAt?.add(const Duration(days: kCoinsHoldDays));

  /// `Sami` -> `S***i`. Applied server-side before the doc is written.
  static String maskName(String name) {
    final n = name.trim();
    if (n.length <= 2) return '${n.isEmpty ? '?' : n[0]}***';
    return '${n[0].toUpperCase()}***${n[n.length - 1]}';
  }

  factory Referral.fromJson(String id, Map<String, dynamic> json) => Referral(
    id: id,
    ambassadorId: readString(json['ambassadorId']),
    referralCode: readString(json['referralCode']),
    companyId: readString(json['companyId']),
    carId: readString(json['carId']),
    carModel: readString(json['carModel']),
    customerMaskedName: readString(json['customerMaskedName'], '***'),
    source: readEnum(
      ReferralSource.values,
      json['source'],
      ReferralSource.code,
    ),
    rentalDays: readInt(json['rentalDays'], 1),
    pricePerDay: readDouble(json['pricePerDay']),
    discountRate: readDouble(json['discountRate'], kCustomerDiscountRate),
    commissionRate: readDouble(json['commissionRate']),
    isRepeatCustomer: readBool(json['isRepeatCustomer']),
    status: readEnum(
      ReferralStatus.values,
      json['status'],
      ReferralStatus.booked,
    ),
    bookedAt: readDate(json['bookedAt']) ?? DateTime.now(),
    startDate: readDate(json['startDate']),
    returnedAt: readDate(json['returnedAt']),
  );

  Map<String, dynamic> toJson() => {
    'ambassadorId': ambassadorId,
    'referralCode': referralCode,
    'companyId': companyId,
    'carId': carId,
    'carModel': carModel,
    'customerMaskedName': customerMaskedName,
    'source': source.name,
    'rentalDays': rentalDays,
    'pricePerDay': pricePerDay,
    'discountRate': discountRate,
    'commissionRate': commissionRate,
    'isRepeatCustomer': isRepeatCustomer,
    'status': status.name,
    'bookedAt': writeDate(bookedAt),
    'startDate': writeDate(startDate),
    'returnedAt': writeDate(returnedAt),
  };
}

/// Aggregated counters for "Mes clients" (`users/{uid}/stats/{period}`).
class ReferralStats {
  final int clicks;
  final int bookings;
  final int completed;

  const ReferralStats({this.clicks = 0, this.bookings = 0, this.completed = 0});

  factory ReferralStats.fromJson(Map<String, dynamic> json) => ReferralStats(
    clicks: readInt(json['clicks']),
    bookings: readInt(json['bookings']),
    completed: readInt(json['completed']),
  );

  Map<String, dynamic> toJson() => {
    'clicks': clicks,
    'bookings': bookings,
    'completed': completed,
  };
}
