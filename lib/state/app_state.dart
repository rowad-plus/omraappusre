import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_booking.dart';
import '../models/api_company.dart';
import '../models/api_notification.dart';
import '../models/api_post.dart';
import '../models/api_trip.dart';
import '../models/country.dart';
import '../models/schedule_result.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';
import 'locale_state.dart';
import '../state/country_state.dart';

/// Result of sending a login OTP — distinguishes "no account with this
/// phone" from other errors so the UI can offer to switch into registration.
class LoginOtpResult {
  final bool success;
  final bool notRegistered;
  final String? error;
  const LoginOtpResult({required this.success, this.notRegistered = false, this.error});
}

/// Result of creating a booking — carries the new booking's id (needed to
/// then call [AppState.initiatePayment]) and its server-derived payment
/// option alongside the existing error-message shape.
class BookingCreateResult {
  final int? bookingId;
  final String? paymentOption;
  final String? error;
  const BookingCreateResult({this.bookingId, this.paymentOption, this.error});
}

/// Result of starting a NeoLeap payment — either a hosted payment page URL
/// to open in [NeoLeapPaymentScreen], or a display-ready error message.
class PaymentInitiateResult {
  final String? paymentUrl;
  final String? error;
  const PaymentInitiateResult({this.paymentUrl, this.error});
}

/// Real app-wide session state for the rihlaty customer app, backed by the
/// Front API (Sanctum token auth). Replaces the old static
/// `ValueNotifier<bool> isLoggedIn` placeholder.
class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();
  static const _tokenPrefsKey = 'rihlaty_api_token';

  bool sessionLoading = true;
  bool isLoggedIn = false;

  int? userId;
  String userName = '';
  String? userEmail;
  String? userPhone;

  /// Profile photo uploaded on the website (`avatar_url`), null if none.
  String? userAvatarUrl;

  void _applyUserPayload(Map<String, dynamic> user) {
    userId = user['id'] as int?;
    userName = user['name'] as String? ?? '';
    userEmail = user['email'] as String?;
    userPhone = user['phone'] as String?;
    userAvatarUrl = user['avatar_url'] as String?;
  }

  void _clearSession() {
    isLoggedIn = false;
    userId = null;
    userName = '';
    userEmail = null;
    userPhone = null;
    userAvatarUrl = null;
  }

  /// Checks for a saved token from a previous session and tries to restore
  /// the account. Called once on app start.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenPrefsKey);
    if (token == null) {
      sessionLoading = false;
      notifyListeners();
      return;
    }

    api.setToken(token);
    try {
      final res = await api.get('/me') as Map<String, dynamic>;
      // The backend's auth middleware redirects (not 401) an invalid token,
      // which `http` follows — landing here as a 200 with an unrelated body.
      // A real account payload always has an id, so require that.
      if (res['id'] == null) throw ApiException(401, 'invalid session');
      _applyUserPayload(res);
      isLoggedIn = true;
    } on ApiException catch (e) {
      // Only a genuine "this session is no longer valid" response (401,
      // including the synthetic one thrown above) signs the user out.
      // Any other server error must never silently end a saved session.
      if (e.statusCode == 401) {
        await prefs.remove(_tokenPrefsKey);
        api.setToken(null);
      } else {
        isLoggedIn = true;
      }
    } catch (_) {
      // Network/timeout/offline — keep the saved session; access resumes
      // once connectivity is back instead of forcing a re-login.
      isLoggedIn = true;
    }
    sessionLoading = false;
    notifyListeners();
    if (isLoggedIn) _registerPush();
  }

  /// Registers this phone's FCM token so booking updates (confirmation,
  /// bus, hotel/room, room-mates, payment) arrive as push notifications.
  void _registerPush() {
    PushService.instance.register(
      (token) => api.post('/device-tokens', {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'locale': LocaleState.locale.value.languageCode,
      }),
    );
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, token);
    api.setToken(token);
    _registerPush();
  }

  Future<LoginOtpResult> sendLoginOtp(String phone) async {
    try {
      await api.post('/auth/login/send-otp', {'phone': phone});
      return const LoginOtpResult(success: true);
    } on ApiException catch (e) {
      if (e.data?['not_registered'] == true) {
        return const LoginOtpResult(success: false, notRegistered: true);
      }
      return LoginOtpResult(success: false, error: e.message);
    } catch (_) {
      return const LoginOtpResult(success: false, error: 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا');
    }
  }

  Future<String?> verifyLoginOtp(String phone, String code) async {
    try {
      final res = await api.post('/auth/login/verify-otp', {'phone': phone, 'code': code}) as Map<String, dynamic>;
      await _persistToken(res['token'] as String);
      _applyUserPayload(res['user'] as Map<String, dynamic>);
      isLoggedIn = true;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا';
    }
  }

  Future<String?> sendRegisterOtp({required String name, String? email, required String phone}) async {
    try {
      await api.post('/auth/register/send-otp', {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        'phone': phone,
        'terms': true,
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا';
    }
  }

  Future<String?> verifyRegisterOtp({required String name, String? email, required String phone, required String code}) async {
    try {
      final res = await api.post('/auth/register/verify-otp', {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        'phone': phone,
        'code': code,
      }) as Map<String, dynamic>;
      await _persistToken(res['token'] as String);
      _applyUserPayload(res['user'] as Map<String, dynamic>);
      isLoggedIn = true;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا';
    }
  }

  Future<String?> resendOtp(String phone, {String type = 'login'}) async {
    try {
      await api.post('/auth/resend-otp', {'phone': phone, 'type': type});
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا';
    }
  }

  // ------- Trip browsing (real backend, public — no auth required) -------

  /// Fetches active Umrah trips, optionally scoped to a departure-market
  /// country (by ISO code, matching the local country picker) and/or trip
  /// type ('vip' | 'premium' | 'economy'). Returns an empty list on any
  /// failure rather than throwing, since browsing should degrade quietly.
  Future<List<ApiTrip>> fetchTrips(
      {String? countryCode, String? type, int? companyId, int? cityId}) async {
    try {
      final res = await api.get('/umrah-trips', {
        if (countryCode != null) 'country_code': countryCode,
        if (type != null) 'trip_type': type,
        if (companyId != null) 'company_id': companyId,
        // A specific departure city narrows within the country — omitted
        // entirely (not just null) means "every city in the country",
        // matching `departure_city` being genuinely absent server-side.
        if (cityId != null) 'departure_city': cityId,
      }) as Map<String, dynamic>;
      return (res['trips'] as List<dynamic>)
          .map((t) => ApiTrip.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// The mobile equivalent of the website's `/umrah/schedule` date-based
  /// search page — resolves a departure city the same way the server
  /// already does for [fetchTrips] (geo/country fallback) when [cityId]
  /// isn't given, and returns that day's real matching trips plus a
  /// real per-day price date-strip (not a placeholder).
  Future<ScheduleResult?> fetchSchedule({
    String? countryCode,
    int? cityId,
    DateTime? date,
    String? type,
  }) async {
    try {
      final res = await api.get('/umrah-trips/schedule', {
        if (countryCode != null) 'country_code': countryCode,
        if (cityId != null) 'city': cityId,
        if (date != null)
          'date':
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        if (type != null) 'trip_type': type,
      }) as Map<String, dynamic>;
      return ScheduleResult.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Real departure cities for a country — mirrors the *exact* query the
  /// website's own location picker uses (`AppServiceProvider`'s
  /// `$activeCitiesByCountry`: every active city in the country, featured
  /// first) instead of the old static `Country.cityKeys` catalog
  /// (hand-typed, capped at 1-2 per country) or a trip-existence filter
  /// (which undercounted just as badly — most active cities have no live
  /// trip departing from them yet, same as on the website).
  Future<List<CityOption>> fetchDepartureCities(String countryCode) async {
    try {
      final res = await api.get('/departure-cities', {
        'country_code': countryCode,
      }) as Map<String, dynamic>;
      return (res['cities'] as List<dynamic>)
          .map((c) => CityOption.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ApiTrip?> fetchTripDetail(int id) async {
    try {
      final res = await api.get('/umrah-trips/$id') as Map<String, dynamic>;
      return ApiTrip.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Lightweight company search for the "tag a company" picker in the post
  /// composer. Empty query returns the top companies (featured first) so
  /// the picker isn't blank before the user types anything.
  Future<List<ApiFeaturedCompany>> searchCompanies(String query) async {
    try {
      final res = await api.get('/companies', {
        if (query.isNotEmpty) 'search': query,
      }) as Map<String, dynamic>;
      return (res['companies'] as List<dynamic>)
          .map((c) => ApiFeaturedCompany.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Companies the signed-in user has booked with, latest booking first
  /// (the `booked` list of `/companies`). Empty when signed out or on error.
  Future<List<ApiFeaturedCompany>> fetchBookedCompanies() async {
    try {
      final res = await api.get('/companies') as Map<String, dynamic>;
      return ((res['booked'] as List<dynamic>?) ?? const [])
          .map((c) => ApiFeaturedCompany.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// A provider company's public profile — powers the company profile page
  /// opened from a featured-company card or the provider scroller. Returns
  /// null on any failure (missing/inactive company, network error) so the
  /// screen can show a clean "not found" state instead of crashing.
  Future<ApiCompany?> fetchCompany(int id) async {
    try {
      final res = await api.get('/companies/$id') as Map<String, dynamic>;
      return ApiCompany.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  // ------- Timeline / لقطات feed (real backend; posts are public,
  // likes/comments/creation require auth) -------

  Future<(List<ApiFeaturedCompany>, List<ApiNearbyTrip>)> fetchTimelineHome() async {
    try {
      final country = CountryState.selected.value?.code;
      final res = await api.get('/timeline/home',
          country == null ? null : {'country': country}) as Map<String, dynamic>;
      final companies = (res['featured_companies'] as List<dynamic>)
          .map((c) => ApiFeaturedCompany.fromJson(c as Map<String, dynamic>))
          .toList();
      final trips = (res['nearby_trips'] as List<dynamic>)
          .map((t) => ApiNearbyTrip.fromJson(t as Map<String, dynamic>))
          .toList();
      return (companies, trips);
    } catch (_) {
      return (<ApiFeaturedCompany>[], <ApiNearbyTrip>[]);
    }
  }

  /// Returns (posts, hasMore) for the given page. Empty list + hasMore:false
  /// on any failure, so the feed just stops loading rather than erroring.
  Future<(List<ApiPost>, bool)> fetchTimelinePosts(int page) async {
    try {
      // The selected country lets the server rank same-day posts about local
      // companies (based in / departing from that country) higher.
      final country = CountryState.selected.value?.code;
      final res = await api.get('/timeline/posts', {
        'page': page,
        if (country != null) 'country': country,
      }) as Map<String, dynamic>;
      final posts = (res['posts'] as List<dynamic>)
          .map((p) => ApiPost.fromJson(p as Map<String, dynamic>))
          .toList();
      return (posts, res['has_more'] as bool? ?? false);
    } catch (_) {
      return (<ApiPost>[], false);
    }
  }

  /// Returns the new liked state, or null if the request failed.
  Future<bool?> toggleTimelineLike(int postId) async {
    try {
      final res = await api.post('/timeline/posts/$postId/like') as Map<String, dynamic>;
      return res['liked'] as bool?;
    } catch (_) {
      return null;
    }
  }

  Future<List<ApiPostComment>> fetchTimelineComments(int postId) async {
    try {
      final res = await api.get('/timeline/posts/$postId/comments') as Map<String, dynamic>;
      return (res['comments'] as List<dynamic>)
          .map((c) => ApiPostComment.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ApiPostComment?> addTimelineComment(int postId, String content) async {
    try {
      final res = await api.post('/timeline/posts/$postId/comments', {'content': content}) as Map<String, dynamic>;
      return ApiPostComment.fromJson(res['comment'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Creates a timeline post. [type] is one of text|photos|video|review.
  /// [imageBytes] is optional — one image, matching the mobile composer's
  /// current single-photo picker (video capture/upload isn't wired yet).
  /// Returns null on success, or a display-ready error message on failure.
  Future<String?> createTimelinePost({
    required String type,
    required String content,
    int? companyId,
    int? rating,
    List<int>? imageBytes,
    List<int>? videoBytes,
  }) async {
    try {
      await api.postMultipart(
        '/timeline/posts',
        {
          'type': type,
          'content': content,
          if (companyId != null) 'company_id': companyId,
          if (rating != null) 'rating': rating,
        },
        files: [
          if (imageBytes != null) MapEntry('media[]', imageBytes),
          if (videoBytes != null) MapEntry('media[]', videoBytes),
        ],
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا';
    }
  }

  // ------- Notifications (real backend, requires auth) -------

  Future<(List<ApiNotification>, int)> fetchNotifications() async {
    try {
      final res = await api.get('/notifications') as Map<String, dynamic>;
      final notifications = (res['data'] as List<dynamic>)
          .map((n) => ApiNotification.fromJson(n as Map<String, dynamic>))
          .toList();
      return (notifications, res['unread_count'] as int? ?? 0);
    } catch (_) {
      return (<ApiNotification>[], 0);
    }
  }

  /// تحديثات حجز واحد (تسكين، باص، دفع، تجمّعات الشركة) لصفحة العمرة.
  Future<List<ApiNotification>> fetchBookingUpdates(int bookingId) async {
    try {
      final res = await api.get('/notifications?booking_id=$bookingId') as Map<String, dynamic>;
      return (res['data'] as List<dynamic>)
          .map((n) => ApiNotification.fromJson(n as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> fetchUnreadNotificationsCount() async {
    try {
      final res = await api.get('/notifications/unread-count') as Map<String, dynamic>;
      return res['unread_count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markNotificationRead(int id) async {
    try {
      await api.post('/notifications/$id/read');
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await api.post('/notifications/read-all');
    } catch (_) {}
  }

  // ------- Favorites (real backend, requires auth) -------

  Future<List<ApiTrip>> fetchFavorites() async {
    try {
      final res = await api.get('/favorites') as Map<String, dynamic>;
      return (res['trips'] as List<dynamic>)
          .map((t) => ApiTrip.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Toggles the favorite state of [tripId]. Returns the new state (true =
  /// now favorited), or null if the request failed — the caller should
  /// leave its own state unchanged in that case.
  Future<bool?> toggleFavorite(int tripId) async {
    try {
      final res = await api.post('/favorites/toggle', {
        'trip_type': 'umrah',
        'trip_id': tripId,
      }) as Map<String, dynamic>;
      return res['active'] as bool?;
    } catch (_) {
      return null;
    }
  }

  // ------- Comparisons (real backend, requires auth) -------

  Future<List<ApiTrip>> fetchComparisons() async {
    try {
      final res = await api.get('/comparisons') as Map<String, dynamic>;
      return (res['trips'] as List<dynamic>)
          .map((t) => ApiTrip.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Toggles [tripId] in/out of the comparison list. Returns the new state
  /// (true = now added), `'max_reached'` if the server's 3-item cap was hit
  /// (mirrors the website's own `ComparisonController::toggle()` exactly),
  /// or null on any other failure.
  Future<Object?> toggleComparison(int tripId) async {
    try {
      final res = await api.post('/comparisons/toggle', {
        'trip_type': 'umrah',
        'trip_id': tripId,
      }) as Map<String, dynamic>;
      return res['active'] as bool?;
    } on ApiException catch (e) {
      return e.data?['error'] == 'max_reached' ? 'max_reached' : null;
    } catch (_) {
      return null;
    }
  }

  // ------- Bookings/orders (real backend, requires auth) -------

  Future<List<ApiBooking>> fetchBookings() async {
    try {
      final res = await api.get('/bookings') as Map<String, dynamic>;
      return (res['bookings'] as List<dynamic>)
          .map((b) => ApiBooking.fromJson(b as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ApiBooking?> fetchBookingDetail(int id) async {
    try {
      final res = await api.get('/bookings/$id') as Map<String, dynamic>;
      return ApiBooking.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Creates a booking for [tripId]. Returns the new booking's id + payment
  /// option on success, or a display-ready error message (in Arabic, from
  /// the backend) on failure.
  Future<BookingCreateResult> createBooking({
    required int tripId,
    required int personsCount,
    required String countryCode,
    required List<ApiBookingTraveler> travelers,
    required String tripDateId,
    String? notes,
    bool privateRoom = false,
  }) async {
    try {
      final res = await api.post('/bookings', {
        'trip_id': tripId,
        'persons_count': personsCount,
        'country_code': countryCode,
        // Private room (2+ persons) → the trip's family price; otherwise the
        // server charges the per-person price × persons.
        'private_room': privateRoom && personsCount > 1,
        'travelers': travelers.map((t) => t.toJson()).toList(),
        'trip_date_id': tripDateId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }) as Map<String, dynamic>;
      return BookingCreateResult(
        bookingId: res['booking_id'] as int?,
        paymentOption: res['payment_option'] as String?,
      );
    } on ApiException catch (e) {
      return BookingCreateResult(error: e.message);
    } catch (_) {
      return const BookingCreateResult(
          error: 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا');
    }
  }

  /// Cancels a still-pending, still-unpaid booking — mirrors the website's
  /// `BookingController::cancel()` rule exactly (see `Api\BookingController
  /// ::cancel()`): once a booking is confirmed or paid, only an admin can
  /// cancel it, and the backend rejects the request accordingly. Returns
  /// null on success, or a display-ready error message on failure.
  Future<String?> cancelBooking(int bookingId) async {
    try {
      await api.post('/bookings/$bookingId/cancel');
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا';
    }
  }

  /// Starts a NeoLeap payment for an already-created booking — returns the
  /// Bank-Hosted payment page URL to load in [NeoLeapPaymentScreen], or a
  /// display-ready error message. Safe to call again for the same booking
  /// (the backend reuses the in-flight/pending payment attempt rather than
  /// double-charging — see `PaymentController::initiate`).
  Future<PaymentInitiateResult> initiatePayment(int bookingId) async {
    try {
      final res =
          await api.post('/bookings/$bookingId/pay') as Map<String, dynamic>;
      return PaymentInitiateResult(paymentUrl: res['payment_url'] as String?);
    } on ApiException catch (e) {
      return PaymentInitiateResult(error: e.message);
    } catch (_) {
      return const PaymentInitiateResult(
          error: 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا');
    }
  }

  /// Asks the server to confirm a booking's payment directly with Paymob
  /// (`POST /bookings/{id}/payment/verify`) — the native SDK never returns
  /// through the website, so this records the payment without waiting for
  /// the webhook. True once the booking is paid, false if not (yet), null
  /// on a network/API error.
  Future<bool?> verifyPayment(int bookingId) async {
    try {
      final res = await api.post('/bookings/$bookingId/payment/verify')
          as Map<String, dynamic>;
      return res['paid'] == true;
    } catch (_) {
      return null;
    }
  }

  /// Previews the payment plan (full / commission / unconfirmed) for a trip
  /// before the customer actually submits a booking — the payment path
  /// itself is always server-derived from the customer's country, never
  /// chosen client-side. Returns null on any failure (network/API error);
  /// the booking sheet shows a retry state in that case.
  Future<BookingQuote?> getBookingQuote({
    required int tripId,
    required int personsCount,
    required String countryCode,
    bool privateRoom = false,
  }) async {
    try {
      final res = await api.get('/umrah-trips/$tripId/booking-quote', {
        'persons_count': personsCount,
        'country_code': countryCode,
        if (privateRoom && personsCount > 1) 'private_room': 1,
      }) as Map<String, dynamic>;
      return BookingQuote.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Updates the user's name/email via PUT /me. Returns null on success, or
  /// a display-ready error message on failure. Phone isn't included — the
  /// backend requires OTP re-verification to change it (see the web's
  /// phoneSendOtp/phoneVerifyOtp flow), which this doesn't attempt.
  Future<String?> updateProfile({required String name, String? email}) async {
    try {
      final res = await api.put('/me', {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
      }) as Map<String, dynamic>;
      final user = res['user'] as Map<String, dynamic>;
      userName = user['name'] as String? ?? userName;
      userEmail = user['email'] as String?;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا';
    }
  }

  /// Submits the "تواصل معنا" contact-us message form. Returns null on
  /// success, or a display-ready error message on failure.
  Future<String?> submitContactMessage({
    required String subject,
    required String message,
  }) async {
    try {
      await api.post('/contact', {
        'name': userName,
        if (userEmail != null && userEmail!.isNotEmpty) 'email': userEmail,
        if (userPhone != null && userPhone!.isNotEmpty) 'phone': userPhone,
        'subject': subject,
        'message': message,
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا';
    }
  }

  /// Submits the "صمم رحلتك" custom-trip design request. Returns null on
  /// success, or a display-ready error message on failure. Mirrors
  /// createBooking's error-handling shape.
  Future<String?> submitDesignRequest({
    required String startCity,
    required int daysInMakkah,
    required int daysInMadinah,
    String? hotelStarsMakkah,
    List<String>? hotelPrefs,
    String? departureCity,
    String? flightClass,
    required int adults,
    List<String>? extras,
    required String contactName,
    required String contactPhone,
    String? roomType,
    String? specialRequests,
  }) async {
    try {
      await api.post('/design-umrah', {
        'start_city': startCity,
        'days_in_makkah': daysInMakkah,
        'days_in_madinah': daysInMadinah,
        if (hotelStarsMakkah != null) 'hotel_stars_makkah': hotelStarsMakkah,
        if (hotelPrefs != null) 'hotel_prefs': hotelPrefs,
        if (departureCity != null && departureCity.isNotEmpty)
          'departure_city': departureCity,
        if (flightClass != null) 'flight_class': flightClass,
        'adults': adults,
        if (extras != null) 'extras': extras,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        if (roomType != null) 'room_type': roomType,
        if (specialRequests != null && specialRequests.isNotEmpty)
          'special_requests': specialRequests,
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت وحاول مجددًا';
    }
  }

  Future<void> logout() async {
    await PushService.instance.unregister((token) => api.delete('/device-tokens', {'token': token}));
    try {
      await api.post('/logout');
    } catch (_) {
      // Ignore server-side failures — the local session is cleared regardless.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefsKey);
    api.setToken(null);
    _clearSession();
    notifyListeners();
  }
}
