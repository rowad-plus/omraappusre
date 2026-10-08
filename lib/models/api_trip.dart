import 'package:flutter/material.dart';
import '../core/theme/trip_tier_style.dart';
import 'trip.dart';

/// A trip as returned by the real Front API (`/umrah-trips`,
/// `/umrah-trips/{id}`). [toTrip] adapts it into the display-only [Trip]
/// model the existing card/detail widgets already know how to render —
/// fields that don't correspond to an i18n key (title, price, provider
/// name...) are passed through as plain strings, which `tr()` renders
/// unchanged when it finds no matching key.
class ApiTrip {
  final int id;
  final String title;
  final String type; // vip | premium | economy
  final double price;
  final String currency;
  final int durationDays;
  final int hotelStars;
  final bool hasGuide;
  final bool hasFlight;
  final bool hasTransport;
  final bool hasVisits;
  final String scheduleType;
  final String? nextDate;
  final String? thumbnail;
  final int? companyId;
  final String companyName;
  final String? companyLogo;

  /// `company.rank == 'featured'` — the company has an active subscription.
  final bool companyFeatured;
  final int? departureCityId;
  final String? departureCityName;

  // Detail-only fields (null when built from the list endpoint).
  final List<String>? images;
  final List<String>? routeCityNames;
  final List<ApiTripDate>? dates;
  /// True when [dates] came from `computeAvailableDepartureDates()`
  /// (a 'daily'/'recurring' trip with no real `umrah_trip_dates` rows yet)
  /// rather than real fixed rows — see `ApiTripDate.id`.
  final bool datesAreComputed;
  final List<ApiTripProgramDay>? programs;
  final String? hotelName;
  final String? hotelLocation;
  final int? distanceFromHaram;
  /// Whether the authenticated user has favorited this trip — null (not
  /// false) when built from the list endpoint, which doesn't compute it.
  final bool? isFavorited;
  /// Whether the authenticated user has this trip in their comparison
  /// list — same null-when-not-computed convention as [isFavorited].
  final bool? isCompared;

  const ApiTrip({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.hotelStars,
    required this.hasGuide,
    required this.hasFlight,
    required this.hasTransport,
    required this.hasVisits,
    required this.scheduleType,
    this.nextDate,
    this.thumbnail,
    this.companyId,
    required this.companyName,
    this.companyLogo,
    this.companyFeatured = false,
    this.departureCityId,
    this.departureCityName,
    this.images,
    this.routeCityNames,
    this.dates,
    this.datesAreComputed = false,
    this.programs,
    this.hotelName,
    this.hotelLocation,
    this.distanceFromHaram,
    this.isFavorited,
    this.isCompared,
  });

  factory ApiTrip.fromJson(Map<String, dynamic> j) {
    final company = j['company'] as Map<String, dynamic>?;
    final departureCity = j['departure_city'] as Map<String, dynamic>?;

    return ApiTrip(
      id: j['id'] as int,
      title: j['title'] as String? ?? '',
      type: j['type'] as String? ?? 'economy',
      price: (j['price'] as num?)?.toDouble() ?? 0,
      currency: j['currency'] as String? ?? '',
      durationDays: j['duration_days'] as int? ?? 0,
      hotelStars: j['hotel_stars'] as int? ?? 0,
      hasGuide: j['has_guide'] as bool? ?? false,
      hasFlight: j['has_flight'] as bool? ?? false,
      hasTransport: j['has_transport'] as bool? ?? false,
      hasVisits: j['has_visits'] as bool? ?? false,
      scheduleType: j['schedule_type'] as String? ?? 'fixed',
      nextDate: j['next_date'] as String?,
      thumbnail: j['thumbnail'] as String?,
      companyId: company?['id'] as int?,
      companyName: company?['name'] as String? ?? '',
      companyLogo: company?['logo'] as String?,
      companyFeatured: company?['rank'] == 'featured',
      departureCityId: departureCity?['id'] as int?,
      departureCityName: departureCity?['name'] as String?,
      images: (j['images'] as List<dynamic>?)?.cast<String>(),
      routeCityNames: (j['routes'] as List<dynamic>?)
          ?.map((r) => (r as Map<String, dynamic>)['name'] as String? ?? '')
          .toList(),
      dates: (j['dates'] as List<dynamic>?)
          ?.map((d) => ApiTripDate.fromJson(d as Map<String, dynamic>))
          .toList(),
      datesAreComputed: j['dates_are_computed'] as bool? ?? false,
      programs: (j['programs'] as List<dynamic>?)
          ?.map((p) => ApiTripProgramDay.fromJson(p as Map<String, dynamic>))
          .toList(),
      hotelName: j['hotel_name'] as String?,
      hotelLocation: j['hotel_location'] as String?,
      distanceFromHaram: j['distance_from_haram'] as int?,
      isFavorited: j['is_favorited'] as bool?,
      isCompared: j['is_compared'] as bool?,
    );
  }

  bool get visitsMadinah => (routeCityNames ?? []).any((c) => c.contains('المدينة'));

  String get _typeKey => switch (type) {
        'vip' => 'trip.type.umrahVip',
        'premium' => 'trip.type.premium',
        'economy' => 'trip.type.economy',
        _ => 'trip.type.umrah',
      };

  String get _starGlyphs => '★' * hotelStars.clamp(0, 5) + '☆' * (5 - hotelStars.clamp(0, 5));

  Trip toTrip() => Trip(
        apiId: id,
        title: title,
        emoji: '🕋',
        bg: const LinearGradient(colors: [Color(0xFF8E6A28), Color(0xFFB8892F)]),
        networkImage: thumbnail ?? (images != null && images!.isNotEmpty ? images!.first : null),
        hotel: hotelName ?? companyName,
        stars: _starGlyphs,
        type: _typeKey,
        days: '$durationDays',
        travelers: type,
        price: '${price.toStringAsFixed(0)} $currency',
        // Daily trips have no next date — the cards tr() this key instead.
        date: nextDate ?? (scheduleType == 'daily' ? 'trip.date.daily' : ''),
        provider: companyName,
        dest: visitsMadinah ? 'city.madinah' : 'city.makkah',
        vip: type == 'vip',
        premium: type == 'premium',
        featured: companyFeatured,
        isGreen: true,
        // VIP cards get the same gold accent as their day-count badge —
        // every other green touch (route arrow, provider avatar, price
        // border/text) reads `accent`, so this alone keeps a VIP card's
        // whole color story consistently gold instead of gold-badge-on-an-
        // otherwise-green-card.
        accent: TripTierStyle.of(vip: type == 'vip', premium: type == 'premium')
            .accent,
        // The real departure city always leads the route now — previously
        // this list only ever held destination stops (Mecca [+ Madinah]),
        // so any trip not visiting Madinah had length < 2 and fell through
        // to `CardRouteRow`'s own hardcoded "Cairo" placeholder regardless
        // of the trip's actual departure city (a Saudi-departing trip would
        // still show "القاهرة ← مكة المكرمة").
        stops: [
          if (departureCityName != null) TripStop(departureCityName!),
          const TripStop('city.makkah'),
          if (visitsMadinah) const TripStop('city.madinah', transportToNext: null),
        ],
        feats: [
          if (hasFlight) 'feat.flight',
          if (hasTransport) 'feat.transport',
          if (hasGuide) 'feat.guide',
          if (hasVisits) 'feat.sightseeing',
          if (hotelStars >= 5) 'feat.hotel5star',
        ],
        departureCityId: departureCityId,
      );
}

/// [id] is either an existing `umrah_trip_dates` row id, or — for a
/// computed (see [ApiTrip.datesAreComputed]) entry with no real row yet —
/// the raw `Y-m-d` date string itself. Both forms are valid values for the
/// booking API's `trip_date_id`, which resolves whichever was sent the
/// same way the website's own form does (see `AppState.createBooking`).
class ApiTripDate {
  final String id;
  final String departureDate;
  final String? bookingDeadline;
  const ApiTripDate({required this.id, required this.departureDate, this.bookingDeadline});

  factory ApiTripDate.fromJson(Map<String, dynamic> j) => ApiTripDate(
        id: j['id'] as String,
        departureDate: j['departure_date'] as String,
        bookingDeadline: j['booking_deadline'] as String?,
      );
}

class ApiTripProgramDay {
  final int dayNumber;
  final String? title;
  final String? location;
  final List<String> steps;
  const ApiTripProgramDay({required this.dayNumber, this.title, this.location, required this.steps});

  factory ApiTripProgramDay.fromJson(Map<String, dynamic> j) => ApiTripProgramDay(
        dayNumber: j['day_number'] as int? ?? 0,
        title: j['title'] as String?,
        location: j['location'] as String?,
        steps: (j['steps'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}
