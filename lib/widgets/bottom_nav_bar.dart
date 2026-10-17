import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';
import '../l10n/translations.dart';

class BottomNavItemData {
  final FaIconData icon;
  final String label;
  final Color accent;
  const BottomNavItemData(
      {required this.icon, required this.label, this.accent = AppColors.blue});
}

/// Mirrors `.bnav` / `.bi` — the 4-tab bottom bar (العمرة، صمم رحلتك،
/// لقطات، المزيد). The "العمرة" tab highlights green, the rest blue.
/// A search button sits in the middle; it opens the search tab via
/// [onSearchTap] and is highlighted while [searchActive].
class AppBottomNavBar extends StatelessWidget {
  static List<BottomNavItemData> get items => [
        BottomNavItemData(
            icon: FontAwesomeIcons.kaaba,
            label: tr('nav.umrah'),
            accent: AppColors.green),
        BottomNavItemData(
            icon: FontAwesomeIcons.wandMagicSparkles, label: tr('nav.design')),
        BottomNavItemData(
            icon: FontAwesomeIcons.solidImages, label: tr('nav.photos')),
        BottomNavItemData(
            icon: FontAwesomeIcons.ellipsis, label: tr('nav.more')),
      ];

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSearchTap;

  /// True on the search screen itself: highlights search and no tab.
  final bool searchActive;

  const AppBottomNavBar(
      {super.key,
      required this.currentIndex,
      required this.onTap,
      required this.onSearchTap,
      this.searchActive = false});

  static const _idle = Color(0xFF9CA3AF);

  Widget _item(
      {required FaIconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 9, bottom: 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// The search button: a raised gold circle that rises above the bar so it
  /// stands apart from the 4 tabs. Always gold; a soft halo while active.
  Widget _searchItem() {
    return Expanded(
      child: GestureDetector(
        onTap: onSearchTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 9, bottom: 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Takes the same 22px as the other icons in the layout (so the
              // bar keeps its height) and lets the circle overflow upward.
              SizedBox(
                height: 22,
                child: OverflowBox(
                  minHeight: 54,
                  maxHeight: 54,
                  minWidth: 54,
                  maxWidth: 54,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.brandLight, AppColors.brandDark]),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.brand
                                .withValues(alpha: searchActive ? 0.55 : 0.35),
                            blurRadius: searchActive ? 16 : 10,
                            spreadRadius: searchActive ? 2 : 0,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const FaIcon(FontAwesomeIcons.magnifyingGlass,
                        size: 20, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(tr('nav.search'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: searchActive ? AppColors.brandDark : AppColors.brand,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            const Border(top: BorderSide(color: AppColors.border, width: 2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i == 2) _searchItem(),
              _item(
                  icon: items[i].icon,
                  label: items[i].label,
                  color: !searchActive && currentIndex == i
                      ? items[i].accent
                      : _idle,
                  onTap: () => onTap(i)),
            ],
          ],
        ),
      ),
    );
  }
}
