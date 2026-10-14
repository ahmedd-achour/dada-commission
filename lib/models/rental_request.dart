import '../core/constants.dart';
import 'json_utils.dart';

enum CarCategory {
  citadine('Citadine'),
  compacte('Compacte'),
  berline('Berline'),
  suv('SUV / 4x4'),
  utilitaire('Utilitaire'),
  luxe('Luxe');

  const CarCategory(this.label);
  final String label;
}

/// Lifecycle of a request:
/// awaitingPayment -> open (prepaid, visible to agencies) -> claimed (an
/// agency took it and contacts the client) -> completed (car rented).
/// cancelled / expired are terminal without a rental.
enum RequestStatus {
  awaitingPayment('Acompte à payer'),
  open('Ouverte'),
  claimed('Prise en charge'),
  completed('Terminée'),
  cancelled('Annulée'),
  expired('Expirée');

  const RequestStatus(this.label);
  final String label;

  /// Shown in the public feed (paid, so the client is serious).
  bool get isPublic =>
      this == RequestStatus.open ||
      this == RequestStatus.claimed ||
      this == RequestStatus.completed;
}

/// How a request's money splits. Amounts in millimes (1 DT = 1000) so the
/// maths never drifts.
///
/// Example (Mercedes G-Class, 3 days, 700 DT after the −5 %):
///   prepayment 10 % = 70 DT paid to Dada
///   ambassador 8 %  = 56 DT = 560 DC, credited instantly
///   Dada keeps 2 %  = 14 DT
///   agency collects the remaining 90 % = 630 DT from the client.
class RequestPricing {
  final int listPriceMillimes;
  final int discountMillimes;
  final int amountDueMillimes;
  final int prepaymentMillimes;
  final int ambassadorMillimes;
  final int dadaFeeMillimes;
  final int agencyMillimes;

  const RequestPricing._({
    required this.listPriceMillimes,
    required this.discountMillimes,
    required this.amountDueMillimes,
    required this.prepaymentMillimes,
    required this.ambassadorMillimes,
    required this.dadaFeeMillimes,
    required this.agencyMillimes,
  });

  /// From the agency's usual price (before the code's discount).
  factory RequestPricing.fromListPrice(double listPriceDt) {
    final list = (listPriceDt * 1000).round();
    final discount = (list * kCustomerDiscountRate).round();
    return RequestPricing._fromDue(list, discount, list - discount);
  }

  /// From the price the client will actually pay (already discounted).
  factory RequestPricing.fromAmountDue(double amountDueDt) {
    final due = (amountDueDt * 1000).round();
    final list = (due / (1 - kCustomerDiscountRate)).round();
    return RequestPricing._fromDue(list, list - due, due);
  }

  factory RequestPricing._fromDue(int list, int discount, int due) {
    final prepay = (due * kPrepaymentRate).round();
    // Coins are whole: round the ambassador share down to 100 millimes.
    const millimesPerCoin = 1000 ~/ kCoinsPerDinar;
    final ambassador =
        (due * kAmbassadorRate).round() ~/ millimesPerCoin * millimesPerCoin;
    return RequestPricing._(
      listPriceMillimes: list,
      discountMillimes: discount,
      amountDueMillimes: due,
      prepaymentMillimes: prepay,
      ambassadorMillimes: ambassador,
      dadaFeeMillimes: prepay - ambassador,
      agencyMillimes: due - prepay,
    );
  }

  double get listPriceDt => listPriceMillimes / 1000;
  double get discountDt => discountMillimes / 1000;
  double get amountDueDt => amountDueMillimes / 1000;
  double get prepaymentDt => prepaymentMillimes / 1000;
  double get ambassadorDt => ambassadorMillimes / 1000;
  double get dadaFeeDt => dadaFeeMillimes / 1000;
  double get agencyDt => agencyMillimes / 1000;

  /// Dada Coins credited to the ambassador.
  int get ambassadorCoins => ambassadorMillimes ~/ (1000 ~/ kCoinsPerDinar);
}

/// The car the agency actually rented, entered when it closes the request.
class RentedCar {
  final String model;
  final String? plate;
  final double finalPriceDt;

  const RentedCar({
    required this.model,
    required this.finalPriceDt,
    this.plate,
  });

  factory RentedCar.fromJson(Map<String, dynamic> json) => RentedCar(
    model: readString(json['model']),
    plate: readNullableString(json['plate']),
    finalPriceDt: readDouble(json['finalPriceDt']),
  );

  Map<String, dynamic> toJson() => {
    'model': model,
    'plate': plate,
    'finalPriceDt': finalPriceDt,
  };
}

/// A client's prepaid rental request: `requests/{id}`.
///
/// This replaces the social posts: the feed only shows requests, as car-rental
/// cards. The client's phone is private and only revealed to the agency that
/// takes the request.
class RentalRequest {
  final String id;

  /// Ambassador whose code the client used.
  final String referralCode;
  final String ambassadorId;
  final String ambassadorName;

  final String clientId;
  final String clientName;
  final String? clientPhone;

  /// What the client wants, e.g. "Mercedes-Benz Classe G".
  final String carWanted;
  final CarCategory category;
  final String city;
  final DateTime startDate;
  final DateTime endDate;
  final String? note;

  /// Agency price before the code's −5 %, in DT.
  final double listPriceDt;

  final RequestStatus status;

  /// Click to Pay order of the 10 % prepayment.
  final String? paymentId;
  final DateTime? paidAt;

  final String? companyId;
  final String? companyName;
  final DateTime? claimedAt;
  final RentedCar? rentedCar;
  final DateTime? completedAt;
  final DateTime createdAt;

  const RentalRequest({
    required this.id,
    required this.referralCode,
    required this.ambassadorId,
    required this.ambassadorName,
    required this.clientId,
    required this.clientName,
    required this.carWanted,
    required this.category,
    required this.city,
    required this.startDate,
    required this.endDate,
    required this.listPriceDt,
    required this.createdAt,
    this.status = RequestStatus.awaitingPayment,
    this.clientPhone,
    this.note,
    this.paymentId,
    this.paidAt,
    this.companyId,
    this.companyName,
    this.claimedAt,
    this.rentedCar,
    this.completedAt,
  });

  /// Rental days (at least 1).
  int get days {
    final d = DateTime(endDate.year, endDate.month, endDate.day)
        .difference(DateTime(startDate.year, startDate.month, startDate.day))
        .inDays;
    return d < 1 ? 1 : d;
  }

  RequestPricing get pricing => RequestPricing.fromListPrice(listPriceDt);

  bool get isPaid => paidAt != null;

  /// Public name: "Sami B." -> "S***i".
  String get maskedClientName => maskName(clientName);

  static String maskName(String name) {
    final n = name.trim().split(RegExp(r'\s+')).first;
    if (n.length <= 2) return '${n.isEmpty ? '?' : n[0]}***';
    return '${n[0].toUpperCase()}***${n[n.length - 1]}';
  }

  factory RentalRequest.fromJson(String id, Map<String, dynamic> json) =>
      RentalRequest(
        id: id,
        referralCode: readString(json['referralCode']),
        ambassadorId: readString(json['ambassadorId']),
        ambassadorName: readString(json['ambassadorName']),
        clientId: readString(json['clientId']),
        clientName: readString(json['clientName']),
        clientPhone: readNullableString(json['clientPhone']),
        carWanted: readString(json['carWanted']),
        category: readEnum(
          CarCategory.values,
          json['category'],
          CarCategory.citadine,
        ),
        city: readString(json['city']),
        startDate: readDate(json['startDate']) ?? DateTime.now(),
        endDate: readDate(json['endDate']) ?? DateTime.now(),
        note: readNullableString(json['note']),
        listPriceDt: readDouble(json['listPriceDt']),
        status: readEnum(
          RequestStatus.values,
          json['status'],
          RequestStatus.awaitingPayment,
        ),
        paymentId: readNullableString(json['paymentId']),
        paidAt: readDate(json['paidAt']),
        companyId: readNullableString(json['companyId']),
        companyName: readNullableString(json['companyName']),
        claimedAt: readDate(json['claimedAt']),
        rentedCar: json['rentedCar'] is Map<String, dynamic>
            ? RentedCar.fromJson(json['rentedCar'] as Map<String, dynamic>)
            : null,
        completedAt: readDate(json['completedAt']),
        createdAt: readDate(json['createdAt']) ?? DateTime.now(),
      );

  /// Public document. The phone lives in `requests/{id}/private/contact`,
  /// readable by the client and the agency that took the request.
  Map<String, dynamic> toJson() {
    final p = pricing;
    return {
      'referralCode': referralCode,
      'ambassadorId': ambassadorId,
      'ambassadorName': ambassadorName,
      'clientId': clientId,
      'clientName': clientName,
      'carWanted': carWanted,
      'category': category.name,
      'city': city,
      'startDate': writeDate(startDate),
      'endDate': writeDate(endDate),
      'note': note,
      'listPriceDt': listPriceDt,
      // Denormalised for queries / statements; recomputed server-side.
      'amountDueDt': p.amountDueDt,
      'prepaymentDt': p.prepaymentDt,
      'ambassadorCoins': p.ambassadorCoins,
      'status': status.name,
      'paymentId': paymentId,
      'paidAt': writeDate(paidAt),
      'companyId': companyId,
      'companyName': companyName,
      'claimedAt': writeDate(claimedAt),
      'rentedCar': rentedCar?.toJson(),
      'completedAt': writeDate(completedAt),
      'createdAt': writeDate(createdAt),
    };
  }

  RentalRequest copyWith({
    RequestStatus? status,
    String? paymentId,
    DateTime? paidAt,
    String? companyId,
    String? companyName,
    DateTime? claimedAt,
    RentedCar? rentedCar,
    DateTime? completedAt,
  }) => RentalRequest(
    id: id,
    referralCode: referralCode,
    ambassadorId: ambassadorId,
    ambassadorName: ambassadorName,
    clientId: clientId,
    clientName: clientName,
    clientPhone: clientPhone,
    carWanted: carWanted,
    category: category,
    city: city,
    startDate: startDate,
    endDate: endDate,
    note: note,
    listPriceDt: listPriceDt,
    status: status ?? this.status,
    paymentId: paymentId ?? this.paymentId,
    paidAt: paidAt ?? this.paidAt,
    companyId: companyId ?? this.companyId,
    companyName: companyName ?? this.companyName,
    claimedAt: claimedAt ?? this.claimedAt,
    rentedCar: rentedCar ?? this.rentedCar,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt,
  );
}
