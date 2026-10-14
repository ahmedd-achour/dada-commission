# Conception — Dada Commission v2 : le hub des demandes prépayées

Base : **Cloud Firestore** (projet `dada-commission`). Paiement : **Click to Pay**.
Logique d'argent : **Cloud Functions** uniquement.

## 1. Le modèle économique en une ligne

> Le client prépaie **10 %** à Dada → l'ambassadeur reçoit **8 %** en Dada Coins
> **immédiatement** → Dada garde **2 %** → l'agence qui prend la demande encaisse
> les **90 %** restants auprès du client.

| Exemple : Mercedes Classe G, 3 jours | Montant |
|---|---|
| Prix annoncé par l'agence | 736,842 DT |
| Remise code ambassadeur −5 % | −36,842 DT |
| **Total client** | **700,000 DT** |
| Acompte 10 % payé avec Click to Pay → compte Dada | 70,000 DT |
| Ambassadeur 8 % → **560 DC** (10 DC = 1 DT), crédités tout de suite | 56,000 DT |
| Dada garde 2 % | 14,000 DT |
| Payé par le client à l'agence (90 %) | 630,000 DT |

Règles :
- Taux **fixes** pour tous : client −5 %, acompte 10 %, ambassadeur 8 %.
- L'acompte n'est **jamais** reversé à l'agence. Il n'est pas remboursé si le client ne vient pas.
- **Pas de catalogue de voitures** : le fil n'affiche que des **demandes prépayées**, pas de publications de type réseau social.
- Les Dada Coins se **transfèrent** (avec le code du destinataire) et s'**achètent** (Click to Pay, 10 DC = 1 DT).

## 2. Les comptes

| Rôle | Ce qu'il fait |
|---|---|
| `client` | publie une demande avec un code et paie l'acompte de 10 % |
| `ambassador` | partage son code, gagne 8 % en DC à chaque acompte payé (dès 18 ans) |
| `partner` | hôtel, agence de voyage, commerce : comme un ambassadeur, avec un QR à l'accueil |
| `companyAdmin` | agence de location : prend des demandes, contacte le client, loue, marque « louée » |
| `staff` | équipe Dada : valide les agences, gère les litiges |

## 3. Cycle de vie d'une demande

```
awaitingPayment ──(acompte Click to Pay OK)──▶ open ──(agence prend)──▶ claimed ──(agence : louée)──▶ completed
       │                                         │
       └──(client annule)──▶ cancelled           └──(dates dépassées, personne)──▶ expired
```

- `open` : visible par toutes les agences validées, coins **déjà** versés à l'ambassadeur.
- `claimed` : une seule agence ; elle voit le téléphone du client.
- `completed` : l'agence saisit la voiture louée (modèle, immatriculation, prix final). C'est la **source de vérité** de la location.

## 4. Collections

| Collection | Modèle Dart | Qui écrit |
|---|---|---|
| `users/{uid}` | `AppUser` | l'utilisateur (profil) + Functions (rôle, code) |
| `referralCodes/{code}` | — | Functions — garantit l'unicité du code |
| `companies/{id}` | `RentalCompany` | gérant (dossier) + équipe Dada (statut) |
| `requests/{id}` | `RentalRequest` | client (création) · Functions (paiement) · agence (prise, terminée) |
| `requests/{id}/private/contact` | — | client ; lisible par l'agence qui a pris la demande |
| `payments/{id}` | `Payment` | Functions uniquement (Click to Pay) |
| `wallets/{uid}` | `Wallet` | Functions uniquement |
| `wallets/{uid}/transactions/{id}` | `CoinTransaction` | Functions uniquement (historique) |
| `transfers/{id}` | `CoinTransfer` | Functions uniquement |

### `requests/{id}`
| Champ | Remarque |
|---|---|
| `referralCode`, `ambassadorId`, `ambassadorName` | code utilisé (pas le sien) |
| `clientId`, `clientName` | nom affiché masqué dans le fil (« S\*\*\*i ») |
| `carWanted`, `category`, `city`, `startDate`, `endDate`, `note` | la voiture recherchée |
| `listPriceDt` | prix annoncé avant remise |
| `amountDueDt`, `prepaymentDt`, `ambassadorCoins` | copies calculées par le serveur (`RequestPricing`) |
| `status` | voir §3 |
| `paymentId`, `paidAt` | acompte |
| `companyId`, `companyName`, `claimedAt` | agence qui a pris |
| `rentedCar {model, plate, finalPriceDt}`, `completedAt` | saisi par l'agence |

### `payments/{id}`
`userId`, `purpose` (`prepayment` | `coinPurchase`), `amountMillimes`, `status`
(`pending` → `succeeded` | `failed` | `refunded`), `requestId`, `providerOrderId`
(identifiant Click to Pay), `createdAt`, `confirmedAt`.

### `wallets/{uid}/transactions/{id}`
`amount` (+/−, coins entiers), `type` (`referralEarning`, `transferIn`, `transferOut`,
`purchase`, `reversal`, `adjustment`), `title`, `subtitle`, `requestId`,
`transferId`, `paymentId`, `counterpartyId/Name`, `createdAt`.

## 5. Cloud Functions

| Fonction | Déclencheur | Effet |
|---|---|---|
| `onUserCreated` | 1re connexion | `users/{uid}` (`setupComplete: false`), `wallets/{uid}` à 0, code unique |
| `createPrepayment` | appel (client) | recalcule 10 % depuis la demande, enregistre la commande Click to Pay, renvoie l'URL de paiement |
| `confirmPayment` | retour / notification Click to Pay | vérifie la commande auprès de Click to Pay puis, **dans une seule transaction** : paiement `succeeded`, demande `open`, wallet ambassadeur **+8 %**, ligne `referralEarning` |
| `buyCoins` | appel | commande Click to Pay ; à la confirmation : wallet + ligne `purchase` |
| `claimRequest` | appel (agence validée) | `open` → `claimed` (une seule agence, en transaction), ouvre l'accès au contact |
| `completeRequest` | appel (agence qui a pris) | `claimed` → `completed` + voiture louée |
| `transferCoins` | appel | débit / crédit + 2 lignes + `transfers/{id}` |
| `expireRequests` | tous les jours | `open` dont la date de départ est passée → `expired` |
| `reviewCompany` | console Dada | agence `approved` / `rejected` |

Anti-fraude : un client ne peut pas utiliser son propre code (même compte,
même téléphone, même carte de paiement) ; paiement remboursé par Click to Pay
→ ligne `reversal` qui reprend les coins.

## 6. Règles de sécurité (brouillon)

```
match /requests/{id} {
  allow read: if signedIn();
  allow create: if signedIn()
    && request.resource.data.clientId == request.auth.uid
    && request.resource.data.status == 'awaitingPayment';
  allow update, delete: if false;          // tout passe par les Functions
  match /private/{doc} {
    allow read: if signedIn() && (
      get(/databases/$(db)/documents/requests/$(id)).data.clientId == request.auth.uid ||
      get(/databases/$(db)/documents/requests/$(id)).data.companyId ==
        get(/databases/$(db)/documents/users/$(request.auth.uid)).data.companyId);
    allow create: if signedIn()
      && get(/databases/$(db)/documents/requests/$(id)).data.clientId == request.auth.uid;
  }
}
match /payments/{id}  { allow read: if signedIn() && resource.data.userId == request.auth.uid; allow write: if false; }
match /wallets/{uid}  { allow read: if isMe(uid); allow write: if false;
  match /transactions/{t} { allow read: if isMe(uid); allow write: if false; } }
match /transfers/{id} { allow read: if signedIn() && request.auth.uid in [resource.data.fromUserId, resource.data.toUserId]; allow write: if false; }
```

> ⚠️ Les règles actuelles (`firestore.rules`) ouvrent toute la base et expirent le
> **12 novembre 2026**. À remplacer avant la mise en ligne.

## 7. Points ouverts

1. **Personne ne prend la demande** avant la date de départ : rembourser
   l'acompte au client (et reprendre les 8 % à l'ambassadeur) ou garder la
   garantie Dada Rent Car ? Le code marque la demande `expired` sans décider.
2. **Annulation par le client** après paiement : acompte perdu (règle actuelle).
3. **Réglementation** : vente et transfert de coins contre de l'argent = à
   valider avec un juriste (monnaie électronique, BCT).
4. **API Click to Pay** : à brancher dans `ClickToPayGateway`
   (`lib/services/payment_service.dart`) dès réception de la documentation.
