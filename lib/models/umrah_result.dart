import 'package:flutter/material.dart';
import '../core/theme/trip_tier_style.dart';
import '../l10n/translations.dart';
import 'trip.dart';

/// A result row on the Umrah results (search) page — needs a numeric
/// price/rating so it can be sorted/filtered, unlike the display-only [Trip].
class UmrahResult {
  /// Backend trip id — null for local seed/demo results. When present, the
  /// detail screen fetches the full real record instead of placeholders.
  final int? apiId;
  final String id;
  final String name;
  final String emoji;
  final Gradient bg;
  /// A real photo URL from the backend — takes priority over [emoji]
  /// wherever the result image is shown.
  final String? networkImage;
  final String hotel;
  final String stars;
  final int rating;
  final String type; // 'VIP' | 'مميزة' | 'اقتصادية'
  final String days;
  final String travelers;
  final int price;
  final String currency;
  final String provider;
  final Color providerColor;
  final String providerLetter;
  final bool vip;
  final bool premium;
  final bool featured;
  final List<String> feats;
  final List<TripStop> stops;
  final String countryCode;
  final String programType; // 'trip.program.umrah' | 'umrahHajj' | 'hajj'

  const UmrahResult({
    this.apiId,
    required this.id,
    required this.name,
    required this.emoji,
    required this.bg,
    this.networkImage,
    required this.hotel,
    required this.stars,
    required this.rating,
    required this.type,
    required this.days,
    required this.travelers,
    required this.price,
    this.currency = 'trip.currency.pound',
    required this.provider,
    required this.providerColor,
    required this.providerLetter,
    this.vip = false,
    this.premium = false,
    this.featured = false,
    this.feats = const [],
    this.stops = const [],
    this.countryCode = 'EG',
    this.programType = 'trip.program.umrah',
  });

  Trip toTrip({required String date}) => Trip(
        apiId: apiId,
        title: name,
        emoji: emoji,
        bg: bg,
        networkImage: networkImage,
        hotel: hotel.isEmpty ? provider : hotel,
        stars: stars,
        type: 'trip.type.umrah',
        days: days,
        travelers: travelers,
        price: '$price ${tr(currency)}',
        date: date,
        provider: provider,
        dest: 'city.makkah',
        vip: vip,
        premium: premium,
        featured: featured,
        isGreen: true,
        accent: TripTierStyle.of(vip: vip, premium: premium).accent,
        stops: stops,
        feats: feats,
        countryCode: countryCode,
      );
}
