import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';
import '../l10n/translations.dart';

/// Mirrors `.vhd` / `.vpill` / `.vline` — the gradient pill + fading line
/// used above VIP trip sections, followed by a "المزيد" link.
class SectionVipHeader extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final Gradient gradient;
  final Color lineColor;
  final Color moreColor;
  final VoidCallback? onMoreTap;

  const SectionVipHeader({
    super.key,
    required this.icon,
    required this.label,
    this.gradient = AppColors.vipGradient,
    this.lineColor = const Color(0x80F59E0B),
    this.moreColor = AppColors.blue,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMoreTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
              decoration: BoxDecoration(
                  gradient: gradient, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(icon, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: [Colors.transparent, lineColor])),
            ),
          ),
          if (onMoreTap != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: GestureDetector(
                onTap: onMoreTap,
                child: Text(tr('nav.viewMore'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: moreColor)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
