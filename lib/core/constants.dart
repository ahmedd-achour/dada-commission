// Business rules of the Dada Commission hub (v2: prepaid requests).
//
// Kept in one place so the app, the future Cloud Functions and the tests all
// agree on the same numbers.

/// 1 DT = 10 Dada Coins (1 coin = 0.100 DT = 100 millimes).
const int kCoinsPerDinar = 10;

/// Discount the client gets when booking with an ambassador's code.
const double kCustomerDiscountRate = 0.05;

/// Share of the amount due that the client prepays to Dada (Click to Pay).
/// It is what makes a request "sure": no prepayment, no request.
const double kPrepaymentRate = 0.10;

/// Share of the amount due credited to the ambassador, in Dada Coins, as soon
/// as the prepayment succeeds. Fixed for every ambassador.
const double kAmbassadorRate = 0.08;

/// What Dada keeps from the prepayment (10 % - 8 % = 2 % of the amount due).
const double kDadaRate = kPrepaymentRate - kAmbassadorRate;

/// Smallest amount that can be sent to another account.
const int kMinTransferCoins = 10;

/// Smallest Dada Coin purchase (10 DT).
const int kMinCoinPurchase = 100;

/// Base of every referral link: `<base><CODE>`. Firebase Hosting default
/// domain of the `dada-commission` project; swap for a custom domain later.
const String kReferralBaseUrl = 'https://dada-commission.web.app/r/';

/// Minimum age to become an ambassador.
const int kMinAmbassadorAge = 18;
