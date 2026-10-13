/// Commission levels. The level is recomputed on the 1st of each month from
/// the rentals completed by the ambassador's clients over the last 3 months.
enum AmbassadorTier {
  bronze('Bronze', 0.08, 0),
  silver('Argent', 0.12, 3),
  gold('Or', 0.16, 10),
  diamond('Diamant', 0.20, 25);

  const AmbassadorTier(
    this.label,
    this.commissionRate,
    this.minCompletedRentals,
  );

  final String label;

  /// Share of each paid rental (after the customer's discount).
  final double commissionRate;

  /// Completed rentals over the last 3 months needed to reach this level.
  final int minCompletedRentals;

  static AmbassadorTier forCompletedRentals(int completed) =>
      values.lastWhere((t) => completed >= t.minCompletedRentals);

  AmbassadorTier? get next =>
      index + 1 < values.length ? values[index + 1] : null;

  /// 0..1 progress towards [next] (1 when already at the top level).
  double progressFor(int completed) {
    final n = next;
    if (n == null) return 1;
    final span = n.minCompletedRentals - minCompletedRentals;
    return ((completed - minCompletedRentals) / span).clamp(0.0, 1.0);
  }
}
