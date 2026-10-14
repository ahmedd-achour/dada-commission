import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../models/models.dart';

/// Round avatar: picked photo bytes, else initials on a tinted background.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.bytes,
    this.radius = 22,
    this.ring,
  });

  final String name;
  final Uint8List? bytes;
  final double radius;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0]).join().toUpperCase();
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      backgroundImage: bytes == null ? null : MemoryImage(bytes!),
      child: bytes == null
          ? Text(
              initials.isEmpty ? '?' : initials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.7,
              ),
            )
          : null,
    );
    if (ring == null) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring!, width: 2.5),
      ),
      child: avatar,
    );
  }
}

/// Avatar of the signed-in user (uses the locally picked photo).
class MyAvatar extends StatelessWidget {
  const MyAvatar({super.key, this.radius = 22, this.ring});
  final double radius;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return UserAvatar(
      name: state.user?.displayName ?? '?',
      bytes: state.photoBytes,
      radius: radius,
      ring: ring,
    );
  }
}

/// "184 DC" pill shown in app bars.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins, this.onTap});
  final int coins;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      shape: StadiumBorder(side: BorderSide(color: scheme.primary, width: 1.2)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.toll_rounded,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                Fmt.coins(coins),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coloured status label ("Terminée", "En cours", "Annulée").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  factory StatusPill.request(RequestStatus status) => StatusPill(
    label: status.label,
    color: switch (status) {
      RequestStatus.open => AppTheme.blueBright,
      RequestStatus.claimed => AppTheme.warning,
      RequestStatus.completed => AppTheme.success,
      RequestStatus.awaitingPayment => AppTheme.navUnselected,
      RequestStatus.cancelled || RequestStatus.expired => AppTheme.danger,
    },
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Image from the app bundle (`assets/...`) or the network (`https://...`,
/// e.g. Firebase Storage). Shows [fallback] while loading or on error.
class AppImage extends StatelessWidget {
  const AppImage(
    this.source, {
    super.key,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  final String? source;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final src = source;
    if (src == null || src.isEmpty) return fallback;
    Widget onError(BuildContext _, Object _, StackTrace? _) => fallback;
    return src.startsWith('http')
        ? Image.network(src, fit: fit, errorBuilder: onError)
        : Image.asset(src, fit: fit, errorBuilder: onError);
  }
}

/// 3D illustration for a car category (until agencies upload photos).
String? categoryImage(CarCategory? category) => switch (category) {
  null => null,
  CarCategory.citadine => 'assets/images/fluent/car_citadine.png',
  CarCategory.compacte ||
  CarCategory.berline => 'assets/images/fluent/car_berline.png',
  CarCategory.suv => 'assets/images/fluent/car_suv.png',
  CarCategory.utilitaire => 'assets/images/fluent/car_utilitaire.png',
  CarCategory.luxe => 'assets/images/fluent/car_luxe.png',
};

/// Car picture on a soft brand-tinted card (icon fallback).
class CarImage extends StatelessWidget {
  const CarImage({
    super.key,
    this.height = 170,
    this.label,
    this.category,
    this.imageUrl,
  });
  final double height;
  final String? label;
  final CarCategory? category;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (category) {
      CarCategory.suv => Icons.directions_car_filled_rounded,
      CarCategory.utilitaire => Icons.airport_shuttle_rounded,
      CarCategory.luxe => Icons.electric_car_rounded,
      _ => Icons.directions_car_rounded,
    };
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(height * 0.1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.55),
            AppTheme.green.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: AppImage(
              imageUrl ?? categoryImage(category),
              fallback: FittedBox(
                child: Icon(icon, size: height * 0.38, color: scheme.outline),
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Blue -> green brand card (wallet, setup header).
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius + 6),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}

/// QR code of a referral link (always on white so scanners can read it).
class ReferralQr extends StatelessWidget {
  const ReferralQr({super.key, required this.data, this.size = 180});
  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: QrImageView(
        data: data,
        size: size,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}

Future<void> copyText(
  BuildContext context,
  String text, {
  String? message,
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  showSnack(context, message ?? 'Copié : $text');
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppTheme.danger : null,
    ),
  );
}
