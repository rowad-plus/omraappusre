import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../l10n/translations.dart';
import '../models/order.dart';
import '../services/payment_launcher.dart';
import '../screens/trip_detail/trip_detail_screen.dart';
import '../state/app_state.dart';
import 'app_toast.dart';

/// Booking actions shared by `OrderCard` and `OrderDetailSheet`, so the
/// card's buttons (matching the website's "حجوزاتي" card) and the sheet's
/// buttons run the exact same flow.

/// Opens the NeoLeap payment WebView for [order] — same flow as the initial
/// booking sheet (`BookingSheet._startPayment`). Returns once the attempt
/// finishes; callers should re-fetch the booking afterwards either way,
/// since the WebView redirect alone isn't proof of capture.
Future<void> payForOrder(BuildContext context, Order order) async {
  final apiId = order.apiId;
  if (apiId == null) return;

  final result = await context.read<AppState>().initiatePayment(apiId);
  if (!context.mounted) return;

  if (result.paymentUrl == null) {
    showAppToast(
        context, '⚠️ ${result.error ?? tr('booking.payment.startError')}');
    return;
  }

  final paid = await launchPayment(context, result.paymentUrl!);
  if (!context.mounted) return;

  if (paid == true) {
    showAppToast(context, '✅ ${tr('booking.payment.success')}');
  } else if (paid == false) {
    showAppToast(context, '⚠️ ${tr('booking.payment.failed')}');
  }
}

/// Asks for confirmation, then cancels [order]. Only offered when
/// [Order.canCancel] is true; the backend re-checks the same rule anyway.
/// Returns true if the booking was actually cancelled.
Future<bool> cancelOrder(BuildContext context, Order order) async {
  final apiId = order.apiId;
  if (apiId == null) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('orders.cancel.confirmTitle')),
      content: Text(tr('orders.cancel.confirmBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr('orders.cancel.confirmNo')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(tr('orders.cancel.confirmYes'),
              style: const TextStyle(color: AppColors.red)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final error = await context.read<AppState>().cancelBooking(apiId);
  if (!context.mounted) return false;

  if (error != null) {
    showAppToast(context, '⚠️ $error');
    return false;
  }
  showAppToast(context, '✅ ${tr('orders.cancel.success')}');
  return true;
}

/// Fetches [order]'s trip and opens its detail page — the website card's
/// "عرض الرحلة" link.
Future<void> openOrderTrip(BuildContext context, Order order) async {
  final tripId = order.tripId;
  if (tripId == null) return;
  final full = await context.read<AppState>().fetchTripDetail(tripId);
  if (!context.mounted) return;
  if (full == null) {
    showAppToast(context, tr('orders.view_trip_error'));
    return;
  }
  Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripDetailScreen(trip: full.toTrip())));
}
