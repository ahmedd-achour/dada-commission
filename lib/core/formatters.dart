import 'constants.dart';

/// Display helpers (French formatting: `6 000 DC`, `68,400 DT`).
class Fmt {
  Fmt._();

  static String _group(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }

  /// `1500` -> `1 500 DC`
  static String coins(int coins) => '${_group(coins)} DC';

  /// `684` -> `+684 DC`, `-500` -> `−500 DC`
  static String signedCoins(int amount) {
    if (amount > 0) return '+${coins(amount)}';
    if (amount < 0) return '−${coins(-amount)}';
    return coins(0);
  }

  /// Tunisian dinar with 3 decimals: `68.4` -> `68,400 DT`.
  static String dinars(double dt) {
    final millimes = (dt * 1000).round();
    final whole = millimes ~/ 1000;
    final frac = (millimes.abs() % 1000).toString().padLeft(3, '0');
    return '${_group(whole)},$frac DT';
  }

  /// Short form for prices: `150` -> `150 DT`.
  static String price(double dt) =>
      dt == dt.roundToDouble() ? '${_group(dt.round())} DT' : dinars(dt);

  static double coinsToDinars(int coins) => coins / kCoinsPerDinar;

  static int dinarsToCoins(double dt) => (dt * kCoinsPerDinar).round();

  static String percent(double rate) {
    final p = rate * 100;
    return p == p.roundToDouble()
        ? '${p.round()} %'
        : '${p.toStringAsFixed(1)} %';
  }

  static String timeAgo(DateTime date, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return shortDate(date);
  }

  static const _months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  static String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static String longDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';
}
