# Dada Commission

Android and iOS (Flutter) app for the Dada Rent Car referral program. You share a
car with your code, link or QR code; someone rents it; you earn **Dada Coins**
(10 DC = 1 DT) and spend them in the Dada shop or send them to another account.
Other rent-car companies can register and get customers through ambassadors.

The full concept is in `assets/Le concept.pdf`.

**Documentation (in French)**
- `docs/Guide-Dada-Commission.pdf`: short illustrated guide for non-technical
  readers (source: `docs/guide/guide.html`)
- `docs/conception-base-de-donnees.md`: database design (collections, fields,
  Cloud Functions, draft security rules, key flows)

## Status

- The UI is done and runs in **guest mode** on mock data (`lib/data/mock_data.dart`).
- After sign-in, an **account setup** wizard is required: ambassador, partner
  venue, or rent-car company (company file, documents, commission agreement).
- Sign-in with Facebook, Google and WhatsApp is stubbed in
  `lib/services/auth_service.dart`. The buttons show a "bientôt disponible" message.
- The models are ready for Firestore (`fromJson` / `toJson`).

## Structure

```
lib/
  app.dart                  MaterialApp + auth gate (sign-in vs main shell)
  core/                     constants (business rules), theme, formatters
  models/                   data model (see below)
  data/app_state.dart       session state (ChangeNotifier) + AppScope
  data/mock_data.dart       guest-mode demo data
  services/auth_service.dart
  screens/
    auth/                   sign-in (Facebook, Google, WhatsApp, guest)
    setup/                  required account-setup wizard
    business/               business guide (how to join as a company)
    main_shell.dart         bottom nav: Accueil · Marketplace · Activité · Profil
    home/                   feed, post card, create post, share a car
    marketplace/            wallet panel + Dada shop + cars of every company
    activity/               my clients, challenges, badges, leaderboard
    profile/                profile, code/link/QR, settings, edit profile
    wallet/                 wallet + history, send coins
    company/                company space (file status, documents)
  widgets/                  shared UI pieces
```

Colours: Samsung blue (`#1428A0`) and a fresh green (`#14B88A`), with a
blue-to-green gradient for the sign-in screen and wallet cards. Layout follows
`shnell_android_ios_client` (Material 3, Inter body text, Outfit and Poppins
titles, 16 px rounded corners). Marketplace images are Microsoft Fluent Emoji 3D
(MIT, see `assets/images/fluent/CREDITS.md`).

## Data model (Firestore)

| Collection | Model | Notes |
|---|---|---|
| `users/{uid}` | `AppUser` | Profile, role (ambassador, partner, companyAdmin, staff), `referralCode`, tier |
| `referralCodes/{code}` | n/a | `{uid}`, guarantees each code is unique |
| `companies/{id}` | `RentalCompany` | `pending` until the Dada team approves it |
| `cars/{id}` | `Car` | Belongs to a company |
| `posts/{id}` | `Post` | Feed. Likes and comments (`Comment`) go in subcollections |
| `referrals/{id}` | `Referral` | A rental booked with a code, link or QR. Server-written |
| `wallets/{uid}` | `Wallet` | Read-only for clients |
| `wallets/{uid}/transactions/{id}` | `CoinTransaction` | Append-only ledger |
| `transfers/{id}` | `CoinTransfer` | Coins sent from one account to another |
| `rewards/{id}` / `redemptions/{id}` | `Reward` / `Redemption` | Shop and orders |
| `challenges/{id}` | `Challenge` | Monthly challenges |

Commission math lives in `CommissionCalculator` (`lib/models/referral.dart`).
Example: 3 × 150 DT, −5 % = 427,500 DT; Gold level 16 % = 68,400 DT = 684 DC.
Levels: Bronze 8 %, Silver 12 % (3 rentals), Gold 16 % (10), Diamond 20 % (25),
counted over 3 months.

## Next steps

1. Wire sign-in. Google: `google_sign_in`. Facebook: `flutter_facebook_auth`.
   WhatsApp: OTP sent by a Cloud Function, then a Firebase custom token.
2. Add Cloud Functions to create the profile, wallet and code on first sign-in,
   and to handle transfers, redemptions and commission validation (7-day hold).
3. Replace the open `firestore.rules`, which expire on 2026-11-12.

## Development

```
flutter pub get
flutter analyze
flutter test
flutter run
```
