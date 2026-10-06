import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/trip_tier_style.dart';
import '../l10n/translations.dart';
import '../models/trip.dart';

/// Home-page trip card in the gold design shared with omraway.com
/// (`_trip-card-gold.blade.php`): photo on top with the destination chip,
/// tier tag, title, meta line, price + date, and a full-width gold
/// "book your umrah" button.
class TripCardGold extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  const TripCardGold({super.key, required this.trip, this.onTap, this.onBook});

  static const _goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB78B32), Color(0xFFE6C66F)],
  );

  @override
  Widget build(BuildContext context) {
    // First stop is the departure city; the rest are the destinations.
    final destinations =
        trip.stops.length > 1 ? trip.stops.skip(1).toList() : trip.stops;
    final placeLabel =
        destinations.isNotEmpty ? tr(destinations.first.city) : tr(trip.dest);

    // trip.price is "<amount> <currency>", where the currency may be a
    // long name like "Saudi Riyal (SAR)" — show the ISO code when present.
    final rawPrice = tr(trip.price).trim();
    final space = rawPrice.indexOf(' ');
    final amountRaw = space < 0 ? rawPrice : rawPrice.substring(0, space);
    final currencyRaw = space < 0 ? '' : rawPrice.substring(space + 1).trim();
    final code = RegExp(r'\(([A-Za-z]{3})\)').firstMatch(currencyRaw)?.group(1);
    final currency = code ?? currencyRaw;
    final amount = _groupThousands(amountRaw);

    final date = DateTime.tryParse(trip.date);
    final dateLabel = date == null
        ? (trip.date.isEmpty ? null : tr(trip.date))
        : '${date.day}/${date.month}/${date.year}';

    final tag = trip.vip ? 'VIP' : tr('trip.type.premium');

    // Each tier keeps its own colour (VIP gold, premium purple, economy
    // green) for the tag, icons, price, outline and button.
    final style = TripTierStyle.of(vip: trip.vip, premium: trip.premium);
    final accent = style.accent;
    final buttonGradient = trip.vip
        ? _goldGradient
        : (style.gradient ?? AppColors.economyGradient);
    final buttonText = trip.vip ? const Color(0xFF1A1408) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.borderColor ?? AppColors.border),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF785A1E).withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 165,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _image(),
                  // No "مقترح" badge on home — only search / all-trips lists.
                  PositionedDirectional(
                    bottom: 12,
                    start: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xEE0B0B0A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.brand),
                      ),
                      child: Text(placeLabel,
                          style: const TextStyle(
                              color: Color(0xFFEFD47D),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title at the start (right in Arabic), trip type at the end.
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Text(tr(trip.title),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                              height: 1.35)),
                    ),
                    // Economy cards carry no tier tag — only VIP / premium.
                    if (trip.vip || trip.premium) ...[
                      const SizedBox(width: 8),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: style.softBg,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: accent.withValues(alpha: 0.35)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (style.badgeIcon != null) ...[
                            FaIcon(style.badgeIcon!, size: 9, color: accent),
                            const SizedBox(width: 4),
                          ],
                          Text(tag,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent)),
                        ]),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      if (destinations.isNotEmpty)
                        _meta(
                            FontAwesomeIcons.locationDot,
                            destinations.map((s) => tr(s.city)).join(' + '),
                            accent),
                      _meta(
                          FontAwesomeIcons.solidClock,
                          '${_dayNumber(tr(trip.days))} ${tr('trip.days.unit')}',
                          accent),
                      if (trip.provider.isNotEmpty)
                        _meta(FontAwesomeIcons.solidBuilding, tr(trip.provider),
                            accent),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(amount,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                      color: accent)),
                            ),
                            if (currency.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(currency,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: accent)),
                            ],
                          ],
                        ),
                      ),
                      if (dateLabel != null)
                        Text(dateLabel,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onBook,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: buttonGradient,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent),
                      ),
                      child: Text(tr('trip.card.book_umrah'),
                          style: TextStyle(
                              color: buttonText,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Leading digit run of a resolved days phrase ("٧ أيام" / "7 days").
  String _dayNumber(String resolved) =>
      RegExp(r'[0-9٠-٩]+').firstMatch(resolved)?.group(0) ?? resolved;

  String _groupThousands(String digits) {
    if (!RegExp(r'^\d+$').hasMatch(digits)) return digits;
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  Widget _meta(FaIconData icon, String text, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        FaIcon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ),
      ]);

  Widget _image() {
    const placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9DCC0), Color(0xFFF8F1E1)],
        ),
      ),
      child: Center(
          child:
              FaIcon(FontAwesomeIcons.kaaba, size: 40, color: AppColors.brand)),
    );
    if (trip.networkImage != null) {
      return CachedNetworkImage(
        imageUrl: trip.networkImage!,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }
    if (trip.imageAsset != null) {
      return Image.asset(trip.imageAsset!, fit: BoxFit.cover);
    }
    return placeholder;
  }
}
