import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationLookupResult {
  final String? countryCode;
  final String? cityName;
  const LocationLookupResult.found(this.countryCode, this.cityName);
  const LocationLookupResult.notFound() : countryCode = null, cityName = null;
}

class LocationService {
  static Future<LocationLookupResult> detect() async {
    try {
      final res = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return const LocationLookupResult.notFound();
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['success'] != true) return const LocationLookupResult.notFound();
      return LocationLookupResult.found(
        json['country_code'] as String?,
        json['city'] as String?,
      );
    } catch (_) {
      // Any failure (timeout, DNS, offline, malformed JSON) collapses to the
      // same "ask the user" outcome — never guess a default country.
      return const LocationLookupResult.notFound();
    }
  }
}
