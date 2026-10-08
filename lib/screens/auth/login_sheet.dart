import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../state/app_state.dart';
import '../../state/country_state.dart';
import '../../utils/western_digits_formatter.dart';
import '../../widgets/app_toast.dart';

/// Mirrors `#loginSheet` — phone number entry then a 4-digit OTP step,
/// backed by the real Front OTP API. An unrecognized phone number reveals a
/// name field in place so the same flow doubles as registration.
class LoginSheet extends StatefulWidget {
  const LoginSheet({super.key});

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  bool _otpStep = false;
  bool _registering = false;
  bool _sending = false;
  bool _verifying = false;
  String? _error;
  String _countryCode = '🇪🇬 +20';
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _otpCtrls = List.generate(4, (_) => TextEditingController());
  final _otpFocus = List.generate(4, (_) => FocusNode());
  Timer? _timer;
  int _seconds = 60;
  bool _canResend = false;

  static const _codes = [
    '🇪🇬 +20',
    '🇸🇦 +966',
    '🇦🇪 +971',
    '🇰🇼 +965',
    '🇶🇦 +974',
    '🇯🇴 +962'
  ];

  // Maps the ISO country code from CountryState's IP-based detection to one
  // of the fixed dial-code entries above. Countries outside this short list
  // keep the Egypt default rather than guessing.
  static const _dialByCountryCode = {
    'EG': '🇪🇬 +20',
    'SA': '🇸🇦 +966',
    'AE': '🇦🇪 +971',
    'KW': '🇰🇼 +965',
    'QA': '🇶🇦 +974',
    'JO': '🇯🇴 +962',
  };

  // Example mobile number (without the trunk 0) shown as the field's hint,
  // matching the chosen dial code.
  static const _phoneHintByDial = {
    '🇪🇬 +20': '1X XXXX XXXX',
    '🇸🇦 +966': '5X XXX XXXX',
    '🇦🇪 +971': '5X XXX XXXX',
    '🇰🇼 +965': 'XXXX XXXX',
    '🇶🇦 +974': 'XXXX XXXX',
    '🇯🇴 +962': '7X XXX XXXX',
  };

  @override
  void initState() {
    super.initState();
    final detected = _dialByCountryCode[CountryState.selected.value?.code];
    if (detected != null) _countryCode = detected;
  }

  String get _fullPhone {
    final dial = _countryCode.split(' ').last;
    final local = _phoneCtrl.text.trim();
    if (local.startsWith('+')) return local;
    // A leading trunk 0 (e.g. "0569148737", the domestic-dialing form) must
    // be dropped before combining with the country code — otherwise this
    // sends "+9660569148737" instead of the account's real "+966569148737"
    // and login/register silently treats it as a different, unregistered
    // number even though it's the same phone.
    return '$dial${local.replaceFirst(RegExp(r'^0+'), '')}';
  }

  void _startTimer() {
    _seconds = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        setState(() {
          _seconds = 0;
          _canResend = true;
        });
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().isEmpty) return;
    if (_registering && _nameCtrl.text.trim().isEmpty) {
      setState(() => _error = tr('auth.register.nameRequired'));
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final state = context.read<AppState>();
    String? error;

    if (_registering) {
      error = await state.sendRegisterOtp(name: _nameCtrl.text.trim(), phone: _fullPhone);
    } else {
      final result = await state.sendLoginOtp(_fullPhone);
      if (!result.success && result.notRegistered) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _registering = true;
        });
        return;
      }
      error = result.error;
    }

    if (!mounted) return;
    setState(() => _sending = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _otpStep = true);
    _startTimer();
  }

  Future<void> _verify() async {
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length < 4) return;

    setState(() {
      _verifying = true;
      _error = null;
    });

    final state = context.read<AppState>();
    final error = _registering
        ? await state.verifyRegisterOtp(name: _nameCtrl.text.trim(), phone: _fullPhone, code: code)
        : await state.verifyLoginOtp(_fullPhone, code);

    if (!mounted) return;
    setState(() => _verifying = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    Navigator.of(context).pop();
    showAppToast(context, '✅ ${tr('auth.login.successToast')}');
  }

  Future<void> _resend() async {
    _startTimer();
    final state = context.read<AppState>();
    final error = await state.resendOtp(_fullPhone, type: _registering ? 'register' : 'login');
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
    } else {
      showAppToast(context, '📱 ${tr('auth.otp.resentToast')}');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        top: 0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2))),
          _otpStep ? _buildOtpStep() : _buildPhoneStep(),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
                _registering
                    ? tr('auth.register.title')
                    : tr('auth.login.title'),
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
            _closeBtn(),
          ]),
        ),
        Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: AppColors.blue, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const FaIcon(FontAwesomeIcons.mapLocationDot,
                color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(height: 12),
        Text(
            _registering
                ? tr('auth.register.subtitle')
                : tr('auth.login.subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppColors.muted, height: 1.6)),
        const SizedBox(height: 20),
        if (_registering) ...[
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(tr('auth.register.nameLabel'),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted))),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: tr('auth.register.nameHint'),
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
          ),
          const SizedBox(height: 16),
        ],
        Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(tr('auth.login.phoneLabel'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted))),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            height: 46,
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(9)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _countryCode,
                items: [
                  for (final c in _codes)
                    DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 12.5)))
                ],
                onChanged: (v) => setState(() => _countryCode = v!),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [WesternDigitsFormatter()],
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: _phoneHintByDial[_countryCode] ?? tr('auth.login.phoneHint'),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 1.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide:
                        const BorderSide(color: AppColors.blue, width: 1.5)),
              ),
            ),
          ),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFE84040))),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _sending ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: _sending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const FaIcon(FontAwesomeIcons.solidPaperPlane,
                      size: 13, color: Colors.white),
                  const SizedBox(width: 7),
                  Text(tr('auth.login.sendCode'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ]),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: tr('auth.login.termsPrefix'),
            style: const TextStyle(
                fontSize: 11, color: AppColors.muted, height: 1.7),
            children: [
              TextSpan(
                  text: tr('auth.login.termsOfUse'),
                  style: const TextStyle(color: AppColors.blue)),
              TextSpan(text: tr('auth.login.and')),
              TextSpan(
                  text: tr('auth.login.privacyPolicy'),
                  style: const TextStyle(color: AppColors.blue)),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() => _otpStep = false),
              child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: AppColors.bg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: FaIcon(
                      Directionality.of(context) == TextDirection.rtl
                          ? FontAwesomeIcons.arrowRight
                          : FontAwesomeIcons.arrowLeft,
                      size: 14,
                      color: AppColors.muted)),
            ),
            Expanded(
                child: Text(tr('auth.otp.title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text))),
            _closeBtn(),
          ]),
        ),
        Text('${tr('auth.otp.sentTo')}$_fullPhone',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 20),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  // The square is drawn by this fixed 56x56 Container, not
                  // by the TextField's own border — the field sizes itself
                  // to its text line, which made the outlined box shorter
                  // than it was wide.
                  child: ListenableBuilder(
                    listenable: _otpFocus[i],
                    builder: (context, child) => Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _otpFocus[i].hasFocus
                                ? AppColors.blue
                                : AppColors.border,
                            width: 2),
                      ),
                      child: child,
                    ),
                    child: TextField(
                      controller: _otpCtrls[i],
                      focusNode: _otpFocus[i],
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.number,
                      inputFormatters: [WesternDigitsFormatter()],
                      maxLength: 1,
                      // The app's global font (Cairo, an Arabic/Latin dual-
                      // script font) draws unusually-shaped digit glyphs at
                      // this Black (900) weight — a user screenshot showed
                      // "2"/"3"/"4" rendering as distorted/hard-to-read
                      // shapes in these boxes specifically. Not a bidi or
                      // clipping bug: overriding to the platform's plain
                      // Roboto here (only here — every other digit/text
                      // field on the app keeps Cairo) draws normal, fully
                      // legible Western numerals.
                      style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 22,
                          height: 1.2,
                          fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        counterText: '',
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 3) {
                          _otpFocus[i + 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFE84040))),
        ],
        const SizedBox(height: 14),
        if (!_canResend)
          Text(
              '${tr('auth.otp.resendPrefix')}$_seconds${tr('auth.otp.resendSuffix')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted))
        else
          TextButton(
            onPressed: _resend,
            child: Text(tr('auth.otp.resendCode'),
                style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _verifying ? null : _verify,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: _verifying
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const FaIcon(FontAwesomeIcons.check, size: 14, color: Colors.white),
                  const SizedBox(width: 7),
                  Text(tr('auth.otp.confirmCode'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ]),
        ),
      ],
    );
  }

  Widget _closeBtn() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
          width: 30,
          height: 30,
          decoration:
              BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const FaIcon(FontAwesomeIcons.xmark,
              size: 14, color: AppColors.muted)),
    );
  }
}

void openLoginSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const LoginSheet(),
  );
}
