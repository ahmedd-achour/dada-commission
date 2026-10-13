import '../core/constants.dart';
import 'json_utils.dart';

enum TransferStatus { pending, completed, failed, reversed }

/// Account-to-account Dada Coin transfer: `transfers/{id}`.
///
/// The client only creates the request (via a callable Cloud Function); the
/// function re-runs [validate], debits the sender, credits the recipient and
/// writes a `transferOut` / `transferIn` ledger entry on each wallet in one
/// Firestore transaction.
class CoinTransfer {
  final String id;
  final String fromUserId;
  final String fromName;
  final String toUserId;
  final String toName;

  /// The recipient is addressed by their referral code.
  final String toReferralCode;
  final int amount;
  final String? note;
  final TransferStatus status;
  final DateTime createdAt;

  const CoinTransfer({
    required this.id,
    required this.fromUserId,
    required this.fromName,
    required this.toUserId,
    required this.toName,
    required this.toReferralCode,
    required this.amount,
    required this.createdAt,
    this.note,
    this.status = TransferStatus.pending,
  });

  /// Returns an error message, or null when the transfer is allowed.
  static String? validate({
    required int amount,
    required int balance,
    required String fromCode,
    required String toCode,
  }) {
    final to = toCode.trim().toUpperCase();
    if (to.isEmpty) return 'Entrez le code du destinataire.';
    if (to == fromCode.toUpperCase()) {
      return 'Vous ne pouvez pas vous envoyer des coins.';
    }
    if (amount < kMinTransferCoins) {
      return 'Montant minimum : $kMinTransferCoins DC.';
    }
    if (amount > balance) return 'Solde insuffisant.';
    return null;
  }

  factory CoinTransfer.fromJson(String id, Map<String, dynamic> json) =>
      CoinTransfer(
        id: id,
        fromUserId: readString(json['fromUserId']),
        fromName: readString(json['fromName']),
        toUserId: readString(json['toUserId']),
        toName: readString(json['toName']),
        toReferralCode: readString(json['toReferralCode']),
        amount: readInt(json['amount']),
        note: readNullableString(json['note']),
        status: readEnum(
          TransferStatus.values,
          json['status'],
          TransferStatus.pending,
        ),
        createdAt: readDate(json['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'fromUserId': fromUserId,
    'fromName': fromName,
    'toUserId': toUserId,
    'toName': toName,
    'toReferralCode': toReferralCode,
    'amount': amount,
    'note': note,
    'status': status.name,
    'createdAt': writeDate(createdAt),
  };
}
