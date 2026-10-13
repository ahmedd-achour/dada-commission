import '../core/constants.dart';
import 'json_utils.dart';

enum RewardCategory {
  voucher("Bons d'achat"),
  phone('Téléphones'),
  tablet('Tablettes'),
  rental('Locations'),
  topUp('Recharges'),
  leisure('Loisirs');

  const RewardCategory(this.label);
  final String label;
}

/// Item of the Dada shop: `rewards/{id}`. Price rule: 1 DT = 10 coins.
class Reward {
  final String id;
  final String title;
  final String? description;
  final RewardCategory category;
  final int priceCoins;
  final String? imageUrl;

  /// null = unlimited.
  final int? stock;
  final bool isActive;

  const Reward({
    required this.id,
    required this.title,
    required this.category,
    required this.priceCoins,
    this.description,
    this.imageUrl,
    this.stock,
    this.isActive = true,
  });

  double get valueDt => priceCoins / kCoinsPerDinar;

  /// Big rewards need a one-time photo of the CIN.
  bool get requiresIdCheck => priceCoins > kIdCheckThresholdCoins;

  bool get inStock => stock == null || stock! > 0;

  factory Reward.fromJson(String id, Map<String, dynamic> json) => Reward(
    id: id,
    title: readString(json['title']),
    description: readNullableString(json['description']),
    category: readEnum(
      RewardCategory.values,
      json['category'],
      RewardCategory.voucher,
    ),
    priceCoins: readInt(json['priceCoins']),
    imageUrl: readNullableString(json['imageUrl']),
    stock: json['stock'] == null ? null : readInt(json['stock']),
    isActive: readBool(json['isActive'], true),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category.name,
    'priceCoins': priceCoins,
    'imageUrl': imageUrl,
    'stock': stock,
    'isActive': isActive,
  };
}

enum RedemptionStatus {
  reserved('Coins réservés'),
  preparing('En préparation'),
  ready('Prêt (code envoyé par SMS)'),
  delivered('Livré'),
  cancelled('Annulé');

  const RedemptionStatus(this.label);
  final String label;
}

/// A shop order: `redemptions/{id}`. Created via Cloud Function, which
/// reserves the coins; the Dada team then prepares and delivers it.
class Redemption {
  final String id;
  final String userId;
  final String rewardId;
  final String rewardTitle;
  final int coins;
  final RedemptionStatus status;

  /// Voucher / pickup code sent by SMS when ready.
  final String? pickupCode;
  final DateTime createdAt;

  const Redemption({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardTitle,
    required this.coins,
    required this.createdAt,
    this.status = RedemptionStatus.reserved,
    this.pickupCode,
  });

  factory Redemption.fromJson(String id, Map<String, dynamic> json) =>
      Redemption(
        id: id,
        userId: readString(json['userId']),
        rewardId: readString(json['rewardId']),
        rewardTitle: readString(json['rewardTitle']),
        coins: readInt(json['coins']),
        status: readEnum(
          RedemptionStatus.values,
          json['status'],
          RedemptionStatus.reserved,
        ),
        pickupCode: readNullableString(json['pickupCode']),
        createdAt: readDate(json['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'rewardId': rewardId,
    'rewardTitle': rewardTitle,
    'coins': coins,
    'status': status.name,
    'pickupCode': pickupCode,
    'createdAt': writeDate(createdAt),
  };
}
