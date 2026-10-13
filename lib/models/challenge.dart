import 'json_utils.dart';

/// Monthly challenge published by the Dada team: `challenges/{id}`.
/// Per-user progress lives in `users/{uid}/challengeProgress/{challengeId}`.
class Challenge {
  final String id;
  final String title;
  final String description;

  /// Completed rentals needed.
  final int target;
  final int bonusCoins;
  final DateTime startsAt;
  final DateTime endsAt;

  /// Current user's progress (merged client-side).
  final int progress;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.bonusCoins,
    required this.startsAt,
    required this.endsAt,
    this.progress = 0,
  });

  double get ratio => target == 0 ? 0 : (progress / target).clamp(0.0, 1.0);
  bool get isDone => progress >= target;

  factory Challenge.fromJson(
    String id,
    Map<String, dynamic> json, {
    int progress = 0,
  }) => Challenge(
    id: id,
    title: readString(json['title']),
    description: readString(json['description']),
    target: readInt(json['target'], 1),
    bonusCoins: readInt(json['bonusCoins']),
    startsAt: readDate(json['startsAt']) ?? DateTime.now(),
    endsAt: readDate(json['endsAt']) ?? DateTime.now(),
    progress: progress,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'target': target,
    'bonusCoins': bonusCoins,
    'startsAt': writeDate(startsAt),
    'endsAt': writeDate(endsAt),
  };
}

/// Milestone badge ("1er client", "10 clients", "Vérifiée"…).
class AchievementBadge {
  final String id;
  final String label;
  final String shortLabel;
  final bool earned;

  const AchievementBadge({
    required this.id,
    required this.label,
    required this.shortLabel,
    this.earned = false,
  });
}

/// Monthly ranking row. Only ranks and rental counts are shown, never the
/// earnings of other users.
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int completedRentals;
  final bool isMe;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.completedRentals,
    this.isMe = false,
  });
}
