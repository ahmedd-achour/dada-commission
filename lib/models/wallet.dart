import '../core/constants.dart';
import 'json_utils.dart';

/// Dada Coin balance: `wallets/{uid}` (doc id == user id).
///
/// Read-only for clients. Every change goes through a Cloud Function that
/// updates the balance and appends a [CoinTransaction] in the same Firestore
/// transaction, so the ledger always explains the balance:
///
///   match /wallets/{uid} {
///     allow read: if request.auth.uid == uid;
///     allow write: if false;
///   }
///
/// Amounts are whole coins (10 DC = 1 DT); coins are never fractional.
class Wallet {
  final String userId;

  /// Spendable coins.
  final int balance;

  /// Coins not yet available (e.g. a purchase being confirmed).
  final int pendingBalance;
  final int lifetimeEarned;
  final DateTime? updatedAt;

  const Wallet({
    required this.userId,
    this.balance = 0,
    this.pendingBalance = 0,
    this.lifetimeEarned = 0,
    this.updatedAt,
  });

  double get balanceDt => balance / kCoinsPerDinar;

  factory Wallet.fromJson(String userId, Map<String, dynamic> json) => Wallet(
    userId: userId,
    balance: readInt(json['balance']),
    pendingBalance: readInt(json['pendingBalance']),
    lifetimeEarned: readInt(json['lifetimeEarned']),
    updatedAt: readDate(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'pendingBalance': pendingBalance,
    'lifetimeEarned': lifetimeEarned,
    'updatedAt': writeDate(updatedAt),
  };

  Wallet copyWith({int? balance, int? pendingBalance, int? lifetimeEarned}) =>
      Wallet(
        userId: userId,
        balance: balance ?? this.balance,
        pendingBalance: pendingBalance ?? this.pendingBalance,
        lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
        updatedAt: DateTime.now(),
      );
}

enum CoinTransactionType {
  /// 8 % of a request paid by a client who used the ambassador's code.
  referralEarning('Gain parrainage'),
  transferIn('Transfert reçu'),
  transferOut('Transfert envoyé'),

  /// Dada Coins bought with Click to Pay.
  purchase('Achat de coins'),

  /// Coins taken back (fraud, refunded prepayment).
  reversal('Coins repris'),
  adjustment('Ajustement');

  const CoinTransactionType(this.label);
  final String label;
}

enum CoinTransactionStatus { pending, completed, cancelled }

/// Append-only ledger entry: `wallets/{uid}/transactions/{id}`.
class CoinTransaction {
  final String id;
  final String userId;

  /// Positive = credit, negative = debit.
  final int amount;
  final CoinTransactionType type;
  final CoinTransactionStatus status;
  final String title;
  final String? subtitle;
  final String? requestId;
  final String? transferId;
  final String? paymentId;
  final String? counterpartyId;
  final String? counterpartyName;
  final DateTime createdAt;

  /// Optional expiry of earned coins (policy to decide).
  final DateTime? expiresAt;

  const CoinTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.title,
    required this.createdAt,
    this.status = CoinTransactionStatus.completed,
    this.subtitle,
    this.requestId,
    this.transferId,
    this.paymentId,
    this.counterpartyId,
    this.counterpartyName,
    this.expiresAt,
  });

  bool get isCredit => amount > 0;

  factory CoinTransaction.fromJson(String id, Map<String, dynamic> json) =>
      CoinTransaction(
        id: id,
        userId: readString(json['userId']),
        amount: readInt(json['amount']),
        type: readEnum(
          CoinTransactionType.values,
          json['type'],
          CoinTransactionType.adjustment,
        ),
        status: readEnum(
          CoinTransactionStatus.values,
          json['status'],
          CoinTransactionStatus.completed,
        ),
        title: readString(json['title']),
        subtitle: readNullableString(json['subtitle']),
        requestId: readNullableString(json['requestId']),
        transferId: readNullableString(json['transferId']),
        paymentId: readNullableString(json['paymentId']),
        counterpartyId: readNullableString(json['counterpartyId']),
        counterpartyName: readNullableString(json['counterpartyName']),
        createdAt: readDate(json['createdAt']) ?? DateTime.now(),
        expiresAt: readDate(json['expiresAt']),
      );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'amount': amount,
    'type': type.name,
    'status': status.name,
    'title': title,
    'subtitle': subtitle,
    'requestId': requestId,
    'transferId': transferId,
    'paymentId': paymentId,
    'counterpartyId': counterpartyId,
    'counterpartyName': counterpartyName,
    'createdAt': writeDate(createdAt),
    'expiresAt': writeDate(expiresAt),
  };
}
