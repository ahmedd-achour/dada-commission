import 'package:cloud_firestore/cloud_firestore.dart';

/// Lenient readers shared by every model's `fromJson`, so a missing or
/// mistyped field in Firestore degrades to a default instead of crashing.

DateTime? readDate(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

Timestamp? writeDate(DateTime? d) => d == null ? null : Timestamp.fromDate(d);

int readInt(Object? v, [int fallback = 0]) =>
    v is num ? v.toInt() : int.tryParse('$v') ?? fallback;

double readDouble(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;

bool readBool(Object? v, [bool fallback = false]) => v is bool ? v : fallback;

String readString(Object? v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

String? readNullableString(Object? v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

List<String> readStringList(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

/// Enum lookup by `name`, falling back when the stored value is unknown.
T readEnum<T extends Enum>(List<T> values, Object? v, T fallback) {
  for (final e in values) {
    if (e.name == v) return e;
  }
  return fallback;
}
