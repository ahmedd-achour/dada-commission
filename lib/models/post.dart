import 'ambassador_tier.dart';
import 'app_user.dart';
import 'json_utils.dart';

enum PostType {
  /// Plain status update ("Quoi de neuf ?").
  status,

  /// Promotes a car; shows "Réserver avec CODE".
  carPromo,

  /// Official news / promos from Dada or a company.
  announcement,

  /// Monthly challenge published by the Dada team.
  challenge,
}

/// Feed entry: `posts/{id}`. Likes live in `posts/{id}/likes/{uid}` and
/// comments in `posts/{id}/comments/{commentId}`; the counters here are
/// kept in sync by Cloud Functions.
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final UserRole authorRole;
  final AmbassadorTier authorTier;
  final PostType type;
  final String text;
  final List<String> mediaUrls;

  /// Car snapshot (denormalised) for [PostType.carPromo].
  final String? carId;
  final String? carModel;
  final double? carPricePerDay;
  final String? carCompanyName;

  /// Code applied when someone books from this post.
  final String? referralCode;

  /// Creators must flag paid promotion ("#sponsorisé").
  final bool isSponsored;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;

  /// Client-side only: whether the current user liked it.
  final bool likedByMe;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.type,
    required this.text,
    required this.createdAt,
    this.authorPhotoUrl,
    this.authorRole = UserRole.ambassador,
    this.authorTier = AmbassadorTier.bronze,
    this.mediaUrls = const [],
    this.carId,
    this.carModel,
    this.carPricePerDay,
    this.carCompanyName,
    this.referralCode,
    this.isSponsored = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.likedByMe = false,
  });

  bool get hasCar => carId != null;

  String get authorHeadline => authorRole == UserRole.ambassador
      ? '${authorRole.label} ${authorTier.label}'
      : authorRole.label;

  factory Post.fromJson(
    String id,
    Map<String, dynamic> json, {
    bool likedByMe = false,
  }) => Post(
    id: id,
    authorId: readString(json['authorId']),
    authorName: readString(json['authorName']),
    authorPhotoUrl: readNullableString(json['authorPhotoUrl']),
    authorRole: readEnum(
      UserRole.values,
      json['authorRole'],
      UserRole.ambassador,
    ),
    authorTier: readEnum(
      AmbassadorTier.values,
      json['authorTier'],
      AmbassadorTier.bronze,
    ),
    type: readEnum(PostType.values, json['type'], PostType.status),
    text: readString(json['text']),
    mediaUrls: readStringList(json['mediaUrls']),
    carId: readNullableString(json['carId']),
    carModel: readNullableString(json['carModel']),
    carPricePerDay: json['carPricePerDay'] == null
        ? null
        : readDouble(json['carPricePerDay']),
    carCompanyName: readNullableString(json['carCompanyName']),
    referralCode: readNullableString(json['referralCode']),
    isSponsored: readBool(json['isSponsored']),
    likeCount: readInt(json['likeCount']),
    commentCount: readInt(json['commentCount']),
    shareCount: readInt(json['shareCount']),
    createdAt: readDate(json['createdAt']) ?? DateTime.now(),
    likedByMe: likedByMe,
  );

  Map<String, dynamic> toJson() => {
    'authorId': authorId,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'authorRole': authorRole.name,
    'authorTier': authorTier.name,
    'type': type.name,
    'text': text,
    'mediaUrls': mediaUrls,
    'carId': carId,
    'carModel': carModel,
    'carPricePerDay': carPricePerDay,
    'carCompanyName': carCompanyName,
    'referralCode': referralCode,
    'isSponsored': isSponsored,
    'likeCount': likeCount,
    'commentCount': commentCount,
    'shareCount': shareCount,
    'createdAt': writeDate(createdAt),
  };

  Post copyWith({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    int? shareCount,
  }) => Post(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorPhotoUrl: authorPhotoUrl,
    authorRole: authorRole,
    authorTier: authorTier,
    type: type,
    text: text,
    mediaUrls: mediaUrls,
    carId: carId,
    carModel: carModel,
    carPricePerDay: carPricePerDay,
    carCompanyName: carCompanyName,
    referralCode: referralCode,
    isSponsored: isSponsored,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    shareCount: shareCount ?? this.shareCount,
    createdAt: createdAt,
    likedByMe: likedByMe ?? this.likedByMe,
  );
}
