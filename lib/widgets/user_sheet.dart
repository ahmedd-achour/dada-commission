import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../screens/wallet/transfer_screen.dart';
import 'common.dart';

/// Mini public profile of another account, with "Envoyer des coins".
void showUserSheet(BuildContext context, AppUser user) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(name: user.displayName, radius: 36),
            const SizedBox(height: 12),
            Text(user.displayName, style: AppTheme.display(fontSize: 22)),
            const SizedBox(height: 4),
            if (user.role == UserRole.ambassador)
              TierBadge(tier: user.tier)
            else
              Text(user.role.label),
            if (user.bio != null) ...[
              const SizedBox(height: 8),
              Text(user.bio!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 8),
            Text(
              ['Code ${user.referralCode}', ?user.city].join(' · '),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.send_rounded),
                label: const Text('Envoyer des coins'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          TransferScreen(initialCode: user.referralCode),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
