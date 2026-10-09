import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../state/app_state.dart';
import '../../widgets/sub_page_header.dart';
import '../../widgets/app_toast.dart';
import '../auth/login_sheet.dart';

/// Mirrors `#pg-contact`. Support phone/email match the ones shown on the
/// web /contact page (Modules/Front/resources/views/contact.blade.php) —
/// there's no per-channel WhatsApp number configured site-wide (only
/// per-provider-company WhatsApp links elsewhere), so the WhatsApp tile
/// reuses the same general support number as the call tile.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  // From Admin → Settings via /contact-info; null = not set, tile hidden.
  String? _phone;
  String? _email;
  String? _whatsapp;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().fetchContactInfo().then((info) {
      if (!mounted) return;
      setState(() {
        _phone = info.phone;
        _email = info.email;
        _whatsapp = info.whatsapp ?? info.phone;
      });
    });
  }

  late String _subject;
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch(Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      showAppToast(context, tr('more_menu.contact.launch_failed_toast'));
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final appState = context.read<AppState>();
    if (!appState.isLoggedIn) {
      openLoginSheet(context);
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      showAppToast(context, tr('more_menu.contact.message_required_toast'));
      return;
    }
    setState(() => _sending = true);
    final error = await appState.submitContactMessage(
      subject: _subject,
      message: _messageCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      showAppToast(context, error);
      return;
    }
    _messageCtrl.clear();
    showAppToast(context, tr('more_menu.contact.send_toast'));
  }

  @override
  Widget build(BuildContext context) {
    final subjects = [
      tr('more_menu.contact.subject_trip_inquiry'),
      tr('more_menu.contact.subject_booking_issue'),
      tr('more_menu.contact.subject_suggestion'),
      tr('more_menu.contact.subject_complaint'),
    ];
    _subject = subjects.contains(_subject) ? _subject : subjects.first;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: tr('more_menu.contact_us')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_whatsapp != null || _phone != null || _email != null) ...[
            Row(children: [
              for (final w in [
                if (_whatsapp != null)
                  _way(
                      context,
                      FontAwesomeIcons.whatsapp,
                      AppColors.whatsapp,
                      tr('more_menu.contact.whatsapp'),
                      tr('more_menu.contact.whatsapp_hours'),
                      () => _launch(Uri.parse(
                          'https://wa.me/${_whatsapp!.replaceAll(RegExp(r'[^0-9]'), '')}'))),
                if (_phone != null)
                  _way(
                      context,
                      FontAwesomeIcons.phone,
                      AppColors.blue,
                      tr('more_menu.contact.call'),
                      tr('more_menu.contact.call_hours'),
                      () => _launch(Uri.parse('tel:${_phone!.replaceAll(' ', '')}'))),
                if (_email != null)
                  _way(
                      context,
                      FontAwesomeIcons.solidEnvelope,
                      const Color(0xFF7C3AED),
                      tr('more_menu.contact.email'),
                      tr('more_menu.contact.email_hours'),
                      () => _launch(Uri.parse('mailto:$_email'))),
              ].indexed) ...[
                if (w.$1 > 0) const SizedBox(width: 10),
                Expanded(child: w.$2),
              ],
            ]),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const FaIcon(FontAwesomeIcons.solidPaperPlane,
                    size: 13, color: AppColors.text),
                const SizedBox(width: 6),
                Text(tr('more_menu.contact.send_message_title'),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text))
              ]),
              const SizedBox(height: 14),
              Text(tr('more_menu.contact.subject_label'),
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(9)),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                        isExpanded: true,
                        value: _subject,
                        items: [
                          for (final s in subjects)
                            DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(fontSize: 12.5)))
                        ],
                        onChanged: (v) => setState(() => _subject = v!))),
              ),
              const SizedBox(height: 12),
              Text(tr('more_menu.contact.message_label'),
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted)),
              const SizedBox(height: 6),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                    hintText: tr('more_menu.contact.message_hint'),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                            color: AppColors.border, width: 1.5))),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11))),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.solidPaperPlane,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(tr('more_menu.contact.send'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800))
                          ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _way(BuildContext context, FaIconData icon, Color color, String label,
      String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: FaIcon(icon, color: Colors.white, size: 20)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          Text(sub,
              style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
        ]),
      ),
    );
  }
}
