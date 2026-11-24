import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/api_booking.dart';
import '../../models/api_notification.dart';
import '../../models/order.dart';
import '../../services/live_updates.dart';
import '../../state/app_state.dart';
import '../../widgets/app_toast.dart';
import '../../l10n/translations.dart';
import '../../widgets/order_actions.dart';
import 'notifications_screen.dart' show notificationStyleFor;

/// Mirrors `#orderDetailSheet`. [order] is built from the bookings *list*
/// endpoint, which omits hotel/bus/room assignment (see ApiBooking's
/// "detail-only fields" comment) — so on open this re-fetches the single
/// booking via GET /bookings/{id} and swaps in that fuller detail once it
/// lands, instead of showing "not assigned yet" for data that actually
/// exists server-side.
class OrderDetailSheet extends StatefulWidget {
  final Order order;

  /// الإشعار اللي فتح الصفحة (من البوب أب أو شاشة الإشعارات) — بيتميّز.
  final int? highlightNotificationId;
  const OrderDetailSheet({super.key, required this.order, this.highlightNotificationId});

  @override
  State<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<OrderDetailSheet>
    with LiveReload<OrderDetailSheet> {
  @override
  Future<void> onLiveUpdate() => _loadDetail();

  late Order _order;
  bool _loadingDetail = true;
  List<ApiNotification> _updates = [];
  bool _showAllUpdates = false;
  bool _payingNow = false;
  bool _cancelling = false;
  Map<String, dynamic>? _ext; // «تمديد الإقامة»

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final apiId = widget.order.apiId;
    if (apiId == null) {
      setState(() => _loadingDetail = false);
      return;
    }
    final state = context.read<AppState>();
    final results = await Future.wait([state.fetchBookingDetail(apiId), state.fetchBookingUpdates(apiId)]);
    if (!mounted) return;
    final detail = results[0] as ApiBooking?;
    setState(() {
      if (detail != null) {
        _order = detail.toOrder();
        _ext = detail.extension;
      }
      _updates = results[1] as List<ApiNotification>;
      _loadingDetail = false;
    });
    final hl = widget.highlightNotificationId;
    if (hl != null && _updates.any((n) => n.id == hl && !n.isRead)) {
      state.markNotificationRead(hl);
    }
  }

  Order get order => _order;

  /// Retry payment for a booking that was created but never paid (closed
  /// the payment screen, connection dropped, gateway declined, etc.).
  Future<void> _payNow() async {
    if (_payingNow) return;
    setState(() => _payingNow = true);
    await payForOrder(context, order);
    if (!mounted) return;
    setState(() => _payingNow = false);
    // Re-check the real server-side status either way — the WebView
    // redirect alone isn't proof of capture.
    await _loadDetail();
  }

  Future<void> _cancelBooking() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    final cancelled = await cancelOrder(context, order);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (cancelled) await _loadDetail();
  }

  /// Bottom sheet: pick days, see the price, send the request.
  Future<void> _openExtend() async {
    final ext = _ext;
    final apiId = widget.order.apiId;
    if (ext == null || apiId == null) return;
    final rate = (ext['rate'] as num?)?.toDouble() ?? 0;
    final persons = (ext['persons'] as num?)?.toInt() ?? 1;
    final maxDays = (ext['max_days'] as num?)?.toInt() ?? 30;
    final currency = '${ext['currency'] ?? ''}';
    final isFamily = ext['is_family'] == true;
    var days = 1;
    var sending = false;
    String f(num v) => v.toStringAsFixed(0);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('📅 ${tr('orders.extend.title')}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 4),
            Text(order.trip, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 16),
            Text(tr('orders.extend.days'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton.filledTonal(
                  onPressed: days > 1 ? () => setSheet(() => days--) : null, icon: const Icon(Icons.remove)),
              SizedBox(
                  width: 70,
                  child: Text('$days',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
              IconButton.filledTonal(
                  onPressed: days < maxDays ? () => setSheet(() => days++) : null, icon: const Icon(Icons.add)),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Text(
                    '$persons ${tr('orders.extend.persons')} × $days × ${f(rate)} $currency'
                    '${isFamily ? ' (${tr('orders.extend.family')})' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                const SizedBox(height: 4),
                Text('${tr('orders.extend.total')}: ${f(rate * persons * days)} $currency',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brandDark)),
              ]),
            ),
            const SizedBox(height: 8),
            Text(tr('orders.extend.note'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: sending
                    ? null
                    : () async {
                        setSheet(() => sending = true);
                        final (err, fresh) = await context.read<AppState>().requestBookingExtension(apiId, days);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        showAppToast(context, err ?? '✅ ${tr('orders.extend.sent')}');
                        if (err == null) {
                          setState(() => _ext = fresh ?? _ext);
                          _loadDetail();
                        }
                      },
                child: sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(tr('orders.extend.send'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Extend button / pending request / confirmed days.
  Widget _extensionBlock() {
    final ext = _ext;
    if (ext == null) return const SizedBox.shrink();
    final pending = ext['pending'] as Map<String, dynamic>?;
    final confirmedDays = (ext['confirmed_days'] as num?)?.toInt() ?? 0;
    final rows = <Widget>[];
    if (pending != null) {
      rows.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
        child: Text(
            '⏳ ${tr('orders.extend.pending')} — ${pending['days']} · ${((pending['amount'] as num?) ?? 0).toStringAsFixed(0)} ${pending['currency'] ?? ''}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF9A3412))),
      ));
    }
    if (confirmedDays > 0) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('✅ +$confirmedDays ${tr('orders.extend.confirmed_days')}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
      ));
    }
    if (ext['available'] == true) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandDark,
                side: const BorderSide(color: AppColors.brandLine),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _openExtend,
            icon: const FaIcon(FontAwesomeIcons.calendarPlus, size: 14),
            label: Text(tr('orders.extend.title'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ));
    }
    return Column(children: rows);
  }

  static Map<OrderStatus, (Color, Color, String)> get _statusStyle => {
        OrderStatus.pending: (
          Color(0xFFFEF3C7),
          Color(0xFFD97706),
          tr('orders.status.pending')
        ),
        OrderStatus.confirmed: (
          AppColors.blueLight,
          AppColors.blue,
          tr('orders.status.confirmed')
        ),
        OrderStatus.completed: (
          AppColors.greenLight,
          AppColors.green,
          tr('orders.status.completed')
        ),
        OrderStatus.cancelled: (
          Color(0xFFFFE4E4),
          Color(0xFFE84040),
          tr('orders.status.cancelled')
        ),
      };

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle[order.status]!;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(tr('orders.detail_title'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text)),
                if (_loadingDetail) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.blue)),
                ],
              ]),
              GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: AppColors.bg, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const FaIcon(FontAwesomeIcons.xmark,
                          size: 14, color: AppColors.muted))),
            ]),
            const SizedBox(height: 14),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: style.$1, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const FaIcon(FontAwesomeIcons.solidCircle,
                      size: 8, color: Colors.transparent),
                  Text(style.$3,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: style.$2)),
                ])),
            const SizedBox(height: 16),
            if (_updates.isNotEmpty) _updatesSection(),
            _section(tr('orders.section.trip_info'), FontAwesomeIcons.plane, [
              (tr('orders.field.order_number'), order.id, null),
              (
                tr('orders.field.trip'),
                '${order.emoji} ${tr(order.trip)}',
                null
              ),
              (
                tr('orders.field.departure_location'),
                order.departureCity,
                () => _openMap(context, order.departureCity)
              ),
              (tr('orders.field.provider'), order.provider, null),
              (tr('orders.field.travel_date'), order.date, null),
              (tr('orders.field.duration'), order.duration, null),
              (tr('orders.field.travelers_count'), order.pax, null),
            ]),
            if (order.bus != null)
              _section(tr('orders.section.bus_info'), FontAwesomeIcons.bus, [
                (tr('orders.field.bus_number'), order.bus!.num, null),
                (tr('orders.field.capacity'), order.bus!.cap, null),
                (
                  tr('orders.field.bus_supervisor'),
                  order.bus!.supervisor,
                  null
                ),
                (tr('orders.field.supervisor_phone'), order.bus!.phone, null),
              ]),
            _section(tr('orders.section.hotel_info'),
                FontAwesomeIcons.solidBuilding, [
              (tr('orders.field.hotel'), order.hotel.name, null),
              (tr('orders.field.rating'), order.hotel.stars, null),
              (tr('orders.field.location'), order.hotel.location, null),
            ]),
            _roomSection(order.hotel),
            _section(
                tr('orders.section.price_details'), FontAwesomeIcons.receipt, [
              (tr('orders.field.unit_price'), order.priceUnit, null),
              (tr('orders.field.people_count'), order.pax, null),
              (tr('orders.field.total'), order.total, null),
            ]),
            if (order.needsPayment) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _payingNow ? null : _payNow,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: _payingNow
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.creditCard,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(tr('orders.pay_now'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
            ],
            _extensionBlock(),
            if (order.canCancel) ...[
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _cancelling ? null : _cancelBooking,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E4),
                        borderRadius: BorderRadius.circular(20)),
                    child: _cancelling
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFFE84040)))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(FontAwesomeIcons.ban,
                                  size: 11, color: Color(0xFFE84040)),
                              const SizedBox(width: 6),
                              Text(tr('orders.cancel.button'),
                                  style: const TextStyle(
                                      color: Color(0xFFE84040),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            // WhatsApp contact button removed on request — the call/rate
            // action below is the only contact affordance here now.
            GestureDetector(
              onTap: () => showAppToast(
                  context,
                  order.status == OrderStatus.completed
                      ? tr('orders.rate_thanks_toast')
                      : tr('orders.calling_toast')),
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: order.status == OrderStatus.completed
                          ? AppColors.green
                          : AppColors.blue,
                      borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(tr(order.action),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700))),
            ),
          ],
        ),
      ),
    );
  }

  /// تحديثات الرحلة: تجمّعات الشركة + تسكين/باص/دفع الخاصة بالحجز ده.
  Widget _updatesSection() {
    final hl = widget.highlightNotificationId;
    var shown = _showAllUpdates ? _updates : _updates.take(3).toList();
    if (hl != null && !shown.any((n) => n.id == hl)) {
      shown = [..._updates.where((n) => n.id == hl), ...shown];
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const FaIcon(FontAwesomeIcons.bullhorn, size: 13, color: AppColors.blue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(tr('orders.section.updates'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
          ),
        ]),
        const SizedBox(height: 10),
        for (final n in shown) _updateTile(n, highlighted: n.id == hl),
        if (_updates.length > 3 && !_showAllUpdates)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAllUpdates = true),
              child: Text('${tr('orders.updates.show_all')} (${_updates.length})',
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
      ]),
    );
  }

  Widget _updateTile(ApiNotification n, {required bool highlighted}) {
    final (icon, bg, fg) = notificationStyleFor(n.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF8E6) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: highlighted ? const Color(0xFFD97706) : const Color(0xFFEDEFF3),
            width: highlighted ? 1.5 : 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
          alignment: Alignment.center,
          child: FaIcon(icon, size: 14, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.text)),
            if ((n.body ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(n.body!, style: const TextStyle(fontSize: 12, color: AppColors.text, height: 1.5)),
            ],
            const SizedBox(height: 4),
            Text(n.timeAgo, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
          ]),
        ),
      ]),
    );
  }

  Widget _section(String title, FaIconData icon,
      List<(String, String, VoidCallback?)> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          FaIcon(icon, size: 13, color: AppColors.blue),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text))
        ]),
        const SizedBox(height: 10),
        for (final r in rows)
          GestureDetector(
            onTap: r.$3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Text(r.$1,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(tr(r.$2),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: r.$3 != null ? AppColors.blue : AppColors.text,
                          decoration: r.$3 != null
                              ? TextDecoration.underline
                              : TextDecoration.none)),
                ),
                if (r.$3 != null) ...[
                  const SizedBox(width: 6),
                  const FaIcon(FontAwesomeIcons.locationDot,
                      size: 12, color: AppColors.blue),
                ],
              ]),
            ),
          ),
      ]),
    );
  }

  Future<void> _openMap(BuildContext context, String cityKey) async {
    final query = Uri.encodeComponent(tr(cityKey));
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showAppToast(context, tr('orders.map_open_failed'));
    }
  }

  Widget _roomSection(OrderHotelInfo hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const FaIcon(FontAwesomeIcons.bed, size: 13, color: AppColors.blue),
          const SizedBox(width: 6),
          Text(tr('orders.section.room_details'),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
        ]),
        const SizedBox(height: 10),
        for (final r in [
          (tr('orders.field.room_number'), hotel.room),
          (tr('orders.field.room_type'), hotel.roomType)
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Text(r.$1,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(tr(r.$2),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
            ]),
          ),
        if (hotel.roommates.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(tr('orders.section.roommates'),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
          for (final name in hotel.roommates)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const FaIcon(FontAwesomeIcons.solidUser,
                    size: 12, color: AppColors.muted),
                const SizedBox(width: 8),
                Text(tr(name),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ]),
            ),
        ],
      ]),
    );
  }
}
