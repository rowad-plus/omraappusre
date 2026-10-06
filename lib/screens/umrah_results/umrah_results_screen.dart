import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/trip_tier_style.dart';
import '../../core/constants/app_dims.dart';
import '../../l10n/translations.dart';
import '../../models/api_trip.dart';
import '../../models/schedule_result.dart';
import '../../models/trip.dart';
import '../../models/umrah_result.dart';
import '../../state/app_state.dart';
import '../../state/country_state.dart';
import '../../state/locale_state.dart';
import '../../state/nav_state.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/h_scroll_auto.dart';
import '../../widgets/trip_card_parts.dart';
import '../trip_detail/trip_detail_screen.dart';

enum _SortMode {
  nearest,
  priceLowToHigh,
  priceHighToLow,
  ratingHighToLow,
  ratingLowToHigh,
  starsHighToLow,
  starsLowToHigh
}

const _sortLabels = {
  _SortMode.nearest: 'trip.filter.sort_nearest',
  _SortMode.priceLowToHigh: 'trip.filter.sort_price_low_high',
  _SortMode.priceHighToLow: 'trip.filter.sort_price_high_low',
  _SortMode.ratingHighToLow: 'trip.filter.sort_rating_high_low',
  _SortMode.ratingLowToHigh: 'trip.filter.sort_rating_low_high',
  _SortMode.starsHighToLow: 'trip.filter.sort_stars_high_low',
  _SortMode.starsLowToHigh: 'trip.filter.sort_stars_low_high',
};

const _kAll = '__all__';

// Best-effort city → country lookup, shared in spirit with TripListScreen's.
const _cityCountry = {
  'city.makkah': 'country.saudi',
  'city.madinah': 'country.saudi',
};

/// Mirrors `#pg-umrah-results` — search results with a date strip and filters.
class UmrahResultsScreen extends StatefulWidget {
  /// A date already picked on the search bar (`Y-m-d`) — defaults to today,
  /// same as the website's `/umrah/schedule` with no `?date=`.
  final String? initialDate;
  /// A trip type already picked on the search bar (API value: `economy` /
  /// `premium` / `vip`) — preselects the type filter; null means all.
  final String? initialType;
  const UmrahResultsScreen({super.key, this.initialDate, this.initialType});

  @override
  State<UmrahResultsScreen> createState() => _UmrahResultsScreenState();
}

class _UmrahResultsScreenState extends State<UmrahResultsScreen> {
  // Holds the display label [_fromApiTrip] puts on `UmrahResult.type`.
  late String _type = switch (widget.initialType) {
    'vip' => 'VIP',
    'premium' => 'مميزة',
    'economy' => 'اقتصادية',
    _ => _kAll,
  };
  _SortMode _sort = _SortMode.nearest;
  String _country = _kAll;
  String _city = _kAll;
  String _route = _kAll;
  String _program = _kAll;
  bool _searchOpen = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  late String _selectedDate = widget.initialDate ?? _todayIso();
  List<DateStripEntry> _dateStrip = [];

  /// Marks the selected day in the date strip so we can scroll it into view —
  /// the strip always starts at today, so a date picked weeks ahead sat far
  /// off-screen and looked like it hadn't been selected at all.
  final GlobalKey _selectedDateKey = GlobalKey();

  void _scrollToSelectedDate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedDateKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(ctx,
          alignment: 0.5, duration: const Duration(milliseconds: 300));
    });
  }

  List<UmrahResult> _apiResults = [];
  bool _loading = false;
  String? _loadedForCode;

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    CountryState.selected.addListener(_onCountryChanged);
    CountryState.detecting.addListener(_onCountryChanged);
    CountryState.selectedCityId.addListener(_onCountryChanged);
    _maybeLoad();
  }

  void _onCountryChanged() => _maybeLoad(force: true);

  void _onDateStripTap(DateStripEntry entry) {
    if (entry.date == _selectedDate) return;
    setState(() => _selectedDate = entry.date);
    _maybeLoad(force: true);
  }

  /// Real per-day matching trips + a real per-day price date-strip for the
  /// selected country/city/date — the website's `/umrah/schedule` equivalent
  /// (previously this screen fetched every trip in the country once and
  /// showed a fake, unconnected date strip on top — the date strip did
  /// nothing and no trip ever carried its searched date into booking).
  Future<void> _maybeLoad({bool force = false}) async {
    if (CountryState.detecting.value) return;
    final code = CountryState.selected.value?.code ?? 'EG';
    final cityId = CountryState.selectedCityId.value;
    final key = '$code:${cityId ?? ''}';
    if (!force && key == _loadedForCode || _loading) return;

    setState(() => _loading = true);
    final result = await context.read<AppState>().fetchSchedule(
          countryCode: code,
          cityId: cityId,
          date: DateTime.tryParse(_selectedDate),
        );
    if (!mounted) return;

    setState(() {
      _loadedForCode = key;
      _loading = false;
      if (result != null) {
        _dateStrip = result.dateStrip;
        _apiResults = result.trips.map((t) => _fromApiTrip(t, code)).toList();
      }
    });
    _scrollToSelectedDate();
  }

  UmrahResult _fromApiTrip(ApiTrip t, String countryCode) {
    final visitsMadinah = t.visitsMadinah;
    final stars = '★' * t.hotelStars.clamp(0, 5) + '☆' * (5 - t.hotelStars.clamp(0, 5));
    return UmrahResult(
      apiId: t.id,
      id: '${t.id}',
      name: t.title,
      emoji: '🕋',
      bg: const LinearGradient(colors: [Color(0xFF8E6A28), Color(0xFFB8892F)]),
      networkImage: t.thumbnail ?? (t.images != null && t.images!.isNotEmpty ? t.images!.first : null),
      hotel: t.hotelName ?? t.companyName,
      stars: stars,
      rating: t.hotelStars,
      type: switch (t.type) {
        'vip' => 'VIP',
        'premium' => 'مميزة',
        _ => 'اقتصادية',
      },
      days: '${t.durationDays}',
      travelers: t.type,
      price: t.price.toInt(),
      currency: t.currency,
      provider: t.companyName,
      providerColor: AppColors.green,
      providerLetter: t.companyName.isNotEmpty ? t.companyName[0] : '؟',
      vip: t.type == 'vip',
      premium: t.type == 'premium',
      featured: t.companyFeatured,
      feats: [
        if (t.hasFlight) 'feat.flight',
        if (t.hasTransport) 'feat.transport',
        if (t.hasGuide) 'feat.guide',
        if (t.hasVisits) 'feat.sightseeing',
        if (t.hotelStars >= 5) 'feat.hotel5star',
      ],
      stops: [
        const TripStop('city.makkah'),
        if (visitsMadinah) const TripStop('city.madinah', transportToNext: null),
      ],
      countryCode: countryCode,
    );
  }

  String _destCity(UmrahResult t) =>
      t.stops.isNotEmpty ? t.stops.last.city : 'city.makkah';
  String _destCountry(UmrahResult t) =>
      _cityCountry[_destCity(t)] ?? _destCity(t);
  int _starCount(UmrahResult t) =>
      t.stars.split('').where((c) => c == '★').length;
  bool _visitsMadinah(UmrahResult t) =>
      t.stops.any((s) => s.city == 'city.madinah');

  /// Results scoped to the home country currently selected in [CountryState]
  /// — a different axis from `_country`/`_city` below, which filter by
  /// *destination* (Makkah vs Madinah) within that already-scoped list.
  List<UmrahResult> get _baseResults => _apiResults;

  List<UmrahResult> get _results {
    final query = _searchQuery.trim().toLowerCase();
    var list = _baseResults.where((t) {
      if (_type != _kAll && t.type != _type) return false;
      if (_country != _kAll && _destCountry(t) != _country) return false;
      if (_city != _kAll && _destCity(t) != _city) return false;
      if (_route == 'makkah_only' && _visitsMadinah(t)) return false;
      if (_route == 'makkah_madinah' && !_visitsMadinah(t)) return false;
      if (_program != _kAll && t.programType != _program) return false;
      if (query.isNotEmpty) {
        final haystack =
            '${tr(t.name)} ${tr(t.hotel)} ${tr(t.provider)}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case _SortMode.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _SortMode.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
      case _SortMode.ratingHighToLow:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortMode.ratingLowToHigh:
        list.sort((a, b) => a.rating.compareTo(b.rating));
      case _SortMode.starsHighToLow:
        list.sort((a, b) => _starCount(b).compareTo(_starCount(a)));
      case _SortMode.starsLowToHigh:
        list.sort((a, b) => _starCount(a).compareTo(_starCount(b)));
      case _SortMode.nearest:
        break;
    }
    // Featured companies always lead, whatever the chosen sort — a stable
    // partition so the sort order still holds inside each group.
    return [
      ...list.where((t) => t.featured),
      ...list.where((t) => !t.featured),
    ];
  }

  @override
  void dispose() {
    CountryState.selected.removeListener(_onCountryChanged);
    CountryState.detecting.removeListener(_onCountryChanged);
    CountryState.selectedCityId.removeListener(_onCountryChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: NavState.tab.value,
        searchActive: true,
        onSearchTap: () {},
        onTap: (i) {
          NavState.tab.value = i;
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: Column(children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: AppColors.bg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: FaIcon(
                      Directionality.of(context) == TextDirection.rtl
                          ? FontAwesomeIcons.arrowRight
                          : FontAwesomeIcons.arrowLeft,
                      size: 14)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('trip.results.header_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  Text(
                      '${tr(_baseResults.isNotEmpty ? _baseResults.first.stops.first.city : 'city.cairo')}'
                      ' ← '
                      '${tr(_baseResults.isNotEmpty ? _baseResults.first.stops.last.city : 'city.makkah')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.muted)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              }),
              child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: _searchOpen ? AppColors.greenLight : AppColors.bg,
                      shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: FaIcon(FontAwesomeIcons.magnifyingGlass,
                      size: 13,
                      color:
                          _searchOpen ? AppColors.green : AppColors.muted)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openFilterSheet,
              child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: AppColors.bg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const FaIcon(FontAwesomeIcons.sliders,
                      size: 13, color: AppColors.muted)),
            ),
          ]),
        ),
        if (_searchOpen)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                isDense: true,
                hintText: tr('trip.results.search_hint'),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(10),
                  child: FaIcon(FontAwesomeIcons.magnifyingGlass,
                      size: 13, color: AppColors.muted),
                ),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: _dateStrip.isEmpty
              ? const SizedBox(
                  height: 66,
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))))
              : HScrollAuto(
                  itemCount: _dateStrip.length,
                  spacing: 6,
                  itemBuilder: (context, i) {
                    final entry = _dateStrip[i];
                    final d = DateTime.parse(entry.date);
                    final selected = entry.date == _selectedDate;
                    return GestureDetector(
                      key: selected ? _selectedDateKey : null,
                      onTap: () => _onDateStripTap(entry),
                      child: Container(
                        width: 72,
                        height: 66,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.green : Colors.white,
                          border: Border.all(
                              color:
                                  selected ? AppColors.green : AppColors.border,
                              width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                  intl.DateFormat('EEE',
                                          LocaleState.locale.value.languageCode)
                                      .format(d),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white70
                                          : AppColors.muted)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    intl.DateFormat('d MMM',
                                            LocaleState.locale.value.languageCode)
                                        .format(d),
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.muted)),
                              ),
                              Text(
                                  entry.minPrice != null
                                      ? '${entry.minPrice!.toInt()} ${tr('trip.results.currency_short')}'
                                      : '—',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white70
                                          : AppColors.green)),
                            ]),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(children: [
            Expanded(
              child: Text(
                  '${_results.length} ${tr('trip.results.trips_available')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
            ),
            const SizedBox(width: 8),
            Text(
                intl.DateFormat(
                        'EEE d MMMM', LocaleState.locale.value.languageCode)
                    .format(selectedDate),
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : _results.isEmpty
              ? Center(
                  child: Text(tr('trip.list.no_results'),
                      style: const TextStyle(color: AppColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  itemCount: _results.length,
                  itemBuilder: (context, i) => _ResultCard(
                    result: _results[i],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => TripDetailScreen(
                            trip: _results[i].toTrip(
                                date: intl.DateFormat('d MMMM yyyy',
                                        LocaleState.locale.value.languageCode)
                                    .format(selectedDate)),
                            initialDate: _selectedDate))),
                  ),
                ),
        ),
      ]),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final countries = [
            _kAll,
            ...{for (final t in _baseResults) _destCountry(t)}
          ];
          final citiesInCountry = _country == _kAll
              ? _baseResults
              : _baseResults.where((t) => _destCountry(t) == _country);
          final cities = [
            _kAll,
            ...{for (final t in citiesInCountry) _destCity(t)}
          ];
          if (!cities.contains(_city)) _city = _kAll;

          return Container(
            padding: EdgeInsets.fromLTRB(
                16, 14, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2)))),
                  Text(tr('trip.results.filter_sheet_title'),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: tr('trip.filter.type'),
                        value: _type,
                        accent: AppColors.green,
                        options: {
                          _kAll: tr('filter.all'),
                          'VIP': 'VIP',
                          'مميزة': tr('trip.filter.chip_golden'),
                          'اقتصادية': tr('trip.filter.chip_economy'),
                        },
                        onChanged: (v) =>
                            setState(() => setSheetState(() => _type = v!)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppDropdown<_SortMode>(
                        label: tr('trip.filter.sort'),
                        value: _sort,
                        accent: AppColors.green,
                        options: {
                          for (final m in _SortMode.values)
                            m: tr(_sortLabels[m]!)
                        },
                        onChanged: (m) =>
                            setState(() => setSheetState(() => _sort = m!)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: tr('trip.filter.country'),
                        value: _country,
                        accent: AppColors.green,
                        options: {
                          for (final c in countries)
                            c: c == _kAll ? tr('filter.all') : tr(c)
                        },
                        onChanged: (c) => setState(() => setSheetState(() {
                              _country = c!;
                              _city = _kAll;
                            })),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppDropdown<String>(
                        label: tr('trip.filter.city'),
                        value: _city,
                        accent: AppColors.green,
                        options: {
                          for (final c in cities)
                            c: c == _kAll ? tr('filter.all') : tr(c)
                        },
                        onChanged: (c) =>
                            setState(() => setSheetState(() => _city = c!)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: tr('trip.filter.route'),
                        value: _route,
                        accent: AppColors.green,
                        options: {
                          _kAll: tr('filter.all'),
                          'makkah_only': tr('trip.filter.route_makkah_only'),
                          'makkah_madinah':
                              tr('trip.filter.route_makkah_madinah'),
                        },
                        onChanged: (v) =>
                            setState(() => setSheetState(() => _route = v!)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppDropdown<String>(
                        label: tr('trip.filter.program'),
                        value: _program,
                        accent: AppColors.green,
                        options: {
                          _kAll: tr('filter.all'),
                          'trip.program.umrah': tr('trip.filter.program_umrah'),
                          'trip.program.umrahHajj':
                              tr('trip.filter.program_umrah_hajj'),
                          'trip.program.hajj': tr('trip.filter.program_hajj'),
                        },
                        onChanged: (v) =>
                            setState(() => setSheetState(() => _program = v!)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: Text(tr('trip.filter.apply'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]),
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final UmrahResult result;
  final VoidCallback onTap;
  const _ResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = result;
    // Same per-tier treatment as the home screen's TripCardUC.
    final tier = TripTierStyle.of(vip: t.vip, premium: t.premium);
    final accent = tier.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppDims.card(
            color: tier.cardColor, borderColor: tier.borderColor),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        gradient: t.bg,
                        borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: t.networkImage != null
                        ? CachedNetworkImage(
                            imageUrl: t.networkImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (_, __) => const Center(
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))),
                            errorWidget: (_, __, ___) =>
                                Text(t.emoji, style: const TextStyle(fontSize: 28)))
                        : Text(t.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                  if (tier.badgeIcon != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            gradient: tier.gradient,
                            borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(8))),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(tier.badgeIcon!,
                                  size: 7, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(tr(tier.badgeLabelKey!),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800)),
                            ]),
                      ),
                    ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tier.badgeIcon != null) ...[
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          FaIcon(tier.badgeIcon!, size: 9, color: accent),
                          const SizedBox(width: 4),
                          Text(tr(tier.badgeLabelKey!),
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5)),
                        ]),
                        const SizedBox(height: 3),
                      ],
                      Text(tr(t.name),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text)),
                      const SizedBox(height: 4),
                      Wrap(
                          spacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.solidBuilding,
                                size: 10, color: accent),
                            Text(tr(t.hotel),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                            const Text('·',
                                style: TextStyle(color: AppColors.muted)),
                            Text(starRatingLabel(t.stars),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.gold)),
                            const Text('·',
                                style: TextStyle(color: AppColors.muted)),
                            FaIcon(FontAwesomeIcons.solidCalendar,
                                size: 10, color: accent),
                            Text(tr(t.days),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                          ]),
                      const SizedBox(height: 6),
                      Wrap(spacing: 5, runSpacing: 5, children: [
                        for (final f in t.feats.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: tier.borderColor != null
                                    ? Colors.white
                                    : AppColors.bg,
                                border: Border.all(
                                    color: tier.borderColor ?? AppColors.border),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(tr(f),
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.text)),
                          ),
                      ]),
                    ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: tier.softBg,
                  borderRadius: BorderRadius.circular(9)),
              child: Row(children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                        tr(t.stops.isNotEmpty
                            ? t.stops.first.city
                            : 'city.cairo'),
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                    child: Container(
                        height: 1.5,
                        decoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(
                                    color: AppColors.border,
                                    width: 1.5,
                                    style: BorderStyle.solid))))),
                Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        color: tier.gradient == null ? accent : null,
                        gradient: tier.gradient,
                        shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Transform.scale(
                        scaleX: Directionality.of(context) == TextDirection.rtl
                            ? -1
                            : 1,
                        child: const FaIcon(FontAwesomeIcons.plane,
                            size: 8, color: Colors.white))),
                Expanded(
                    child: Container(
                        height: 1.5,
                        decoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(
                                    color: AppColors.border,
                                    width: 1.5,
                                    style: BorderStyle.solid))))),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                        t.stops.isNotEmpty
                            ? tr(t.stops.last.city)
                            : tr('city.makkah'),
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                  ),
                ),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: tier.footerBg,
                border: Border(top: BorderSide(color: tier.footerBorder))),
            child: Row(children: [
              Expanded(
                child: Row(children: [
                  Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                          color: t.providerColor,
                          borderRadius: BorderRadius.circular(7)),
                      alignment: Alignment.center,
                      child: Text(t.providerLetter,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900))),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(tr(t.provider),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                Text(tr('trip.detail.price_from'),
                    style:
                        const TextStyle(fontSize: 9.5, color: AppColors.muted)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${t.price} ${tr(t.currency)}',
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: accent)),
                ),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }
}
