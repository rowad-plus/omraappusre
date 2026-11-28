import 'api_trip.dart';

/// One day in the search page's date strip — mirrors the website's
/// `/umrah/schedule` date-strip cells exactly (real per-day minimum price
/// for the selected city, not a placeholder).
class DateStripEntry {
  final String date; // Y-m-d
  final double? minPrice;
  final bool isSelected;
  const DateStripEntry({required this.date, this.minPrice, required this.isSelected});

  factory DateStripEntry.fromJson(Map<String, dynamic> j) => DateStripEntry(
        date: j['date'] as String,
        minPrice: (j['min_price'] as num?)?.toDouble(),
        isSelected: j['is_selected'] as bool? ?? false,
      );
}

/// Response of `GET /umrah-trips/schedule` — the mobile equivalent of the
/// website's date-based search page.
class ScheduleResult {
  final int cityId;
  final String cityName;
  final String selectedDate;
  final List<DateStripEntry> dateStrip;
  final List<ApiTrip> trips;

  /// «المقترح» (2026-11-28): one trip per featured company, rotating every visit.
  final List<ApiTrip> suggested;

  const ScheduleResult({
    required this.cityId,
    required this.cityName,
    required this.selectedDate,
    required this.dateStrip,
    required this.trips,
    this.suggested = const [],
  });

  factory ScheduleResult.fromJson(Map<String, dynamic> j) {
    final city = j['city'] as Map<String, dynamic>;
    return ScheduleResult(
      cityId: city['id'] as int,
      cityName: city['name'] as String? ?? '',
      selectedDate: j['selected_date'] as String,
      dateStrip: (j['date_strip'] as List<dynamic>)
          .map((e) => DateStripEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      trips: (j['trips'] as List<dynamic>)
          .map((t) => ApiTrip.fromJson(t as Map<String, dynamic>))
          .toList(),
      suggested: (j['suggested'] as List<dynamic>? ?? const [])
          .map((t) => ApiTrip.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
