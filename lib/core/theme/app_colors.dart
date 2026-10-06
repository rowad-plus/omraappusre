import 'package:flutter/material.dart';

/// Mirrors the CSS custom properties from rehlaty.html (:root block).
class AppColors {
  AppColors._();

  /// Brand gold (2026-10-06: the whole app moved from blue/green to one
  /// gold colour, matching omraway.com). `blue`/`green` are kept as names
  /// so existing widgets pick the gold up without touching each one.
  static const brand = Color(0xFFB8892F);
  static const brandLight = Color(0xFFD9B45F);
  static const brandDark = Color(0xFF8E6A28);
  static const brandSoft = Color(0xFFFBF5E8);
  static const brandLine = Color(0xFFEEDDB8);

  /// Trip-tier colours stay distinct from the brand gold so VIP / premium /
  /// economy trips are told apart at a glance (VIP gold, premium purple,
  /// economy green).
  static const tierVip = Color(0xFFB8892F);
  static const tierVipDark = Color(0xFF8E6A28);
  static const tierPremium = Color(0xFF7C3AED);
  static const tierPremiumDark = Color(0xFF6D28D9);
  static const tierEconomy = Color(0xFF16A34A);
  static const tierEconomyDark = Color(0xFF15803D);

  static const blue = brand;
  static const blueLight = brandSoft;
  static const green = brand;
  static const greenLight = brandSoft;
  static const gold = brand;
  static const goldDark = brandDark;
  static const bg = Color(0xFFFAF8F3);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFECE6D8);

  /// body background behind the 430px app frame
  static const outerBg = Color(0xFFEFEAE0);

  static const red = Color(0xFFE84040);
  static const purple = Color(0xFF7C3AED);
  static const teal = brandDark;
  static const emerald = brandDark;
  static const sky = brandLight;
  static const violet = Color(0xFF6D28D9);
  static const rose = Color(0xFFE11D48);
  static const cyan = brand;
  static const orange = Color(0xFFC2410C);
  static const whatsapp = Color(0xFF25D366);

  static const vipGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB78B32), Color(0xFFE6C66F)],
  );

  static const premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tierPremium, tierPremiumDark],
  );

  static const economyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tierEconomy, tierEconomyDark],
  );

  static const greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, brandLight],
  );

  static const blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandDark, brand],
  );

  /// Rotating palette used for avatars / provider / company logos.
  static const List<Color> avatarPalette = [
    green,
    goldDark,
    teal,
    blue,
    purple,
    Color(0xFFDC2626),
    emerald,
    violet,
    sky,
    rose,
    cyan,
    orange,
  ];

  static Color avatarColorFor(int seed) =>
      avatarPalette[seed.abs() % avatarPalette.length];
}
