import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../screens/design/my_design_requests_screen.dart';
import '../screens/more/notifications_screen.dart';
import '../screens/more/order_detail_sheet.dart';
import '../state/app_state.dart';

/// Lets push notifications open screens from outside the widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

int? _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

/// يفتح المكان المناسب لإشعار: صفحة الحجز (العمرة) لو فيه booking_id —
/// مع تمييز الإشعار نفسه — وإلا شاشة الإشعارات.
Future<void> openNotificationTarget(Map<String, dynamic> data) async {
  final nav = navigatorKey.currentState;
  final ctx = navigatorKey.currentContext;
  if (nav == null || ctx == null) return;

  final bookingId = _asInt(data['booking_id']);
  if (bookingId != null) {
    final booking = await ctx.read<AppState>().fetchBookingDetail(bookingId);
    final sheetCtx = navigatorKey.currentContext;
    if (booking != null && sheetCtx != null && sheetCtx.mounted) {
      await showModalBottomSheet(
        context: sheetCtx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => OrderDetailSheet(
          order: booking.toOrder(),
          highlightNotificationId: _asInt(data['notification_id']),
        ),
      );
      return;
    }
  }
  final designId = _asInt(data['design_request_id']);
  if (designId != null) {
    nav.push(MaterialPageRoute(
        builder: (_) => MyDesignRequestsScreen(openRequestId: designId)));
    return;
  }
  nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
}

OverlayEntry? _current;
Timer? _hideTimer;

/// بوب أب داخل التطبيق لمدة 4 ثواني لما يوصل إشعار والتطبيق مفتوح.
/// الضغط عليه يفتح صفحة العمرة الخاصة بالإشعار.
void showInAppNotification({
  required String title,
  String? body,
  required Map<String, dynamic> data,
}) {
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) return;

  _hideTimer?.cancel();
  _current?.remove();

  late OverlayEntry entry;
  void dismiss() {
    if (_current == entry) {
      _current = null;
      _hideTimer?.cancel();
    }
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) => _InAppBanner(
      title: title,
      body: body,
      type: '${data['type'] ?? ''}',
      onTap: () {
        dismiss();
        openNotificationTarget(data);
      },
      onDismiss: dismiss,
    ),
  );
  _current = entry;
  overlay.insert(entry);
  _hideTimer = Timer(const Duration(seconds: 4), dismiss);
}

class _InAppBanner extends StatefulWidget {
  final String title;
  final String? body;
  final String type;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _InAppBanner({
    required this.title,
    required this.body,
    required this.type,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<_InAppBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280))
    ..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = notificationStyleFor(widget.type);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -1.2), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
          child: Dismissible(
            key: const ValueKey('in-app-notification'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Material(
                color: Colors.white,
                elevation: 8,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: FaIcon(icon, size: 17, color: fg),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text)),
                              if ((widget.body ?? '').isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(widget.body!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                        height: 1.4)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
