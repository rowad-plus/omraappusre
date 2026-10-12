import 'package:flutter/material.dart';

/// The mode of transport used to reach the *next* stop on a route.
enum RouteTransport { flight, bus }

/// A single stop along a trip's route (used on the route indicator and the
/// detail page route box). [transportToNext] is the leg leaving this stop —
/// null on the final stop, since there's nowhere left to go.
class TripStop {
  final String city;
  final RouteTransport? transportToNext;
  const TripStop(this.city, {this.transportToNext = RouteTransport.flight});
}

/// Generic trip/program shown on cards and the detail page.
/// Mirrors the `data` object passed into `openDetail()` in rehlaty.html.
class Trip {
  /// Backend trip id — null for trips that only exist as local seed/demo
  /// data. When present, the detail screen fetches the full record (real
  /// itinerary, dates, images) instead of using placeholder content.
  final int? apiId;
  final String title;
  final String emoji;
  final Gradient bg;
  final String? imageAsset;
  final String? iconAsset;
  /// A real photo URL from the backend — takes priority over [imageAsset]/
  /// [iconAsset]/[emoji] wherever the trip image is shown.
  final String? networkImage;
  final String hotel;
  final String stars;
  final String type;
  final String days;
  final String travelers;
  final String price;
  final String date;
  final String provider;
  /// Company logo URL (null → the card shows the name's first letter).
  final String? providerLogo;
  final String dest;
  final bool vip;
  final bool premium;

  /// Trip belongs to a featured company (active subscription) — listed first.
  final bool featured;
  final bool isGreen;
  final Color accent;
  final List<TripStop> stops;
  final List<String> feats;
  final String countryCode; // home/departure-market country, e.g. 'EG', 'SA'
  final String programType; // 'trip.program.umrah' | 'umrahHajj' | 'hajj'
  /// The trip's real backend departure city id — used to sort a country's
  /// trip list so the customer's selected departure city (if any) comes
  /// first, without excluding the rest of the country's trips. Null for
  /// local seed/demo trips.
  final int? departureCityId;

  const Trip({
    this.apiId,
    required this.title,
    required this.emoji,
    required this.bg,
    this.imageAsset,
    this.iconAsset,
    this.networkImage,
    required this.hotel,
    required this.stars,
    required this.type,
    required this.days,
    required this.travelers,
    required this.price,
    required this.date,
    required this.provider,
    this.providerLogo,
    required this.dest,
    this.vip = false,
    this.premium = false,
    this.featured = false,
    this.isGreen = false,
    required this.accent,
    this.stops = const [],
    this.feats = const [],
    this.countryCode = 'EG',
    this.programType = 'trip.program.umrah',
    this.departureCityId,
  });
}
