// Business rules from the concept document ("Le concept", assets/).
//
// Kept in one place so the app, the future Cloud Functions and the tests all
// agree on the same numbers.

/// 1 DT = 10 Dada Coins (1 coin = 0.100 DT = 100 millimes).
const int kCoinsPerDinar = 10;

/// Discount a customer gets on their first rental when using a code or link.
const double kCustomerDiscountRate = 0.05;

/// Coins stay "en attente" for 7 days after the car is returned.
const int kCoinsHoldDays = 7;

/// Coins expire 12 months after they are earned.
const int kCoinsExpiryMonths = 12;

/// Redeeming a reward above this price requires a one-time CIN check.
const int kIdCheckThresholdCoins = 5000;

/// Smallest amount that can be sent to another account.
const int kMinTransferCoins = 10;

/// A returning customer (same year) earns the ambassador half their rate.
const double kRepeatCustomerRateFactor = 0.5;

/// Base of every referral link: `<base><CODE>`. Firebase Hosting default
/// domain of the `dada-commission` project; swap for a custom domain later.
const String kReferralBaseUrl = 'https://dada-commission.web.app/r/';

/// Minimum age to become an ambassador.
const int kMinAmbassadorAge = 18;
