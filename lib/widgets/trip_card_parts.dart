import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';
import '../l10n/translations.dart';
import '../models/trip.dart';

/// Shared sub-widgets reused by both trip card styles (`.tc-route`,
/// `.tc-meta-row`, `.tc-price`, `.tc-feats`, `.tc-metas`) plus the detail page.

/// Turns a star-glyph rating (e.g. `'★★★★☆'`) into a compact "4 ⭐" label —
/// a number plus one 3D emoji star instead of a row of flat glyphs.
String starRatingLabel(String starGlyphs) {
  final count = starGlyphs.split('').where((c) => c == '★').length;
  return '$count ⭐';
}

class CardRouteRow extends StatelessWidget {
  final Trip trip;
  const CardRouteRow({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final stops = trip.stops.length >= 2
        ? trip.stops
        : [TripStop('city.cairo'), TripStop(trip.dest, transportToNext: null)];
    // Same look as omraway.com's `.tcc-route`: white strip between two
    // dashed rules, city names joined by thin lines with a gold arrow
    // circle that points toward the destination (left in RTL).
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const _DashedRule(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                for (var i = 0; i < stops.length; i++) ...[
                  (i == 0 || i == stops.length - 1)
                      ? _cityLabel(stops[i].city)
                      : Flexible(child: _cityLabel(stops[i].city)),
                  if (i < stops.length - 1) ...[
                    const Expanded(child: _RouteLine()),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                          color: AppColors.brand, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      // Icons.arrow_forward is already auto-mirrored in RTL
                      // (matchTextDirection), so no manual flip here.
                      child: const Icon(Icons.arrow_forward_rounded,
                          size: 15, color: Colors.white),
                    ),
                    const Expanded(child: _RouteLine()),
                  ],
                ],
              ],
            ),
          ),
          const _DashedRule(),
        ],
      ),
    );
  }

  static const _cityStyle = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text);

  Widget _cityLabel(String city) => Text(tr(city),
      maxLines: 1, overflow: TextOverflow.ellipsis, style: _cityStyle);
}

class _RouteLine extends StatelessWidget {
  const _RouteLine();

  @override
  Widget build(BuildContext context) => Container(
      height: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

/// 1px dashed horizontal rule (CSS `border: 1px dashed`).
class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const dash = 4.0, gap = 3.0;
      final count = (c.maxWidth / (dash + gap)).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
            count,
            (_) => const SizedBox(
                width: dash,
                height: 1,
                child: ColoredBox(color: Color(0xFFDCD3C0)))),
      );
    });
  }
}

class CardMetaRow extends StatelessWidget {
  final Trip trip;
  const CardMetaRow({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
          color: Color(0xFFFAFBFF),
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          // Company logo in the same 24×24 rounded box; the coloured
          // first-letter tile stays as the fallback (no logo / load error).
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: trip.providerLogo != null
                ? CachedNetworkImage(
                    imageUrl: trip.providerLogo!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _letterTile(),
                    errorWidget: (_, __, ___) => _letterTile(),
                  )
                : _letterTile(),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(tr(trip.provider),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600)),
          ),
          // No departure info at all → no divider/calendar icon either,
          // rather than an icon with nothing next to it.
          if (trip.date.isNotEmpty) ...[
            Container(
                width: 1,
                height: 28,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 10)),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(FontAwesomeIcons.solidCalendar,
                      size: 10, color: AppColors.blue),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(tr(trip.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _letterTile() => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
            color: trip.accent, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: Text(tr(trip.provider).firstLetter,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900)),
      );
}

class CardPriceRow extends StatelessWidget {
  /// Site's `--gold-3`: brand gold mixed 72% with black.
  static const _priceBoxColor = Color(0xFF856322);

  final Trip trip;
  final VoidCallback? onBook;
  final String? bookLabel;
  const CardPriceRow(
      {super.key, required this.trip, this.onBook, this.bookLabel});

  @override
  Widget build(BuildContext context) {
    final label = bookLabel ?? tr('trip.card.book');
    // "<amount> <currency words…>" — the amount is the first token, the
    // rest (e.g. "ريال سعودي") is the currency.
    final resolvedPrice = tr(trip.price).trim();
    final space = resolvedPrice.indexOf(' ');
    final amount =
        space < 0 ? resolvedPrice : resolvedPrice.substring(0, space);
    final currency =
        space < 0 ? '' : resolvedPrice.substring(space + 1).trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // omraway.com `.tcc-price`: amount in a dark-gold box, currency
          // in muted text beside it.
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _priceBoxColor,
                      borderRadius: BorderRadius.circular(7)),
                  child: Text(amount,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                if (currency.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(currency,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted)),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onBook,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(9)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(FontAwesomeIcons.solidCalendarCheck,
                      size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatChips extends StatelessWidget {
  final List<String> feats;
  final int max;

  /// When false, chips render on one horizontally-scrollable line instead
  /// of wrapping. Needed anywhere this sits inside an `IntrinsicHeight`
  /// (e.g. TripCardUC's side-by-side layout) — `Wrap`'s intrinsic-height
  /// estimate can be off by a pixel from its actual layout right at a
  /// line-wrap boundary, which throws a RenderFlex overflow. A single
  /// line has no such boundary to get wrong.
  final bool wrap;
  final Color checkColor;
  const FeatChips(
      {super.key,
      required this.feats,
      this.max = 3,
      this.wrap = true,
      this.checkColor = AppColors.green});

  @override
  Widget build(BuildContext context) {
    final shown = feats.take(max).toList();
    final chips = [
      for (final f in shown)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.check, size: 9, color: checkColor),
              const SizedBox(width: 3),
              Text(tr(f),
                  style: const TextStyle(fontSize: 10, color: AppColors.text)),
            ],
          ),
        ),
      if (feats.length > max)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20)),
          child: Text('+${feats.length - max}',
              style: const TextStyle(fontSize: 10, color: AppColors.text)),
        ),
    ];

    if (!wrap) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              chips[i]
            ]
          ],
        ),
      );
    }

    return Wrap(spacing: 5, runSpacing: 5, children: chips);
  }
}

extension on String {
  String get firstLetter => isEmpty ? '' : this[0];
}


/// "مقترح" pill shown on trips of subscribed (featured) companies — same
/// badge as `.suggested-badge` on omraway.com.
class SuggestedBadge extends StatelessWidget {
  const SuggestedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFB78B32), Color(0xFFE6C66F)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF785A1E).withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const FaIcon(FontAwesomeIcons.solidStar,
            size: 8, color: Color(0xFF1A1408)),
        const SizedBox(width: 3),
        Text(tr('trip.card.suggested'),
            style: const TextStyle(
                color: Color(0xFF1A1408),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1.2)),
      ]),
    );
  }
}
