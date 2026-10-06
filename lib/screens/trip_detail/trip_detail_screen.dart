import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/trip_tier_style.dart';
import '../../l10n/translations.dart';
import '../../models/api_trip.dart';
import '../../models/trip.dart';
import '../../state/app_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/h_scroll_auto.dart';
import '../../widgets/trip_card_parts.dart';
import '../auth/login_sheet.dart';
import '../booking/booking_sheet.dart';

class _ProgStep {
  final String day;
  final String title;
  final String loc;
  final List<String> acts;
  const _ProgStep(this.day, this.title, this.loc, this.acts);
}

const _umrahProgram = [
  _ProgStep('١', 'trip.detail.itinerary.step1_title',
      'trip.detail.itinerary.step1_loc', [
    'trip.detail.itinerary.step1_act1',
    'trip.detail.itinerary.step1_act2',
    'trip.detail.itinerary.step1_act3'
  ]),
  _ProgStep('٢', 'trip.detail.itinerary.step2_title',
      'trip.detail.itinerary.step2_loc', [
    'trip.detail.itinerary.step2_act1',
    'trip.detail.itinerary.step2_act2',
    'trip.detail.itinerary.step2_act3'
  ]),
  _ProgStep('٣', 'trip.detail.itinerary.step3_title',
      'trip.detail.itinerary.step3_loc', [
    'trip.detail.itinerary.step3_act1',
    'trip.detail.itinerary.step3_act2',
    'trip.detail.itinerary.step3_act3'
  ]),
  _ProgStep('٤', 'trip.detail.itinerary.step4_title', 'city.madinah', [
    'trip.detail.itinerary.step4_act1',
    'trip.detail.itinerary.step4_act2',
    'trip.detail.itinerary.step4_act3'
  ]),
  _ProgStep('٥', 'trip.detail.itinerary.step5_title', 'city.madinah', [
    'trip.detail.itinerary.step5_act1',
    'trip.detail.itinerary.step5_act2',
    'trip.detail.itinerary.step5_act3'
  ]),
  _ProgStep(
      '🕊️',
      'trip.detail.itinerary.step6_title',
      'trip.detail.itinerary.step6_loc',
      ['trip.detail.itinerary.step6_act1', 'trip.detail.itinerary.step6_act2']),
];

class _DateOption {
  final String month;
  final String day;
  final String price;
  const _DateOption(this.month, this.day, this.price);
}

const _sampleDates = [
  _DateOption('trip.detail.month.march', '٠٥', '٢٥,٠٠٠ ج'),
  _DateOption('trip.detail.month.march', '١٢', '٢٧,٠٠٠ ج'),
  _DateOption('trip.detail.month.april', '٠٢', '٢٥,٠٠٠ ج'),
  _DateOption('trip.detail.month.april', '١٦', '٢٩,٠٠٠ ج'),
  _DateOption('trip.detail.month.may', '٠١', '٢٦,٠٠٠ ج'),
];

const _monthShort = [
  '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

/// Mirrors `#pg-detail` populated by `openDetail(data)` in rehlaty.html.
/// When [trip] carries a real backend id, the full record (real itinerary,
/// dates, photos) is fetched and takes over from the placeholder content.
class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  /// A date already picked on the search page (`Y-m-d`) — see
  /// `BookingSheet.initialDate`, threaded straight through to it.
  final String? initialDate;
  const TripDetailScreen({super.key, required this.trip, this.initialDate});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _saved = false;
  bool _compared = false;
  int _selectedDate = 0;
  ApiTrip? _detail;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    if (widget.trip.apiId != null) {
      _loadingDetail = true;
      context.read<AppState>().fetchTripDetail(widget.trip.apiId!).then((d) {
        if (!mounted) return;
        setState(() {
          _detail = d;
          _loadingDetail = false;
          _saved = d?.isFavorited ?? false;
          _compared = d?.isCompared ?? false;
        });
      });
    }
  }

  Future<void> _toggleSaved() async {
    if (!context.read<AppState>().isLoggedIn) {
      openLoginSheet(context);
      return;
    }
    final tripId = widget.trip.apiId;
    if (tripId == null) {
      setState(() => _saved = !_saved);
      return;
    }
    final previous = _saved;
    setState(() => _saved = !_saved);
    final active = await context.read<AppState>().toggleFavorite(tripId);
    if (!mounted) return;
    if (active == null) setState(() => _saved = previous);
  }

  /// Mirrors the website's own 3-trip cap exactly (see
  /// `Api\ComparisonController::toggle()`) — surfaces that as a toast
  /// instead of silently failing.
  Future<void> _toggleCompared() async {
    if (!context.read<AppState>().isLoggedIn) {
      openLoginSheet(context);
      return;
    }
    final tripId = widget.trip.apiId;
    if (tripId == null) return;
    final previous = _compared;
    setState(() => _compared = !_compared);
    final result = await context.read<AppState>().toggleComparison(tripId);
    if (!mounted) return;
    if (result == 'max_reached') {
      setState(() => _compared = previous);
      showAppToast(context, '⚠️ ${tr('comparisons.max_reached')}');
    } else if (result is bool) {
      showAppToast(context,
          result ? tr('comparisons.added_toast') : tr('comparisons.removed_toast'));
    } else {
      setState(() => _compared = previous);
    }
  }

  void _openBooking() {
    if (!context.read<AppState>().isLoggedIn) {
      openLoginSheet(context);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BookingSheet(trip: widget.trip, initialDate: widget.initialDate),
    ));
  }

  /// True once detail has loaded and the trip genuinely has no server-side
  /// day-by-day program — [_program] is about to fall back to the generic
  /// placeholder itinerary, which needs to say so instead of looking real.
  bool get _usingSampleProgram =>
      !_loadingDetail && (_detail?.programs == null || _detail!.programs!.isEmpty);

  /// Same idea for [_dates] falling back to made-up sample dates/prices.
  bool get _usingSampleDates =>
      !_loadingDetail && (_detail?.dates == null || _detail!.dates!.isEmpty);

  List<_ProgStep> get _program {
    final programs = _detail?.programs;
    if (programs == null || programs.isEmpty) return _umrahProgram;
    return programs
        .map((p) => _ProgStep(
              '${p.dayNumber}',
              p.title ?? '',
              p.location ?? '',
              p.steps,
            ))
        .toList();
  }

  List<_DateOption> get _dates {
    final dates = _detail?.dates;
    if (dates == null || dates.isEmpty) return _sampleDates;
    final priceLabel = widget.trip.price;
    return dates.map((d) {
      final date = DateTime.tryParse(d.departureDate);
      final month = date != null ? _monthShort[date.month] : '';
      final day = date != null ? '${date.day}'.padLeft(2, '0') : '';
      return _DateOption(month, day, priceLabel);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    final program = _program;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageHeader(t),
                  _buildTitleBlock(t),
                  _buildPriceRow(t),
                  _section(
                    icon: FontAwesomeIcons.route,
                    title: tr('trip.detail.section_route'),
                    child: CardRouteRow(trip: t),
                  ),
                  _section(
                    icon: FontAwesomeIcons.solidStar,
                    title: tr('trip.detail.section_features'),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in t.feats)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const FaIcon(FontAwesomeIcons.check,
                                  size: 11, color: AppColors.green),
                              const SizedBox(width: 5),
                              Text(tr(f),
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text)),
                            ]),
                          ),
                      ],
                    ),
                  ),
                  _section(
                    icon: FontAwesomeIcons.circleInfo,
                    title: tr('trip.detail.section_details'),
                    child: Column(children: [
                      _infoRow(FontAwesomeIcons.solidBuilding,
                          tr('trip.detail.label_hotel'), tr(t.hotel)),
                      _infoRow(FontAwesomeIcons.locationDot,
                          tr('trip.detail.label_location'), tr(t.dest)),
                      _infoRow(FontAwesomeIcons.solidCalendar,
                          tr('trip.detail.label_trip_date'), t.date),
                      _infoRow(FontAwesomeIcons.solidClock,
                          tr('trip.detail.label_duration'), t.days),
                      _infoRow(FontAwesomeIcons.users, tr('trip.filter.type'),
                          t.travelers,
                          isLast: true),
                    ]),
                  ),
                  _section(
                    icon: FontAwesomeIcons.solidBuilding,
                    title: tr('trip.detail.section_provider'),
                    child: _infoRow(FontAwesomeIcons.solidBuilding,
                        tr('trip.detail.section_provider'), tr(t.provider),
                        isLast: true),
                  ),
                  _section(
                    icon: FontAwesomeIcons.solidCalendar,
                    title: tr('trip.detail.section_dates'),
                    sample: _usingSampleDates,
                    child: _loadingDetail ? _miniLoader() : _buildDatesScroll(),
                  ),
                  _section(
                    icon: FontAwesomeIcons.solidMap,
                    title: tr('trip.detail.section_itinerary'),
                    sample: _usingSampleProgram,
                    child: _loadingDetail
                        ? _miniLoader()
                        : Column(children: [
                            for (final p in program) _progItem(p, t.isGreen)
                          ]),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _stickyBottom(t),
        ],
      ),
    );
  }

  Widget _miniLoader() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );

  Widget _buildImageHeader(Trip t) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Same CachedNetworkImage/URL as the trip card, so the photo is
          // already on disk and shows instantly, filling the whole header.
          // While it loads (or if it fails) only a neutral grey shows —
          // no green gradient or emoji peeking from underneath.
          t.networkImage != null
              ? CachedNetworkImage(
                  imageUrl: t.networkImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  fadeInDuration: const Duration(milliseconds: 120),
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, __) =>
                      const ColoredBox(color: Color(0xFFE5E7EB)),
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFFE5E7EB)),
                )
              : Container(
                  decoration: BoxDecoration(gradient: t.bg),
                  alignment: Alignment.center,
                  child: Text(t.emoji, style: const TextStyle(fontSize: 80)),
                ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x99000000), Colors.transparent]),
            ),
          ),
          PositionedDirectional(
            top: 10,
            start: 14,
            child: _circleBtn(
                Directionality.of(context) == TextDirection.rtl
                    ? FontAwesomeIcons.arrowRight
                    : FontAwesomeIcons.arrowLeft,
                () => Navigator.of(context).maybePop()),
          ),
          PositionedDirectional(
            top: 10,
            end: 14,
            child: _circleBtn(
              FontAwesomeIcons.solidHeart,
              _toggleSaved,
              color: _saved ? const Color(0xFFE84040) : Colors.white,
            ),
          ),
          PositionedDirectional(
            top: 10,
            end: 62,
            child: _circleBtn(
              FontAwesomeIcons.scaleBalanced,
              _toggleCompared,
              color: _compared ? const Color(0xFFB8892F) : Colors.white,
            ),
          ),
          if (t.vip || t.premium)
            PositionedDirectional(
              top: 90,
              end: 12,
              child: Builder(builder: (context) {
                final tier = TripTierStyle.of(vip: t.vip, premium: t.premium);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      gradient: tier.gradient,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    FaIcon(tier.badgeIcon!, size: 9, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(tr(tier.badgeLabelKey!),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ]),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _circleBtn(FaIconData icon, VoidCallback onTap,
      {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: FaIcon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildTitleBlock(Trip t) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(t.title),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          Row(children: [
            const FaIcon(FontAwesomeIcons.solidBuilding,
                size: 11, color: AppColors.muted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(tr(t.hotel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
            const SizedBox(width: 8),
            Text('|', style: TextStyle(color: AppColors.border)),
            const SizedBox(width: 8),
            Text(t.stars,
                style: const TextStyle(fontSize: 12, color: AppColors.gold)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: t.isGreen ? AppColors.greenLight : AppColors.blueLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tr(t.type),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: t.isGreen ? AppColors.green : AppColors.blue)),
              ),
              const Text('·', style: TextStyle(color: AppColors.muted)),
              const FaIcon(FontAwesomeIcons.solidCalendar,
                  size: 10, color: AppColors.muted),
              Text(tr(t.days),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const Text('·', style: TextStyle(color: AppColors.muted)),
              const FaIcon(FontAwesomeIcons.users,
                  size: 10, color: AppColors.muted),
              Text(tr(t.travelers),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(Trip t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border:
            Border.symmetric(horizontal: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('trip.detail.price_from'),
                  style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              Text(tr(t.price),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: t.accent)),
            ]),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openBooking,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                  color: t.accent, borderRadius: BorderRadius.circular(11)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const FaIcon(FontAwesomeIcons.solidCalendarCheck,
                    size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(tr('trip.detail.book_now'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
      {required FaIconData icon,
      required String title,
      required Widget child,
      bool sample = false}) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            FaIcon(icon, size: 13, color: AppColors.gold),
            const SizedBox(width: 6),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
            ),
            if (sample) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(tr('trip.detail.sample_data_badge'),
                    style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706))),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(FaIconData icon, String label, String value,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Row(children: [
            FaIcon(icon, size: 12, color: AppColors.blue),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesScroll() {
    final dates = _dates;
    if (dates.isEmpty) {
      return Text(tr('trip.country.no_content_title'),
          style: const TextStyle(fontSize: 12, color: AppColors.muted));
    }
    return HScrollAuto(
      itemCount: dates.length,
      spacing: 8,
      itemBuilder: (context, i) {
        final d = dates[i];
        final selected = i == _selectedDate;
        return GestureDetector(
          onTap: () => setState(() => _selectedDate = i),
          child: Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.blue : AppColors.bg,
              border: Border.all(color: AppColors.blue, width: 1.5),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tr(d.month),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.text)),
                Text(d.day,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : AppColors.text)),
                Text(tr(d.price),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white70 : AppColors.green)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _progItem(_ProgStep p, bool isGreen) {
    final isLastDay = p.day.length > 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isGreen || isLastDay)
                  ? AppColors.greenLight
                  : AppColors.blueLight,
              shape: BoxShape.circle,
              border: Border.all(
                  color:
                      (isGreen || isLastDay) ? AppColors.green : AppColors.blue,
                  width: 2),
            ),
            alignment: Alignment.center,
            child: Text(p.day,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: (isGreen || isLastDay)
                        ? AppColors.green
                        : AppColors.blue)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(p.title),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 3),
                Row(children: [
                  const FaIcon(FontAwesomeIcons.locationDot,
                      size: 10, color: AppColors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(tr(p.loc),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted))),
                ]),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final a in p.acts)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.bg,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(tr(a),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.text)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickyBottom(Trip t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              FaIcon(FontAwesomeIcons.solidCalendar, size: 14, color: t.accent),
              const SizedBox(width: 5),
              Text(tr(t.days),
                  style: TextStyle(
                      color: t.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _openBooking,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    color: t.accent, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const FaIcon(FontAwesomeIcons.solidCalendarCheck,
                      size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(tr('trip.detail.book_now'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
