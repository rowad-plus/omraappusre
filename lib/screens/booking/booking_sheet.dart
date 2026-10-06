import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/api_booking.dart';
import '../../models/api_trip.dart';
import '../../models/trip.dart';
import '../../state/app_state.dart';
import '../../state/country_state.dart';
import '../../utils/western_digits_formatter.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/country_picker_sheet.dart';
import 'neoleap_payment_screen.dart';

const _monthShort = [
  '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

const _documentTypes = ['national_id', 'iqama', 'passport'];

/// One traveler's document form entry — sized to `_personsCount` and kept
/// in sync with it via `_syncTravelerEntries`.
class _TravelerEntry {
  String documentType = 'national_id';
  final nameCtrl = TextEditingController();
  final numberCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    numberCtrl.dispose();
  }
}

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
  final List<_TravelerEntry> _travelerEntries = [];
  bool _submitting = false;
  String? _error;

  /// Private room (2+ persons only): the server prices it at the trip's
  /// family price for that group size. Default is a shared room, priced at
  /// the per-person price × persons.
  bool _privateRoom = false;
  double? _privateRoomTotal; // server quote while _privateRoom is on
  bool _quoteLoading = false;
  int _quoteSeq = 0;

  int get _personsCount => _adults + _children;
  bool get _privateRoomApplies => _privateRoom && _personsCount > 1;

  void _onPersonsChanged() {
    _syncTravelerEntries();
    if (_personsCount < 2) _privateRoom = false;
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
    _syncTravelerEntries();
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
    final detail = await context.read<AppState>().fetchTripDetail(tripId);
    if (!mounted) return;
    setState(() {
      _dates = detail?.dates ?? [];
      _datesAreComputed = detail?.datesAreComputed ?? false;
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
    for (final e in _travelerEntries) {
      e.dispose();
    }
    super.dispose();
  }

  void _syncTravelerEntries() {
    final wasEmpty = _travelerEntries.isEmpty;
    while (_travelerEntries.length < _personsCount) {
      _travelerEntries.add(_TravelerEntry());
    }
    while (_travelerEntries.length > _personsCount) {
      _travelerEntries.removeLast().dispose();
    }
    // Mirrors the website's own booking page exactly: traveler #1's name
    // is pre-filled from the logged-in account (`accountName` in
    // `booking.blade.php`'s JS) whenever that field is still empty — not
    // controlled by the "I am the traveler" toggle at all (that toggle
    // only changes what the *Personal Information* section shows; the
    // website's own `submit()` never reads its manual-entry fields, so
    // there's nothing functional there to mirror — see the memory note).
    if (wasEmpty && _travelerEntries.isNotEmpty) {
      final accountName = context.read<AppState>().userName;
      if (accountName.isNotEmpty && _travelerEntries.first.nameCtrl.text.isEmpty) {
        _travelerEntries.first.nameCtrl.text = accountName;
      }
    }
  }

  bool _travelerDocsValid() {
    if (_travelerEntries.isEmpty) return false;
    for (final e in _travelerEntries) {
      if (e.nameCtrl.text.trim().isEmpty || e.numberCtrl.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_datesLoading) return;
    if (_needsDateChoice && _selectedDate == null) {
      showAppToast(context, '⚠️ ${tr('booking.validation.selectDate')}');
      return;
    }
    if (!_travelerDocsValid()) {
      showAppToast(
          context, '⚠️ ${tr('booking.validation.completeTravelerDocs')}');
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

    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await context.read<AppState>().createBooking(
          tripId: tripId,
          personsCount: _personsCount,
          countryCode: country.code,
          travelers: _travelerEntries
              .map((e) => ApiBookingTraveler(
                    name: e.nameCtrl.text.trim(),
                    documentType: e.documentType,
                    documentNumber: e.numberCtrl.text.trim(),
                  ))
              .toList(),
          tripDateId: _selectedDate?.id ?? '',
          notes: _notesCtrl.text.trim(),
          privateRoom: _privateRoomApplies,
        );
    if (!mounted) return;
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
    final payable =
        result.paymentOption == 'full' || result.paymentOption == 'commission';

    if (bookingId != null && payable) {
      await _startPayment(bookingId);
      return;
    }

    setState(() => _submitting = false);
    Navigator.of(context).pop();
    showAppToast(context, '✅ ${tr('booking.success.requestSent')}');
  }

  /// Opens the NeoLeap Bank-Hosted payment page for [bookingId] in an
  /// in-app WebView (see `NeoLeapPaymentScreen`). The booking itself
  /// already exists as 'pending' regardless of the outcome here — a
  /// failed/cancelled payment does not lose the booking request, it just
  /// leaves it unpaid (matching how `PaymentController::initiate` is safe
  /// to retry for the same booking).
  Future<void> _startPayment(int bookingId) async {
    final paymentResult = await context.read<AppState>().initiatePayment(bookingId);
    if (!mounted) return;

    if (paymentResult.paymentUrl == null) {
      setState(() => _submitting = false);
      Navigator.of(context).pop();
      showAppToast(context,
          '⚠️ ${paymentResult.error ?? tr('booking.payment.startError')}');
      return;
    }

    setState(() => _submitting = false);
    final paid = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NeoLeapPaymentScreen(paymentUrl: paymentResult.paymentUrl!),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();

    if (paid == true) {
      showAppToast(context, '✅ ${tr('booking.payment.success')}');
    } else if (paid == false) {
      showAppToast(context, '⚠️ ${tr('booking.payment.failed')}');
    } else {
      showAppToast(context, '✅ ${tr('booking.success.requestSent')}');
    }
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
      body: SafeArea(
        child: SingleChildScrollView(
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
                  _counterRow(
                      tr('booking.travelers.adultsLabel'),
                      tr('booking.travelers.adultsHint'),
                      _adults,
                      (v) => setState(() {
                            _adults = v;
                            _onPersonsChanged();
                          }),
                      min: 1),
                  _counterRow(
                      tr('booking.travelers.childrenLabel'),
                      tr('booking.travelers.childrenHint'),
                      _children,
                      (v) => setState(() {
                            _children = v;
                            _onPersonsChanged();
                          })),
                  if (_personsCount > 1) _privateRoomRow(),
                ]),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                icon: FontAwesomeIcons.idCard,
                title: tr('booking.travelerDocs.stepTitle'),
                child: Column(children: [
                  for (var i = 0; i < _travelerEntries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _travelerEntryCard(i),
                  ],
                ]),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                icon: FontAwesomeIcons.calendarDays,
                title: tr('booking.dateRoom.departureDateLabel'),
                child: _dateSection(),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                icon: FontAwesomeIcons.noteSticky,
                title: tr('booking.contact.notesLabel'),
                child:
                    _textField(_notesCtrl, tr('booking.contact.notesHint'), maxLines: 3),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }

  Widget _sectionCard(
      {required FaIconData icon, required String title, required Widget child}) {
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

  /// Read-only display of the account's own data — mirrors the website's
  /// "Personal Information" section when its traveler-is-me toggle is ON
  /// (the default). The toggle's OFF state (typing a different name/
  /// phone/email) is skipped: the website's own `submit()` never actually
  /// reads those manual-entry fields — its traveler #1 pre-fill always
  /// comes from `auth()->user()->name` regardless of the toggle (see
  /// `_syncTravelerEntries`), so the toggle has no real effect there
  /// either — nothing functional to mirror beyond that pre-fill.
  Widget _personalInfoRows(AppState app) {
    final rows = [
      (tr('booking.contact.fullNameLabel'), app.userName),
      (tr('booking.contact.phoneLabel'), app.userPhone ?? '—'),
      ('Email', app.userEmail ?? '—'),
    ];
    return Column(children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Text(r.$1,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(r.$2,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
            ),
          ]),
        ),
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
      return Text(tr('booking.payment.loadError'),
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted));
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
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: validDates.isEmpty
              ? now
              : validDates.reduce((a, b) => a.isAfter(b) ? a : b),
          selectableDayPredicate: (day) => validDates.any(
              (d) => d.year == day.year && d.month == day.month && d.day == day.day),
        );
        if (picked == null) return;
        final iso =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        setState(() => _selectedDate = ApiTripDate(id: iso, departureDate: iso));
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

  Widget _travelerEntryCard(int index) {
    final entry = _travelerEntries[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${tr('booking.travelerDocs.personLabel')} ${index + 1}',
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
        const SizedBox(height: 10),
        AppDropdown<String>(
          label: tr('booking.travelerDocs.documentTypeLabel'),
          value: entry.documentType,
          options: {
            // API value `national_id` ↔ translation key `nationalId`.
            for (final t in _documentTypes)
              t: tr(t == 'national_id'
                  ? 'booking.travelerDocs.nationalId'
                  : 'booking.travelerDocs.$t'),
          },
          onChanged: (v) => setState(() => entry.documentType = v ?? entry.documentType),
        ),
        const SizedBox(height: 10),
        _fieldLabel(tr('booking.travelerDocs.nameLabel')),
        const SizedBox(height: 6),
        _textField(entry.nameCtrl, tr('booking.travelerDocs.nameHint')),
        const SizedBox(height: 10),
        _fieldLabel(tr('booking.travelerDocs.numberLabel')),
        const SizedBox(height: 6),
        _textField(entry.numberCtrl, tr('booking.travelerDocs.numberHint'),
            keyboardType: entry.documentType == 'passport'
                ? TextInputType.text
                : TextInputType.number,
            formatters: [WesternDigitsFormatter()],
            ltr: entry.documentType != 'passport'),
      ]),
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
                  color: _privateRoom ? AppColors.blue : AppColors.border, width: 1.5),
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('booking.travelers.privateRoomLabel'),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(tr('booking.travelers.privateRoomHint'),
                    style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// Shared room (default): per-person price × persons — computed locally,
  /// same rule as the server. Private room: the server's quoted family price.
  Widget _priceSummaryCard() {
    final unitPrice =
        double.tryParse(widget.trip.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final currency = widget.trip.price.replaceAll(RegExp(r'[0-9.,\s]'), '').trim();
    final usePrivate = _privateRoomApplies && _privateRoomTotal != null;
    final total = usePrivate ? _privateRoomTotal! : unitPrice * _personsCount;
    final label = usePrivate
        ? '${tr('booking.summary.privateRoomPrice')} ($_personsCount)'
        : '${tr('booking.summary.price')} (×$_personsCount)';
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
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue))
        else
          Text('${total.toStringAsFixed(0)} $currency',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.blue)),
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
              Text(hint,
                  style:
                      const TextStyle(fontSize: 10.5, color: AppColors.muted)),
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
