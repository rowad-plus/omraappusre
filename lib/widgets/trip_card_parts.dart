import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/trip_tier_style.dart';
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
    final iconColor = trip.vip || trip.premium
        ? TripTierStyle.of(vip: trip.vip, premium: trip.premium).accent
        : (trip.isGreen ? AppColors.green : AppColors.blue);
    // The route reads origin→destination in the row's natural (already
    // auto-mirrored) order, so the icon must face right in LTR and left in
    // RTL to keep pointing toward the destination in both directions.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 7),
      decoration: const BoxDecoration(
          color: Color(0xFFEFF3F8)),
      child: Row(
        children: [
          for (var i = 0; i < stops.length; i++) ...[
            // Endpoints (first/last) keep more of the shrink priority than
            // a middle waypoint (e.g. Mecca on a Cairo→Mecca→Medina route).
            (i == 0 || i == stops.length - 1)
                ? _routeCityLabel(stops[i].city, isEndpoint: true)
                : Flexible(
                    child: _routeCityLabel(stops[i].city, isEndpoint: false)),
            if (i < stops.length - 1) ...[
              const SizedBox(width: 5),
              Expanded(child: Container(height: 6, color: AppColors.border)),
              const SizedBox(width: 4),
              Container(
                width: 24,
                height: 24,
                decoration:
                    BoxDecoration(color: iconColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Transform.scale(
                  scaleX: isRtl ? -1 : 1,
                  child: FaIcon(
                    stops[i].transportToNext == RouteTransport.bus
                        ? FontAwesomeIcons.bus
                        : FontAwesomeIcons.plane,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(child: Container(height: 6, color: AppColors.border)),
              // No trailing gap before the final city label — the row's own
              // 10px padding already puts it exactly 10px from the edge.
              // Earlier waypoints (3+ stop routes) keep the 5px gutter.
              if (i < stops.length - 2) const SizedBox(width: 5),
            ],
          ],
        ],
      ),
    );
  }

  static const _cityStyle = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text);

  TextStyle _midCityStyle(String city) {
    return TextStyle(
        fontSize: city.length > 12 ? 12 : 15,
        fontWeight: FontWeight.w800,
        color: AppColors.text);
  }

  Widget _routeCityLabel(String city, {required bool isEndpoint}) {
    // Endpoints get no Expanded/flex on purpose: city names are always
    // short, so they should only ever take their own natural width. That
    // leaves the connecting-line Expanded segments free to absorb *all* the
    // remaining space, making the route line itself span the full card
    // width instead of being squeezed by an oversized, mostly-empty label
    // box. A middle waypoint (3-stop routes) is wrapped in Flexible by the
    // caller instead, since it sits between two lines with no natural cap.
    final display = tr(city);
    return Text(
      display,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: isEndpoint ? _cityStyle : _midCityStyle(display),
    );
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
          Container(
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
          Container(
              width: 1,
              height: 28,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 10)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.solidCalendar,
                  size: 10, color: AppColors.blue),
              const SizedBox(width: 4),
              Text(tr(trip.date),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
            ],
          ),
        ],
      ),
    );
  }
}

class CardPriceRow extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onBook;
  final String? bookLabel;
  const CardPriceRow(
      {super.key, required this.trip, this.onBook, this.bookLabel});

  @override
  Widget build(BuildContext context) {
    final label = bookLabel ?? tr('trip.card.book');
    final resolvedPrice = tr(trip.price);
    final parts = resolvedPrice.split(' ');
    final hasCurrency = parts.length > 1;
    final amount = hasCurrency
        ? parts.sublist(0, parts.length - 1).join(' ')
        : resolvedPrice;
    final currency = hasCurrency ? parts.last : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: trip.accent, width: 1.3),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(amount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: trip.accent)),
                  ),
                  if (currency.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(currency,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: trip.accent)),
                  ],
                ],
              ),
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
