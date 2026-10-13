import 'package:flutter/material.dart';

import '../data/app_state.dart';
import 'activity/activity_screen.dart';
import 'home/feed_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'profile/profile_screen.dart';

/// Bottom-nav shell: Accueil (feed) · Marketplace · Activité · Profil.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _tabs = [
    FeedScreen(),
    MarketplaceScreen(),
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
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront_rounded),
            label: 'Marketplace',
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
