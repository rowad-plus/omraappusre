import 'my_design_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../data/country_catalog.dart';
import '../../l10n/translations.dart';
import '../../models/design_option.dart';
import '../../state/app_state.dart';
import '../../state/country_state.dart';
import '../../widgets/app_toast.dart';
import '../auth/login_sheet.dart';
import '../../widgets/instant_date_picker.dart';

/// "صمّم عمرتك" — same steps and fields as the website form; its
/// option lists come from the admin (shared with the website).
const _kHeaderBg = Color(0xFF1F1A10);
const _kStepLabelColor = Color(0xFFD9B45F);
const _kDotInactive = Color(0x2EFFFFFF);
const _kDotActive = Color(0xFFB8892F);
const _kAccent = Color(0xFF8E6A28);
const _kAccentBg = Color(0xFFEEDDB8);
const _kText = Color(0xFF1A1A1A);
const _kMuted = Color(0xFF6B6B68);
const _kMuted2 = Color(0xFF999999);
const _kBorder = Color(0xFFE2E2E0);
const _kBorderDark = Color(0xFFCFCFCA);
const _kFooterBg = Color(0xFFFAFAF9);

class UmrahWizardScreen extends StatefulWidget {
  const UmrahWizardScreen({super.key});

  @override
  State<UmrahWizardScreen> createState() => _UmrahWizardScreenState();
}

class _UmrahWizardScreenState extends State<UmrahWizardScreen> {
  // Same steps and fields as the website's "صمّم عمرتك" form; the last
  // step is the review. Hotel preferences, transport and room types
  // come from Admin → خيارات صمّم عمرتك (shared with the website).
  static const _totalSteps = 7;
  int _step = 0;

  // Values are the ones the website stores on a request.
  String? _startPoint; // مكة أولاً | المدينة أولاً | مكة فقط
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  int _makkaDays = 7;
  int _madinaDays = 3;
  final _makkaDaysCtrl = TextEditingController(text: '7');
  final _madinaDaysCtrl = TextEditingController(text: '3');
  String _makkaStars = 'لا يهم';
  String _madinaStars = 'لا يهم';
  final _hotelPrefs = <String>{};
  final _transport = <String>{};
  String? _departureCountry;
  final _departureCityCtrl = TextEditingController();
  String? _flightType;
  String? _flightClass;
  DateTime? _travelDate;
  bool _flexDates = false;
  String _countryCode = '+20';
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _roomType;
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  Map<String, List<DesignOption>>? _options;
  bool _optionsFailed = false;

  bool get _makkahOnly => _startPoint == 'مكة فقط';

  // Longest first so "+966…" isn't split as "+96…".
  static const _dialCodes = [
    '+966',
    '+971',
    '+965',
    '+974',
    '+962',
    '+212',
    '+20'
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromAccount();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() => _optionsFailed = false);
    final opts = await context.read<AppState>().fetchDesignOptions();
    if (!mounted) return;
    setState(() {
      _options = opts;
      _optionsFailed = opts == null;
    });
  }

  /// Contact step comes pre-filled from the signed-in account (like the
  /// website's form); only empty fields are filled, so edits are kept.
  static const _dialByCountry = {
    'SA': '+966',
    'EG': '+20',
    'AE': '+971',
    'KW': '+965',
    'QA': '+974',
    'JO': '+962',
    'MA': '+212',
  };

  void _prefillFromAccount() {
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      _countryCode =
          _dialByCountry[CountryState.selected.value?.code] ?? _countryCode;
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) _nameCtrl.text = app.userName;
    if (_emailCtrl.text.trim().isEmpty) _emailCtrl.text = app.userEmail ?? '';
    final phone = (app.userPhone ?? '').replaceAll(' ', '');
    if (_phoneCtrl.text.trim().isEmpty && phone.isNotEmpty) {
      final code =
          _dialCodes.firstWhere((c) => phone.startsWith(c), orElse: () => '');
      if (code.isNotEmpty) {
        _countryCode = code;
        _phoneCtrl.text = phone.substring(code.length);
      } else {
        _phoneCtrl.text = phone;
      }
    }
  }

  @override
  void dispose() {
    _departureCityCtrl.dispose();
    _makkaDaysCtrl.dispose();
    _madinaDaysCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Same limits as the website (and its server validation).
  void _setMakkaDays(int v) {
    final clamped = v.clamp(3, 21);
    setState(() => _makkaDays = clamped);
    _makkaDaysCtrl.text = '$clamped';
  }

  void _setMadinaDays(int v) {
    final clamped = v.clamp(0, 14);
    setState(() => _madinaDays = clamped);
    _madinaDaysCtrl.text = '$clamped';
  }

  /// Required parts of a step, checked before moving on (like the website).
  String? _stepError(int step) {
    if (step == 0 && _startPoint == null) {
      return tr('design.error.missing_start');
    }
    if (step == 3 &&
        (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty)) {
      return tr('design.error.missing_contact');
    }
    return null;
  }

  void _next() {
    final err = _stepError(_step);
    if (err != null) {
      showAppToast(context, err);
      return;
    }
    if (_step == _totalSteps - 1) {
      _submit();
      return;
    }
    setState(() => _step++);
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final appState = context.read<AppState>();
    if (!appState.isLoggedIn) {
      openLoginSheet(context);
      return;
    }
    // Signed in from this screen (login sheet above): fill what's still
    // empty and let the user see it before sending.
    final before = '${_nameCtrl.text}|${_phoneCtrl.text}';
    setState(_prefillFromAccount);
    if ('${_nameCtrl.text}|${_phoneCtrl.text}' != before) {
      setState(() => _step = 3);
      return;
    }
    for (var s = 0; s < _totalSteps; s++) {
      final err = _stepError(s);
      if (err != null) {
        setState(() => _step = s);
        showAppToast(context, err);
        return;
      }
    }
    setState(() => _submitting = true);
    final error = await appState.submitDesignRequest(
      startCity: _startPoint!,
      daysInMakkah: _makkaDays,
      daysInMadinah: _makkahOnly ? 0 : _madinaDays,
      hotelStarsMakkah: _makkaStars == 'لا يهم' ? null : _makkaStars,
      hotelStarsMadinah:
          _makkahOnly || _madinaStars == 'لا يهم' ? null : _madinaStars,
      hotelPrefs: _hotelPrefs.toList(),
      transport: _transport.toList(),
      departureCountry: _departureCountry,
      departureCity: _departureCityCtrl.text.trim(),
      flightType: _flightType,
      flightClass: _flightClass,
      travelDate: _travelDate == null ? null : _isoDate(_travelDate!),
      flexDates: _flexDates,
      adults: _adults,
      children: _children,
      infants: _infants,
      contactName: _nameCtrl.text.trim(),
      contactPhone: '$_countryCode${_phoneCtrl.text.trim()}',
      contactEmail: _emailCtrl.text.trim(),
      roomType: _roomType,
      specialRequests: _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      showAppToast(context, error);
      return;
    }
    _showSubmitted();
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showSubmitted() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('design.dialog.submitted_title'),
            textAlign: TextAlign.center),
        content: Text(tr('design.dialog.submitted_body'),
            textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text(tr('design.dialog.ok')),
          ),
          // Straight to the request's status tracker.
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const MyDesignRequestsScreen()));
            },
            child: Text(tr('design.dialog.track'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepBody(),
            ),
          ),
          _buildFooter(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _kHeaderBg,
      padding: const EdgeInsets.fromLTRB(10, 14, 16, 14),
      child: Column(children: [
        Row(children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: FaIcon(
                Directionality.of(context) == TextDirection.rtl
                    ? FontAwesomeIcons.arrowRight
                    : FontAwesomeIcons.arrowLeft,
                color: Colors.white,
                size: 15),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(tr('design.wizard.title'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
          Text(
              '${tr('design.wizard.step_label')} ${_step + 1} ${tr('design.wizard.of')} $_totalSteps',
              style: const TextStyle(fontSize: 13, color: _kStepLabelColor)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < _totalSteps; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                    color: i <= _step ? _kDotActive : _kDotInactive,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _buildFooter() {
    final isFirst = _step == 0;
    final isLast = _step == _totalSteps - 1;
    final isBeforeReview = _step == _totalSteps - 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
          color: _kFooterBg,
          border: Border(top: BorderSide(color: _kBorder, width: 0.5))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Opacity(
          opacity: isFirst ? 0 : 1,
          child: IgnorePointer(
            ignoring: isFirst,
            child: _FooterButton(
                label: tr('common.previous'),
                bg: Colors.white,
                fg: _kText,
                border: _kBorderDark,
                onTap: _prev),
          ),
        ),
        _FooterButton(
            label: isLast
                ? tr('design.send_now')
                : isBeforeReview
                    ? tr('design.review_request')
                    : tr('common.next'),
            bg: _kAccent,
            fg: Colors.white,
            loading: isLast && _submitting,
            onTap: _next),
      ]),
    );
  }

  Widget _buildStepBody() => switch (_step) {
        0 => _stepBasics(),
        1 => _stepStay(),
        2 => _stepFlight(),
        3 => _stepContact(),
        4 => _stepRoom(),
        5 => _stepNotes(),
        _ => _stepReview(),
      };

  // ── option groups from the admin ──────────────────────────────────────
  List<DesignOption> _group(String g) => _options?[g] ?? const [];

  Widget _optionsState() {
    if (_optionsFailed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(
              child: Text(tr('design.error.options_failed'),
                  style: const TextStyle(fontSize: 12.5, color: _kMuted))),
          TextButton(onPressed: _loadOptions, child: Text(tr('design.retry'))),
        ]),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
          child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }

  Widget _multiPills(String group, Set<String> selected) {
    final opts = _group(group);
    if (opts.isEmpty) return _optionsState();
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final o in opts)
        _Pill('${o.icon ?? ''} ${o.label}'.trim(),
            selected: selected.contains(o.value),
            onTap: () => setState(() => selected.contains(o.value)
                ? selected.remove(o.value)
                : selected.add(o.value))),
    ]);
  }

  // ── steps ─────────────────────────────────────────────────────────────
  Widget _stepBasics() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(
          title: tr('design.step1.title'),
          subtitle: tr('design.step1.subtitle')),
      _Label(tr('design.field.start_point')),
      for (final p in const [
        ('مكة أولاً', 'design.option.makkah_first', FontAwesomeIcons.kaaba),
        (
          'المدينة أولاً',
          'design.option.madinah_first',
          FontAwesomeIcons.mosque
        ),
        ('مكة فقط', 'design.option.makkah_only', FontAwesomeIcons.solidMoon),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SelectCard(
              icon: p.$3,
              label: tr(p.$2),
              selected: _startPoint == p.$1,
              onTap: () => setState(() => _startPoint = p.$1)),
        ),
      const SizedBox(height: 4),
      _Label(tr('design.field.travelers_count')),
      _RowInput(
        label: tr('design.field.adults'),
        child: _Counter(
            value: _adults,
            min: 1,
            max: 20,
            onChanged: (v) => setState(() => _adults = v)),
      ),
      _RowInput(
        label: tr('design.field.children'),
        child: _Counter(
            value: _children,
            min: 0,
            max: 10,
            onChanged: (v) => setState(() => _children = v)),
      ),
      _RowInput(
        label: tr('design.field.infants'),
        child: _Counter(
            value: _infants,
            min: 0,
            max: 5,
            onChanged: (v) => setState(() => _infants = v)),
      ),
    ]);
  }

  Widget _stepStay() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(title: tr('design.step2.title'), subtitle: ''),
      _Label(tr('design.field.stay_duration')),
      Row(children: [
        Expanded(
          child: _DayCounterBox(
            label: tr('design.city.makkah'),
            controller: _makkaDaysCtrl,
            onDecrement: () => _setMakkaDays(_makkaDays - 1),
            onIncrement: () => _setMakkaDays(_makkaDays + 1),
            onChangedText: (t) => _setMakkaDays(int.tryParse(t) ?? _makkaDays),
          ),
        ),
        if (!_makkahOnly) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _DayCounterBox(
              label: tr('design.city.madinah'),
              controller: _madinaDaysCtrl,
              onDecrement: () => _setMadinaDays(_madinaDays - 1),
              onIncrement: () => _setMadinaDays(_madinaDays + 1),
              onChangedText: (t) =>
                  _setMadinaDays(int.tryParse(t) ?? _madinaDays),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 16),
      _Label(tr('design.field.hotel_rating_makkah')),
      _HotelRatingDropdown(
          value: _makkaStars,
          onChanged: (v) => setState(() => _makkaStars = v!)),
      if (!_makkahOnly) ...[
        const SizedBox(height: 12),
        _Label(tr('design.field.hotel_rating_madinah')),
        _HotelRatingDropdown(
            value: _madinaStars,
            onChanged: (v) => setState(() => _madinaStars = v!)),
      ],
      const SizedBox(height: 16),
      _Label(tr('design.field.preferences')),
      _multiPills('hotel_pref', _hotelPrefs),
      const SizedBox(height: 16),
      _Label(tr('design.field.transport_services')),
      _multiPills('transport', _transport),
    ]);
  }

  Widget _stepFlight() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(
          title: tr('design.step3.title'),
          subtitle: tr('design.step3.subtitle')),
      _Label(tr('design.field.departure_country')),
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            border: Border.all(color: _kBorder, width: 0.5),
            borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _departureCountry,
            isExpanded: true,
            hint: Text(tr('design.option.any_country'),
                style: const TextStyle(fontSize: 14, color: _kMuted)),
            items: [
              for (final c in CountryCatalog.all)
                DropdownMenuItem(
                    value: tr(c.nameKey),
                    child: Text('${c.flagEmoji} ${tr(c.nameKey)}',
                        style: const TextStyle(fontSize: 14, color: _kText))),
            ],
            onChanged: (v) => setState(() => _departureCountry = v),
          ),
        ),
      ),
      _Label(tr('design.field.departure_city')),
      _TextInput(
          controller: _departureCityCtrl,
          hint: tr('design.field.departure_city')),
      _Label(tr('design.field.flight_type')),
      _Grid2(children: [
        for (final f in const [
          ('ذهاب وإياب', 'design.option.round_trip'),
          ('ذهاب فقط', 'design.option.one_way'),
        ])
          _SelectCard(
              label: tr(f.$2),
              selected: _flightType == f.$1,
              onTap: () => setState(() => _flightType = f.$1)),
      ]),
      _Label(tr('design.field.flight_class')),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final f in const [
          ('اقتصادية', 'design.option.economy'),
          ('رجال الأعمال', 'design.option.business_class'),
          ('الدرجة الأولى', 'design.option.first_class'),
        ])
          _Pill(tr(f.$2),
              selected: _flightClass == f.$1,
              onTap: () => setState(() => _flightClass = f.$1)),
      ]),
      const SizedBox(height: 16),
      _Label(tr('design.field.travel_date')),
      InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showInstantDatePicker(
            context: context,
            title: tr('design.hint.pick_date'),
            initialDate: _travelDate ?? now,
            firstDate: DateTime(now.year, now.month, now.day),
            lastDate: now.add(const Duration(days: 730)),
          );
          if (picked != null) setState(() => _travelDate = picked);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
              border: Border.all(color: _kBorder, width: 0.5),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const FaIcon(FontAwesomeIcons.calendarDays,
                size: 14, color: _kAccent),
            const SizedBox(width: 8),
            Text(
                _travelDate == null
                    ? tr('design.hint.pick_date')
                    : _isoDate(_travelDate!),
                style: TextStyle(
                    fontSize: 14,
                    color: _travelDate == null ? _kMuted : _kText)),
          ]),
        ),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: _flexDates,
        activeTrackColor: _kAccent,
        title: Text(tr('design.field.flex_dates'),
            style: const TextStyle(fontSize: 13.5, color: _kText)),
        onChanged: (v) => setState(() => _flexDates = v),
      ),
    ]);
  }

  Widget _stepContact() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(title: tr('design.stepx.contact'), subtitle: ''),
      _TextInput(controller: _nameCtrl, hint: tr('design.hint.full_name')),
      _PhoneField(
        countryCode: _countryCode,
        onCountryChanged: (v) => setState(() => _countryCode = v!),
        controller: _phoneCtrl,
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(tr('design.whatsapp_note'),
            style: const TextStyle(fontSize: 11, color: _kMuted)),
      ),
      _TextInput(controller: _emailCtrl, hint: tr('design.hint.email')),
    ]);
  }

  Widget _stepRoom() {
    final rooms = _group('room_type');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(title: tr('design.stepx.room'), subtitle: ''),
      if (rooms.isEmpty)
        _optionsState()
      else
        _Grid2(children: [
          for (final r in rooms)
            _SelectCard(
                label: '${r.icon ?? ''} ${r.label}'.trim(),
                selected: _roomType == r.value,
                onTap: () => setState(() => _roomType = r.value)),
        ]),
    ]);
  }

  Widget _stepNotes() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(title: tr('design.stepx.notes'), subtitle: ''),
      _TextInput(
          controller: _notesCtrl, hint: tr('design.hint.notes'), maxLines: 6),
    ]);
  }

  Widget _stepReview() {
    String labels(String group, Set<String> values) {
      final byValue = {for (final o in _group(group)) o.value: o.label};
      return values.map((v) => byValue[v] ?? v).join('، ');
    }

    String pick(String? value, List<(String, String)> map) {
      for (final m in map) {
        if (m.$1 == value) return tr(m.$2);
      }
      return value ?? '';
    }

    final rows = <(String, String)>[
      (
        tr('design.field.start_point'),
        pick(_startPoint, const [
          ('مكة أولاً', 'design.option.makkah_first'),
          ('المدينة أولاً', 'design.option.madinah_first'),
          ('مكة فقط', 'design.option.makkah_only'),
        ])
      ),
      (
        tr('design.field.travelers_count'),
        '$_adults ${tr('design.unit.adult')}${_children > 0 ? ' + $_children ${tr('design.field.children')}' : ''}${_infants > 0 ? ' + $_infants ${tr('design.field.infants')}' : ''}'
      ),
      (
        tr('design.field.stay_duration'),
        '${_makkaDays + (_makkahOnly ? 0 : _madinaDays)} ${tr('design.unit.days')}'
      ),
      if (_makkaStars != 'لا يهم')
        (tr('design.field.hotel_rating_makkah'), _makkaStars),
      if (!_makkahOnly && _madinaStars != 'لا يهم')
        (tr('design.field.hotel_rating_madinah'), _madinaStars),
      if (_hotelPrefs.isNotEmpty)
        (tr('design.field.preferences'), labels('hotel_pref', _hotelPrefs)),
      if (_transport.isNotEmpty)
        (
          tr('design.field.transport_services'),
          labels('transport', _transport)
        ),
      if (_departureCountry != null)
        (tr('design.field.departure_country'), _departureCountry!),
      if (_departureCityCtrl.text.trim().isNotEmpty)
        (tr('design.field.departure_city'), _departureCityCtrl.text.trim()),
      if (_flightType != null)
        (
          tr('design.field.flight_type'),
          pick(_flightType, const [
            ('ذهاب وإياب', 'design.option.round_trip'),
            ('ذهاب فقط', 'design.option.one_way'),
          ])
        ),
      if (_flightClass != null)
        (
          tr('design.field.flight_class'),
          pick(_flightClass, const [
            ('اقتصادية', 'design.option.economy'),
            ('رجال الأعمال', 'design.option.business_class'),
            ('الدرجة الأولى', 'design.option.first_class'),
          ])
        ),
      if (_travelDate != null)
        (tr('design.field.travel_date'), _isoDate(_travelDate!)),
      if (_roomType != null)
        (tr('design.field.room_type'), labels('room_type', {_roomType!})),
      (tr('design.hint.full_name'), _nameCtrl.text.trim()),
      (
        tr('design.hint.phone_number'),
        '$_countryCode ${_phoneCtrl.text.trim()}'
      ),
      if (_emailCtrl.text.trim().isNotEmpty)
        (tr('design.hint.email'), _emailCtrl.text.trim()),
      if (_notesCtrl.text.trim().isNotEmpty)
        (tr('design.stepx.notes'), _notesCtrl.text.trim()),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(title: tr('design.stepx.review'), subtitle: ''),
      for (final r in rows)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder, width: 0.5))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 120,
                child: Text(r.$1,
                    style: const TextStyle(fontSize: 12.5, color: _kMuted))),
            Expanded(
                child: Text(r.$2,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _kText))),
          ]),
        ),
    ]);
  }
}

class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: _kText)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: _kMuted)),
        ],
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, color: _kMuted)),
    );
  }
}

class _Grid2 extends StatelessWidget {
  final List<Widget> children;
  const _Grid2({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.9,
        children: children,
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  final FaIconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectCard(
      {this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kAccentBg : Colors.white,
          border: Border.all(
              color: selected ? _kAccent : _kBorder, width: selected ? 2 : 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            FaIcon(icon, size: 20, color: selected ? _kAccent : _kMuted),
            const SizedBox(height: 6),
          ],
          Text(label,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: selected ? _kAccent : _kText)),
        ]),
      ),
    );
  }
}

class _HotelRatingDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _HotelRatingDropdown({required this.value, required this.onChanged});

  static const _options = [
    ('لا يهم', 0),
    ('3 نجوم', 3),
    ('4 نجوم', 4),
    ('5 نجوم', 5),
  ];

  static const _optionKeys = {
    'نجمة': 'design.option.star_1',
    'نجمتين': 'design.option.star_2',
    '3 نجوم': 'design.option.star_3',
    '4 نجوم': 'design.option.star_4',
    '5 نجوم': 'design.option.star_5',
    '6 نجوم': 'design.option.star_6',
    '7 نجوم': 'design.option.star_7',
    'لا يهم': 'design.option.no_preference',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder, width: 0.5),
          borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: _kMuted, size: 18),
          borderRadius: BorderRadius.circular(12),
          selectedItemBuilder: (context) =>
              [for (final o in _options) _row(o.$1, o.$2)],
          items: [
            for (final o in _options)
              DropdownMenuItem(value: o.$1, child: _row(o.$1, o.$2))
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _row(String label, int stars) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        if (stars > 0) ...[
          Text('⭐' * stars, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
        ],
        Text(tr(_optionKeys[label]!),
            style: const TextStyle(fontSize: 14, color: _kText)),
      ]),
    );
  }
}

class _RowInput extends StatelessWidget {
  final String label;
  final Widget child;
  const _RowInput({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          border: Border.all(color: _kBorder, width: 0.5),
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, color: _kText)),
        child,
      ]),
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Counter(
      {required this.value,
      this.min = 1,
      this.max = 99,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _btn('−', () => onChanged(value > min ? value - 1 : value)),
      SizedBox(
          width: 24,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kText))),
      _btn('+', () => onChanged(value < max ? value + 1 : value)),
    ]);
  }

  Widget _btn(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              border: Border.all(color: _kBorderDark, width: 0.5),
              borderRadius: BorderRadius.circular(8)),
          child:
              Text(label, style: const TextStyle(fontSize: 15, color: _kText)),
        ),
      ),
    );
  }
}

class _DayCounterBox extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<String> onChangedText;
  const _DayCounterBox({
    required this.label,
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    required this.onChangedText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          border: Border.all(color: _kBorder, width: 0.5),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _kMuted2)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _stepBtn('−', onDecrement),
          SizedBox(
            width: 34,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: _kText),
              decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none),
              onChanged: onChangedText,
            ),
          ),
          _stepBtn('+', onIncrement),
        ]),
        const SizedBox(height: 2),
        Text(tr('design.unit.days'),
            style: const TextStyle(fontSize: 10, color: _kMuted2)),
      ]),
    );
  }

  Widget _stepBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            border: Border.all(color: _kBorderDark, width: 0.5),
            borderRadius: BorderRadius.circular(7)),
        child: Text(label, style: const TextStyle(fontSize: 15, color: _kText)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _Pill(this.label, {this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: selected ? _kAccentBg : null,
            border: Border.all(
                color: selected ? _kAccent : _kBorder,
                width: selected ? 1.5 : 0.5),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style:
                TextStyle(fontSize: 12, color: selected ? _kAccent : _kText)),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final String countryCode;
  final ValueChanged<String?> onCountryChanged;
  final TextEditingController controller;
  const _PhoneField(
      {required this.countryCode,
      required this.onCountryChanged,
      required this.controller});

  static const _codes = ['+20', '+966', '+971', '+965', '+974', '+962', '+212'];

  // Example mobile number for the chosen dial code (without the trunk 0).
  static const _hintByCode = {
    '+20': '1X XXXX XXXX',
    '+966': '5X XXX XXXX',
    '+971': '5X XXX XXXX',
    '+965': 'XXXX XXXX',
    '+974': 'XXXX XXXX',
    '+962': '7X XXX XXXX',
    '+212': '6XX XXX XXX',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              border: Border.all(color: _kBorder, width: 0.5),
              borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: countryCode,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: _kMuted, size: 16),
              style: const TextStyle(fontSize: 14, color: _kText),
              items: [
                for (final c in _codes)
                  DropdownMenuItem(value: c, child: Text(c))
              ],
              onChanged: onCountryChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 14, color: _kText),
              decoration: InputDecoration(
                hintText:
                    _hintByCode[countryCode] ?? tr('design.hint.phone_number'),
                hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder, width: 0.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder, width: 0.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kAccent, width: 1)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _TextInput(
      {required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: _kText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder, width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder, width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kAccent, width: 1)),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;
  final bool loading;
  final VoidCallback onTap;
  const _FooterButton(
      {required this.label,
      required this.bg,
      required this.fg,
      this.border,
      this.loading = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border:
              border != null ? Border.all(color: border!, width: 0.5) : null,
        ),
        child: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg))
            : Text(label,
                style: TextStyle(fontSize: 14, color: fg),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
      ),
    );
  }
}
