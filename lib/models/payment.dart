import 'json_utils.dart';

enum PaymentPurpose {
  /// The client's 10 % prepayment of a rental request.
  prepayment('Acompte de location'),

  /// Buying Dada Coins (10 DC = 1 DT).
  coinPurchase('Achat de Dada Coins');

  const PaymentPurpose(this.label);
  final String label;
}

enum PaymentStatus { pending, succeeded, failed, refunded }

/// A Click to Pay order: `payments/{id}`.
///
/// Created by a Cloud Function (never by the app), which registers the order
/// with Click to Pay and returns the payment page URL. When Click to Pay
/// confirms the order, the function marks it `succeeded` and, in the same
/// transaction, opens the request and credits the ambassador's coins.
class Payment {
  final String id;
  final String userId;
  final PaymentPurpose purpose;

  /// Amount in millimes (1 DT = 1000).
  final int amountMillimes;
  final PaymentStatus status;

  /// Request paid by this order (prepayment only).
  final String? requestId;

  /// Click to Pay's own order id, used to check the status server-side.
  final String? providerOrderId;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  const Payment({
    required this.id,
    required this.userId,
    required this.purpose,
    required this.amountMillimes,
    required this.createdAt,
    this.status = PaymentStatus.pending,
    this.requestId,
    this.providerOrderId,
    this.confirmedAt,
  });

  double get amountDt => amountMillimes / 1000;

  factory Payment.fromJson(String id, Map<String, dynamic> json) => Payment(
    id: id,
    userId: readString(json['userId']),
    purpose: readEnum(
      PaymentPurpose.values,
      json['purpose'],
      PaymentPurpose.prepayment,
    ),
    amountMillimes: readInt(json['amountMillimes']),
    status: readEnum(
      PaymentStatus.values,
      json['status'],
      PaymentStatus.pending,
    ),
    requestId: readNullableString(json['requestId']),
    providerOrderId: readNullableString(json['providerOrderId']),
    createdAt: readDate(json['createdAt']) ?? DateTime.now(),
    confirmedAt: readDate(json['confirmedAt']),
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'purpose': purpose.name,
    'amountMillimes': amountMillimes,
    'status': status.name,
    'requestId': requestId,
    'providerOrderId': providerOrderId,
    'createdAt': writeDate(createdAt),
    'confirmedAt': writeDate(confirmedAt),
  };
}
