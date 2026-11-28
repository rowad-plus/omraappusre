import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
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

  /// Weekly recurring trips: departure weekdays (0 = Sunday … 6 = Saturday).
  final List<int> recurrenceDays;

  /// Monthly recurring trips: day of the month they depart on.
  final int? recurrenceDayOfMonth;
  final String? thumbnail;
  final int? companyId;
  final String companyName;
  final String? companyLogo;

  /// `company.rank == 'featured'` — the company has an active subscription.
  final bool companyFeatured;
  final int? departureCityId;
  final String? departureCityName;
  final bool? nearYou;
  final String? oneWayLeg; // 'go' | 'return' when listed as a one-way bus
  final String? oneWayFrom;
  final String? oneWayTo;

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

  /// Saudi trips: 'visit' (Madinah day trip, no nights) | 'overnight'; null otherwise.
  final String? madinahStay;
  final int madinahDays;

  /// '32' | '49' passengers, or null.
  final String? busType;

  /// Company-uploaded trip videos (detail endpoint only).
  final List<String> videos;

  /// Trip hotels with their page (detail endpoint only, 2026-11-28).
  final List<TripHotel> hotels;

  /// Saudi trips: optional one-way prices (detail endpoint).
  final double? priceGoOnly;
  final double? priceReturnOnly;

  /// Company's flat price per extra room for the whole trip (detail endpoint).
  final double? extraRoomPrice;

  /// Price for ONE person alone in a private room (null = not offered).
  final double? privateRoomPrice;

  /// Admin enabled "الدفع عند الباص" for this trip's company.
  final bool payAtBus;

  /// Seriousness deposit % paid online for «الدفع عند الباص» (0 = none).
  final double payAtBusDeposit;

  /// «احجز عبر واتساب» switched on by the admin.
  final bool whatsappBooking;

  /// 2026-11-27: private rooms the company priced, {persons: whole-room price}, 1-4 people.
  final Map<int, double> roomOptions;

  /// List endpoint: card photos (up to 6) and the first video, if any.
  final List<String> gallery;
  final String? cardVideo;

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
    this.recurrenceDays = const [],
    this.recurrenceDayOfMonth,
    this.thumbnail,
    this.companyId,
    required this.companyName,
    this.companyLogo,
    this.companyFeatured = false,
    this.departureCityId,
    this.departureCityName,
    this.nearYou,
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
    this.madinahStay,
    this.madinahDays = 0,
    this.busType,
    this.oneWayLeg,
    this.oneWayFrom,
    this.oneWayTo,
    this.videos = const [],
    this.hotels = const [],
    this.priceGoOnly,
    this.priceReturnOnly,
    this.extraRoomPrice,
    this.privateRoomPrice,
    this.payAtBus = false,
    this.payAtBusDeposit = 0,
    this.whatsappBooking = true,
    this.gallery = const [],
    this.cardVideo,
    this.roomOptions = const {},
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
      recurrenceDays: (j['recurrence_days'] as List<dynamic>?)
              ?.map((d) => (d as num).toInt())
              .toList() ??
          const [],
      recurrenceDayOfMonth: (j['recurrence_day_of_month'] as num?)?.toInt(),
      thumbnail: j['thumbnail'] as String?,
      companyId: company?['id'] as int?,
      companyName: company?['name'] as String? ?? '',
      companyLogo: company?['logo'] as String?,
      companyFeatured: company?['rank'] == 'featured',
      departureCityId: departureCity?['id'] as int?,
      departureCityName: departureCity?['name'] as String?,
      nearYou: j['near_you'] as bool?,
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
      madinahStay: j['madinah_stay'] as String?,
      madinahDays: (j['madinah_days'] as num?)?.toInt() ?? 0,
      busType: j['bus_type']?.toString(),
      oneWayLeg: j['one_way_leg'] as String?,
      oneWayFrom: j['one_way_from'] as String?,
      oneWayTo: j['one_way_to'] as String?,
      videos: (j['videos'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      hotels: (j['hotels'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TripHotel.fromJson)
          .where((h) => h.name.isNotEmpty)
          .toList(),
      priceGoOnly: (j['price_go_only'] as num?)?.toDouble(),
      priceReturnOnly: (j['price_return_only'] as num?)?.toDouble(),
      extraRoomPrice: (j['extra_room_price'] as num?)?.toDouble(),
      privateRoomPrice: (j['private_room_price'] as num?)?.toDouble(),
      payAtBus: j['pay_at_bus'] == true || j['pay_at_bus'] == 1,
      payAtBusDeposit: (j['pay_at_bus_deposit'] as num?)?.toDouble() ?? 0,
      whatsappBooking: j['whatsapp_booking'] != false && j['whatsapp_booking'] != 0,
      gallery: (j['gallery'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      cardVideo: j['card_video'] as String?,
      roomOptions: {
        for (final r in (j['room_options'] as List<dynamic>? ?? const []))
          if (r is Map && r['persons'] is num && (r['price'] as num? ?? 0) > 0)
            (r['persons'] as num).toInt(): (r['price'] as num).toDouble(),
      },
    );
  }

  /// Departure city then the trip's real destination stops in order
  /// (e.g. Riyadh → Makkah → Madinah). Falls back to Makkah [+ Madinah]
  /// when the API sent no routes.
  List<TripStop> get routeStops {
    String key(String name) => name.contains('مكة')
        ? 'city.makkah'
        : name.contains('المدينة')
            ? 'city.madinah'
            : name;
    final dests =
        (routeCityNames ?? []).where((n) => n.isNotEmpty).map(key).toList();
    final cities = [
      if (departureCityName != null) departureCityName!,
      ...(dests.isNotEmpty
          ? dests
          : ['city.makkah', if (visitsMadinah) 'city.madinah']),
    ];
    return [
      for (var i = 0; i < cities.length; i++)
        TripStop(cities[i],
            transportToNext:
                i < cities.length - 1 ? RouteTransport.flight : null),
    ];
  }

  bool get visitsMadinah =>
      (routeCityNames ?? []).any((c) => c.contains('المدينة'));

  String get _typeKey => switch (type) {
        'vip' => 'trip.type.umrahVip',
        'premium' => 'trip.type.premium',
        'economy' => 'trip.type.economy',
        _ => 'trip.type.umrah',
      };

  String get _starGlyphs =>
      '★' * hotelStars.clamp(0, 5) + '☆' * (5 - hotelStars.clamp(0, 5));

  Trip toTrip() => Trip(
        apiId: id,
        title: oneWayLeg != null && (oneWayFrom ?? '').isNotEmpty ? '$oneWayFrom ← $oneWayTo' : title,
        emoji: '🕋',
        bg: const LinearGradient(
            colors: [Color(0xFF8E6A28), Color(0xFFB8892F)]),
        networkImage: thumbnail ??
            (images != null && images!.isNotEmpty ? images!.first : null),
        hotel: hotelName ?? companyName,
        stars: _starGlyphs,
        type: _typeKey,
        days: '$durationDays',
        travelers: type,
        price: '${NumberFormat('#,##0', 'en').format(price)} $currency',
        // Daily trips have no next date — the cards tr() this key instead.
        // Weekly / monthly recurring trips get an encoded key that tr()
        // turns into the weekday name(s) / day of month at render time.
        date: nextDate ??
            (scheduleType == 'daily'
                ? 'trip.date.daily'
                : recurrenceDays.isNotEmpty
                    ? 'trip.date.weekly:${recurrenceDays.join(',')}'
                    : recurrenceDayOfMonth != null
                        ? 'trip.date.monthly:$recurrenceDayOfMonth'
                        : ''),
        provider: companyName,
        providerLogo: companyLogo,
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
        stops: routeStops,
        feats: [
          if (hasFlight) 'feat.flight',
          if (hasTransport) 'feat.transport',
          if (hasGuide) 'feat.guide',
          if (hasVisits) 'feat.sightseeing',
          if (hotelStars >= 5) 'feat.hotel5star',
        ],
        departureCityId: departureCityId,
        nearYou: nearYou,
        busType: busType,
        oneWayLeg: oneWayLeg,
        gallery: gallery,
        cardVideo: cardVideo,
        roomOptions: [
          for (final e in (roomOptions.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
            RoomOption(e.key, '${NumberFormat('#,##0', 'en').format(e.value)} $currency'),
        ],
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
  const ApiTripDate(
      {required this.id, required this.departureDate, this.bookingDeadline});

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
  const ApiTripProgramDay(
      {required this.dayNumber,
      this.title,
      this.location,
      required this.steps});

  factory ApiTripProgramDay.fromJson(Map<String, dynamic> j) =>
      ApiTripProgramDay(
        dayNumber: j['day_number'] as int? ?? 0,
        title: j['title'] as String?,
        location: j['location'] as String?,
        steps: (j['steps'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}

/// One hotel of a trip: name, city (makkah / madinah), stars, picture and its page on the site.
class TripHotel {
  final String name;
  final String? city;
  final int? stars;
  final String? distanceHaram;
  final String? image;
  final String? url;

  const TripHotel({required this.name, this.city, this.stars, this.distanceHaram, this.image, this.url});

  factory TripHotel.fromJson(Map<String, dynamic> j) => TripHotel(
        name: '${j['name'] ?? ''}'.trim(),
        city: j['city'] as String?,
        stars: (j['stars'] as num?)?.toInt(),
        distanceHaram: j['distance_haram']?.toString(),
        image: j['image'] as String?,
        url: j['url'] as String?,
      );
}
