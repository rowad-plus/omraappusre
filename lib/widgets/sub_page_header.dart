import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';

/// Mirrors `.sub-hdr` used on every drill-down page (favorites, orders,
/// settings, terms, etc.): back button + centered title + optional action.
class SubPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  /// false on a bottom-bar tab (nothing to go back to).
  final bool showBack;

  const SubPageHeader(
      {super.key,
      required this.title,
      this.actionLabel,
      this.onAction,
      this.trailing,
      this.showBack = true});

  @override
  Size get preferredSize => const Size.fromHeight(54);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!showBack) const SizedBox(width: 34) else GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppColors.bg, borderRadius: BorderRadius.circular(17)),
              alignment: Alignment.center,
              child: FaIcon(
                Directionality.of(context) == TextDirection.rtl
                    ? FontAwesomeIcons.arrowRight
                    : FontAwesomeIcons.arrowLeft,
                size: 14,
                color: AppColors.text,
              ),
            ),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
          ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: const Size(34, 34)),
              child: Text(actionLabel!,
                  style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            )
          else
            const SizedBox(width: 34),
        ],
      ),
    );
  }
}
