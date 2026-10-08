import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../widgets/sub_page_header.dart';
import 'umrah_wizard_screen.dart';

/// Mirrors `#pg-design` — the "صمّم عمرتك بنفسك" entry point into the
/// umrah design wizard.
class DesignHubScreen extends StatelessWidget {
  const DesignHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: tr('design.hub.appbar_title')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFBF5E8), Color(0xFFFBF5E8)]),
              ),
              child: Column(children: [
                Text(tr('design.hub.eyebrow'),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        height: 1.3),
                    children: [
                      TextSpan(text: tr('design.hub.heading_prefix')),
                      TextSpan(
                          text: tr('design.hub.heading_highlight'),
                          style: const TextStyle(color: AppColors.blue))
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(tr('design.hub.subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.muted, height: 1.7)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              child: Column(children: [
                _DesignCard(
                  emoji: '🕋',
                  iconBg: const Color(0xFFFBF5E8),
                  title: tr('design.hub.card_title'),
                  desc: tr('design.hub.card_desc'),
                  tags: [
                    tr('design.hub.tag_makkah_madinah'),
                    tr('design.hub.tag_vip_or_economy'),
                    tr('design.hub.tag_with_without_flight'),
                    tr('design.hub.tag_solo_or_group'),
                  ],
                  tagBg: AppColors.greenLight,
                  tagColor: AppColors.green,
                  buttonColor: AppColors.green,
                  buttonIcon: FontAwesomeIcons.solidMap,
                  buttonLabel: tr('design.hub.start_button'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const UmrahWizardScreen())),
                ),
              ]),
            ),
            Container(
              margin: const EdgeInsets.only(top: 18),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Expanded(
                      child: _TrustItem(
                          icon: FontAwesomeIcons.shieldHalved,
                          label: tr('design.trust.data_safe'))),
                  Expanded(
                      child: _TrustItem(
                          icon: FontAwesomeIcons.solidClock,
                          label: tr('design.trust.reply_24h'))),
                  Expanded(
                      child: _TrustItem(
                          icon: FontAwesomeIcons.solidStar,
                          label: tr('design.trust.trusted_companies'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final String emoji;
  final Color iconBg;
  final String title;
  final String desc;
  final List<String> tags;
  final Color tagBg;
  final Color tagColor;
  final Color buttonColor;
  final FaIconData buttonIcon;
  final String buttonLabel;
  final VoidCallback onTap;

  const _DesignCard({
    required this.emoji,
    required this.iconBg,
    required this.title,
    required this.desc,
    required this.tags,
    required this.tagBg,
    required this.tagColor,
    required this.buttonColor,
    required this.buttonIcon,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2)),
        child: Column(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Text(desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.muted, height: 1.75)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
              for (final t in tags)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(
                      color: tagBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(t,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tagColor)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FaIcon(buttonIcon, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(buttonLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      FaIcon(icon, size: 18, color: AppColors.green),
      const SizedBox(height: 5),
      Text(label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.muted,
              fontWeight: FontWeight.w600)),
    ]);
  }
}
