import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/user_sheet.dart';
import 'create_post_screen.dart';
import 'post_card.dart';

/// Accueil: Facebook-style feed where every car post can be booked with its
/// author's code.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Dada Commission', style: AppTheme.display(fontSize: 22)),
        actions: [
          CoinChip(
            coins: state.wallet.balance,
            onTap: () => AppScope.read(context).setTab(1),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            Future<void>.delayed(const Duration(milliseconds: 400)),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: state.posts.length + 2,
          itemBuilder: (context, i) {
            if (i == 0) return const _StoriesRow();
            if (i == 1) return const _Composer();
            return PostCard(post: state.posts[i - 2]);
          },
        ),
      ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _Story(
            label: 'Vous',
            onTap: () => _openComposer(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const MyAvatar(radius: 26),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: scheme.primary,
                    child: Icon(Icons.add, size: 14, color: scheme.onPrimary),
                  ),
                ),
              ],
            ),
          ),
          for (final u in state.directory)
            _Story(
              label: u.displayName.split(' ').first,
              onTap: () => showUserSheet(context, u),
              child: UserAvatar(
                name: u.displayName,
                radius: 23,
                ring: u.role == UserRole.companyAdmin
                    ? AppTheme.blue
                    : AppTheme.tierColor(u.tier).withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.label, required this.child, required this.onTap});
  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            child,
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.surfaceContainerHighest, width: 8),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const MyAvatar(radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _openComposer(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      'Quoi de neuf ?',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _ComposerAction(
                icon: Icons.photo_library_outlined,
                color: Colors.green,
                label: 'Photo',
                onTap: () => _openComposer(context),
              ),
              _ComposerAction(
                icon: Icons.campaign_outlined,
                color: AppTheme.green,
                label: 'Promo',
                onTap: () => AppScope.read(context).setTab(1),
              ),
              _ComposerAction(
                icon: Icons.toll_outlined,
                color: scheme.primary,
                label: 'Mon gain',
                onTap: () => AppScope.read(context).setTab(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

void _openComposer(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
}
