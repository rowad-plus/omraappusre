import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order.dart';
import '../../services/live_updates.dart';
import '../../state/app_state.dart';
import '../../widgets/order_card.dart';
import '../../widgets/sub_page_header.dart';
import '../../l10n/translations.dart';

/// Mirrors `#pg-orders` — "حجوزاتي", the *complete* booking archive (every
/// status, ever made), split into الحالية / مكتملة / ملغاة tabs. Distinct
/// from `MyTripsScreen` ("رحلاتي"), which is just the current/upcoming
/// slice of this same data — see that file for why they're separate.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.inTab = false});

  /// Shown as the «حجوزاتي» bottom-bar tab (no back button).
  final bool inTab;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with LiveReload<OrdersScreen> {
  @override
  Future<void> onLiveUpdate() => _load();

  int _tab = 0;
  bool _loading = true;
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookings = await context.read<AppState>().fetchBookings();
    if (!mounted) return;
    // Bookings never disappear, so an empty result on a refresh means a
    // failed request — keep what's on screen instead of blanking it.
    if (bookings.isEmpty && _orders.isNotEmpty) return;
    setState(() {
      // Nearest-upcoming-first within each tab — the backend returns these
      // newest-created-first, which isn't the same thing as soonest-to-depart.
      _orders = bookings.map((b) => b.toOrder()).toList()
        ..sort(compareOrdersByUpcomingDate);
      _loading = false;
    });
  }

  static List<String> get _tabs => [
        tr('orders.tab_current'),
        tr('orders.tab_completed'),
        tr('orders.tab_cancelled')
      ];

  bool _matchesTab(Order order) {
    switch (_tab) {
      case 0:
        return order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed;
      case 1:
        return order.status == OrderStatus.completed;
      default:
        return order.status == OrderStatus.cancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders.where(_matchesTab).toList();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: tr('orders.title'), showBack: !widget.inTab),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    margin: EdgeInsetsDirectional.only(
                        end: i < _tabs.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: i == _tab ? AppColors.blue : Colors.white,
                      border: Border.all(
                          color: i == _tab ? AppColors.blue : AppColors.border,
                          width: 1.5),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(_tabs[i],
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: i == _tab ? Colors.white : AppColors.muted)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))))
          else if (orders.isEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                    child: Text(tr('orders.no_trips'),
                        style: const TextStyle(color: AppColors.muted)))),
          for (final order in orders) OrderCard(order: order, onChanged: _load),
        ],
      ),
    );
  }
}
