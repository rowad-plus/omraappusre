import 'order.dart';

/// A booking as returned by the real Front API (`/bookings`, `/bookings/{id}`).
/// [toOrder] adapts it into the display-only [Order] model the existing
/// orders screens already know how to render — mirrors how [ApiTrip.toTrip]
/// bridges the trips API into the [Trip] model.
class ApiBooking {
  final int id;
  final String ref;
  final String status; // pending | confirmed | cancelled
  final int tripId;
  final String tripTitle;
  final String providerName;
  final String? thumbnail;
  final int personsCount;
  final double totalPrice;
  final String currency;
  final String? createdAt;

  // Detail-only fields (null when built from the list endpoint).
  final String? nationalId;
  final String? notes;
  final String? departureCity;
  final int? durationDays;
  final String? departureDate;
  final ApiBookingHotel? hotel;
  final String? roomNumber;
  final int? roomCapacity;
  final List<String>? roommates;
  final ApiBookingBus? bus;
  final String? attendanceStatus;
  final String? paymentOption; // full | commission | unconfirmed
  final String? paymentStatus; // unpaid | pending | captured | failed
  final double? commissionAmount;
  final List<ApiBookingTraveler>? travelers;

  const ApiBooking({
    required this.id,
    required this.ref,
    required this.status,
    required this.tripId,
    required this.tripTitle,
    required this.providerName,
    this.thumbnail,
    required this.personsCount,
    required this.totalPrice,
    required this.currency,
    this.createdAt,
    this.nationalId,
    this.notes,
    this.departureCity,
    this.durationDays,
    this.departureDate,
    this.hotel,
    this.roomNumber,
    this.roomCapacity,
    this.roommates,
    this.bus,
    this.attendanceStatus,
    this.paymentOption,
    this.paymentStatus,
    this.commissionAmount,
    this.travelers,
  });

  factory ApiBooking.fromJson(Map<String, dynamic> j) => ApiBooking(
        id: j['id'] as int,
        ref: j['ref'] as String? ?? '',
        status: j['status'] as String? ?? 'pending',
        tripId: j['trip_id'] as int,
        tripTitle: j['trip_title'] as String? ?? '',
        providerName: j['provider_name'] as String? ?? '',
        thumbnail: j['thumbnail'] as String?,
        personsCount: j['persons_count'] as int? ?? 1,
        totalPrice: (j['total_price'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? '',
        createdAt: j['created_at'] as String?,
        nationalId: j['national_id'] as String?,
        notes: j['notes'] as String?,
        departureCity: j['departure_city'] as String?,
        durationDays: j['duration_days'] as int?,
        departureDate: j['departure_date'] as String?,
        hotel: j['hotel'] != null ? ApiBookingHotel.fromJson(j['hotel'] as Map<String, dynamic>) : null,
        roomNumber: j['room_number'] as String?,
        roomCapacity: j['room_capacity'] as int?,
        roommates: (j['roommates'] as List<dynamic>?)?.cast<String>(),
        bus: j['bus'] != null ? ApiBookingBus.fromJson(j['bus'] as Map<String, dynamic>) : null,
        attendanceStatus: j['attendance_status'] as String?,
        paymentOption: j['payment_option'] as String?,
        paymentStatus: j['payment_status'] as String?,
        commissionAmount: (j['commission_amount'] as num?)?.toDouble(),
        travelers: (j['travelers'] as List<dynamic>?)
            ?.map((t) => ApiBookingTraveler.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  /// True once the trip's departure date has passed for a confirmed
  /// booking — the backend only tracks pending/confirmed/cancelled, so
  /// "completed" (mirrors the app's own third order tab) is derived here.
  bool get _isPast {
    final d = departureDate;
    if (d == null) return false;
    final parsed = DateTime.tryParse(d);
    // Compare calendar days: a trip departing today is still current
    // ("2026-10-07" parses to midnight, which is already before "now").
    final now = DateTime.now();
    return parsed != null &&
        parsed.isBefore(DateTime(now.year, now.month, now.day));
  }

  OrderStatus get _orderStatus {
    if (status == 'cancelled') return OrderStatus.cancelled;
    if (status == 'confirmed') return _isPast ? OrderStatus.completed : OrderStatus.confirmed;
    return OrderStatus.pending;
  }

  Order toOrder() {
    final unitPrice = personsCount > 0 ? (totalPrice / personsCount) : totalPrice;
    return Order(
      apiId: id,
      tripId: tripId,
      bookingDate: createdAt,
      departureDate: departureDate,
      personsCount: personsCount,
      id: ref,
      trip: tripTitle,
      emoji: '🕋',
      networkImage: thumbnail,
      provider: providerName,
      date: departureDate ?? createdAt ?? '',
      duration: durationDays != null ? '$durationDays' : '',
      pax: '$personsCount',
      departureCity: departureCity ?? 'city.cairo',
      status: _orderStatus,
      statusText: 'orders.status.$status',
      bus: bus?.toOrderBusInfo(),
      hotel: hotel?.toOrderHotelInfo(roomNumber, roomCapacity, roommates) ??
          OrderHotelInfo(
            name: 'orders.not_assigned_yet',
            stars: '',
            location: 'orders.not_assigned_yet',
            room: 'orders.not_assigned_yet',
            roomType: 'orders.not_assigned_yet',
          ),
      hotelAssigned: hotel != null,
      roomAssigned: roomNumber != null,
      priceUnit: '${unitPrice.toStringAsFixed(0)} $currency',
      total: '${totalPrice.toStringAsFixed(0)} $currency',
      action: 'orders.action.view_details',
      paymentStatus: paymentStatus,
      paymentOption: paymentOption,
    );
  }
}

class ApiBookingHotel {
  final String name;
  final int? stars;
  final String? location;
  const ApiBookingHotel({required this.name, this.stars, this.location});

  factory ApiBookingHotel.fromJson(Map<String, dynamic> j) => ApiBookingHotel(
        name: j['name'] as String? ?? '',
        stars: j['stars'] as int?,
        location: j['location'] as String?,
      );

  OrderHotelInfo toOrderHotelInfo(String? roomNumber, int? roomCapacity, List<String>? roommates) {
    final starCount = stars?.clamp(0, 5) ?? 0;
    return OrderHotelInfo(
      name: name,
      stars: '★' * starCount + '☆' * (5 - starCount),
      location: location ?? '',
      room: roomNumber ?? 'orders.not_assigned_yet',
      roomType: roomCapacity != null ? '$roomCapacity' : 'orders.not_assigned_yet',
      roommates: roommates ?? const [],
    );
  }
}

class ApiBookingBus {
  final String number;
  final int? capacity;
  final String? driverName;
  final String? driverPhone;
  const ApiBookingBus({required this.number, this.capacity, this.driverName, this.driverPhone});

  factory ApiBookingBus.fromJson(Map<String, dynamic> j) => ApiBookingBus(
        number: j['number'] as String? ?? '',
        capacity: j['capacity'] as int?,
        driverName: j['driver_name'] as String?,
        driverPhone: j['driver_phone'] as String?,
      );

  OrderBusInfo toOrderBusInfo() => OrderBusInfo(
        num: number,
        cap: capacity != null ? '$capacity' : '',
        supervisor: driverName ?? 'orders.not_assigned_yet',
        phone: driverPhone ?? '',
      );
}

/// One pilgrim's identity document, entered per-person during booking and
/// echoed back in booking detail responses.
class ApiBookingTraveler {
  final String name;
  final String documentType; // national_id | iqama | passport
  final String documentNumber;

  const ApiBookingTraveler({
    required this.name,
    required this.documentType,
    required this.documentNumber,
  });

  factory ApiBookingTraveler.fromJson(Map<String, dynamic> j) => ApiBookingTraveler(
        name: j['name'] as String? ?? '',
        documentType: j['document_type'] as String? ?? '',
        documentNumber: j['document_number'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'document_type': documentType,
        'document_number': documentNumber,
      };
}

/// Preview of a trip's payment plan for a given persons_count + country —
/// fetched via GET /umrah-trips/{id}/booking-quote before the booking is
/// actually submitted, so the booking wizard can show the customer the
/// right step (full payment / commission / unconfirmed) ahead of time. The
/// server derives [paymentOption] itself from the country's admin-configured
/// booking mode — the app only displays it, never chooses it.
class BookingQuote {
  final double totalPrice;
  final String currency;
  final String paymentOption; // full | commission | unconfirmed
  final double? commissionAmount;
  /// Whether the trip has a family (private-room) price for this group size.
  final bool privateRoomAvailable;
  /// Amount the customer must pay now to confirm (full total, deposit, or 0).
  final double? amountDueNow;

  const BookingQuote({
    required this.totalPrice,
    required this.currency,
    required this.paymentOption,
    this.commissionAmount,
    this.privateRoomAvailable = false,
    this.amountDueNow,
  });

  factory BookingQuote.fromJson(Map<String, dynamic> j) => BookingQuote(
        totalPrice: (j['total_price'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? '',
        paymentOption: j['payment_option'] as String? ?? 'unconfirmed',
        commissionAmount: double.tryParse('${j['commission_amount']}'),
        privateRoomAvailable: j['private_room_available'] == true,
        amountDueNow: double.tryParse('${j['amount_due_now']}'),
      );
}
