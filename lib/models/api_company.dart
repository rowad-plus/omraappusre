/// A provider company's public profile, as returned by the real Front API
/// (`GET /companies/{id}`). The company's own trip list is fetched
/// separately via `AppState.fetchTrips(companyId: id)` (same `/umrah-trips`
/// endpoint the rest of the app already uses) rather than duplicated here.
class ApiCompany {
  final int id;
  final String name;
  final String? logo;
  final String? about;
  final String? slogan;
  final String rank; // featured | regular
  final int? foundedYear;
  final String? phone;
  final String? whatsapp;
  final String? website;
  final String? cityName;
  final String? countryName;
  final int tripsCount;

  const ApiCompany({
    required this.id,
    required this.name,
    this.logo,
    this.about,
    this.slogan,
    required this.rank,
    this.foundedYear,
    this.phone,
    this.whatsapp,
    this.website,
    this.cityName,
    this.countryName,
    this.tripsCount = 0,
  });

  factory ApiCompany.fromJson(Map<String, dynamic> j) => ApiCompany(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        logo: j['logo'] as String?,
        about: j['about'] as String?,
        slogan: j['slogan'] as String?,
        rank: j['rank'] as String? ?? 'regular',
        foundedYear: j['founded_year'] as int?,
        phone: j['phone'] as String?,
        whatsapp: j['whatsapp'] as String?,
        website: j['website'] as String?,
        cityName: j['city_name'] as String?,
        countryName: j['country_name'] as String?,
        tripsCount: j['trips_count'] as int? ?? 0,
      );
}

/// One row of the «مكاتب العمرة» directory (`GET /companies-directory`).
class ApiDirectoryCompany {
  final int id;
  final String name;
  final String? logo;
  final bool featured;
  final String? cityName;
  final int tripsCount;

  const ApiDirectoryCompany({
    required this.id,
    required this.name,
    this.logo,
    this.featured = false,
    this.cityName,
    this.tripsCount = 0,
  });

  factory ApiDirectoryCompany.fromJson(Map<String, dynamic> j) =>
      ApiDirectoryCompany(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        logo: j['logo'] as String?,
        featured: j['rank'] == 'featured',
        cityName: j['city_name'] as String?,
        tripsCount: (j['trips_count'] as num?)?.toInt() ?? 0,
      );
}

/// A city chip in the directory filter, with its number of offices.
class ApiDirectoryCity {
  final int id;
  final String name;
  final int count;
  const ApiDirectoryCity(this.id, this.name, this.count);

  factory ApiDirectoryCity.fromJson(Map<String, dynamic> j) => ApiDirectoryCity(
      j['id'] as int, j['name'] as String? ?? '', (j['count'] as num?)?.toInt() ?? 0);
}
