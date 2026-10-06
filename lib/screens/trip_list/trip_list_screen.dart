import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/trip.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/sub_page_header.dart';
import '../../widgets/trip_card_uc.dart';
import '../booking/booking_sheet.dart';
import '../trip_detail/trip_detail_screen.dart';

enum _SortMode {
  priceLowToHigh,
  priceHighToLow,
  starsHighToLow,
  starsLowToHigh
}

const _sortLabels = {
  _SortMode.priceLowToHigh: 'trip.filter.sort_price_low_high',
  _SortMode.priceHighToLow: 'trip.filter.sort_price_high_low',
  _SortMode.starsHighToLow: 'trip.filter.sort_stars_high_low',
  _SortMode.starsLowToHigh: 'trip.filter.sort_stars_low_high',
};

const _kAll = '__all__';

// Best-effort city → country lookup for the destinations seen in seed data;
// unmapped cities just filter as their own "country" bucket.
const _cityCountry = {
  'city.makkah': 'country.saudi',
  'المالديف': 'المالديف',
  'دبي': 'الإمارات',
  'إسطنبول': 'تركيا',
  'تبليسي': 'جورجيا',
};

/// A filterable/sortable trip listing — opened from "المزيد" / "عرض الكل"
/// on a VIP or economy umrah trip section.
class TripListScreen extends StatefulWidget {
  final String title;
  final List<Trip> trips;
  final Color accent;

  const TripListScreen({
    super.key,
    required this.title,
    required this.trips,
    this.accent = AppColors.blue,
  });

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  _SortMode _sort = _SortMode.priceLowToHigh;
  String _country = _kAll;
  String _city = _kAll;

  void _openDetail(Trip trip) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));
  }

  void _openBooking(Trip trip) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => BookingSheet(trip: trip)));
  }

  String _countryOf(Trip t) => _cityCountry[t.dest] ?? t.dest;

  int _priceValue(Trip t) =>
      int.tryParse(t.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  int _starCount(Trip t) => t.stars.split('').where((c) => c == '★').length;

  @override
  Widget build(BuildContext context) {
    final countries = [
      _kAll,
      ...{for (final t in widget.trips) _countryOf(t)}
    ];
    final citiesInCountry = _country == _kAll
        ? widget.trips
        : widget.trips.where((t) => _countryOf(t) == _country);
    final cities = [
      _kAll,
      ...{for (final t in citiesInCountry) t.dest}
    ];
    if (!cities.contains(_city)) _city = _kAll;

    var list = widget.trips.where((t) {
      if (_country != _kAll && _countryOf(t) != _country) return false;
      if (_city != _kAll && t.dest != _city) return false;
      return true;
    }).toList();

    switch (_sort) {
      case _SortMode.priceLowToHigh:
        list.sort((a, b) => _priceValue(a).compareTo(_priceValue(b)));
      case _SortMode.priceHighToLow:
        list.sort((a, b) => _priceValue(b).compareTo(_priceValue(a)));
      case _SortMode.starsHighToLow:
        list.sort((a, b) => _starCount(b).compareTo(_starCount(a)));
      case _SortMode.starsLowToHigh:
        list.sort((a, b) => _starCount(a).compareTo(_starCount(b)));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: widget.title),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(
              child: AppDropdown<_SortMode>(
                label: tr('trip.filter.sort'),
                value: _sort,
                accent: widget.accent,
                options: {
                  for (final m in _SortMode.values) m: tr(_sortLabels[m]!)
                },
                onChanged: (m) => setState(() => _sort = m!),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: AppDropdown<String>(
                label: tr('trip.filter.country'),
                value: _country,
                accent: widget.accent,
                options: {
                  for (final c in countries)
                    c: c == _kAll ? tr('filter.all') : tr(c)
                },
                onChanged: (c) => setState(() {
                  _country = c!;
                  _city = _kAll;
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: AppDropdown<String>(
                label: tr('trip.filter.city'),
                value: _city,
                accent: widget.accent,
                options: {
                  for (final c in cities)
                    c: c == _kAll ? tr('filter.all') : tr(c)
                },
                onChanged: (c) => setState(() => _city = c!),
              ),
            ),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(tr('trip.list.no_results'),
                      style: const TextStyle(color: AppColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return TripCardUC(
                      showSuggested: true,
                        trip: t,
                        onTap: () => _openDetail(t),
                        onBook: () => _openBooking(t));
                  },
                ),
        ),
      ]),
    );
  }
}
