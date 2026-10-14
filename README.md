# Dada Commission

Android and iOS (Flutter) app: a hub of **prepaid car-rental requests**.

1. A client posts the car they want with an ambassador's code (−5 %) and
   prepays **10 %** to Dada through **Click to Pay**.
2. The ambassador instantly receives **8 %** in **Dada Coins** (10 DC = 1 DT).
   Dada keeps 2 %.
3. Any approved rent-car agency can take the request, contact the client and
   collect the remaining **90 %**. It marks the rental as done.

Dada Coins can be sent to another account (by code) and bought (Click to Pay).

**Documentation (in French)**
- `docs/conception-base-de-donnees.md`: v2 design (money split, request
  lifecycle, collections, Cloud Functions, draft rules, open questions)
- `docs/Guide-Dada-Commission.pdf` and `assets/Dada-Commission-Agences-Partenaires.pdf`:
  illustrated guides written for the **previous** model (tiers, shop); to update.

## Status

- The UI is done and runs in **guest mode** on mock data (`lib/data/mock_data.dart`).
- After sign-in, an **account setup** wizard is required: client, ambassador,
  partner venue, or rent-car agency (company file, documents, conditions).
- Click to Pay is stubbed in `lib/services/payment_service.dart`
  (`ClickToPayGateway`); guest mode uses `DemoPaymentGateway`.
- Sign-in with Facebook, Google and WhatsApp is stubbed in
  `lib/services/auth_service.dart`. The buttons show a "bientôt disponible" message.
- The models are ready for Firestore (`fromJson` / `toJson`).

## Structure

```
lib/
  app.dart                  MaterialApp + auth gate (sign-in / setup / main shell)
  core/                     business rules (rates), theme, formatters
  models/                   data model (see below)
  data/app_state.dart       session state (ChangeNotifier) + AppScope
  data/mock_data.dart       guest-mode demo data
  services/                 auth, payment (Click to Pay), share
  screens/
    auth/                   sign-in (Facebook, Google, WhatsApp, guest)
    setup/                  required account-setup wizard
    main_shell.dart         bottom nav: Accueil · Wallet · Activité · Profil
    requests/               feed of prepaid requests, new request + payment, detail
    wallet/                 Dada Coin wallet (send, receive, buy, history)
    activity/               per role: my referrals / my requests / taken requests
    profile/                profile, code/link/QR, settings
    business/               guide for agencies
    company/                agency space (file status, documents)
  widgets/                  shared UI pieces
```

Colours: Samsung blue (`#1428A0`) and a fresh green (`#14B88A`), with a
blue-to-green gradient for the sign-in screen and wallet cards. Layout follows
`shnell_android_ios_client` (Material 3, Inter body text, Outfit and Poppins
titles, 16 px rounded corners). Car and coin images are Microsoft Fluent Emoji 3D
(MIT, see `assets/images/fluent/CREDITS.md`).

## Data model (Firestore)

| Collection | Model | Notes |
|---|---|---|
| `users/{uid}` | `AppUser` | Profile, role (client, ambassador, partner, companyAdmin, staff), `referralCode` |
| `referralCodes/{code}` | n/a | `{uid}`, guarantees each code is unique |
| `companies/{id}` | `RentalCompany` | Agencies; can take requests once `approved` |
| `requests/{id}` | `RentalRequest` | Prepaid rental request (feed). Phone in `private/contact` |
| `payments/{id}` | `Payment` | Click to Pay orders (prepayment, coin purchase). Server-written |
| `wallets/{uid}` | `Wallet` | Read-only for clients |
| `wallets/{uid}/transactions/{id}` | `CoinTransaction` | Append-only ledger |
| `transfers/{id}` | `CoinTransfer` | Coins sent from one account to another |

The money split lives in `RequestPricing` (`lib/models/rental_request.dart`),
computed in millimes: 700 DT due → 70 DT prepaid → 560 DC to the ambassador →
14 DT to Dada → 630 DT for the agency.

## Next steps

1. Wire Click to Pay (`ClickToPayGateway`) with server-side confirmation.
2. Wire sign-in. Google: `google_sign_in`. Facebook: `flutter_facebook_auth`.
   WhatsApp: OTP sent by a Cloud Function, then a Firebase custom token.
3. Add the Cloud Functions listed in the design doc (payment confirmation +
   coin credit, claim / complete, transfers, coin purchase).
4. Replace the open `firestore.rules`, which expire on 2026-11-12.

## Development

```
flutter pub get
flutter analyze
flutter test
flutter run
```
