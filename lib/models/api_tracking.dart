/// "تتبع الرحلة" payload from GET /bookings/{id}/tracking — the same
/// stage list the website's track page renders (built server-side by
/// `BookingTracking`), so the app and the site always agree on where a
/// trip stands. Stage titles and [labels] arrive already translated into
/// the app's current language (Accept-Language).
class ApiTracking {
  final int bookingId;
  final String ref;
  final String status; // pending | confirmed | in_trip | completed | cancelled | rejected
  final String headline;
  final String? currentStage;
  final int progress;
  final int? daysLeft;
  final List<TrackingStage> stages;
  final TrackingTrip trip;
  final String? companyName;
  final String? companyPhone;
  final String? companyWhatsapp;
  final String? companyLogo;
  final String? companyCity;

  /// Admin-controlled (company override, else country switch): when false
  /// the server sends no phone/WhatsApp at all.
  final bool companyContactVisible;
  final Map<String, dynamic>? hotel;
  final Map<String, dynamic>? bus;
  final bool needsPayment;
  final String? paymentStatusLabel;
  final double total;
  final double paid;
  final String currency;
  final int personsCount;
  final List<TrackingUpdate> updates;
  final Map<String, String> labels;

  const ApiTracking({
    required this.bookingId,
    required this.ref,
    required this.status,
    required this.headline,
    this.currentStage,
    required this.progress,
    this.daysLeft,
    required this.stages,
    required this.trip,
    this.companyName,
    this.companyPhone,
    this.companyWhatsapp,
    this.companyLogo,
    this.companyCity,
    this.companyContactVisible = false,
    this.hotel,
    this.bus,
    required this.needsPayment,
    this.paymentStatusLabel,
    required this.total,
    required this.paid,
    required this.currency,
    required this.personsCount,
    required this.updates,
    required this.labels,
  });

  bool get isTerminated => status == 'cancelled' || status == 'rejected';

  /// Server label for [key], or [fallback] when an older backend omits it.
  String label(String key, [String fallback = '']) => labels[key] ?? fallback;

  factory ApiTracking.fromJson(Map<String, dynamic> j) {
    final company = (j['company'] as Map<String, dynamic>?) ?? const {};
    final payment = (j['payment'] as Map<String, dynamic>?) ?? const {};
    return ApiTracking(
      bookingId: j['booking_id'] as int,
      ref: j['ref'] as String? ?? '',
      status: j['status'] as String? ?? 'pending',
      headline: j['headline'] as String? ?? '',
      currentStage: j['current_stage'] as String?,
      progress: (j['progress'] as num?)?.toInt() ?? 0,
      daysLeft: (j['days_left'] as num?)?.toInt(),
      stages: ((j['stages'] as List<dynamic>?) ?? const [])
          .map((s) => TrackingStage.fromJson(s as Map<String, dynamic>))
          .toList(),
      trip: TrackingTrip.fromJson((j['trip'] as Map<String, dynamic>?) ?? const {}),
      companyName: company['name'] as String?,
      companyPhone: company['phone'] as String?,
      companyWhatsapp: company['whatsapp'] as String?,
      companyLogo: company['logo'] as String?,
      companyCity: company['city'] as String?,
      companyContactVisible: company['contact_visible'] == true,
      hotel: j['hotel'] as Map<String, dynamic>?,
      bus: j['bus'] as Map<String, dynamic>?,
      needsPayment: payment['needs_payment'] == true,
      paymentStatusLabel: payment['status'] != null ? payment['status_label'] as String? : null,
      total: (payment['total'] as num?)?.toDouble() ?? 0,
      paid: (payment['paid'] as num?)?.toDouble() ?? 0,
      currency: payment['currency'] as String? ?? '',
      personsCount: (j['persons_count'] as num?)?.toInt() ?? 1,
      updates: ((j['updates'] as List<dynamic>?) ?? const [])
          .map((u) => TrackingUpdate.fromJson(u as Map<String, dynamic>))
          .toList(),
      labels: ((j['labels'] as Map<String, dynamic>?) ?? const {})
          .map((k, v) => MapEntry(k, '$v')),
    );
  }
}

class TrackingStage {
  final String key;
  final String state; // done | current | upcoming | skipped
  final String title;
  final String subtitle;
  final String? date;

  const TrackingStage({
    required this.key,
    required this.state,
    required this.title,
    required this.subtitle,
    this.date,
  });

  factory TrackingStage.fromJson(Map<String, dynamic> j) => TrackingStage(
        key: j['key'] as String? ?? '',
        state: j['state'] as String? ?? 'upcoming',
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        date: j['date'] as String?,
      );
}

class TrackingTrip {
  final int? id;
  final String title;
  final String? thumbnail;
  final int durationDays;
  final String? departureDate;
  final String? returnDate;
  final String? departureCity;
  final String? departureLocation;
  final String? mapUrl;

  const TrackingTrip({
    this.id,
    required this.title,
    this.thumbnail,
    required this.durationDays,
    this.departureDate,
    this.returnDate,
    this.departureCity,
    this.departureLocation,
    this.mapUrl,
  });

  factory TrackingTrip.fromJson(Map<String, dynamic> j) => TrackingTrip(
        id: j['id'] as int?,
        title: j['title'] as String? ?? '',
        thumbnail: j['thumbnail'] as String?,
        durationDays: (j['duration_days'] as num?)?.toInt() ?? 1,
        departureDate: j['departure_date'] as String?,
        returnDate: j['return_date'] as String?,
        departureCity: j['departure_city'] as String?,
        departureLocation: j['departure_location'] as String?,
        mapUrl: j['map_url'] as String?,
      );
}

class TrackingUpdate {
  final int id;
  final String type;
  final String title;
  final String? body;
  final String? timeAgo;

  const TrackingUpdate({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.timeAgo,
  });

  factory TrackingUpdate.fromJson(Map<String, dynamic> j) => TrackingUpdate(
        id: j['id'] as int,
        type: j['type'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String?,
        timeAgo: j['time_ago'] as String?,
      );
}
