import 'app_user.dart';
import 'json_utils.dart';

/// Comment on a post: `posts/{postId}/comments/{id}`.
/// A Cloud Function keeps `posts/{postId}.commentCount` in sync.
class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final UserRole authorRole;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.authorRole = UserRole.ambassador,
  });

  factory Comment.fromJson(String id, Map<String, dynamic> json) => Comment(
    id: id,
    postId: readString(json['postId']),
    authorId: readString(json['authorId']),
    authorName: readString(json['authorName']),
    authorRole: readEnum(
      UserRole.values,
      json['authorRole'],
      UserRole.ambassador,
    ),
    text: readString(json['text']),
    createdAt: readDate(json['createdAt']) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'postId': postId,
    'authorId': authorId,
    'authorName': authorName,
    'authorRole': authorRole.name,
    'text': text,
    'createdAt': writeDate(createdAt),
  };
}
