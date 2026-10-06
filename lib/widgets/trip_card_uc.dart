import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants/app_dims.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/trip_tier_style.dart';
import '../l10n/translations.dart';
import '../models/trip.dart';
import 'trip_card_parts.dart';

/// Mirrors `.uc` — the side-image trip card style used on the Umrah tab
/// and the home page's umrah VIP section.
class TripCardUC extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  /// "مقترح" badge for subscribed companies — only in search / all-trips lists.
  final bool showSuggested;

  const TripCardUC(
      {super.key,
      required this.trip,
      this.onTap,
      this.onBook,
      this.showSuggested = false});

  /// The day-count badge sits 5px in from the card's physical top and
  /// left edges — no longer flush, so it doesn't need to fight the
  /// card's border stroke there.
  static const double _daysBadgeInset = 5.0;

  @override
  Widget build(BuildContext context) {
    // The image follows the language direction (start = right in RTL, left
    // in LTR), but the day-count badge is pinned to the card's physical
    // left edge always — so in LTR they'd land on the same side. Reserve
    // both zones there together in that case instead of letting them overlap.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final tier = TripTierStyle.of(vip: trip.vip, premium: trip.premium);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        // The image sits flush against the top + start edge with zero
        // gap, so that corner must stay sharp — a rounded clip there would
        // carve a visible curved sliver out of the image instead of a
        // clean flush edge. The day-count badge is inset 5px now (not
        // flush), so its corner keeps the normal rounding like the
        // bottom two.
        // VIP / premium trips get their tier's treatment on the card itself
        // (a light tinted wash + thin colored outline) instead of
        // badges/frames competing with the photo.
        decoration: AppDims.card(
          color: tier.cardColor,
          borderColor: tier.borderColor,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.zero,
            topEnd: const Radius.circular(AppDims.radius),
            bottomStart: const Radius.circular(AppDims.radius),
            bottomEnd: const Radius.circular(AppDims.radius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Fixed height so the image + day-count zone stay the same size
            // on every card — previously the Stack sized itself to the text
            // column (title/rating/feats), so a 2-line title made that
            // card's image taller than a 1-line-title card's, and the whole
            // header block looked inconsistent card to card.
            SizedBox(
              height: 108,
              // StackFit.expand forces this Stack to the card's full width
              // always. Without it (default StackFit.loose), the Stack
              // sizes itself to its widest non-positioned child — the
              // title/meta Column — so a short title left it narrower than
              // the card, and the image/badge (positioned relative to the
              // Stack's own bounds) sat flush to that shrunk edge instead
              // of the card's real edge: a real gap, not a border pixel.
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    // Title/meta block is 100% - 169px: 95px image + 5px
                    // gap on one side, 5px + 62px badge + 5px gap on the
                    // other — opposite sides in RTL, stacked together on
                    // the left in LTR.
                    padding: EdgeInsets.only(
                      right: isRtl ? 100 : 0,
                      left: isRtl ? 69 : 169,
                      top: 11,
                      bottom: 11,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showSuggested && trip.featured) ...[
                          const SuggestedBadge(),
                          const SizedBox(height: 3),
                        ],
                        if (tier.badgeIcon != null) ...[
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            FaIcon(tier.badgeIcon!,
                                size: 9, color: tier.accent),
                            const SizedBox(width: 4),
                            Text(tr(tier.badgeLabelKey!),
                                style: TextStyle(
                                    color: tier.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5)),
                          ]),
                          const SizedBox(height: 3),
                        ],
                        Text(tr(trip.title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text)),
                        const SizedBox(height: 5),
                        _metaItem(FontAwesomeIcons.solidBuilding,
                            starRatingLabel(trip.stars)),
                        const SizedBox(height: 6),
                        FeatChips(
                            feats: trip.feats,
                            max: 3,
                            wrap: false,
                            checkColor: tier.accent),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    // Flush against the card's top + start edge: top:0,
                    // end-of-card:0 (physical top-right in RTL).
                    start: 0,
                    top: 0,
                    bottom: 0,
                    width: 95,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minHeight: 90),
                          decoration: BoxDecoration(gradient: trip.bg),
                          // foregroundDecoration paints after the child, so
                          // the border stays visible on top of the photo
                          // instead of being covered by it.
                          foregroundDecoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.greenLight, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: trip.networkImage != null
                              ? CachedNetworkImage(
                                  imageUrl: trip.networkImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fadeInDuration:
                                      const Duration(milliseconds: 150),
                                  placeholder: (_, __) => const Center(
                                      child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))),
                                  errorWidget: (_, __, ___) => Text(trip.emoji,
                                      style: const TextStyle(fontSize: 32)))
                              : trip.imageAsset != null
                                  ? Image.asset(trip.imageAsset!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity)
                                  : trip.iconAsset != null
                                      ? Image.asset(trip.iconAsset!,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.contain)
                                      : Text(trip.emoji,
                                          style:
                                              TextStyle(fontSize: 32, shadows: [
                                            Shadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 9,
                                                offset: const Offset(0, 4)),
                                            Shadow(
                                                color: Colors.white
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 1.5,
                                                offset: const Offset(-1, -1)),
                                          ])),
                        ),
                        // No VIP badge on the image itself anymore — the
                        // card's own gold border/background wash (below)
                        // and the gold day-count box already signal VIP
                        // status without cluttering the photo.
                        // Every trip on this platform is Umrah by default —
                        // a badge saying so on every single card is just
                        // noise. Only worth calling out when a trip is
                        // actually Hajj instead, which stands out from the
                        // norm.
                        if (trip.programType == 'trip.program.hajj')
                          PositionedDirectional(
                            top: 6,
                            end: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.green.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(tr('trip.card.badge_hajj'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    // Always the card's physical top-left corner — not
                    // direction-relative — sitting right after the image
                    // when the image shares that side too (LTR). Inset
                    // 5px from both edges, not flush, so fully rounded.
                    top: _daysBadgeInset,
                    left: isRtl ? _daysBadgeInset : 95,
                    width: 62,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: tier.gradient == null ? trip.accent : null,
                        gradient: tier.gradient,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_dayNumber(tr(trip.days)),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1)),
                          Text(tr('trip.days.unit'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CardRouteRow(trip: trip),
            CardMetaRow(trip: trip),
            CardPriceRow(trip: trip, onBook: onBook),
          ],
        ),
      ),
    );
  }

  /// Pulls just the leading digit run out of a resolved days phrase (e.g.
  /// "٧ أيام" or "7 days") for the big number in the day-count box —
  /// handles both Arabic-Indic and Latin digits.
  String _dayNumber(String resolvedDays) {
    final match = RegExp(r'[0-9٠-٩]+').firstMatch(resolvedDays);
    return match?.group(0) ?? resolvedDays;
  }

  Widget _metaItem(FaIconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      FaIcon(icon, size: 10, color: AppColors.blue),
      const SizedBox(width: 3),
      Flexible(
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
      ),
    ]);
  }
}
