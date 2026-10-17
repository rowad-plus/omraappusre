/// Stages of a "صمّم عمرتك" design request, in order — the admin moves it
/// along from Admin → طلبات صمّم عمرتك (server `status`).
enum DesignRequestStage { received, reviewed, completed, cancelled }

/// A submitted "صمّم عمرتك" wizard request, from
/// `GET /design-umrah/mine` — the wizard's inputs plus the admin-set status.
/// Not a confirmed booking (no bus/hotel assignment, no supervisor contact).
/// Option values are stored as the wizard's labels, so they're shown via
/// `tr()` (which falls back to the raw label).
class UmrahDesignRequest {
  final int apiId;
  final String ref;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DesignRequestStage stage;
  final String startPoint;
  final int adults;
  final int children;
  final int infants;
  final int makkaDays;
  final int madinaDays;
  final String hotelStarsMakkah;
  final String hotelStarsMadinah;
  final String roomType;
  final List<String> hotelPrefs;
  final List<String> transport;
  final String departureCountry;
  final String departureCity;
  final String flightType;
  final String flightClass;
  final String? travelDate;
  final List<String> extras;
  final String name;
  final String phone;
  final String email;
  final String notes;

  const UmrahDesignRequest({
    required this.apiId,
    required this.ref,
    this.createdAt,
    this.updatedAt,
    required this.stage,
    required this.startPoint,
    required this.adults,
    this.children = 0,
    this.infants = 0,
    required this.makkaDays,
    required this.madinaDays,
    this.hotelStarsMakkah = '',
    this.hotelStarsMadinah = '',
    this.roomType = '',
    this.hotelPrefs = const [],
    this.transport = const [],
    this.departureCountry = '',
    this.departureCity = '',
    this.flightType = '',
    this.flightClass = '',
    this.travelDate,
    this.extras = const [],
    required this.name,
    required this.phone,
    this.email = '',
    this.notes = '',
  });

  static DesignRequestStage _stage(String? s) => switch (s) {
        'reviewed' => DesignRequestStage.reviewed,
        'completed' => DesignRequestStage.completed,
        'cancelled' => DesignRequestStage.cancelled,
        _ => DesignRequestStage.received,
      };

  factory UmrahDesignRequest.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] as String?) ?? '';
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    List<String> l(String k) =>
        [for (final v in (j[k] as List<dynamic>? ?? const [])) '$v'];
    return UmrahDesignRequest(
      apiId: n('id'),
      ref: s('ref'),
      createdAt: DateTime.tryParse(s('created_at'))?.toLocal(),
      updatedAt: DateTime.tryParse(s('updated_at'))?.toLocal(),
      stage: _stage(j['status'] as String?),
      startPoint: s('start_city'),
      adults: n('adults'),
      children: n('children'),
      infants: n('infants'),
      makkaDays: n('days_in_makkah'),
      madinaDays: n('days_in_madinah'),
      hotelStarsMakkah: s('hotel_stars_makkah'),
      hotelStarsMadinah: s('hotel_stars_madinah'),
      roomType: s('room_type'),
      hotelPrefs: l('hotel_prefs'),
      transport: l('transport'),
      departureCountry: s('departure_country'),
      departureCity: s('departure_city'),
      flightType: s('flight_type'),
      flightClass: s('flight_class'),
      travelDate: j['travel_date'] as String?,
      extras: l('extras'),
      name: s('contact_name'),
      phone: s('contact_phone'),
      email: s('contact_email'),
      notes: s('special_requests'),
    );
  }
}
