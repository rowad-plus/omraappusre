import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../l10n/translations.dart';
import '../../state/app_state.dart';
import '../../widgets/app_toast.dart';
import '../auth/login_sheet.dart';

/// Mirrors `umrah_app_redesign.html` — the condensed 4-step "صمّم عمرتك"
/// wizard (replaces the old 8-step flow).
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
  static const _totalSteps = 4;
  static const _hotelPrefKeys = {
    'قريب من الحرم': 'design.option.near_haram',
    'إفطار مدرج': 'design.option.breakfast_included',
  };
  int _step = 0;

  String _startPoint = 'مكة ثم المدينة';
  int _adults = 2;
  int _makkaDays = 7;
  int _madinaDays = 3;
  final _makkaDaysCtrl = TextEditingController(text: '7');
  final _madinaDaysCtrl = TextEditingController(text: '3');
  String _makkaStars = 'لا يهم';
  String _roomType = 'مزدوجة';
  final _departureCityCtrl = TextEditingController();
  String _flightClass = 'اقتصادية';
  String? _extraService;
  final _hotelPrefs = <String>{};
  String _countryCode = '+20';
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _departureCityCtrl.dispose();
    _makkaDaysCtrl.dispose();
    _madinaDaysCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setMakkaDays(int v) {
    final clamped = v < 1 ? 1 : v;
    setState(() => _makkaDays = clamped);
    _makkaDaysCtrl.text = '$clamped';
  }

  void _setMadinaDays(int v) {
    final clamped = v < 0 ? 0 : v;
    setState(() => _madinaDays = clamped);
    _madinaDaysCtrl.text = '$clamped';
  }

  void _next() {
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
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      showAppToast(context, tr('design.error.missing_contact'));
      return;
    }
    setState(() => _submitting = true);
    final error = await appState.submitDesignRequest(
      startCity: _startPoint,
      daysInMakkah: _makkaDays,
      daysInMadinah: _madinaDays,
      hotelStarsMakkah: _makkaStars,
      hotelPrefs: _hotelPrefs.toList(),
      departureCity: _departureCityCtrl.text.trim(),
      flightClass: _flightClass,
      adults: _adults,
      extras: _extraService == null ? null : [_extraService!],
      contactName: _nameCtrl.text.trim(),
      contactPhone: '$_countryCode${_phoneCtrl.text.trim()}',
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

  void _showSubmitted() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('design.dialog.submitted_title'),
            textAlign: TextAlign.center),
        content: Text(tr('design.dialog.submitted_body'),
            textAlign: TextAlign.center),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: Text(tr('design.dialog.ok')),
            ),
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
            if (i > 0) const SizedBox(width: 6),
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
            label: isLast ? tr('design.review_request') : tr('common.next'),
            bg: _kAccent,
            fg: Colors.white,
            loading: isLast && _submitting,
            onTap: _next),
      ]),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return _step0();
      case 1:
        return _step1();
      case 2:
        return _step2();
      default:
        return _step3();
    }
  }

  Widget _step0() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(
          title: tr('design.step1.title'),
          subtitle: tr('design.step1.subtitle')),
      _Label(tr('design.field.start_point')),
      _Grid2(children: [
        _SelectCard(
            icon: FontAwesomeIcons.solidMoon,
            label: tr('design.option.makkah_only'),
            selected: _startPoint == 'مكة فقط',
            onTap: () => setState(() => _startPoint = 'مكة فقط')),
        _SelectCard(
            icon: FontAwesomeIcons.mosque,
            label: tr('design.option.makkah_then_madinah'),
            selected: _startPoint == 'مكة ثم المدينة',
            onTap: () => setState(() => _startPoint = 'مكة ثم المدينة')),
      ]),
      _Label(tr('design.field.travelers_count')),
      _RowInput(
        label: tr('design.field.adults'),
        child: _Counter(
            value: _adults, onChanged: (v) => setState(() => _adults = v)),
      ),
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
      ]),
    ]);
  }

  Widget _step1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(
          title: tr('design.step2.title'),
          subtitle: tr('design.step2.subtitle')),
      _Label(tr('design.field.hotel_rating_makkah')),
      _HotelRatingDropdown(
        value: _makkaStars,
        onChanged: (v) => setState(() => _makkaStars = v!),
      ),
      const SizedBox(height: 16),
      _Label(tr('design.field.room_type')),
      _Grid2(children: [
        _SelectCard(
            icon: FontAwesomeIcons.bed,
            label: tr('design.option.double_room'),
            selected: _roomType == 'مزدوجة',
            onTap: () => setState(() => _roomType = 'مزدوجة')),
        _SelectCard(
            icon: FontAwesomeIcons.users,
            label: tr('design.option.family_room'),
            selected: _roomType == 'عائلية',
            onTap: () => setState(() => _roomType = 'عائلية')),
      ]),
      _Label(tr('design.field.preferences')),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in const ['قريب من الحرم', 'إفطار مدرج'])
          _Pill(tr(_hotelPrefKeys[p]!),
              selected: _hotelPrefs.contains(p),
              onTap: () => setState(() => _hotelPrefs.contains(p)
                  ? _hotelPrefs.remove(p)
                  : _hotelPrefs.add(p))),
      ]),
    ]);
  }

  Widget _step2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(
          title: tr('design.step3.title'),
          subtitle: tr('design.step3.subtitle')),
      _Label(tr('design.field.departure_city')),
      _TextInput(
          controller: _departureCityCtrl,
          hint: tr('design.hint.departure_city')),
      _Label(tr('design.field.flight_class')),
      _Grid2(children: [
        _SelectCard(
            label: tr('design.option.economy'),
            selected: _flightClass == 'اقتصادية',
            onTap: () => setState(() => _flightClass = 'اقتصادية')),
        _SelectCard(
            label: tr('design.option.business'),
            selected: _flightClass == 'رجال أعمال',
            onTap: () => setState(() => _flightClass = 'رجال أعمال')),
      ]),
      _Label(tr('design.field.transport_services')),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Pill(tr('design.option.airport_pickup')),
        _Pill(tr('design.option.intercity_transfer')),
      ]),
    ]);
  }

  Widget _step3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepHeader(
          title: tr('design.step4.title'),
          subtitle: tr('design.step4.subtitle')),
      _Grid2(children: [
        _SelectCard(
            icon: FontAwesomeIcons.solidIdCard,
            label: tr('design.option.umrah_visa'),
            selected: _extraService == 'تأشيرة العمرة',
            onTap: () => setState(() => _extraService = 'تأشيرة العمرة')),
        _SelectCard(
            icon: FontAwesomeIcons.shieldHalved,
            label: tr('design.option.travel_insurance'),
            selected: _extraService == 'تأمين سفر',
            onTap: () => setState(() => _extraService = 'تأمين سفر')),
        _SelectCard(
            icon: FontAwesomeIcons.simCard,
            label: tr('design.option.saudi_sim'),
            selected: _extraService == 'شريحة سعودية',
            onTap: () => setState(() => _extraService = 'شريحة سعودية')),
        _SelectCard(
            icon: FontAwesomeIcons.solidStar,
            label: tr('design.option.vip_services'),
            selected: _extraService == 'خدمات VIP',
            onTap: () => setState(() => _extraService = 'خدمات VIP')),
      ]),
      const SizedBox(height: 8),
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
      _TextInput(
          controller: _notesCtrl, hint: tr('design.hint.notes'), maxLines: 3),
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
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: _kMuted)),
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
    ('نجمة', 1),
    ('نجمتين', 2),
    ('3 نجوم', 3),
    ('4 نجوم', 4),
    ('5 نجوم', 5),
    ('6 نجوم', 6),
    ('7 نجوم', 7),
    ('لا يهم', 0),
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
  final ValueChanged<int> onChanged;
  const _Counter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _btn('−', () => onChanged(value > 1 ? value - 1 : value)),
      SizedBox(
          width: 24,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kText))),
      _btn('+', () => onChanged(value + 1)),
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
                hintText: _hintByCode[countryCode] ?? tr('design.hint.phone_number'),
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
