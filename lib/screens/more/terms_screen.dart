import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/server_legal_page.dart';
import '../../widgets/legal_section.dart';
import '../../l10n/translations.dart';

/// Mirrors `#pg-terms`.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Text comes from Admin → Pages (same as the website); the built-in
    // text below is only shown until it loads / when offline.
    return ServerLegalPage(
      type: 'terms',
      title: tr('legal.terms.title_page'),
      fallback: [
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(tr('legal.terms.last_updated'),
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.muted))),
          LegalSection(
            icon: FontAwesomeIcons.solidHandshake,
            title: tr('legal.terms.intro.title'),
            text: tr('legal.terms.intro.body'),
          ),
          LegalSection(
            icon: FontAwesomeIcons.userCheck,
            title: tr('legal.terms.eligibility.title'),
            text: tr('legal.terms.eligibility.body'),
            bullets: [
              tr('legal.terms.eligibility.bullet1'),
              tr('legal.terms.eligibility.bullet2'),
              tr('legal.terms.eligibility.bullet3'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.plane,
            title: tr('legal.terms.nature.title'),
            text: tr('legal.terms.nature.body'),
            bullets: [
              tr('legal.terms.nature.bullet1'),
              tr('legal.terms.nature.bullet2'),
              tr('legal.terms.nature.bullet3'),
              tr('legal.terms.nature.bullet4'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.solidCreditCard,
            title: tr('legal.terms.booking.title'),
            bullets: [
              tr('legal.terms.booking.bullet1'),
              tr('legal.terms.booking.bullet2'),
              tr('legal.terms.booking.bullet3'),
              tr('legal.terms.booking.bullet4'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.ban,
            title: tr('legal.terms.cancellation.title'),
            text: tr('legal.terms.cancellation.body'),
            bullets: [
              tr('legal.terms.cancellation.bullet1'),
              tr('legal.terms.cancellation.bullet2'),
              tr('legal.terms.cancellation.bullet3'),
              tr('legal.terms.cancellation.bullet4'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.users,
            title: tr('legal.terms.conduct.title'),
            text: tr('legal.terms.conduct.body'),
            bullets: [
              tr('legal.terms.conduct.bullet1'),
              tr('legal.terms.conduct.bullet2'),
              tr('legal.terms.conduct.bullet3'),
              tr('legal.terms.conduct.bullet4'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.solidStar,
            title: tr('legal.terms.ratings.title'),
            bullets: [
              tr('legal.terms.ratings.bullet1'),
              tr('legal.terms.ratings.bullet2'),
              tr('legal.terms.ratings.bullet3'),
            ],
          ),
          LegalSection(
            icon: FontAwesomeIcons.gavel,
            title: tr('legal.terms.liability.title'),
            text: tr('legal.terms.liability.body'),
          ),
          LegalSection(
            icon: FontAwesomeIcons.scaleBalanced,
            title: tr('legal.terms.law.title'),
            text: tr('legal.terms.law.body'),
          ),
          LegalSection(
            icon: FontAwesomeIcons.solidEnvelope,
            title: tr('legal.terms.contact.title'),
            text: tr('legal.terms.contact.body'),
          ),
      ],
    );
  }
}
