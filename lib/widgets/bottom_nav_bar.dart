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

  static const _idle = Color(0xFF8A8F98);

  Widget _item(
      {required FaIconData icon,
      required String label,
      required bool active,
      required Color accent,
      required VoidCallback onTap}) {
    final color = active ? accent : _idle;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 9, bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                  )),
              const SizedBox(height: 4),
              // Short underline under the active tab.
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 22 : 0,
                height: 3,
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Height of the bar body, not counting the device's bottom safe-area
  /// inset or the cradle bump around the search circle.
  static const barHeight = 64.0;

  /// How far the cradle bump (and the circle in it) rises above the bar.
  /// The widget is this much taller than the bar; outside the bump that
  /// strip is transparent and only the circle in it takes taps.
  static const rise = 20.0;

  static const _circle = 56.0;

  /// The search circle's centre sits this far below the bar's top edge.
  static const _circleDrop = 14.0;

  /// Empty space kept under the labels for the device's bottom inset. On
  /// iPhones the full home-indicator inset (~34px) left a visible gap under
  /// the bar, so only part of it is kept — the indicator sits over the bar.
  static double bottomInset(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    if (Theme.of(context).platform != TargetPlatform.iOS) return inset;
    return (inset - 22).clamp(0.0, inset);
  }

  /// Total height this widget takes, including the safe-area inset.
  static double totalHeight(BuildContext context) =>
      rise + barHeight + bottomInset(context);

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

  /// The search button sitting in the bar's cradle. Idle it is a very soft
  /// gold with a gold icon; while the search tab is open it fills with the
  /// full gold and a white icon. It lies inside this widget's bounds, so
  /// all of it takes taps.
  Widget _searchCircle() {
    return GestureDetector(
      onTap: onSearchTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: _circle,
        height: _circle,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: searchActive
                  ? const [AppColors.brandLight, AppColors.brandDark]
                  : const [Color(0xFFFCF6E6), Color(0xFFF5E8C8)]),
          border: Border.all(
              color: searchActive ? Colors.transparent : AppColors.brandLine,
              width: 1),
          boxShadow: [
            BoxShadow(
                color: AppColors.brand
                    .withValues(alpha: searchActive ? 0.45 : 0.15),
                blurRadius: searchActive ? 16 : 8,
                offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: FaIcon(FontAwesomeIcons.magnifyingGlass,
            size: 21, color: searchActive ? Colors.white : AppColors.brand),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = bottomInset(context);
    return SizedBox(
      height: totalHeight(context),
      child: Stack(children: [
        // The bar body + the cradle bump, painted as one shape.
        Positioned.fill(
          child: CustomPaint(
            painter: _NavBarPainter(
                barTop: rise,
                cradleCenterY: rise + _circleDrop,
                cradleRadius: _circle / 2 + 7),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: barHeight + inset,
          child: Padding(
            padding: EdgeInsets.only(bottom: inset),
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
                        active: !searchActive && currentIndex == i,
                        accent: items[i].accent,
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
            top: rise + _circleDrop - _circle / 2,
            left: 0,
            right: 0,
            child: Center(child: _searchCircle())),
      ]),
    );
  }
}

/// White bar with rounded top corners and a round cradle bump in the middle
/// that holds the search circle, with a thin gold outline and soft shadow.
class _NavBarPainter extends CustomPainter {
  final double barTop;
  final double cradleCenterY;
  final double cradleRadius;

  _NavBarPainter(
      {required this.barTop,
      required this.cradleCenterY,
      required this.cradleRadius});

  static const _corner = 26.0;

  Path _shape(Size size) {
    final bar = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTRB(0, barTop, size.width, size.height),
        topLeft: const Radius.circular(_corner),
        topRight: const Radius.circular(_corner),
      ));
    final cradle = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width / 2, cradleCenterY), radius: cradleRadius));
    return Path.combine(PathOperation.union, bar, cradle);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape(size);
    canvas.drawShadow(shape, Colors.black.withValues(alpha: 0.35), 6, false);
    canvas.drawPath(shape, Paint()..color = const Color(0xFFFFFDF9));
    canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.brandLine);
  }

  @override
  bool shouldRepaint(_NavBarPainter old) =>
      old.barTop != barTop ||
      old.cradleCenterY != cradleCenterY ||
      old.cradleRadius != cradleRadius;
}
