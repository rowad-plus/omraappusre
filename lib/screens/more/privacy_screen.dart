import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/server_legal_page.dart';
import '../../widgets/legal_section.dart';
import '../../l10n/translations.dart';

/// Mirrors `#pg-privacy`.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Text comes from Admin → Pages (same as the website); the built-in
    // text below is only shown until it loads / when offline.
    return ServerLegalPage(
      type: 'privacy',
      title: tr('legal.privacy.title_page'),
      fallback: [
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(tr('legal.privacy.last_updated'),
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.muted))),
          LegalSection(
            icon: FontAwesomeIcons.shieldHalved,
            title: tr('legal.privacy.commitment.title'),
            text: tr('legal.privacy.commitment.body'),
          ),
          LegalSection(
            icon: FontAwesomeIcons.database,
            title: tr('legal.privacy.data_collected.title'),
            bullets: [
              tr('legal.privacy.data_collected.bullet1'),
              tr('legal.privacy.data_collected.bullet2'),
              tr('legal.privacy.data_collected.bullet3'),
              tr('legal.privacy.data_collected.bullet4'),
              tr('legal.privacy.data_collected.bullet5'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.solidChartBar,
            title: tr('legal.privacy.data_use.title'),
            bullets: [
              tr('legal.privacy.data_use.bullet1'),
              tr('legal.privacy.data_use.bullet2'),
              tr('legal.privacy.data_use.bullet3'),
              tr('legal.privacy.data_use.bullet4'),
              tr('legal.privacy.data_use.bullet5'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.shareNodes,
            title: tr('legal.privacy.data_sharing.title'),
            text: tr('legal.privacy.data_sharing.body'),
            bullets: [
              tr('legal.privacy.data_sharing.bullet1'),
              tr('legal.privacy.data_sharing.bullet2'),
              tr('legal.privacy.data_sharing.bullet3'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.lock,
            title: tr('legal.privacy.data_security.title'),
            bullets: [
              tr('legal.privacy.data_security.bullet1'),
              tr('legal.privacy.data_security.bullet2'),
              tr('legal.privacy.data_security.bullet3'),
              tr('legal.privacy.data_security.bullet4'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.userShield,
            title: tr('legal.privacy.user_rights.title'),
            bullets: [
              tr('legal.privacy.user_rights.bullet1'),
              tr('legal.privacy.user_rights.bullet2'),
              tr('legal.privacy.user_rights.bullet3'),
              tr('legal.privacy.user_rights.bullet4'),
              tr('legal.privacy.user_rights.bullet5'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.cookieBite,
            title: tr('legal.privacy.cookies.title'),
            text: tr('legal.privacy.cookies.body'),
          ),
          LegalSection(
            icon: FontAwesomeIcons.solidEnvelope,
            title: tr('legal.privacy.contact.title'),
            text: tr('legal.privacy.contact.body'),
          ),
      ],
    );
  }
}
