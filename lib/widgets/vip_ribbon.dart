import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/translations.dart';

/// Diagonal sash across a trip card's physical top-right corner — the ONLY
/// tier marker on cards (the small VIP / مميزة tags next to the title were
/// removed): gold "VIP 👑" for VIP trips, black-and-gold "مميزة" for
/// premium ones. Same look as the website's `article[data-trip-type]`
/// ribbons. Place it as the last child of a Stack that fills the card, e.g.
/// `Positioned(top: 0, right: 0, child: VipRibbon())`; the card's own
/// clipping trims the band's ends along its rounded corner.
class VipRibbon extends StatelessWidget {
  const VipRibbon({super.key, this.size = 82}) : premium = false;

  /// The "مميزة" variant for premium trips.
  const VipRibbon.premium({super.key, this.size = 82}) : premium = true;

  /// Side of the square corner area the band crosses.
  final double size;
  final bool premium;

  static const _vipColors = [
    Color(0xFF8E6A28),
    Color(0xFFD9B45F),
    Color(0xFFF3DE9A),
    Color(0xFFD9B45F),
    Color(0xFF8E6A28),
  ];
  static const _premiumColors = [
    Color(0xFF0B0B0A),
    Color(0xFF2B2B28),
    Color(0xFF3D3A33),
    Color(0xFF2B2B28),
    Color(0xFF0B0B0A),
  ];

  @override
  Widget build(BuildContext context) {
    // Everything scales with [size] (82 = the full-size card ribbon), so a
    // smaller size gives a thinner band that hugs the corner.
    final k = size / 82;
    final bandWidth = 120.0 * k;
    final bandHeight = 21.0 * k;
    // Band centre sits on the corner's diagonal, ~27px (scaled) in from the corner.
    final cx = size - 24 * k;
    final cy = 24.0 * k;
    final fg = premium ? const Color(0xFFF3DE9A) : Colors.white;
    final label = Text(
      premium ? tr('trip.type.premium') : 'VIP',
      style: TextStyle(
        color: fg,
        fontSize: 11 * k,
        fontWeight: FontWeight.w900,
        letterSpacing: premium ? 0 : 1.6 * k,
        height: 1,
        shadows: premium
            ? null
            : const [Shadow(color: Color(0x8C462D05), blurRadius: 2, offset: Offset(0, 1))],
      ),
    );
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: cx - bandWidth / 2,
              top: cy - bandHeight / 2,
              width: bandWidth,
              height: bandHeight,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: premium ? _premiumColors : _vipColors,
                      stops: const [0, .35, .5, .65, 1],
                    ),
                    border: Border(
                      top: BorderSide(color: premium ? const Color(0x8CD9B45F) : const Color(0x8CFFFFFF)),
                      bottom: BorderSide(color: premium ? const Color(0x59D9B45F) : const Color(0x99785519)),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x59503710), blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: premium
                      ? label
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr,
                          children: [
                            label,
                            SizedBox(width: 4 * k),
                            FaIcon(FontAwesomeIcons.crown, size: 9 * k, color: Colors.white),
                          ],
                        ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
