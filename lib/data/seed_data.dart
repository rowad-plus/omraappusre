import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/trip.dart';
import '../models/provider_company.dart';
import '../models/post.dart';
import '../models/order.dart';
import '../models/umrah_result.dart';
import '../models/design_request.dart';

/// Static content mirroring the inline JS data literals in rehlaty.html
/// (home cards, provider scrollers, feed posts, orders, companies).
class SeedData {
  SeedData._();

  // ── Gradients used across trip cards ──
  static const gGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8892F), Color(0xFF8E6A28)],
  );
  static const gGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFB45309)],
  );
  static const gTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E6A28), Color(0xFF8E6A28)],
  );
  static const gSky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8892F), Color(0xFF8E6A28)],
  );
  static const gPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
  );
  static const gRed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
  );
  static const gEmerald = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E6A28), Color(0xFF8E6A28)],
  );
  static const gViolet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
  );
  static const gRose = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE11D48), Color(0xFF9F1239)],
  );
  static const gCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8892F), Color(0xFF8E6A28)],
  );
  static const gOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC2410C), Color(0xFF7C2D12)],
  );

  // ── Umrah VIP trips (home + umrah tab) ──
  static final Trip umrahMuyassara = Trip(
    title: 'trip.muyassara.title',
    emoji: '🕋',
    bg: gGreen,
    iconAsset: 'assets/images/kaaba.png',
    hotel: 'trip.muyassara.hotel',
    stars: '★★★★☆',
    type: 'trip.type.umrah',
    days: 'trip.days.d20',
    travelers: 'trip.travelers.groups',
    price: 'trip.muyassara.price',
    date: 'trip.muyassara.date',
    provider: 'trip.provider.alferdaws',
    dest: 'city.makkah',
    vip: true,
    isGreen: true,
    accent: AppColors.green,
    stops: const [
      TripStop('city.cairo'),
      TripStop('city.makkah', transportToNext: RouteTransport.bus),
      TripStop('city.madinah'),
    ],
    feats: const [
      'feat.guide',
      'feat.flight',
      'feat.hotel5star',
      'feat.sightseeing',
      'feat.transport'
    ],
  );

  static final Trip umrahDhahabiya = Trip(
    title: 'trip.dhahabiya.title',
    emoji: '⭐',
    bg: gGold,
    iconAsset: 'assets/images/vip.png',
    hotel: 'trip.dhahabiya.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrahVip',
    days: 'trip.days.d14',
    travelers: 'trip.travelers.coupleOrSolo',
    price: 'trip.dhahabiya.price',
    date: 'trip.dhahabiya.date',
    provider: 'trip.provider.nasma',
    dest: 'city.makkah',
    vip: true,
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.privateGuide',
      'feat.vipCar',
      'feat.firstClass',
      'feat.kaabaViewHotel',
      'feat.meals'
    ],
  );

  static final Trip umrahDiamond = Trip(
    title: 'trip.diamond.title',
    emoji: '💎',
    bg: gViolet,
    hotel: 'trip.diamond.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrahVip',
    days: 'trip.days.d10',
    travelers: 'trip.travelers.soloOrFamily',
    price: 'trip.diamond.price',
    date: 'trip.diamond.date',
    provider: 'trip.provider.alferdaws',
    dest: 'city.makkah',
    vip: true,
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.privateGuide',
      'feat.businessClass',
      'feat.hotel5starView',
      'feat.vipCar',
      'feat.wifi'
    ],
  );

  static final Trip umrahDawn = Trip(
    title: 'trip.dawn.title',
    emoji: '🌅',
    bg: gSky,
    hotel: 'trip.dawn.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrahVip',
    days: 'trip.days.d9',
    travelers: 'trip.travelers.smallGroups',
    price: 'trip.dawn.price',
    date: 'trip.dawn.date',
    provider: 'trip.provider.nasma',
    dest: 'city.makkah',
    vip: true,
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.spiritualGuide',
      'feat.flight',
      'feat.hotel5star',
      'feat.fajrProgram',
      'feat.meals'
    ],
  );

  static final Trip umrahElite = Trip(
    title: 'trip.elite.title',
    emoji: '👑',
    bg: gRose,
    hotel: 'trip.elite.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrahVip',
    days: 'trip.days.d12',
    travelers: 'trip.travelers.solo',
    price: 'trip.elite.price',
    date: 'trip.elite.date',
    provider: 'trip.provider.makkahtours',
    dest: 'city.makkah',
    vip: true,
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.privateGuide',
      'feat.firstClass',
      'feat.hotel5starLuxury',
      'feat.suiteCar',
      'feat.conciergeService'
    ],
  );

  static final Trip umrahRajab = Trip(
    title: 'trip.rajab.title',
    emoji: '🌙',
    bg: gEmerald,
    hotel: 'trip.rajab.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrahVip',
    days: 'trip.days.d11',
    travelers: 'trip.travelers.families',
    price: 'trip.rajab.price',
    date: 'trip.rajab.date',
    provider: 'trip.provider.alferdaws',
    dest: 'city.makkah',
    vip: true,
    isGreen: true,
    accent: AppColors.green,
    stops: const [
      TripStop('city.cairo'),
      TripStop('city.makkah', transportToNext: RouteTransport.bus),
      TripStop('city.madinah'),
    ],
    feats: const [
      'feat.spiritualGuide',
      'feat.flight',
      'feat.hotel5star',
      'feat.meals',
      'feat.privateCar'
    ],
  );

  static final Trip umrahRoyalFamily = Trip(
    title: 'trip.royalFamily.title',
    emoji: '👨‍👩‍👧‍👦',
    bg: gTeal,
    hotel: 'trip.royalFamily.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrahVip',
    days: 'trip.days.d13',
    travelers: 'trip.travelers.largeFamilies',
    price: 'trip.royalFamily.price',
    date: 'trip.royalFamily.date',
    provider: 'trip.provider.nasma',
    dest: 'city.makkah',
    vip: true,
    isGreen: true,
    accent: AppColors.green,
    stops: const [
      TripStop('city.cairo'),
      TripStop('city.makkah', transportToNext: RouteTransport.bus),
      TripStop('city.madinah'),
    ],
    feats: const [
      'feat.familyGuide',
      'feat.flight',
      'feat.hotel5star',
      'feat.kidsActivities',
      'feat.meals'
    ],
  );

  static final Trip umrahBusiness = Trip(
    title: 'trip.business.title',
    emoji: '💼',
    bg: gPurple,
    hotel: 'trip.business.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrahVip',
    days: 'trip.days.d7',
    travelers: 'trip.travelers.solo',
    price: 'trip.business.price',
    date: 'trip.business.date',
    provider: 'trip.provider.makkahtours',
    dest: 'city.makkah',
    vip: true,
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.privateGuide',
      'feat.firstClass',
      'feat.hotel5star',
      'feat.vipCar',
      'feat.wifi'
    ],
  );

  static final Trip umrahEconomy = Trip(
    title: 'trip.economy.title',
    emoji: '🕌',
    bg: gTeal,
    iconAsset: 'assets/images/kaaba.png',
    hotel: 'trip.economy.hotel',
    stars: '★★★★☆',
    type: 'trip.type.economy',
    days: 'trip.days.d10',
    travelers: 'trip.travelers.individualsAndGroups',
    price: 'trip.economy.price',
    date: 'trip.economy.date',
    provider: 'trip.provider.makkahtours',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.guide',
      'feat.flight',
      'feat.hotel4star',
      'feat.transport'
    ],
  );

  static final Trip umrahStudents = Trip(
    title: 'trip.students.title',
    emoji: '🎓',
    bg: gCyan,
    hotel: 'trip.students.hotel',
    stars: '★★★☆☆',
    type: 'trip.type.economy',
    days: 'trip.days.d7',
    travelers: 'trip.travelers.groups',
    price: 'trip.students.price',
    date: 'trip.students.date',
    provider: 'trip.provider.nasma',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.guide',
      'feat.flight',
      'feat.hotel3star',
      'feat.transport'
    ],
  );

  static final Trip umrahSaving = Trip(
    title: 'trip.saving.title',
    emoji: '💰',
    bg: gOrange,
    hotel: 'trip.saving.hotel',
    stars: '★★★☆☆',
    type: 'trip.type.economy',
    days: 'trip.days.d8',
    travelers: 'trip.travelers.individuals',
    price: 'trip.saving.price',
    date: 'trip.saving.date',
    provider: 'trip.provider.alferdaws',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.guide',
      'feat.flight',
      'feat.hotel3star',
      'feat.transport'
    ],
  );

  static final Trip umrahFamilyEconomy = Trip(
    title: 'trip.familyEconomy.title',
    emoji: '👪',
    bg: gGold,
    hotel: 'trip.familyEconomy.hotel',
    stars: '★★★★☆',
    type: 'trip.type.economy',
    days: 'trip.days.d9',
    travelers: 'trip.travelers.families',
    price: 'trip.familyEconomy.price',
    date: 'trip.familyEconomy.date',
    provider: 'trip.provider.makkahtours',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.familyGuide',
      'feat.flight',
      'feat.hotel4star',
      'feat.transport'
    ],
  );

  static final Trip umrahWeekend = Trip(
    title: 'trip.weekend.title',
    emoji: '🕒',
    bg: gSky,
    hotel: 'trip.weekend.hotel',
    stars: '★★★☆☆',
    type: 'trip.type.economy',
    days: 'trip.days.d4',
    travelers: 'trip.travelers.soloOrCouple',
    price: 'trip.weekend.price',
    date: 'trip.weekend.date',
    provider: 'trip.provider.nasma',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.guide',
      'feat.flight',
      'feat.hotel3star',
      'feat.transport'
    ],
  );

  static final Trip umrahUniversities = Trip(
    title: 'trip.universities.title',
    emoji: '📚',
    bg: gTeal,
    hotel: 'trip.universities.hotel',
    stars: '★★★☆☆',
    type: 'trip.type.economy',
    days: 'trip.days.d6',
    travelers: 'trip.travelers.groups',
    price: 'trip.universities.price',
    date: 'trip.universities.date',
    provider: 'trip.provider.alferdaws',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.guide',
      'feat.flight',
      'feat.hotel3star',
      'feat.transport'
    ],
  );

  static final Trip umrahGoldenMuyassara = Trip(
    title: 'trip.goldenMuyassara.title',
    emoji: '🌟',
    bg: gEmerald,
    hotel: 'trip.goldenMuyassara.hotel',
    stars: '★★★★☆',
    type: 'trip.type.economy',
    days: 'trip.days.d10',
    travelers: 'trip.travelers.individualsAndGroups',
    price: 'trip.goldenMuyassara.price',
    date: 'trip.goldenMuyassara.date',
    provider: 'trip.provider.makkahtours',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.guide',
      'feat.flight',
      'feat.hotel4star',
      'feat.transport',
      'feat.meals'
    ],
  );

  static final Trip umrahRamadanEconomy = Trip(
    title: 'trip.ramadanEconomy.title',
    emoji: '🌙',
    bg: gPurple,
    hotel: 'trip.ramadanEconomy.hotel',
    stars: '★★★☆☆',
    type: 'trip.type.economy',
    days: 'trip.days.d15',
    travelers: 'trip.travelers.largeGroups',
    price: 'trip.ramadanEconomy.price',
    date: 'trip.ramadanEconomy.date',
    provider: 'trip.provider.alferdaws',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.green,
    stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    feats: const [
      'feat.guide',
      'feat.flight',
      'feat.hotel3star',
      'feat.transport',
      'feat.meals'
    ],
  );

  // ── Saudi Arabia (SA) — domestic Umrah packages departing from Riyadh/Jeddah ──
  static final Trip riyadhRoyal = Trip(
    title: 'trip.riyadhRoyal.title',
    emoji: '👑',
    bg: gGold,
    hotel: 'trip.riyadhRoyal.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrah',
    days: 'trip.days.d7',
    travelers: 'trip.travelers.soloOrFamily',
    price: 'trip.riyadhRoyal.price',
    date: 'trip.riyadhRoyal.date',
    provider: 'trip.provider.alharamain',
    dest: 'city.madinah',
    vip: true,
    isGreen: true,
    accent: AppColors.gold,
    countryCode: 'SA',
    stops: const [
      TripStop('city.riyadh'),
      TripStop('city.makkah', transportToNext: RouteTransport.bus),
      TripStop('city.madinah'),
    ],
    feats: const [
      'feat.privateGuide',
      'feat.vipCar',
      'feat.hotel5starLuxury',
      'feat.firstClass',
    ],
  );

  static final Trip jeddahDiamond = Trip(
    title: 'trip.jeddahDiamond.title',
    emoji: '💎',
    bg: gSky,
    hotel: 'trip.jeddahDiamond.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrah',
    days: 'trip.days.d10',
    travelers: 'trip.travelers.coupleOrSolo',
    price: 'trip.jeddahDiamond.price',
    date: 'trip.jeddahDiamond.date',
    provider: 'trip.provider.almashaer',
    dest: 'city.madinah',
    vip: true,
    isGreen: true,
    accent: AppColors.sky,
    countryCode: 'SA',
    stops: const [
      TripStop('city.jeddah'),
      TripStop('city.makkah', transportToNext: RouteTransport.bus),
      TripStop('city.madinah'),
    ],
    feats: const [
      'feat.guide',
      'feat.hotel5starView',
      'feat.transport',
      'feat.wifi',
    ],
  );

  static final Trip riyadhEconomy = Trip(
    title: 'trip.riyadhEconomy.title',
    emoji: '🕋',
    bg: gTeal,
    hotel: 'trip.riyadhEconomy.hotel',
    stars: '★★★☆☆',
    type: 'trip.type.economy',
    days: 'trip.days.d4',
    travelers: 'trip.travelers.individuals',
    price: 'trip.riyadhEconomy.price',
    date: 'trip.riyadhEconomy.date',
    provider: 'trip.provider.alharamain',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.teal,
    countryCode: 'SA',
    stops: const [TripStop('city.riyadh'), TripStop('city.makkah')],
    feats: const ['feat.transport', 'feat.meals'],
  );

  static final Trip jeddahFamily = Trip(
    title: 'trip.jeddahFamily.title',
    emoji: '👨‍👩‍👧‍👦',
    bg: gEmerald,
    hotel: 'trip.jeddahFamily.hotel',
    stars: '★★★★☆',
    type: 'trip.type.economy',
    days: 'trip.days.d6',
    travelers: 'trip.travelers.families',
    price: 'trip.jeddahFamily.price',
    date: 'trip.jeddahFamily.date',
    provider: 'trip.provider.almashaer',
    dest: 'city.madinah',
    isGreen: true,
    accent: AppColors.emerald,
    countryCode: 'SA',
    stops: const [
      TripStop('city.jeddah'),
      TripStop('city.makkah', transportToNext: RouteTransport.bus),
      TripStop('city.madinah'),
    ],
    feats: const ['feat.transport', 'feat.meals', 'feat.hotel4star'],
  );

  // ── UAE (AE) — Umrah packages departing from Dubai/Abu Dhabi ──
  static final Trip dubaiElite = Trip(
    title: 'trip.dubaiElite.title',
    emoji: '✨',
    bg: gPurple,
    hotel: 'trip.dubaiElite.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrah',
    days: 'trip.days.d8',
    travelers: 'trip.travelers.coupleOrSolo',
    price: 'trip.dubaiElite.price',
    date: 'trip.dubaiElite.date',
    provider: 'trip.provider.emiratesJourneys',
    dest: 'city.makkah',
    vip: true,
    isGreen: true,
    accent: AppColors.purple,
    countryCode: 'AE',
    stops: const [
      TripStop('city.dubai'),
      TripStop('city.makkah', transportToNext: RouteTransport.bus),
      TripStop('city.madinah'),
    ],
    feats: const [
      'feat.privateGuide',
      'feat.businessClass',
      'feat.hotel5starLuxury',
      'feat.wifi',
    ],
  );

  static final Trip abudhabiRoyal = Trip(
    title: 'trip.abudhabiRoyal.title',
    emoji: '🕌',
    bg: gRose,
    hotel: 'trip.abudhabiRoyal.hotel',
    stars: '★★★★★',
    type: 'trip.type.umrah',
    days: 'trip.days.d10',
    travelers: 'trip.travelers.soloOrFamily',
    price: 'trip.abudhabiRoyal.price',
    date: 'trip.abudhabiRoyal.date',
    provider: 'trip.provider.daralDiyafa',
    dest: 'city.madinah',
    vip: true,
    isGreen: true,
    accent: AppColors.rose,
    countryCode: 'AE',
    stops: const [
      TripStop('city.abudhabi'),
      TripStop('city.makkah', transportToNext: RouteTransport.bus),
      TripStop('city.madinah'),
    ],
    feats: const [
      'feat.guide',
      'feat.vipCar',
      'feat.hotel5starView',
      'feat.firstClass',
    ],
  );

  static final Trip dubaiEconomy = Trip(
    title: 'trip.dubaiEconomy.title',
    emoji: '🕋',
    bg: gCyan,
    hotel: 'trip.dubaiEconomy.hotel',
    stars: '★★★☆☆',
    type: 'trip.type.economy',
    days: 'trip.days.d4',
    travelers: 'trip.travelers.individuals',
    price: 'trip.dubaiEconomy.price',
    date: 'trip.dubaiEconomy.date',
    provider: 'trip.provider.emiratesJourneys',
    dest: 'city.makkah',
    isGreen: true,
    accent: AppColors.cyan,
    countryCode: 'AE',
    stops: const [TripStop('city.dubai'), TripStop('city.makkah')],
    feats: const ['feat.transport', 'feat.meals'],
  );

  static final Trip abudhabiFamily = Trip(
    title: 'trip.abudhabiFamily.title',
    emoji: '👨‍👩‍👧‍👦',
    bg: gOrange,
    hotel: 'trip.abudhabiFamily.hotel',
    stars: '★★★★☆',
    type: 'trip.type.economy',
    days: 'trip.days.d6',
    travelers: 'trip.travelers.families',
    price: 'trip.abudhabiFamily.price',
    date: 'trip.abudhabiFamily.date',
    provider: 'trip.provider.daralDiyafa',
    dest: 'city.madinah',
    isGreen: true,
    accent: AppColors.orange,
    countryCode: 'AE',
    stops: const [
      TripStop('city.abudhabi'),
      TripStop('city.makkah', transportToNext: RouteTransport.bus),
      TripStop('city.madinah'),
    ],
    feats: const ['feat.transport', 'feat.meals', 'feat.hotel4star'],
  );

  static final List<Trip> umrahVipTrips = [
    umrahMuyassara,
    umrahDhahabiya,
    umrahDiamond,
    umrahDawn,
    umrahElite,
    umrahRajab,
    umrahRoyalFamily,
    umrahBusiness,
    riyadhRoyal,
    jeddahDiamond,
    dubaiElite,
    abudhabiRoyal,
  ];

  static final List<Trip> umrahEconomyTrips = [
    umrahEconomy,
    umrahStudents,
    umrahSaving,
    umrahFamilyEconomy,
    umrahWeekend,
    umrahUniversities,
    umrahGoldenMuyassara,
    umrahRamadanEconomy,
    riyadhEconomy,
    jeddahFamily,
    dubaiEconomy,
    abudhabiFamily,
  ];

  static List<Trip> vipTripsForCountry(String code) =>
      umrahVipTrips.where((t) => t.countryCode == code).toList();

  static List<Trip> economyTripsForCountry(String code) =>
      umrahEconomyTrips.where((t) => t.countryCode == code).toList();

  // ── Providers / companies ──
  static const List<ProviderCompany> umrahProviders = [
    ProviderCompany(
        name: 'company.alferdawsShort',
        color: Color(0xFFB8892F),
        letter: 'ف',
        stars: '★★★★★',
        trips: 48),
    ProviderCompany(
        name: 'company.nasmaShort',
        color: Color(0xFFD97706),
        letter: 'ن',
        stars: '★★★★☆',
        trips: 32),
    ProviderCompany(
        name: 'company.makkahtours',
        color: Color(0xFF8E6A28),
        letter: 'م',
        stars: '★★★★☆',
        trips: 26),
    ProviderCompany(
        name: 'company.alharamainShort',
        color: AppColors.gold,
        letter: 'ح',
        stars: '★★★★★',
        trips: 20,
        countryCode: 'SA'),
    ProviderCompany(
        name: 'company.almashaerShort',
        color: AppColors.teal,
        letter: 'م',
        stars: '★★★★☆',
        trips: 15,
        countryCode: 'SA'),
    ProviderCompany(
        name: 'company.emiratesJourneysShort',
        color: AppColors.purple,
        letter: 'إ',
        stars: '★★★★★',
        trips: 18,
        countryCode: 'AE'),
    ProviderCompany(
        name: 'company.daralDiyafaShort',
        color: AppColors.rose,
        letter: 'ض',
        stars: '★★★★☆',
        trips: 14,
        countryCode: 'AE'),
  ];

  static List<ProviderCompany> providersForCountry(String code) =>
      umrahProviders.where((p) => p.countryCode == code).toList();

  /// Full company directory used by the post composer's "tag a company" search.
  static const List<ProviderCompany> companies = [
    ProviderCompany(
        name: 'company.alferdawsFull',
        color: Color(0xFFB8892F),
        letter: 'ف',
        handle: 'alferdaws'),
    ProviderCompany(
        name: 'company.safarplus',
        color: AppColors.blue,
        letter: 'س',
        handle: 'safarplus'),
    ProviderCompany(
        name: 'company.nasmaFull',
        color: Color(0xFFD97706),
        letter: 'ن',
        handle: 'nasma'),
    ProviderCompany(
        name: 'company.dreamtravel',
        color: Color(0xFF7C3AED),
        letter: 'د',
        handle: 'dreamtravel'),
    ProviderCompany(
        name: 'company.awj',
        color: Color(0xFFDC2626),
        letter: 'أ',
        handle: 'awj'),
    ProviderCompany(
        name: 'company.makkahtours',
        color: Color(0xFF8E6A28),
        letter: 'م',
        handle: 'makkahtours'),
    ProviderCompany(
        name: 'company.rahal',
        color: Color(0xFF8E6A28),
        letter: 'ر',
        handle: 'rahal'),
  ];

  // ── Umrah results (search) page ──
  static final List<UmrahResult> umrahResults = [
    UmrahResult(
      id: 'u1',
      name: 'trip.muyassara.title',
      emoji: '🕋',
      bg: gGreen,
      hotel: 'trip.muyassara.hotel',
      stars: '★★★★☆',
      rating: 4,
      type: 'result.type.vip',
      days: 'trip.days.d20',
      travelers: 'trip.travelers.groups',
      price: 25000,
      provider: 'trip.provider.alferdaws',
      providerColor: const Color(0xFFB8892F),
      providerLetter: 'ف',
      vip: true,
      feats: const [
        'feat.guide',
        'feat.flight',
        'feat.hotel5star',
        'feat.sightseeing',
        'feat.transport'
      ],
      stops: const [
        TripStop('city.cairo'),
        TripStop('city.makkah', transportToNext: RouteTransport.bus),
        TripStop('city.madinah'),
      ],
    ),
    UmrahResult(
      id: 'u2',
      name: 'trip.dhahabiya.title',
      emoji: '⭐',
      bg: gGold,
      hotel: 'trip.dhahabiya.hotel',
      stars: '★★★★★',
      rating: 5,
      type: 'result.type.vip',
      days: 'trip.days.d14',
      travelers: 'trip.travelers.coupleOrSolo',
      price: 45000,
      provider: 'trip.provider.nasma',
      providerColor: const Color(0xFFD97706),
      providerLetter: 'ن',
      vip: true,
      feats: const [
        'feat.privateGuide',
        'feat.vipCar',
        'feat.firstClass',
        'feat.kaabaView'
      ],
      stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    ),
    UmrahResult(
      id: 'u3',
      name: 'trip.economy.title',
      emoji: '🕌',
      bg: gTeal,
      hotel: 'trip.economy.hotel',
      stars: '★★★★☆',
      rating: 4,
      type: 'result.type.economy',
      days: 'trip.days.d10',
      travelers: 'trip.travelers.individualsAndGroups',
      price: 12000,
      provider: 'trip.provider.makkahtours',
      providerColor: const Color(0xFF8E6A28),
      providerLetter: 'م',
      feats: const [
        'feat.guide',
        'feat.flight',
        'feat.hotel4star',
        'feat.transport'
      ],
      stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    ),
    UmrahResult(
      id: 'u4',
      name: 'result.u4.name',
      emoji: '🌙',
      bg: gViolet,
      hotel: 'result.u4.hotel',
      stars: '★★★★★',
      rating: 5,
      type: 'result.type.vip',
      days: 'trip.days.d15',
      travelers: 'trip.travelers.groups',
      price: 38000,
      provider: 'trip.provider.alferdaws',
      providerColor: const Color(0xFFB8892F),
      providerLetter: 'ف',
      vip: true,
      feats: const [
        'feat.spiritualGuide',
        'feat.flight',
        'feat.hotel5star',
        'feat.meals',
        'feat.privateCar'
      ],
      stops: const [
        TripStop('city.cairo'),
        TripStop('city.makkah', transportToNext: RouteTransport.bus),
        TripStop('city.madinah'),
      ],
    ),
    UmrahResult(
      id: 'u5',
      name: 'result.u5.name',
      emoji: '👨‍👩‍👧',
      bg: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.blue, const Color(0xFF8E6A28)],
      ),
      hotel: 'result.u5.hotel',
      stars: '★★★★★',
      rating: 5,
      type: 'result.type.vip',
      days: 'trip.days.d12',
      travelers: 'trip.travelers.families',
      price: 32000,
      provider: 'trip.provider.nasma',
      providerColor: const Color(0xFFD97706),
      providerLetter: 'ن',
      vip: true,
      feats: const [
        'feat.familyGuide',
        'feat.flight',
        'feat.hotel5star',
        'feat.kidsActivities'
      ],
      stops: const [TripStop('city.cairo'), TripStop('city.makkah')],
    ),
    UmrahResult(
      id: 'u6',
      name: 'result.u6.name',
      emoji: '✈️',
      bg: gEmerald,
      hotel: 'result.u6.hotel',
      stars: '★★★★★',
      rating: 5,
      type: 'result.type.vip',
      days: 'trip.days.d8',
      travelers: 'trip.travelers.soloOrCouple',
      price: 65000,
      provider: 'company.rahal',
      providerColor: const Color(0xFF8E6A28),
      providerLetter: 'ر',
      vip: true,
      feats: const [
        'feat.firstClass',
        'feat.privateGuide',
        'feat.hotel5starLuxury',
        'feat.suiteCar'
      ],
      stops: const [
        TripStop('city.cairo'),
        TripStop('city.makkah', transportToNext: RouteTransport.bus),
        TripStop('city.madinah'),
      ],
    ),
    UmrahResult(
      id: 'sa1',
      name: 'trip.riyadhRoyal.title',
      emoji: '👑',
      bg: gGold,
      hotel: 'trip.riyadhRoyal.hotel',
      stars: '★★★★★',
      rating: 5,
      type: 'result.type.vip',
      days: 'trip.days.d7',
      travelers: 'trip.travelers.soloOrFamily',
      price: 4800,
      currency: 'trip.currency.sar',
      provider: 'trip.provider.alharamain',
      providerColor: AppColors.gold,
      providerLetter: 'ح',
      vip: true,
      feats: const [
        'feat.privateGuide',
        'feat.vipCar',
        'feat.hotel5starLuxury',
        'feat.firstClass',
      ],
      stops: const [
        TripStop('city.riyadh'),
        TripStop('city.makkah', transportToNext: RouteTransport.bus),
        TripStop('city.madinah'),
      ],
      countryCode: 'SA',
    ),
    UmrahResult(
      id: 'sa2',
      name: 'trip.riyadhEconomy.title',
      emoji: '🕋',
      bg: gTeal,
      hotel: 'trip.riyadhEconomy.hotel',
      stars: '★★★☆☆',
      rating: 3,
      type: 'result.type.economy',
      days: 'trip.days.d4',
      travelers: 'trip.travelers.individuals',
      price: 1200,
      currency: 'trip.currency.sar',
      provider: 'trip.provider.alharamain',
      providerColor: AppColors.teal,
      providerLetter: 'ح',
      feats: const ['feat.transport', 'feat.meals'],
      stops: const [TripStop('city.riyadh'), TripStop('city.makkah')],
      countryCode: 'SA',
    ),
    UmrahResult(
      id: 'ae1',
      name: 'trip.dubaiElite.title',
      emoji: '✨',
      bg: gPurple,
      hotel: 'trip.dubaiElite.hotel',
      stars: '★★★★★',
      rating: 5,
      type: 'result.type.vip',
      days: 'trip.days.d8',
      travelers: 'trip.travelers.coupleOrSolo',
      price: 5900,
      currency: 'trip.currency.aed',
      provider: 'trip.provider.emiratesJourneys',
      providerColor: AppColors.purple,
      providerLetter: 'إ',
      vip: true,
      feats: const [
        'feat.privateGuide',
        'feat.businessClass',
        'feat.hotel5starLuxury',
        'feat.wifi',
      ],
      stops: const [
        TripStop('city.dubai'),
        TripStop('city.makkah', transportToNext: RouteTransport.bus),
        TripStop('city.madinah'),
      ],
      countryCode: 'AE',
    ),
    UmrahResult(
      id: 'ae2',
      name: 'trip.dubaiEconomy.title',
      emoji: '🕋',
      bg: gCyan,
      hotel: 'trip.dubaiEconomy.hotel',
      stars: '★★★☆☆',
      rating: 3,
      type: 'result.type.economy',
      days: 'trip.days.d4',
      travelers: 'trip.travelers.individuals',
      price: 1700,
      currency: 'trip.currency.aed',
      provider: 'trip.provider.emiratesJourneys',
      providerColor: AppColors.cyan,
      providerLetter: 'إ',
      feats: const ['feat.transport', 'feat.meals'],
      stops: const [TripStop('city.dubai'), TripStop('city.makkah')],
      countryCode: 'AE',
    ),
  ];

  static List<UmrahResult> resultsForCountry(String code) =>
      umrahResults.where((r) => r.countryCode == code).toList();

  // ── Feed posts (لقطات / snapshots) ──
  static final List<Post> allPosts = [
    Post(
      id: 1,
      avatar: 'أح',
      avatarBg: const Color(0xFFB8892F),
      name: 'post.p1.name',
      time: 'time.day2',
      company: 'company.alferdawsFull',
      stars: 5,
      likes: 24,
      text: 'post.p1.text',
      comments: [
        const PostComment(
            name: 'post.c.mohamedAhmed',
            avatar: 'مأ',
            avatarBg: AppColors.blue,
            text: 'post.p1.c1.text'),
        const PostComment(
            name: 'post.c.reemKhaled',
            avatar: 'رخ',
            avatarBg: Color(0xFF7C3AED),
            text: 'post.p1.c2.text'),
      ],
    ),
    Post(
      id: 2,
      avatar: 'سم',
      avatarBg: const Color(0xFF7C3AED),
      name: 'post.p2.name',
      time: 'time.day3',
      company: 'company.safarplus',
      stars: 5,
      likes: 47,
      text: 'post.p2.text',
      media: const PostMedia(
          bg: gSky, emoji: '🏝️', imageAsset: 'assets/images/tourism1.jpg'),
      comments: [
        const PostComment(
            name: 'post.c.ahmedAli',
            avatar: 'أع',
            avatarBg: Color(0xFFB8892F),
            text: 'post.p2.c1.text'),
        const PostComment(
            name: 'post.c.hodaMohamed',
            avatar: 'هم',
            avatarBg: Color(0xFFD97706),
            text: 'post.p2.c2.text'),
        const PostComment(
            name: 'post.c.omarElsayed',
            avatar: 'عس',
            avatarBg: Color(0xFF8E6A28),
            text: 'post.p2.c3.text'),
      ],
    ),
    Post(
      id: 3,
      avatar: 'عب',
      avatarBg: const Color(0xFFD97706),
      name: 'post.p3.name',
      time: 'time.week1',
      company: 'company.nasmaFull',
      stars: 4,
      likes: 31,
      text: 'post.p3.text',
      comments: [
        const PostComment(
            name: 'post.c.fatmaMohamed',
            avatar: 'فم',
            avatarBg: Color(0xFF7C3AED),
            text: 'post.p3.c1.text'),
        const PostComment(
            name: 'post.c.youssefAhmed',
            avatar: 'يأ',
            avatarBg: AppColors.blue,
            text: 'post.p3.c2.text'),
      ],
    ),
    Post(
      id: 4,
      avatar: 'مح',
      avatarBg: const Color(0xFF8E6A28),
      name: 'post.p4.name',
      time: 'time.week2',
      company: 'company.awj',
      stars: 5,
      likes: 58,
      text: 'post.p4.text',
      media: const PostMedia(
          bg: gRed, emoji: '🕌', imageAsset: 'assets/images/tourism2.jpg'),
      comments: [
        const PostComment(
            name: 'post.c.samiAlomar',
            avatar: 'سع',
            avatarBg: Color(0xFFDC2626),
            text: 'post.p4.c1.text'),
        const PostComment(
            name: 'post.c.lamiaKarim',
            avatar: 'لك',
            avatarBg: Color(0xFFD97706),
            text: 'post.p4.c2.text'),
      ],
    ),
    Post(
      id: 5,
      avatar: 'كإ',
      avatarBg: AppColors.blue,
      name: 'post.p5.name',
      time: 'time.month1',
      company: 'company.alferdawsFull',
      stars: 5,
      likes: 19,
      text: 'post.p5.text',
      comments: [
        const PostComment(
            name: 'post.c.emanReda',
            avatar: 'إر',
            avatarBg: Color(0xFFB8892F),
            text: 'post.p5.c1.text')
      ],
    ),
    Post(
      id: 6,
      avatar: 'رأ',
      avatarBg: const Color(0xFFB8892F),
      name: 'post.p6.name',
      time: 'time.day4',
      company: 'company.safarplus',
      stars: 5,
      likes: 83,
      text: 'post.p6.text',
      media: const PostMedia(
          bg: gEmerald,
          emoji: '🏔️',
          videoLabel: 'فيديو الرحلة • ٢:٣٤',
          videoAsset: 'assets/videos/trip1.mp4'),
      comments: [
        const PostComment(
            name: 'post.c.amirSaeed',
            avatar: 'أس',
            avatarBg: Color(0xFF7C3AED),
            text: 'post.p6.c1.text'),
        const PostComment(
            name: 'post.p6.name',
            avatar: 'رأ',
            avatarBg: Color(0xFFB8892F),
            text: 'post.p6.c2.text'),
        const PostComment(
            name: 'post.c.nourEldin',
            avatar: 'ند',
            avatarBg: Color(0xFFD97706),
            text: 'post.p6.c3.text'),
      ],
    ),
    Post(
      id: 7,
      avatar: 'يم',
      avatarBg: const Color(0xFF7C3AED),
      name: 'post.p7.name',
      time: 'time.day5',
      company: 'company.makkahtours',
      stars: 4,
      likes: 42,
      text: 'post.p7.text',
      comments: [
        const PostComment(
            name: 'post.c.hassanTarek',
            avatar: 'حط',
            avatarBg: Color(0xFFB8892F),
            text: 'post.p7.c1.text'),
        const PostComment(
            name: 'post.p7.name',
            avatar: 'يم',
            avatarBg: Color(0xFF7C3AED),
            text: 'post.p7.c2.text'),
      ],
    ),
    Post(
      id: 8,
      avatar: 'نه',
      avatarBg: const Color(0xFFDC2626),
      name: 'post.p8.name',
      time: 'time.week1',
      company: 'company.dreamtravel',
      stars: 5,
      likes: 66,
      text: 'post.p8.text',
      media: const PostMedia(
          bg: gPurple, emoji: '🏙️', imageAsset: 'assets/images/tourism1.jpg'),
      comments: [
        const PostComment(
            name: 'post.c.tarekMansour',
            avatar: 'طم',
            avatarBg: Color(0xFF8E6A28),
            text: 'post.p8.c1.text'),
        const PostComment(
            name: 'post.c.salmaWaleed',
            avatar: 'سو',
            avatarBg: Color(0xFFD97706),
            text: 'post.p8.c2.text'),
        const PostComment(
            name: 'post.p8.name',
            avatar: 'نه',
            avatarBg: Color(0xFFDC2626),
            text: 'post.p8.c3.text'),
      ],
    ),
    Post(
      id: 9,
      avatar: 'فع',
      avatarBg: const Color(0xFF8E6A28),
      name: 'post.p9.name',
      time: 'time.week2',
      company: 'company.nasmaFull',
      stars: 5,
      likes: 95,
      text: 'post.p9.text',
      media: const PostMedia(
          bg: gGreen,
          emoji: '🕋',
          videoLabel: 'فيديو الحرم • ١:١٨',
          videoAsset: 'assets/videos/trip2.mp4'),
      comments: [
        const PostComment(
            name: 'post.c.amalSami',
            avatar: 'أس',
            avatarBg: AppColors.blue,
            text: 'post.p9.c1.text'),
        const PostComment(
            name: 'post.c.wesamKhaled',
            avatar: 'وخ',
            avatarBg: Color(0xFF7C3AED),
            text: 'post.p9.c2.text'),
      ],
    ),
    Post(
      id: 10,
      avatar: 'لس',
      avatarBg: const Color(0xFFD97706),
      name: 'post.p10.name',
      time: 'time.week3',
      company: 'company.safarplus',
      stars: 4,
      likes: 38,
      text: 'post.p10.text',
      media: const PostMedia(
          bg: gCyan, emoji: '🌴', imageAsset: 'assets/images/tourism2.jpg'),
      comments: [
        const PostComment(
            name: 'post.c.ahmedFares',
            avatar: 'أف',
            avatarBg: Color(0xFF8E6A28),
            text: 'post.p10.c1.text'),
        const PostComment(
            name: 'post.c.reemOmar',
            avatar: 'رع',
            avatarBg: Color(0xFFDC2626),
            text: 'post.p10.c2.text'),
      ],
    ),
    Post(
      id: 11,
      avatar: 'حب',
      avatarBg: AppColors.blue,
      name: 'post.p11.name',
      time: 'time.month1',
      company: 'company.alferdawsFull',
      stars: 5,
      likes: 27,
      text: 'post.p11.text',
      comments: [
        const PostComment(
            name: 'post.c.souadReda',
            avatar: 'سر',
            avatarBg: Color(0xFFB8892F),
            text: 'post.p11.c1.text'),
        const PostComment(
            name: 'post.c.amrHassan',
            avatar: 'عح',
            avatarBg: Color(0xFFD97706),
            text: 'post.p11.c2.text'),
      ],
    ),
    Post(
      id: 12,
      avatar: 'إأ',
      avatarBg: const Color(0xFF7C3AED),
      name: 'post.p12.name',
      time: 'time.month1',
      company: 'company.awj',
      stars: 5,
      likes: 71,
      text: 'post.p12.text',
      media: const PostMedia(
          bg: gViolet,
          emoji: '🏰',
          videoLabel: 'جولة في بودابست • ٣:٤٥',
          videoAsset: 'assets/videos/trip1.mp4'),
      comments: [
        const PostComment(
            name: 'post.c.mariamSayed',
            avatar: 'مس',
            avatarBg: Color(0xFF8E6A28),
            text: 'post.p12.c1.text'),
        const PostComment(
            name: 'post.c.karimWaleed',
            avatar: 'كو',
            avatarBg: Color(0xFFDC2626),
            text: 'post.p12.c2.text'),
      ],
    ),
    Post(
      id: 13,
      avatar: 'طس',
      avatarBg: const Color(0xFF8E6A28),
      name: 'post.p13.name',
      time: 'time.day3',
      company: 'company.makkahtours',
      stars: 5,
      likes: 112,
      text: 'post.p13.text',
      media: const PostMedia(
          bg: gTeal,
          emoji: '🕌',
          videoLabel: 'الحرم المكي فجراً • ٢:٠٧',
          videoAsset: 'assets/videos/trip3.mp4'),
      comments: [
        const PostComment(
            name: 'post.c.khaledOmar',
            avatar: 'خع',
            avatarBg: AppColors.blue,
            text: 'post.p13.c1.text'),
        const PostComment(
            name: 'post.c.samarAhmed',
            avatar: 'سأ',
            avatarBg: Color(0xFF7C3AED),
            text: 'post.p13.c2.text'),
        const PostComment(
            name: 'post.c.waleedFarouk',
            avatar: 'وف',
            avatarBg: Color(0xFFDC2626),
            text: 'post.p13.c3.text'),
      ],
    ),
    Post(
      id: 14,
      avatar: 'هم',
      avatarBg: const Color(0xFFDC2626),
      name: 'post.p14.name',
      time: 'time.day6',
      company: 'company.dreamtravel',
      stars: 4,
      likes: 44,
      text: 'post.p14.text',
      media: const PostMedia(
          bg: gGold, emoji: '🏖️', imageAsset: 'assets/images/tourism1.jpg'),
      comments: [
        const PostComment(
            name: 'post.c.amiraSami',
            avatar: 'أس',
            avatarBg: Color(0xFF8E6A28),
            text: 'post.p14.c1.text'),
        const PostComment(
            name: 'post.c.mahmoudAli',
            avatar: 'مع',
            avatarBg: AppColors.blue,
            text: 'post.p14.c2.text'),
      ],
    ),
    Post(
      id: 15,
      avatar: 'أو',
      avatarBg: const Color(0xFF6D28D9),
      name: 'post.p15.name',
      time: 'time.week1',
      company: 'company.alferdawsFull',
      stars: 5,
      likes: 89,
      text: 'post.p15.text',
      comments: [
        const PostComment(
            name: 'post.c.nadiaHassan',
            avatar: 'نح',
            avatarBg: Color(0xFFB8892F),
            text: 'post.p15.c1.text'),
        const PostComment(
            name: 'post.c.salwaOmar',
            avatar: 'سع',
            avatarBg: Color(0xFFD97706),
            text: 'post.p15.c2.text'),
        const PostComment(
            name: 'post.c.adelMaher',
            avatar: 'عم',
            avatarBg: AppColors.blue,
            text: 'post.p15.c3.text'),
      ],
    ),
    Post(
      id: 16,
      avatar: 'رن',
      avatarBg: const Color(0xFFB8892F),
      name: 'post.p16.name',
      time: 'time.day10',
      company: 'company.safarplus',
      stars: 5,
      likes: 67,
      text: 'post.p16.text',
      media: const PostMedia(
          bg: gRose,
          emoji: '🗾',
          videoLabel: 'جولة في كيوتو • ٤:١٢',
          videoAsset: 'assets/videos/trip2.mp4'),
      comments: [
        const PostComment(
            name: 'post.c.hamdyAmin',
            avatar: 'حأ',
            avatarBg: Color(0xFF6D28D9),
            text: 'post.p16.c1.text'),
        const PostComment(
            name: 'post.p16.name',
            avatar: 'رن',
            avatarBg: Color(0xFFB8892F),
            text: 'post.p16.c2.text'),
      ],
    ),
    Post(
      id: 17,
      avatar: 'عر',
      avatarBg: const Color(0xFFB8892F),
      name: 'post.p17.name',
      time: 'time.week2',
      company: 'company.nasmaFull',
      stars: 5,
      likes: 143,
      text: 'post.p17.text',
      comments: [
        const PostComment(
            name: 'post.c.saharRadwan',
            avatar: 'سر',
            avatarBg: Color(0xFF7C3AED),
            text: 'post.p17.c1.text'),
        const PostComment(
            name: 'post.c.tamerSaleh',
            avatar: 'تص',
            avatarBg: Color(0xFFDC2626),
            text: 'post.p17.c2.text'),
        const PostComment(
            name: 'post.c.emanWaleed',
            avatar: 'إو',
            avatarBg: Color(0xFF8E6A28),
            text: 'post.p17.c3.text'),
      ],
    ),
    Post(
      id: 18,
      avatar: 'سب',
      avatarBg: const Color(0xFFD97706),
      name: 'post.p18.name',
      time: 'time.week3',
      company: 'company.awj',
      stars: 4,
      likes: 52,
      text: 'post.p18.text',
      media: const PostMedia(
          bg: gOrange, emoji: '🕌', imageAsset: 'assets/images/tourism2.jpg'),
      comments: [
        const PostComment(
            name: 'post.c.dinaMohamed',
            avatar: 'دم',
            avatarBg: AppColors.blue,
            text: 'post.p18.c1.text'),
        const PostComment(
            name: 'post.p18.name',
            avatar: 'سب',
            avatarBg: Color(0xFFD97706),
            text: 'post.p18.c2.text'),
      ],
    ),
    Post(
      id: 19,
      avatar: 'كأ',
      avatarBg: AppColors.blue,
      name: 'post.p19.name',
      time: 'time.month1',
      company: 'company.makkahtours',
      stars: 5,
      likes: 78,
      text: 'post.p19.text',
      comments: [
        const PostComment(
            name: 'post.c.haniSalam',
            avatar: 'هس',
            avatarBg: Color(0xFFB8892F),
            text: 'post.p19.c1.text'),
        const PostComment(
            name: 'post.c.rihamAhmed',
            avatar: 'را',
            avatarBg: Color(0xFF7C3AED),
            text: 'post.p19.c2.text'),
      ],
    ),
    Post(
      id: 20,
      avatar: 'مك',
      avatarBg: const Color(0xFF8E6A28),
      name: 'post.p20.name',
      time: 'time.month1',
      company: 'company.dreamtravel',
      stars: 5,
      likes: 61,
      text: 'post.p20.text',
      media: const PostMedia(
          bg: gEmerald,
          emoji: '🌺',
          videoLabel: 'غروب بالي • ١:٥٥',
          videoAsset: 'assets/videos/trip3.mp4'),
      comments: [
        const PostComment(
            name: 'post.c.ahmedMaher',
            avatar: 'أم',
            avatarBg: Color(0xFFDC2626),
            text: 'post.p20.c1.text'),
        const PostComment(
            name: 'post.p20.name',
            avatar: 'مك',
            avatarBg: Color(0xFF8E6A28),
            text: 'post.p20.c2.text'),
      ],
    ),
  ];

  // ── Generated post pool (infinite feed beyond the 20 seeded posts) ──
  static const List<_ExtraName> _extraNames = [
    _ExtraName('نأ', Color(0xFFE11D48), 'extra.name1', 'company.safarplus'),
    _ExtraName('طر', Color(0xFFB8892F), 'extra.name2', 'company.alferdawsFull'),
    _ExtraName('مص', Color(0xFF7C3AED), 'extra.name3', 'company.dreamtravel'),
    _ExtraName('هن', Color(0xFF8E6A28), 'extra.name4', 'company.nasmaFull'),
    _ExtraName('عف', Color(0xFFD97706), 'extra.name5', 'company.awj'),
    _ExtraName('سك', Color(0xFFDC2626), 'extra.name6', 'company.makkahtours'),
    _ExtraName('أب', Color(0xFF6D28D9), 'extra.name7', 'company.safarplus'),
    _ExtraName('ره', Color(0xFF8E6A28), 'extra.name8', 'company.alferdawsFull'),
  ];

  static final List<_ExtraMedia> _extraMedia = [
    _ExtraMedia(
        const PostMedia(
            bg: gSky, emoji: '🏝️', imageAsset: 'assets/images/tourism1.jpg'),
        'extra.media1'),
    _ExtraMedia(
        const PostMedia(
            bg: gGreen,
            emoji: '🕋',
            videoLabel: 'لحظة الطواف • ٢:١٥',
            videoAsset: 'assets/videos/trip1.mp4'),
        'extra.media2'),
    _ExtraMedia(
        const PostMedia(
            bg: gPurple,
            emoji: '🏙️',
            imageAsset: 'assets/images/tourism2.jpg'),
        'extra.media3'),
    _ExtraMedia(
        const PostMedia(
            bg: gRed,
            emoji: '🕌',
            videoLabel: 'المسجد الأزرق • ١:٤٥',
            videoAsset: 'assets/videos/trip2.mp4'),
        'extra.media4'),
    _ExtraMedia(
        const PostMedia(
            bg: gGold, emoji: '🏖️', imageAsset: 'assets/images/tourism1.jpg'),
        'extra.media5'),
    _ExtraMedia(
        const PostMedia(
            bg: gEmerald,
            emoji: '🏔️',
            videoLabel: 'جبال جورجيا • ٣:٢٢',
            videoAsset: 'assets/videos/trip3.mp4'),
        'extra.media6'),
    _ExtraMedia(
        const PostMedia(
            bg: gOrange, emoji: '🕌', imageAsset: 'assets/images/tourism2.jpg'),
        'extra.media7'),
    _ExtraMedia(
        const PostMedia(
            bg: gViolet,
            emoji: '🏰',
            videoLabel: 'قلاع أوروبا • ٢:٥٨',
            videoAsset: 'assets/videos/trip1.mp4'),
        'extra.media8'),
    _ExtraMedia(
        const PostMedia(
            bg: gTeal, emoji: '🌴', imageAsset: 'assets/images/tourism1.jpg'),
        'extra.media9'),
    _ExtraMedia(
        const PostMedia(
            bg: gRose,
            emoji: '🗾',
            videoLabel: 'كيوتو اليابان • ٤:٠٥',
            videoAsset: 'assets/videos/trip2.mp4'),
        'extra.media10'),
  ];

  static const List<String> _times = [
    'time.justNow',
    'time.min30',
    'time.hour1',
    'time.day1',
    'time.day2',
    'time.week1',
  ];

  static Post generatePost(int id) {
    final n = _extraNames[(id - 21) % _extraNames.length];
    final m = _extraMedia[(id - 21) % _extraMedia.length];
    final stars = 4 + (id % 2);
    return Post(
      id: id,
      avatar: n.avatar,
      avatarBg: n.bg,
      name: n.name,
      time: _times[id % _times.length],
      company: n.company,
      stars: stars,
      text: m.text,
      media: m.media,
      likes: 10 + (id * 7 % 90),
      comments: const [
        PostComment(
            name: 'generic.userName',
            avatar: 'مس',
            avatarBg: AppColors.blue,
            text: 'generic.comment')
      ],
    );
  }

  static Post postById(int id) {
    return allPosts.firstWhere((p) => p.id == id,
        orElse: () => generatePost(id));
  }

  static List<Post> get mediaPosts =>
      allPosts.where((p) => p.media != null).toList();

  // ── Orders ──
  static final Map<String, Order> orders = {
    'ord1': const Order(
      id: '#RH-2025-001',
      trip: 'trip.muyassara.title',
      emoji: '🕋',
      provider: 'company.alferdawsFull',
      date: 'order.ord1.date',
      duration: 'trip.days.d20',
      pax: 'order.pax.three',
      status: OrderStatus.pending,
      statusText: 'order.status.pending',
      bus: null,
      hotel: OrderHotelInfo(
          name: 'order.ord1.hotelName',
          stars: '★★★★★',
          location: 'order.ord1.location',
          room: 'order.ord1.room',
          roomType: 'order.ord1.roomType'),
      hotelAssigned: true,
      roomAssigned: false,
      priceUnit: 'order.ord1.priceUnit',
      total: 'trip.muyassara.price',
      action: 'order.ord1.action',
    ),
    'ord2': const Order(
      id: '#RH-2025-002',
      trip: 'trip.dhahabiya.title',
      emoji: '⭐',
      provider: 'company.nasmaFull',
      date: 'order.ord2.date',
      duration: 'trip.days.d14',
      pax: 'order.pax.two',
      status: OrderStatus.confirmed,
      statusText: 'order.status.confirmed',
      bus: OrderBusInfo(
          num: 'order.ord2.busNum',
          cap: 'order.ord2.busCap',
          supervisor: 'order.supervisor.mohamedElsayed',
          phone: '0101 987 6543'),
      hotel: OrderHotelInfo(
          name: 'order.ord2.hotelName',
          stars: '★★★★★',
          location: 'order.ord2.location',
          room: 'order.ord2.room',
          roomType: 'order.ord2.roomType',
          roommates: [
            'order.roommate.mohamedRizq',
            'order.roommate.ahmedRizq'
          ]),
      priceUnit: 'order.ord2.priceUnit',
      total: 'trip.dhahabiya.price',
      action: 'order.ord2.action',
    ),
    'ord3': const Order(
      id: '#RH-2024-089',
      trip: 'order.ord3.trip',
      emoji: '🏝️',
      provider: 'company.safarplus',
      date: 'order.ord3.date',
      duration: 'trip.days.d7',
      pax: 'order.pax.two',
      status: OrderStatus.completed,
      statusText: 'order.status.completed',
      bus: null,
      hotel: OrderHotelInfo(
          name: 'order.ord3.hotelName',
          stars: '★★★★★',
          location: 'order.ord3.location',
          room: 'order.ord3.room',
          roomType: 'order.ord3.roomType',
          roommates: ['order.roommate.saraAhmed']),
      priceUnit: 'order.ord3.priceUnit',
      total: 'trip.muyassara.price',
      action: 'order.ord3.action',
    ),
    'ord4': const Order(
      id: '#RH-2024-071',
      trip: 'order.ord4.trip',
      emoji: '🕋',
      provider: 'order.ord4.provider',
      date: 'order.ord4.date',
      duration: 'trip.days.d10',
      pax: 'order.pax.one',
      status: OrderStatus.cancelled,
      statusText: 'order.status.cancelled',
      bus: null,
      hotel: OrderHotelInfo(
          name: 'order.ord1.hotelName',
          stars: '★★★★',
          location: 'order.ord4.location',
          room: 'order.ord1.room',
          roomType: 'order.ord4.roomType'),
      hotelAssigned: false,
      roomAssigned: false,
      priceUnit: 'order.ord4.price9000',
      total: 'order.ord4.price9000',
      action: 'order.ord4.action',
    ),
  };

  // ── Design requests (submitted via "صمّم عمرتك") ──
  static const umrahDesignRequest = UmrahDesignRequest(
    id: '#DR-2025-014',
    date: 'design_request.sample.date',
    stage: DesignRequestStage.contacted,
    startPoint: 'design.option.makkah_then_madinah',
    adults: 2,
    makkaDays: 7,
    madinaDays: 3,
    hotelStars: 'design.option.star_5',
    roomType: 'design.option.double_room',
    hotelPrefs: [
      'design.option.near_haram',
      'design.option.breakfast_included'
    ],
    departureCity: 'city.cairo',
    flightClass: 'design.option.economy',
    extraService: 'design.option.umrah_visa',
    name: 'محمد رزق',
    phone: '+20 100 123 4567',
  );
}

class _ExtraName {
  final String avatar;
  final Color bg;
  final String name;
  final String company;
  const _ExtraName(this.avatar, this.bg, this.name, this.company);
}

class _ExtraMedia {
  final PostMedia media;
  final String text;
  const _ExtraMedia(this.media, this.text);
}
