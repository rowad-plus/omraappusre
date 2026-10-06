import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';
import '../l10n/translations.dart';
import '../models/order.dart';
import '../screens/more/order_detail_sheet.dart';
import 'app_toast.dart';
import 'order_actions.dart';

/// A single booking/trip card — shared by `OrdersScreen` (the full
/// "حجوزاتي" archive, every status) and `MyTripsScreen` (the focused
/// "رحلاتي" list, current/upcoming only), so the two screens' cards never
/// drift apart visually.
///
/// Carries the same action buttons as the website's "حجوزاتي" card
/// (`profile-bookings.blade.php`): ادفع الآن / إلغاء الحجز / تفاصيل التسكين /
/// عرض الرحلة, with the same show-rules. [onChanged] lets the parent list
/// re-fetch after a payment or cancellation changes a booking's status.
class OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onChanged;
  const OrderCard({super.key, required this.order, this.onChanged});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _paying = false;
  bool _cancelling = false;
  bool _openingTrip = false;

  Order get order => widget.order;

  Future<void> _openDetails() async {
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => OrderDetailSheet(order: order));
    // The sheet can pay/cancel too — refresh the list behind it.
    widget.onChanged?.call();
  }

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    await payForOrder(context, order);
    if (!mounted) return;
    setState(() => _paying = false);
    widget.onChanged?.call();
  }

  Future<void> _cancel() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    final cancelled = await cancelOrder(context, order);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (cancelled) widget.onChanged?.call();
  }

  Future<void> _viewTrip() async {
    if (_openingTrip) return;
    setState(() => _openingTrip = true);
    await openOrderTrip(context, order);
    if (mounted) setState(() => _openingTrip = false);
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

  /// `Y-m-d` → `d/m/Y`, the website card's date format.
  static String _fmtDate(String? ymd) {
    final d = ymd == null ? null : DateTime.tryParse(ymd);
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle[order.status]!;
    return GestureDetector(
      onTap: _openDetails,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 84,
                height: 84,
                child: order.networkImage != null
                    ? CachedNetworkImage(
                        imageUrl: order.networkImage!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                            child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (_, __, ___) => _emojiThumb(),
                      )
                    : _emojiThumb(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(order.trip),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 14, runSpacing: 4, children: [
                      _meta(FontAwesomeIcons.user,
                          '${order.personsCount} ${order.personsCount == 1 ? tr('orders.person_singular') : tr('orders.persons_plural')}'),
                      _meta(FontAwesomeIcons.dollarSign, tr(order.total)),
                    ]),
                  ]),
            ),
          ]),
          const SizedBox(height: 10),
          // Booking/departure dates — the website card's grey dates strip.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
            child: Wrap(spacing: 14, runSpacing: 6, children: [
              _dateItem(FontAwesomeIcons.calendar,
                  tr('orders.booking_date_label'), _fmtDate(order.bookingDate)),
              _dateItem(FontAwesomeIcons.planeDeparture,
                  tr('orders.departure_date_label'),
                  _fmtDate(order.departureDate)),
            ]),
          ),
          const SizedBox(height: 10),
          _actions(),
          const SizedBox(height: 10),
          Row(children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: style.$1, borderRadius: BorderRadius.circular(20)),
                child: Text('${_statusEmoji[order.status]} ${style.$3}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: style.$2))),
            const Spacer(),
            Text('${tr('orders.booking_ref_label')} ${order.id}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ]),
      ),
    );
  }

  static const _statusEmoji = {
    OrderStatus.pending: '⏳',
    OrderStatus.confirmed: '✅',
    OrderStatus.completed: '✅',
    OrderStatus.cancelled: '❌',
  };

  Widget _emojiThumb() => Container(
      color: AppColors.bg,
      alignment: Alignment.center,
      child: Text(order.emoji, style: const TextStyle(fontSize: 32)));

  Widget _meta(FaIconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 11, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      );

  Widget _dateItem(FaIconData icon, String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 11, color: AppColors.muted),
          const SizedBox(width: 4),
          Text('$label ',
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
        ],
      );

  Widget _actions() {
    return Wrap(spacing: 6, runSpacing: 6, children: [
      if (order.needsPayment)
        _actionBtn(
          label: tr('orders.pay_now'),
          icon: FontAwesomeIcons.creditCard,
          fg: Colors.white,
          bg: const Color(0xFFB8892F),
          loading: _paying,
          onTap: _pay,
        ),
      if (order.canCancel)
        _actionBtn(
          label: tr('orders.cancel.button'),
          icon: FontAwesomeIcons.circleXmark,
          fg: const Color(0xFFDC2626),
          bg: const Color(0xFFFEF2F2),
          loading: _cancelling,
          onTap: _cancel,
        ),
      _actionBtn(
        label: tr('orders.accommodation_details'),
        icon: FontAwesomeIcons.suitcase,
        fg: AppColors.text,
        bg: Colors.white,
        onTap: _openDetails,
      ),
      if (order.tripId != null)
        _actionBtn(
          label: tr('orders.view_trip'),
          icon: FontAwesomeIcons.eye,
          fg: const Color(0xFFB8892F),
          bg: const Color(0xFFFBF5E8),
          loading: _openingTrip,
          onTap: _viewTrip,
        ),
      if (order.status == OrderStatus.completed)
        _actionBtn(
          label: tr('orders.rate_trip'),
          icon: FontAwesomeIcons.star,
          fg: AppColors.green,
          bg: AppColors.greenLight,
          onTap: () => showAppToast(context, tr('orders.rate_thanks_toast')),
        ),
    ]);
  }

  Widget _actionBtn({
    required String label,
    required FaIconData icon,
    required Color fg,
    required Color bg,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: bg,
            border: Border.all(
                color: bg == Colors.white ? AppColors.border : bg),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          loading
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg))
              : FaIcon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ]),
      ),
    );
  }
}

/// Nearest-departure-first comparator shared by both screens — falls back
/// to unparseable/missing dates sorting last rather than crashing or
/// silently keeping the backend's `created_at`-descending order.
int compareOrdersByUpcomingDate(Order a, Order b) {
  final da = DateTime.tryParse(a.date);
  final db = DateTime.tryParse(b.date);
  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;
  return da.compareTo(db);
}
