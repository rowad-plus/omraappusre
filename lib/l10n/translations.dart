import '../state/locale_state.dart';
import 'sections/auth.dart';
import 'sections/common.dart';
import 'sections/company_profile.dart';
import 'sections/countries.dart';
import 'sections/design.dart';
import 'sections/feats.dart';
import 'sections/header.dart';
import 'sections/legal.dart';
import 'sections/more_menu.dart';
import 'sections/nav.dart';
import 'sections/orders.dart';
import 'sections/photos.dart';
import 'sections/seed_companies.dart';
import 'sections/seed_orders.dart';
import 'sections/seed_posts.dart';
import 'sections/seed_trips.dart';
import 'sections/seed_trips_sa.dart';
import 'sections/seed_trips_uae.dart';
import 'sections/seed_umrah_results.dart';
import 'sections/settings.dart';
import 'sections/trip.dart';

final Map<String, Map<String, String>> _all = _buildAll();

Map<String, Map<String, String>> _buildAll() {
  final sections = [
    commonTranslations,
    navTranslations,
    headerTranslations,
    settingsTranslations,
    moreMenuTranslations,
    ordersTranslations,
    legalTranslations,
    authTranslations,
    designTranslations,
    tripTranslations,
    countryTranslations,
    photosTranslations,
    companyProfileTranslations,
    featsTranslations,
    seedTripsTranslations,
    seedTripsSaTranslations,
    seedTripsUaeTranslations,
    seedPostsTranslations,
    seedOrdersTranslations,
    seedCompaniesTranslations,
    seedUmrahResultsTranslations,
  ];
  final result = <String, Map<String, String>>{
    for (final l in LocaleState.supportedLocales) l.languageCode: {},
  };
  for (final section in sections) {
    for (final entry in section.entries) {
      result[entry.key]!.addAll(entry.value);
    }
  }
  return result;
}

/// Looks up [key] in the active locale ([LocaleState.locale]), falling back
/// to Arabic, then to the raw key itself so a missing translation is
/// visibly obvious instead of crashing.
String tr(String key) {
  final code = LocaleState.locale.value.languageCode;
  if (key.startsWith('trip.date.weekly:')) return _weeklyLabel(key, code);
  if (key.startsWith('trip.date.monthly:')) {
    final day = key.substring('trip.date.monthly:'.length);
    return (_monthlyTemplates[code] ?? _monthlyTemplates['ar']!)
        .replaceAll('{d}', day);
  }
  return _all[code]?[key] ?? _all['ar']?[key] ?? key;
}

/// `trip.date.weekly:4,6` → "الخميس، السبت" (0 = Sunday, Carbon dayOfWeek).
String _weeklyLabel(String key, String code) {
  final names = _weekdayNames[code] ?? _weekdayNames['ar']!;
  final days = key
      .substring('trip.date.weekly:'.length)
      .split(',')
      .map(int.tryParse)
      .whereType<int>()
      .where((d) => d >= 0 && d < 7)
      .map((d) => names[d]);
  final sep = (code == 'ar' || code == 'ur') ? '، ' : ', ';
  return days.join(sep);
}

const _weekdayNames = <String, List<String>>{
  'ar': ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'],
  'en': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  'fr': ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'],
  'tr': ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'],
  'id': ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'],
  'ur': ['اتوار', 'پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ'],
  'ms': ['Ahad', 'Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu'],
};

const _monthlyTemplates = <String, String>{
  'ar': 'يوم {d} من كل شهر',
  'en': 'Monthly, day {d}',
  'fr': 'Chaque mois, le {d}',
  'tr': 'Her ayın {d}. günü',
  'id': 'Setiap bulan tgl {d}',
  'ur': 'ہر ماہ کی {d} تاریخ',
  'ms': 'Setiap bulan, hari {d}',
};
