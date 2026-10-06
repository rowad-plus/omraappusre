import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../l10n/translations.dart';
import '../state/nav_state.dart';

/// Home-page "design your umrah" block, same layout as omraway.com's
/// `.custom-umrah`: heading + text + gold button, then the wizard's four
/// numbered steps. Any tap opens the Design tab.
class DesignUmrahBanner extends StatelessWidget {
  const DesignUmrahBanner({super.key});

  void _open() => NavState.tab.value = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.brandLine),
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [AppColors.brandSoft, Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('design.hub.eyebrow'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand)),
            const SizedBox(height: 4),
            Text(tr('design.hub.card_title'),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
            const SizedBox(height: 6),
            Text(tr('design.hub.card_desc'),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.muted, height: 1.8)),
            const SizedBox(height: 14),
            for (var i = 1; i <= 4; i++) ...[
              _step(i),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brand),
                gradient: const LinearGradient(
                    colors: [Color(0xFFB78B32), Color(0xFFE6C66F)]),
              ),
              child: Text(tr('design.hub.start_button'),
                  style: const TextStyle(
                      color: Color(0xFF1A1408),
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(int n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brandSoft,
            border: Border.all(color: AppColors.brandLine),
          ),
          child: Text('$n',
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: AppColors.brand)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('design.step$n.title'),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
              Text(tr('design.step$n.subtitle'),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
      ]),
    );
  }
}
