import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'app_colors.dart';

/// Visual treatment for the three trip tiers the backend sends
/// (`economy` | `premium` | `vip`), shared by every trip card so a tier
/// looks the same wherever it appears.
class TripTierStyle {
  /// Icons, price, route plane, feature checks.
  final Color accent;

  /// Day-count box / route plane fill; null → plain [accent].
  final Gradient? gradient;
  final Color cardColor;

  /// Card outline; null → the default card border.
  final Color? borderColor;

  /// Route strip / feature chip wash inside the card.
  final Color softBg;
  final Color footerBg;
  final Color footerBorder;

  /// Small tier badge above the title; null for economy (no badge).
  final FaIconData? badgeIcon;
  final String? badgeLabelKey;

  const TripTierStyle._({
    required this.accent,
    this.gradient,
    required this.cardColor,
    this.borderColor,
    required this.softBg,
    required this.footerBg,
    required this.footerBorder,
    this.badgeIcon,
    this.badgeLabelKey,
  });

  static final vip = TripTierStyle._(
    accent: AppColors.goldDark,
    gradient: AppColors.vipGradient,
    cardColor: const Color(0xFFFFFBF0),
    borderColor: AppColors.gold.withValues(alpha: 0.5),
    softBg: const Color(0xFFFFF4DC),
    footerBg: const Color(0xFFFFF7E6),
    footerBorder: AppColors.gold.withValues(alpha: 0.35),
    badgeIcon: FontAwesomeIcons.crown,
    badgeLabelKey: 'VIP',
  );

  static final premium = TripTierStyle._(
    accent: AppColors.tierPremium,
    gradient: AppColors.premiumGradient,
    cardColor: const Color(0xFFFAFAFA),
    borderColor: AppColors.tierPremium.withValues(alpha: 0.35),
    softBg: const Color(0xFFF0F0F0),
    footerBg: const Color(0xFFF5F5F5),
    footerBorder: AppColors.tierPremium.withValues(alpha: 0.25),
    badgeIcon: FontAwesomeIcons.gem,
    badgeLabelKey: 'trip.type.premium',
  );

  static const economy = TripTierStyle._(
    accent: AppColors.tierEconomy,
    cardColor: Colors.white,
    softBg: AppColors.bg,
    footerBg: Color(0xFFFAFBFF),
    footerBorder: AppColors.border,
  );

  static TripTierStyle of({required bool vip, required bool premium}) =>
      vip ? TripTierStyle.vip : (premium ? TripTierStyle.premium : economy);
}
