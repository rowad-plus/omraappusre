import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../widgets/app_header.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/section_vip_header.dart';
import '../../widgets/provider_scroller.dart';
import '../../widgets/trip_card_gold.dart';
import '../../widgets/design_umrah_banner.dart';
import '../../widgets/filter_chip_bar.dart';
import '../../models/provider_company.dart';
import '../auth/login_sheet.dart';
import '../trip_detail/trip_detail_screen.dart';
import '../booking/booking_sheet.dart';
import '../umrah_results/umrah_results_screen.dart';
import '../trip_list/trip_list_screen.dart';
import '../company/company_profile_screen.dart';
import '../../models/trip.dart';
import '../../data/country_catalog.dart';
import '../../state/app_state.dart';
import '../../state/country_state.dart';

/// Mirrors `#pg-umrah` — now backed by the real Front trips API instead of
/// local seed data.
class UmrahScreen extends StatefulWidget {
  const UmrahScreen({super.key});

  @override
  State<UmrahScreen> createState() => _UmrahScreenState();
}

class _UmrahScreenState extends State<UmrahScreen> {
  int _filter = 0;
  static const _filterKeys = [
    'filter.all',
    'trip.filter.chip_economy',
    'trip.filter.chip_golden',
    'trip.filter.chip_vip',
    'trip.filter.route_makkah_only',
    'trip.filter.route_makkah_madinah',
    'trip.filter.program_hajj',
  ];

  String? _loadedForCode;
  bool _loading = false;
  List<Trip> _trips = [];
  List<ProviderCompany> _providers = [];

  @override
  void initState() {
    super.initState();
    CountryState.selected.addListener(_onCountryChanged);
    CountryState.detecting.addListener(_onCountryChanged);
    CountryState.selectedCityId.addListener(_onCountryChanged);
    _maybeLoad();
  }

  @override
  void dispose() {
    CountryState.selected.removeListener(_onCountryChanged);
    CountryState.detecting.removeListener(_onCountryChanged);
    CountryState.selectedCityId.removeListener(_onCountryChanged);
    super.dispose();
  }

  void _onCountryChanged() => _maybeLoad(force: true);

  Future<void> _maybeLoad({bool force = false}) async {
    if (CountryState.detecting.value) return;
    final code = CountryState.selected.value?.code ?? 'EG';
    final cityId = CountryState.selectedCityId.value;
    final key = '$code:${cityId ?? ''}';
    if (!force && key == _loadedForCode || _loading) return;

    setState(() => _loading = true);
    final state = context.read<AppState>();
    // Deliberately no `cityId:` filter here — a selected departure city is
    // a *priority*, not an exclusion (mirrors the website's own location-
    // picker behavior, see `HasTripHelpers::buildTripQuery()`'s `cityIds`
    // branch): the customer still sees every trip in their country, with
    // whichever one(s) depart from their chosen city surfaced first
    // instead of the rest of the country being hidden entirely.
    final apiTrips = await state.fetchTrips(countryCode: code);
    if (!mounted) return;

    final companiesById = <int, ProviderCompany>{};
    // Featured companies first so they also lead the providers strip.
    final byRank = [
      ...apiTrips.where((t) => t.companyFeatured),
      ...apiTrips.where((t) => !t.companyFeatured),
    ];
    for (final t in byRank) {
      if (t.companyId != null && !companiesById.containsKey(t.companyId)) {
        companiesById[t.companyId!] = ProviderCompany(
          id: t.companyId,
          name: t.companyName,
          color: AppColors.green,
          letter: t.companyName.isNotEmpty ? t.companyName[0] : '؟',
          logo: t.companyLogo,
          stars: '★★★★★',
          trips: apiTrips.where((x) => x.companyId == t.companyId).length,
          handle: t.companyName,
          countryCode: code,
        );
      }
    }

    final trips = apiTrips.map((t) => t.toTrip()).toList();
    // Selected-city trips first, then the rest of the country — a stable
    // partition (not a sort) so relative order is otherwise unchanged.
    final byCity = cityId == null
        ? trips
        : [
            ...trips.where((t) => t.departureCityId == cityId),
            ...trips.where((t) => t.departureCityId != cityId),
          ];
    // Featured companies' trips lead every section, ahead of the city
    // priority (which still orders trips within each group).
    final prioritized = [
      ...byCity.where((t) => t.featured),
      ...byCity.where((t) => !t.featured),
    ];

    setState(() {
      _loadedForCode = key;
      _loading = false;
      _trips = prioritized;
      _providers = companiesById.values.take(8).toList();
    });
  }

  bool _visitsMadinah(Trip t) => t.stops.any((s) => s.city == 'city.madinah');

  void _openFilterChip(int index) {
    late final List<Trip> trips;
    switch (index) {
      case 1:
        trips = _trips.where((t) => t.type == 'trip.type.economy').toList();
      case 2:
        trips = _trips.where((t) => t.premium).toList();
      case 3:
        trips = _trips.where((t) => t.vip).toList();
      case 4:
        trips = _trips.where((t) => !_visitsMadinah(t)).toList();
      case 5:
        trips = _trips.where(_visitsMadinah).toList();
      case 6:
        trips = _trips.where((t) => t.programType == 'trip.program.hajj').toList();
      default:
        trips = _trips;
    }
    _openList(tr(_filterKeys[index]), trips);
  }

  void _openDetail(Trip trip) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));
  }

  void _openBooking(Trip trip) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => BookingSheet(trip: trip)));
  }

  void _openList(String title, List<Trip> trips) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          TripListScreen(title: title, trips: trips, accent: AppColors.green),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vipTrips = _trips.where((t) => t.vip).toList();
    final premiumTrips = _trips.where((t) => t.premium).toList();
    final economyTrips =
        _trips.where((t) => !t.vip && !t.premium).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppHeader(
        onSearchTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UmrahResultsScreen())),
        onSignInTap: () => openLoginSheet(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchBarWidget(
              destIcon: FontAwesomeIcons.kaaba,
              accent: AppColors.green,
              hint: tr('trip.umrah.search_hint'),
              onGo: (date, type) => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => UmrahResultsScreen(
                      initialType: type,
                      initialDate: date == null
                          ? null
                          : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'))),
            ),
            FilterChipBar(
                labels: _filterKeys.map(tr).toList(),
                selected: _filter,
                accent: AppColors.green,
                onSelect: (i) {
                  setState(() => _filter = i);
                  _openFilterChip(i);
                }),
            ValueListenableBuilder<bool>(
              valueListenable: CountryState.detecting,
              builder: (context, detecting, _) {
                if (detecting || _loading) return _buildDetectingSkeleton();
                if (vipTrips.isEmpty &&
                    premiumTrips.isEmpty &&
                    economyTrips.isEmpty) {
                  return _buildNoContentState();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (vipTrips.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionVipHeader(
                                icon: FontAwesomeIcons.crown,
                                label: tr('trip.umrah.vip_section_title'),
                                gradient: AppColors.greenGradient,
                                lineColor: const Color(0x80E5E9F2),
                                moreColor: AppColors.green,
                                onMoreTap: () => _openList(
                                    tr('trip.umrah.vip_section_title'),
                                    vipTrips),
                              ),
                              for (final t in vipTrips)
                                TripCardGold(
                                    trip: t,
                                    onTap: () => _openDetail(t),
                                    onBook: () => _openBooking(t)),
                            ]),
                      ),
                    if (vipTrips.isNotEmpty &&
                        (premiumTrips.isNotEmpty || economyTrips.isNotEmpty))
                      Container(height: 6, color: AppColors.bg),
                    if (premiumTrips.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionVipHeader(
                                icon: FontAwesomeIcons.gem,
                                label: tr('trip.umrah.premium_section_title'),
                                gradient: AppColors.premiumGradient,
                                lineColor: const Color(0x80E5E9F2),
                                moreColor: AppColors.brand,
                                onMoreTap: () => _openList(
                                    tr('trip.umrah.premium_section_title'),
                                    premiumTrips),
                              ),
                              for (final t in premiumTrips)
                                TripCardGold(
                                    trip: t,
                                    onTap: () => _openDetail(t),
                                    onBook: () => _openBooking(t)),
                            ]),
                      ),
                    const DesignUmrahBanner(),
                    if (premiumTrips.isNotEmpty && economyTrips.isNotEmpty)
                      Container(height: 6, color: AppColors.bg),
                    if (economyTrips.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        tr('trip.umrah.economy_section_title'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.text))),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _openList(
                                      tr('trip.umrah.economy_section_title'),
                                      economyTrips),
                                  child: Text(tr('common.viewAll'),
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.green)),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              for (final t in economyTrips)
                                TripCardGold(
                                    trip: t,
                                    onTap: () => _openDetail(t),
                                    onBook: () => _openBooking(t)),
                            ]),
                      ),
                    if (_providers.isNotEmpty)
                      ProviderScroller(
                          title: tr('trip.umrah.providers_title'),
                          providers: _providers,
                          moreColor: AppColors.green,
                          onProviderTap: (p) {
                            if (p.id == null) return;
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => CompanyProfileScreen(
                                    companyId: p.id!, fallbackName: p.name)));
                          }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectingSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
          child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }

  Widget _buildNoContentState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const FaIcon(FontAwesomeIcons.mapLocationDot,
              size: 32, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(tr('trip.country.no_content_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => CountryState.selected.value = CountryCatalog.egypt,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text(tr('trip.country.no_content_cta'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
