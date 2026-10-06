import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../state/locale_state.dart';
import '../../widgets/sub_page_header.dart';
import '../../widgets/app_toast.dart';

/// Mirrors `#pg-settings`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kTripNotifs = 'rihlaty_settings_trip_notifs';
  static const _kOfferNotifs = 'rihlaty_settings_offer_notifs';
  static const _kEmailNotifs = 'rihlaty_settings_email_notifs';
  // Persisted for consistency with the other toggles, but has no visual
  // effect yet — the app has no dark theme/palette implemented, so this
  // switch doesn't do anything beyond remembering its own on/off state.
  static const _kDarkMode = 'rihlaty_settings_dark_mode';

  bool _tripNotifs = true;
  bool _offerNotifs = true;
  bool _emailNotifs = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _tripNotifs = prefs.getBool(_kTripNotifs) ?? true;
      _offerNotifs = prefs.getBool(_kOfferNotifs) ?? true;
      _emailNotifs = prefs.getBool(_kEmailNotifs) ?? false;
      _darkMode = prefs.getBool(_kDarkMode) ?? false;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _confirmClearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.clear_data_confirm_title')),
        content: Text(tr('settings.clear_data_confirm_body')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(tr('common.cancel'))),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(tr('settings.clear_data'),
                  style: const TextStyle(color: Color(0xFFE84040)))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTripNotifs);
    await prefs.remove(_kOfferNotifs);
    await prefs.remove(_kEmailNotifs);
    await prefs.remove(_kDarkMode);
    if (!mounted) return;
    setState(() {
      _tripNotifs = true;
      _offerNotifs = true;
      _emailNotifs = false;
      _darkMode = false;
    });
    showAppToast(context, '🗑️ ${tr('settings.data_cleared')}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: tr('settings.title')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _section([
            _toggleRow(
                FontAwesomeIcons.solidBell,
                AppColors.blueLight,
                AppColors.blue,
                tr('settings.notif_trips'),
                _tripNotifs,
                (v) {
                  setState(() => _tripNotifs = v);
                  _setPref(_kTripNotifs, v);
                }),
            _toggleRow(
                FontAwesomeIcons.tag,
                AppColors.greenLight,
                AppColors.green,
                tr('settings.notif_offers'),
                _offerNotifs,
                (v) {
                  setState(() => _offerNotifs = v);
                  _setPref(_kOfferNotifs, v);
                }),
            _toggleRow(
                FontAwesomeIcons.solidEnvelope,
                const Color(0xFFFEF3C7),
                const Color(0xFFD97706),
                tr('settings.notif_email'),
                _emailNotifs,
                (v) {
                  setState(() => _emailNotifs = v);
                  _setPref(_kEmailNotifs, v);
                }),
          ]),
          _section([
            _languageRow(),
            _toggleRow(
                FontAwesomeIcons.solidMoon,
                const Color(0xFFF3F4F6),
                AppColors.muted,
                tr('settings.dark_mode'),
                _darkMode,
                (v) {
                  setState(() => _darkMode = v);
                  _setPref(_kDarkMode, v);
                }),
            _valueRow(FontAwesomeIcons.coins, tr('settings.currency'),
                tr('settings.currency_value')),
          ]),
          _section([
            InkWell(
              onTap: _confirmClearData,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E4),
                          borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const FaIcon(FontAwesomeIcons.trash,
                          size: 15, color: Color(0xFFE84040))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(tr('settings.clear_data'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE84040)))),
                  FaIcon(
                      Directionality.of(context) == TextDirection.rtl
                          ? FontAwesomeIcons.chevronLeft
                          : FontAwesomeIcons.chevronRight,
                      size: 12,
                      color: AppColors.muted),
                ]),
              ),
            ),
          ]),
          Padding(
              padding: const EdgeInsets.all(14),
              child: Text(tr('settings.footer'),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.muted))),
        ],
      ),
    );
  }

  Widget _languageRow() {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleState.locale,
      builder: (context, locale, _) => InkWell(
        onTap: () => _openLanguagePicker(context, locale),
        child: _valueRow(FontAwesomeIcons.globe, tr('settings.language'),
            LocaleState.nativeNames[locale.languageCode]!),
      ),
    );
  }

  void _openLanguagePicker(BuildContext context, Locale current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(tr('settings.language'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          for (final l in LocaleState.supportedLocales)
            ListTile(
              title: Text(LocaleState.nativeNames[l.languageCode]!),
              trailing: l.languageCode == current.languageCode
                  ? const FaIcon(FontAwesomeIcons.check,
                      size: 14, color: AppColors.blue)
                  : null,
              onTap: () {
                LocaleState.locale.value = l;
                Navigator.of(context).pop();
              },
            ),
        ]),
      ),
    );
  }

  Widget _section(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < children.length; i++)
          Container(
              decoration: i < children.length - 1
                  ? const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: AppColors.border)))
                  : null,
              child: children[i]),
      ]),
    );
  }

  Widget _toggleRow(FaIconData icon, Color bg, Color color, String label,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 14, color: color)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text))),
        Switch(
            value: value, onChanged: onChanged, activeColor: AppColors.green),
      ]),
    );
  }

  Widget _valueRow(FaIconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 14, color: AppColors.muted)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text))),
        Text(value,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]),
    );
  }
}
