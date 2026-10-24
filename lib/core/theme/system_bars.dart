import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Newer Android draws apps edge-to-edge, which slid the custom headers
/// under the status bar and the bottom bars under the system nav buttons.
/// The whole app now lives inside the safe area ([safeAppFrame], applied
/// in `MaterialApp.builder`); the strips behind the system bars stay white
/// with dark icons.
const systemBarsStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
);

/// On iPhones the full home-indicator inset (~34px) left the bottom nav
/// floating well above the screen edge, so only [_iosBottomKeep] of it is
/// kept clear; the thin indicator line sits over the bar's lower edge.
const _iosBottomKeep = 12.0;

Widget safeAppFrame(Widget child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBarsStyle,
      child: ColoredBox(
        color: Colors.white,
        child: Builder(builder: (context) {
          if (Theme.of(context).platform != TargetPlatform.iOS) {
            return SafeArea(child: child);
          }
          final mq = MediaQuery.of(context);
          double trim(double b) => b > _iosBottomKeep ? _iosBottomKeep : b;
          return MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(bottom: trim(mq.padding.bottom)),
              viewPadding:
                  mq.viewPadding.copyWith(bottom: trim(mq.viewPadding.bottom)),
            ),
            child: SafeArea(child: child),
          );
        }),
      ),
    );
