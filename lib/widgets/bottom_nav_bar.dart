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

/// Mirrors `.bnav` / `.bi` — the 4-tab bottom bar (الرئيسية، صمم رحلتك،
/// لقطات، المزيد). The "الرئيسية" tab highlights green, the rest blue.
/// A search button sits in the middle; it opens the search tab via
/// [onSearchTap] and is highlighted while [searchActive].
class AppBottomNavBar extends StatelessWidget {
  static List<BottomNavItemData> get items => [
        BottomNavItemData(
            icon: FontAwesomeIcons.kaaba,
            label: tr('nav.home'),
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

  /// Height of the white bar (top border included), not counting the
  /// device's bottom safe-area inset.
  static const barHeight = 60.0;

  /// How far the search circle rises above the white bar. The widget is
  /// this much taller than the bar; that strip is transparent and only the
  /// circle in it takes taps, so the page underneath stays tappable.
  static const rise = 12.0;

  /// Total height this widget takes, including the safe-area inset.
  static double totalHeight(BuildContext context) =>
      rise + barHeight + MediaQuery.paddingOf(context).bottom;

  /// The search slot inside the bar: an empty, tappable gap under the
  /// circle (no label — the circle speaks for itself).
  Widget _searchSlot() {
    return Expanded(
      child: Semantics(
        button: true,
        label: tr('nav.search'),
        child: GestureDetector(
          onTap: onSearchTap,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  /// The search button: a raised circle that rises above the bar so it
  /// stands apart from the 4 tabs. Gold with a white icon normally; while
  /// the search tab is open it flips to white with a gold ring and icon.
  /// It lies fully inside this widget's bounds, so all of it takes taps.
  Widget _searchCircle() {
    return GestureDetector(
      onTap: onSearchTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: searchActive ? Colors.white : null,
          gradient: searchActive
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brandLight, AppColors.brandDark]),
          border: Border.all(
              color: searchActive ? AppColors.brand : Colors.white,
              width: searchActive ? 3 : 4),
          boxShadow: [
            BoxShadow(
                color: AppColors.brand
                    .withValues(alpha: searchActive ? 0.5 : 0.35),
                blurRadius: searchActive ? 14 : 10,
                spreadRadius: searchActive ? 1 : 0,
                offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: FaIcon(FontAwesomeIcons.magnifyingGlass,
            size: 20,
            color: searchActive ? AppColors.brandDark : Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: totalHeight(context),
      child: Stack(children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: barHeight + inset,
          child: Container(
            padding: EdgeInsets.only(bottom: inset),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                  top: BorderSide(color: AppColors.border, width: 2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2))
              ],
            ),
            // The bar has a fixed height, so labels can't grow without limit.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i == 2) _searchSlot(),
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
          ),
        ),
        // The search slot is the middle of 5 equal slots, so the circle
        // sits at the horizontal centre in both RTL and LTR.
        Positioned(
            top: 0, left: 0, right: 0, child: Center(child: _searchCircle())),
      ]),
    );
  }
}
