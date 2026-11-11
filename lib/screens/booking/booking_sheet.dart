import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/api_trip.dart';
import '../../models/trip.dart';
import '../../state/app_state.dart';
import '../../state/country_state.dart';
import '../../state/locale_state.dart';
import '../../utils/western_digits_formatter.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/country_picker_sheet.dart';
import '../../services/payment_launcher.dart';
import '../auth/login_sheet.dart';
import 'trip_tracking_screen.dart';
import '../../widgets/instant_date_picker.dart';
import '../../widgets/trip_media_grid.dart';

const _monthShort = [
  '',
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// Mirrors the website's own `/trip/{type}/{id}/book` page exactly: one
/// single scrollable form (personal info, persons count, traveler
/// documents, departure date, notes, one submit button) — not a multi-step
/// wizard. The website itself never shows the customer's derived payment
/// plan (full/commission/unconfirmed) before they submit either — that's
/// resolved entirely server-side at booking-creation time — so this form
/// doesn't preview it, matching that exactly.
class BookingSheet extends StatefulWidget {
  final Trip trip;

  /// A date already picked on the search page (`Y-m-d`) — mirrors the
  /// website carrying its date-strip search's `?date=` into the booking
  /// form. Pre-selects that date once the trip's real bookable dates load,
  /// same as the site does, instead of making the customer pick it again.
  final String? initialDate;
  const BookingSheet({super.key, required this.trip, this.initialDate});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  /// A departure date is required for every trip — mirrors the website's
  /// `Departure Date *` field exactly (see `HasTripHelpers`/`BookingController`
  /// on the backend).
  bool _datesLoading = true;
  List<ApiTripDate> _dates = [];
  bool _datesAreComputed = false;
  bool get _needsDateChoice => _dates.length > 1;

  int _adults = 1;
  int _children = 0;
  ApiTripDate? _selectedDate;
  final _notesCtrl = TextEditingController();
  // 2026-11-12: name + WhatsApp at booking (required); travelers' names and
  // documents are entered after payment on the tracking screen.
  final _nameCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  List<String> _images = const [];
  List<String> _videos = const [];
  bool _submitting = false;
  String? _error;

  /// Private room (2+ persons only): the server prices it at the trip's
  /// family price for that group size. Default is a shared room, priced at
  /// the per-person price × persons.
  bool _privateRoom = false;
  double? _privateRoomTotal; // server quote while _privateRoom is on
  bool _quoteLoading = false;
  int _quoteSeq = 0;

  /// Extra rooms: the company's flat price per extra room (null = the trip
  /// doesn't offer it). The base price covers one room → at most persons−1.
  double? _extraRoomPrice;
  int _extraRooms = 0;
  int get _maxExtraRooms => _personsCount > 1 ? _personsCount - 1 : 0;
  double get _extraRoomsCost =>
      (_extraRoomPrice ?? 0) > 0 ? _extraRooms * _extraRoomPrice! : 0;

  /// "الدفع عند الباص" — only when the admin enabled it for this trip's
  /// company (same rule as the website's booking form).
  bool _payAtBusAvailable = false;
  bool _payAtBus = false;

  /// Site WhatsApp number (the server sends it back with the booking).
  static const _waNumber = '966552920858';

  int get _personsCount => _adults + (_showChildren ? _children : 0);

  /// Children counter only outside Saudi Arabia.
  bool get _showChildren =>
      CountryState.selected.value?.code.toUpperCase() != 'SA';
  bool get _privateRoomApplies => _privateRoom && _personsCount > 1;

  void _onPersonsChanged() {
    if (_personsCount < 2) _privateRoom = false;
    if (_extraRooms > _maxExtraRooms) _extraRooms = _maxExtraRooms;
    // Called from inside a setState callback — defer the quote refresh
    // (which calls setState itself) until after this frame's update.
    Future.microtask(_refreshPrivateRoomQuote);
  }

  /// Asks the server for the authoritative private-room total so the app
  /// always shows exactly what the booking will be charged.
  Future<void> _refreshPrivateRoomQuote() async {
    final tripId = widget.trip.apiId;
    if (!_privateRoomApplies || tripId == null) {
      setState(() {
        _privateRoomTotal = null;
        _quoteLoading = false;
      });
      return;
    }
    final seq = ++_quoteSeq;
    setState(() => _quoteLoading = true);
    final quote = await context.read<AppState>().getBookingQuote(
          tripId: tripId,
          personsCount: _personsCount,
          countryCode: CountryState.selected.value?.code ?? 'SA',
          privateRoom: true,
        );
    if (!mounted || seq != _quoteSeq) return;
    setState(() {
      _quoteLoading = false;
      _privateRoomTotal = quote?.totalPrice;
    });
  }

  @override
  void initState() {
    super.initState();
    _prefillContact();
    _loadDates();
  }

  /// Always fetches the trip's bookable dates itself (rather than relying
  /// on whatever a given entry point happened to already have loaded) so
  /// every path into this screen — trip detail, company profile, trip
  /// list, the umrah tab — behaves identically, matching the website where
  /// the booking page is the single source of truth for date requirements.
  Future<void> _loadDates() async {
    final tripId = widget.trip.apiId;
    if (tripId == null) {
      setState(() => _datesLoading = false);
      return;
    }
    if (!_datesLoading) setState(() => _datesLoading = true);
    final state = context.read<AppState>();
    // One silent retry — a dropped request on mobile data shouldn't leave
    // the customer without dates.
    var detail = await state.fetchTripDetail(tripId);
    detail ??= await state.fetchTripDetail(tripId);
    if (!mounted) return;
    setState(() {
      _dates = detail?.dates ?? [];
      // Dates couldn't load, but the customer already picked one on the
      // search page: keep that date (the booking API accepts a raw Y-m-d).
      if (_dates.isEmpty && widget.initialDate != null) {
        _dates = [
          ApiTripDate(
              id: widget.initialDate!, departureDate: widget.initialDate!)
        ];
      }
      _datesAreComputed = detail?.datesAreComputed ?? false;
      _extraRoomPrice =
          (detail?.extraRoomPrice ?? 0) > 0 ? detail!.extraRoomPrice : null;
      _payAtBusAvailable = detail?.payAtBus ?? false;
      _images = (detail?.images ?? const <String>[])
          .where((u) => u.isNotEmpty)
          .toList();
      _videos = detail?.videos ?? const [];
      if (!_payAtBusAvailable) _payAtBus = false;
      _datesLoading = false;
      if (_dates.length == 1) {
        _selectedDate = _dates.first;
      } else if (widget.initialDate != null) {
        for (final d in _dates) {
          if (d.departureDate == widget.initialDate) {
            _selectedDate = d;
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _nameCtrl.dispose();
    _waCtrl.dispose();
    super.dispose();
  }

  /// Name + WhatsApp start from the account (editable). An account whose
  /// "name" is just its phone number starts with an empty name.
  void _prefillContact() {
    final app = context.read<AppState>();
    final phone = (app.userPhone ?? '').trim();
    var name = app.userName.trim();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty && name.replaceAll(RegExp(r'\D'), '') == digits) {
      name = '';
    }
    if (_nameCtrl.text.isEmpty) _nameCtrl.text = name;
    if (_waCtrl.text.isEmpty) _waCtrl.text = phone;
  }

  bool get _contactValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _waCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 8;

  Future<void> _submit({bool viaWhatsapp = false}) async {
    if (_submitting) return;

    if (_datesLoading) return;
    if (_dates.isEmpty) {
      showAppToast(context, '⚠️ ${tr('booking.dateRoom.loadError')}');
      return;
    }
    if (_needsDateChoice && _selectedDate == null) {
      showAppToast(context, '⚠️ ${tr('booking.validation.selectDate')}');
      return;
    }
    if (!_contactValid) {
      final isAr = LocaleState.locale.value.languageCode == 'ar';
      final msg = _nameCtrl.text.trim().isEmpty
          ? (isAr ? 'يرجى كتابة الاسم' : 'Please enter your name')
          : (isAr ? 'يرجى كتابة رقم الواتساب' : 'Please enter your WhatsApp number');
      showAppToast(context, '⚠️ $msg');
      return;
    }

    var country = CountryState.selected.value;
    if (country == null) {
      await openCountryPickerSheet(context);
      if (!mounted) return;
      country = CountryState.selected.value;
      if (country == null) return;
    }

    final tripId = widget.trip.apiId;
    if (tripId == null) return;

    // Guests log in from here and the booking continues with the same form.
    if (!context.read<AppState>().isLoggedIn) {
      setState(() => _error = null);
      await openLoginSheet(context);
      if (!mounted || !context.read<AppState>().isLoggedIn) return;
      _prefillContact();
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await context.read<AppState>().createBooking(
          tripId: tripId,
          personsCount: _personsCount,
          countryCode: country.code,
          contactName: _nameCtrl.text.trim(),
          contactPhone: _waCtrl.text.trim(),
          tripDateId: _selectedDate?.id ?? '',
          notes: _notesCtrl.text.trim(),
          privateRoom: _privateRoomApplies,
          extraRooms: _extraRoomPrice != null ? _extraRooms : 0,
          payAtBus: _payAtBusAvailable && _payAtBus,
          viaWhatsapp: viaWhatsapp,
        );
    if (!mounted) return;
    if (result.unauthorized) {
      setState(() => _submitting = false);
      await openLoginSheet(context);
      if (mounted && context.read<AppState>().isLoggedIn) {
        await _submit(viaWhatsapp: viaWhatsapp);
      }
      return;
    }
    if (result.error != null) {
      setState(() {
        _submitting = false;
        _error = result.error;
      });
      return;
    }

    // Only 'full'/'commission' bookings carry a real NeoLeap card charge —
    // 'unconfirmed' (no online payment configured for this country) just
    // stays a plain booking request, same as before this payment flow existed.
    final bookingId = result.bookingId;

    // WhatsApp booking: saved as a real booking (no gateway) — open the
    // chat with every detail, then land on tracking like the website does.
    if (viaWhatsapp) {
      final opened = await _openWhatsApp(result);
      if (!mounted) return;
      setState(() => _submitting = false);
      if (!opened) {
        showAppToast(context, '⚠️ ${tr('booking.whatsapp.openError')}');
      }
      if (bookingId != null) {
        _openTracking(bookingId);
      } else {
        Navigator.of(context).pop();
      }
      return;
    }

    final payable =
        result.paymentOption == 'full' || result.paymentOption == 'commission';

    if (bookingId != null && payable) {
      await _startPayment(bookingId);
      return;
    }

    setState(() => _submitting = false);
    if (bookingId != null) {
      _openTracking(bookingId);
    } else {
      Navigator.of(context).pop();
      showAppToast(context, '✅ ${tr('booking.success.requestSent')}');
    }
  }

  /// Same message as the website's WhatsApp button (booking.blade.php).
  String _whatsAppMessage(BookingCreateResult result) {
    final isAr = LocaleState.locale.value.languageCode == 'ar';
    final app = context.read<AppState>();
    final d = _selectedDate != null
        ? DateTime.tryParse(_selectedDate!.departureDate)
        : null;
    final dateText = d != null
        ? '${d.day} ${_monthShort[d.month]} ${d.year}'
        : (_selectedDate?.departureDate ?? '');
    final lines = <String>[
      '🕋 ${isAr ? 'طلب حجز عمرة' : 'Umrah booking request'}${result.ref != null ? ' — ${result.ref}' : ''}',
      '${isAr ? 'الرحلة: ' : 'Trip: '}${widget.trip.title}',
      '${isAr ? 'تاريخ الانطلاق: ' : 'Departure: '}$dateText',
    ];
    var p = '${isAr ? 'عدد الأفراد: ' : 'Persons: '}$_personsCount';
    if (_privateRoomApplies) p += isAr ? ' (غرفة خاصة)' : ' (private room)';
    if (_extraRoomPrice != null && _extraRooms > 0) {
      p += isAr
          ? ' + $_extraRooms غرفة إضافية'
          : ' + $_extraRooms extra room(s)';
    }
    lines.add(p);
    final customer = [
      _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : app.userName,
      _waCtrl.text.trim().isNotEmpty ? _waCtrl.text.trim() : (app.userPhone ?? '')
    ]
        .where((v) => v.trim().isNotEmpty)
        .join(' — ');
    if (customer.isNotEmpty) {
      lines.add('${isAr ? 'العميل: ' : 'Customer: '}$customer');
    }
    if (_payAtBusAvailable && _payAtBus) {
      lines.add(
          '${isAr ? 'طريقة الدفع: ' : 'Payment: '}${isAr ? 'الدفع عند الباص' : 'Pay at the bus'}');
    }
    final total = _totalText();
    if (total.isNotEmpty) lines.add('${isAr ? 'الإجمالي: ' : 'Total: '}$total');
    final notes = _notesCtrl.text.trim();
    if (notes.isNotEmpty) lines.add('${isAr ? 'ملاحظات: ' : 'Notes: '}$notes');
    if (result.tripUrl != null) lines.add(result.tripUrl!);
    return lines.join('\n');
  }

  Future<bool> _openWhatsApp(BookingCreateResult result) async {
    final number =
        (result.whatsappNumber ?? _waNumber).replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
        'https://wa.me/$number?text=${Uri.encodeComponent(_whatsAppMessage(result))}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Every successful booking lands on "تتبع الرحلة" — replacing this form,
  /// so back from tracking returns to the trip, not to a spent form.
  void _openTracking(int bookingId, {bool paid = false}) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => TripTrackingScreen(
          bookingId: bookingId, justBooked: true, justPaid: paid),
    ));
  }

  /// Starts payment for [bookingId] via `launchPayment` (Paymob native SDK,
  /// WebView fallback). The booking itself
  /// already exists as 'pending' regardless of the outcome here — a
  /// failed/cancelled payment does not lose the booking request, it just
  /// leaves it unpaid (matching how `PaymentController::initiate` is safe
  /// to retry for the same booking).
  Future<void> _startPayment(int bookingId) async {
    final paymentResult =
        await context.read<AppState>().initiatePayment(bookingId);
    if (!mounted) return;

    if (paymentResult.paymentUrl == null) {
      setState(() => _submitting = false);
      showAppToast(context,
          '⚠️ ${paymentResult.error ?? tr('booking.payment.startError')}');
      // The booking exists (unpaid) — tracking shows its "ادفع الآن" step.
      _openTracking(bookingId);
      return;
    }

    setState(() => _submitting = false);
    final paid = await launchPayment(context, paymentResult.paymentUrl!,
        bookingId: bookingId);
    if (!mounted) return;

    if (paid == true) {
      showAppToast(context, '✅ ${tr('booking.payment.success')}');
    } else if (paid == false) {
      showAppToast(context, '⚠️ ${tr('booking.payment.failed')}');
    }
    _openTracking(bookingId, paid: paid == true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(tr('booking.step.confirm'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
      // The confirm button sits in the body (not bottomNavigationBar) so it
      // rides up above the keyboard instead of being hidden under it — on
      // iOS the number pad has no "done" key, so it was impossible to reach.
      // Tapping outside a field or dragging the form also closes the keyboard.
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionCard(
                      icon: FontAwesomeIcons.solidUser,
                      title: tr('booking.personal.title'),
                      child: _personalInfoRows(app),
                    ),
                    const SizedBox(height: 14),
                    _sectionCard(
                      icon: FontAwesomeIcons.users,
                      title: tr('booking.step.travelers'),
                      child: Column(children: [
                        // Inside Saudi Arabia there is no children split (same as
                        // the website): one "number of people" counter only.
                        _counterRow(
                            _showChildren
                                ? tr('booking.travelers.adultsLabel')
                                : tr('orders.field.people_count'),
                            _showChildren
                                ? tr('booking.travelers.adultsHint')
                                : '',
                            _adults,
                            (v) => setState(() {
                                  _adults = v;
                                  _onPersonsChanged();
                                }),
                            min: 1),
                        if (_showChildren)
                          _counterRow(
                              tr('booking.travelers.childrenLabel'),
                              tr('booking.travelers.childrenHint'),
                              _children,
                              (v) => setState(() {
                                    _children = v;
                                    _onPersonsChanged();
                                  })),
                        if (_personsCount > 1) _privateRoomRow(),
                        if (_personsCount > 1 && _extraRoomPrice != null)
                          _counterRow(
                              tr('booking.travelers.extraRoomsLabel'),
                              '${tr('booking.travelers.extraRoomsHint')} +${NumberFormat('#,##0', 'en').format(_extraRoomPrice)}',
                              _extraRooms,
                              (v) => setState(() =>
                                  _extraRooms = v.clamp(0, _maxExtraRooms))),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    _sectionCard(
                      icon: FontAwesomeIcons.calendarDays,
                      title: tr('booking.dateRoom.departureDateLabel'),
                      child: _dateSection(),
                    ),
                    if (_payAtBusAvailable) ...[
                      const SizedBox(height: 14),
                      _sectionCard(
                        icon: FontAwesomeIcons.wallet,
                        title: tr('booking.payMethod.title'),
                        child: _payMethodSection(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _sectionCard(
                      icon: FontAwesomeIcons.noteSticky,
                      title: tr('booking.contact.notesLabel'),
                      child: _textField(
                          _notesCtrl, tr('booking.contact.notesHint'),
                          maxLines: 3),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E4),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFFE84040), fontSize: 12.5)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _priceSummaryCard(),
                    // 2026-11-12: trip photos + videos as squares at the very bottom.
                    if (_images.isNotEmpty || _videos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _sectionCard(
                        icon: FontAwesomeIcons.images,
                        title: LocaleState.locale.value.languageCode == 'ar'
                            ? 'صور وفيديو الرحلة'
                            : 'Trip photos & videos',
                        child: TripMediaGrid(images: _images, videos: _videos),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _confirmBar(),
        ]),
      ),
    );
  }

  Widget _confirmBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _submitting ? null : () => _submit(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                // Same height as the WhatsApp button beside it.
                minimumSize: const Size.fromHeight(54),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(FontAwesomeIcons.check,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(tr('booking.step.confirm'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // "احجز عبر واتساب": small button beside confirm — saves the booking
          // (no online payment) and opens WhatsApp with its details.
          Tooltip(
            message: tr('booking.whatsapp.button'),
            child: SizedBox(
              width: 54,
              height: 54,
              child: ElevatedButton(
                onPressed:
                    _submitting ? null : () => _submit(viaWhatsapp: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.whatsapp,
                  disabledBackgroundColor:
                      AppColors.whatsapp.withValues(alpha: 0.5),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const FaIcon(FontAwesomeIcons.whatsapp,
                    size: 26, color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionCard(
      {required FaIconData icon,
      required String title,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          FaIcon(icon, size: 15, color: AppColors.blue),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  /// Name + WhatsApp number (both required) — same as the website's
  /// booking form. Travelers' names/documents come later, on tracking.
  Widget _personalInfoRows(AppState app) {
    final isAr = LocaleState.locale.value.languageCode == 'ar';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _fieldLabel('${isAr ? 'الاسم' : 'Full name'} *'),
      const SizedBox(height: 6),
      _textField(_nameCtrl, isAr ? 'اكتب اسمك' : 'Your name'),
      const SizedBox(height: 10),
      _fieldLabel('${isAr ? 'رقم الواتساب' : 'WhatsApp number'} *'),
      const SizedBox(height: 6),
      _textField(_waCtrl, '+966 5X XXX XXXX',
          keyboardType: TextInputType.phone,
          formatters: [WesternDigitsFormatter()],
          ltr: true),
      const SizedBox(height: 8),
      Text(
          isAr
              ? 'بيانات المعتمرين (الأسماء والهويات) تُدخلها بعد الدفع من شاشة تتبع الرحلة.'
              : "Travelers' names and IDs are entered after payment, on the trip tracking screen.",
          style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.brand,
              fontWeight: FontWeight.w600,
              height: 1.5)),
    ]);
  }

  Widget _dateSection() {
    if (_datesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }
    if (_dates.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('booking.dateRoom.loadError'),
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _loadDates,
          icon: const Icon(Icons.refresh, size: 16, color: AppColors.brand),
          label: Text(tr('booking.payment.retryButton'),
              style: const TextStyle(
                  color: AppColors.brand, fontWeight: FontWeight.w700)),
        ),
      ]);
    }
    if (!_needsDateChoice) {
      // A single possible date — same as the website's `isSingleFixedDate`
      // hidden-input case: shown, not chosen.
      return _dateOption(_dates.first, interactive: false);
    }
    // 'daily'/'recurring' trips can have dozens/hundreds of valid candidate
    // dates (see `ApiTrip.datesAreComputed`) — same as the website, that's
    // a calendar picker constrained to the valid set, not a flat
    // scrollable list of every option.
    if (_datesAreComputed) return _computedDatePicker();
    return Column(children: [for (final d in _dates) _dateOption(d)]);
  }

  Widget _computedDatePicker() {
    final validDates = _dates
        .map((d) => DateTime.tryParse(d.departureDate))
        .whereType<DateTime>()
        .toSet();
    final selected = _selectedDate != null
        ? DateTime.tryParse(_selectedDate!.departureDate)
        : null;
    final label = selected != null
        ? '${selected.day} ${_monthShort[selected.month]} ${selected.year}'
        : tr('booking.dateRoom.chooseDate');
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showInstantDatePicker(
          context: context,
          title: tr('booking.dateRoom.chooseDate'),
          initialDate: selected ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: validDates.isEmpty
              ? now
              : validDates.reduce((a, b) => a.isAfter(b) ? a : b),
          selectableDayPredicate: (day) => validDates.any((d) =>
              d.year == day.year && d.month == day.month && d.day == day.day),
        );
        if (picked == null) return;
        final iso =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        setState(
            () => _selectedDate = ApiTripDate(id: iso, departureDate: iso));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
            border: Border.all(
                color: selected != null ? AppColors.blue : AppColors.border,
                width: selected != null ? 2 : 1.5),
            borderRadius: BorderRadius.circular(10),
            color: selected != null ? AppColors.blueLight : Colors.white),
        child: Row(children: [
          const FaIcon(FontAwesomeIcons.calendarDays,
              size: 16, color: AppColors.blue),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
        ]),
      ),
    );
  }

  Widget _dateOption(ApiTripDate d, {bool interactive = true}) {
    final date = DateTime.tryParse(d.departureDate);
    final label = date != null
        ? '${date.day} ${_monthShort[date.month]} ${date.year}'
        : d.departureDate;
    final selected = interactive ? _selectedDate?.id == d.id : true;
    return GestureDetector(
      onTap: interactive
          ? () => setState(() => _selectedDate = selected ? null : d)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            border: Border.all(
                color: selected ? AppColors.blue : AppColors.border,
                width: selected ? 2 : 1.5),
            borderRadius: BorderRadius.circular(10),
            color: selected ? AppColors.blueLight : Colors.white),
        child: Row(children: [
          FaIcon(
              selected
                  ? FontAwesomeIcons.solidCircleCheck
                  : FontAwesomeIcons.circle,
              size: 16,
              color: selected ? AppColors.blue : AppColors.border),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
        ]),
      ),
    );
  }

  /// Private-room toggle — shown only for 2+ persons, same as the website.
  Widget _privateRoomRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: () {
          setState(() => _privateRoom = !_privateRoom);
          _refreshPrivateRoomQuote();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
              color: _privateRoom ? AppColors.blueLight : Colors.white,
              border: Border.all(
                  color: _privateRoom ? AppColors.blue : AppColors.border,
                  width: 1.5),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Checkbox(
              value: _privateRoom,
              activeColor: AppColors.blue,
              onChanged: (v) {
                setState(() => _privateRoom = v ?? false);
                _refreshPrivateRoomQuote();
              },
            ),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('booking.travelers.privateRoomLabel'),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    Text(tr('booking.travelers.privateRoomHint'),
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.muted)),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// The summary card's total as text ("" while the private quote loads).
  String _totalText() {
    final unitPrice =
        double.tryParse(widget.trip.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
    final currency =
        widget.trip.price.replaceAll(RegExp(r'[0-9.,]'), '').trim();
    if (_privateRoomApplies && _privateRoomTotal == null) return '';
    final total =
        (_privateRoomApplies ? _privateRoomTotal! : unitPrice * _personsCount) +
            _extraRoomsCost;
    if (total <= 0) return '';
    return '${NumberFormat('#,##0', 'en').format(total)} $currency';
  }

  /// "ادفع الآن / ادفع عند الباص" — same two options as the website.
  Widget _payMethodSection() {
    Widget option(bool onBus, FaIconData icon, String title, String hint) {
      final selected = _payAtBus == onBus;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => setState(() => _payAtBus = onBus),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
                color: selected ? AppColors.blueLight : Colors.white,
                border: Border.all(
                    color: selected ? AppColors.blue : AppColors.border,
                    width: selected ? 2 : 1.5),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color: selected ? AppColors.blue : AppColors.muted),
              const SizedBox(width: 8),
              FaIcon(icon, size: 15, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                      Text(hint,
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.muted)),
                    ]),
              ),
            ]),
          ),
        ),
      );
    }

    return Column(children: [
      option(false, FontAwesomeIcons.creditCard, tr('booking.payMethod.now'),
          tr('booking.payMethod.nowHint')),
      option(true, FontAwesomeIcons.bus, tr('booking.payMethod.onBus'),
          tr('booking.payMethod.onBusHint')),
    ]);
  }

  /// Shared room (default): per-person price × persons — computed locally,
  /// same rule as the server. Private room: the server's quoted family price.
  Widget _priceSummaryCard() {
    final unitPrice =
        double.tryParse(widget.trip.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
    // Keep the spaces inside the currency name ("ريال سعودي", "Saudi Riyal (SAR)").
    final currency =
        widget.trip.price.replaceAll(RegExp(r'[0-9.,]'), '').trim();
    final usePrivate = _privateRoomApplies && _privateRoomTotal != null;
    final total =
        (usePrivate ? _privateRoomTotal! : unitPrice * _personsCount) +
            _extraRoomsCost;
    var label = usePrivate
        ? '${tr('booking.summary.privateRoomPrice')} ($_personsCount)'
        : '${tr('booking.summary.price')} (×$_personsCount)';
    if (_extraRoomsCost > 0) {
      label += ' + ${tr('booking.summary.extraRooms')} ×$_extraRooms';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.blueLight, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
        ),
        if (_privateRoomApplies && _quoteLoading)
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.blue))
        else
          Text('${NumberFormat('#,##0', 'en').format(total)} $currency',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.blue)),
      ]),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted));

  Widget _textField(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType,
      int maxLines = 1,
      List<TextInputFormatter>? formatters,
      bool ltr = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      textDirection: ltr ? TextDirection.ltr : null,
      style: const TextStyle(fontSize: 12.5, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
      ),
    );
  }

  Widget _counterRow(
      String title, String hint, int value, ValueChanged<int> onChanged,
      {int min = 0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              if (hint.isNotEmpty)
                Text(hint,
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.muted)),
            ]),
          ),
          _stepperBtn('−', () => onChanged(value > min ? value - 1 : value)),
          SizedBox(
              width: 30,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text))),
          _stepperBtn('+', () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _stepperBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.blue, width: 2)),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.blue)),
      ),
    );
  }
}
