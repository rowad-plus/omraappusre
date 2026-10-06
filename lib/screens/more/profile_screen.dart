import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../widgets/sub_page_header.dart';
import '../../widgets/app_toast.dart';
import '../../state/app_state.dart';

/// Mirrors `#pg-profile-user`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  String _nationality = 'eg';
  final _cityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _nameCtrl = TextEditingController(text: state.userName);
    _phoneCtrl = TextEditingController(text: state.userPhone ?? '');
    _emailCtrl = TextEditingController(text: state.userEmail ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      showAppToast(context, tr('more_menu.profile.name_required_toast'));
      return;
    }
    setState(() => _saving = true);
    final error = await context.read<AppState>().updateProfile(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) _editing = false;
    });
    showAppToast(context,
        error ?? tr('more_menu.profile.save_toast'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(
        title: tr('more_menu.profile.title'),
        actionLabel: _editing ? tr('common.cancel') : tr('common.edit'),
        onAction: () => setState(() => _editing = !_editing),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  gradient: AppColors.blueGradient, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Builder(builder: (context) {
                final initial = Text(
                    _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : 'م',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900));
                // Photo uploaded on the website, else the name's initial.
                final url = context.watch<AppState>().userAvatarUrl;
                if (url == null || url.isEmpty) return initial;
                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                  placeholder: (_, __) => initial,
                  errorWidget: (_, __, ___) => initial,
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          if (!_editing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _viewRow(FontAwesomeIcons.solidUser, tr('more_menu.profile.name'),
                    _nameCtrl.text),
                _viewRow(FontAwesomeIcons.phone, tr('more_menu.profile.phone'),
                    _phoneCtrl.text),
                _viewRow(FontAwesomeIcons.solidEnvelope,
                    tr('more_menu.profile.email'), _emailCtrl.text),
                _viewRow(
                    FontAwesomeIcons.solidFlag,
                    tr('more_menu.profile.nationality'),
                    _natLabel(_nationality)),
                _viewRow(FontAwesomeIcons.locationDot,
                    tr('more_menu.profile.city'), _cityCtrl.text,
                    isLast: true),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _editField(tr('more_menu.profile.full_name'), _nameCtrl),
                const SizedBox(height: 12),
                _editField(tr('more_menu.profile.phone_number'), _phoneCtrl,
                    ltr: true, enabled: false),
                const SizedBox(height: 12),
                _editField(tr('more_menu.profile.email_address'), _emailCtrl,
                    ltr: true),
                const SizedBox(height: 12),
                _editNationality(),
                const SizedBox(height: 12),
                _editField(tr('more_menu.profile.city'), _cityCtrl),
              ]),
            ),
          if (_editing) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(tr('more_menu.profile.save_changes'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14)),
            child: InkWell(
              onTap: () async {
                await context.read<AppState>().logout();
                if (!context.mounted) return;
                Navigator.of(context).pop();
                showAppToast(context, tr('more_menu.profile.logout_toast'));
              },
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
                      child: const FaIcon(FontAwesomeIcons.rightFromBracket,
                          size: 15, color: Color(0xFFE84040))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(tr('more_menu.profile.logout'),
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
          ),
        ],
      ),
    );
  }

  Widget _viewRow(FaIconData icon, String label, String value,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Row(children: [
          FaIcon(icon, size: 12, color: AppColors.blue),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted))
        ]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
        ),
      ]),
    );
  }

  String _natLabel(String id) => tr('more_menu.profile.nat_$id');

  Widget _editNationality() {
    const ids = ['eg', 'sa', 'ae', 'kw', 'jo'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('more_menu.profile.nationality'),
          style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.muted)),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(9)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _nationality,
            isExpanded: true,
            items: [
              for (final id in ids)
                DropdownMenuItem(
                    value: id,
                    child: Text(_natLabel(id),
                        style: const TextStyle(fontSize: 12.5)))
            ],
            onChanged: (v) => setState(() => _nationality = v!),
          ),
        ),
      ),
    ]);
  }

  Widget _editField(String label, TextEditingController ctrl,
      {bool ltr = false, bool enabled = true}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.muted)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        enabled: enabled,
        textAlign: ltr ? TextAlign.left : TextAlign.right,
        textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
        ),
      ),
    ]);
  }
}
