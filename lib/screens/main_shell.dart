import 'package:flutter/material.dart';

import '../data/app_state.dart';
import 'activity/activity_screen.dart';
import 'profile/profile_screen.dart';
import 'requests/feed_screen.dart';
import 'wallet/wallet_screen.dart';

/// Bottom-nav shell: Accueil (requests) · Wallet · Activité · Profil.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _tabs = [
    FeedScreen(),
    WalletScreen(),
    ActivityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: IndexedStack(index: state.tabIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: state.tabIndex,
        onTap: state.setTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights_rounded),
            label: 'Activité',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
