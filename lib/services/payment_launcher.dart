import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/booking/neoleap_payment_screen.dart';
import '../state/app_state.dart';

/// Opens the payment for a `payment_url` returned by
/// `POST /bookings/{id}/pay`.
///
/// Paymob Unified Checkout URLs (`.../unifiedcheckout/?publicKey=..&
/// clientSecret=..`) open our own card form (omraway.com/pay/app, Paymob
/// Pixel) in the in-app WebView. Anything else (e.g. NeoLeap) opens the
/// gateway's page in the same WebView.
///
/// Returns `true` when paid, `false` when the payment failed, `null` when
/// the customer cancelled or the result is still pending. After the card
/// form closes, the server is asked to confirm with Paymob ([AppState.
/// verifyPayment]) so the booking is recorded as paid right away; callers
/// should still re-fetch the booking.
Future<bool?> launchPayment(BuildContext context, String paymentUrl,
    {required int bookingId}) async {
  final uri = Uri.tryParse(paymentUrl);
  final publicKey = uri?.queryParameters['publicKey'];
  final clientSecret = uri?.queryParameters['clientSecret'];

  if (uri != null &&
      uri.path.contains('unifiedcheckout') &&
      publicKey != null &&
      publicKey.isNotEmpty &&
      clientSecret != null &&
      clientSecret.isNotEmpty) {
    final state = context.read<AppState>();
    // Our own card form (Paymob Pixel on omraway.com/pay/app) instead of the
    // native SDK, whose screen always shows Paymob's logo and merchant name.
    // The keys go in the fragment, so they never reach server logs.
    final formUrl = Uri.https('omraway.com', '/pay/app').replace(
        fragment: 'pk=${Uri.encodeComponent(publicKey)}'
            '&cs=${Uri.encodeComponent(clientSecret)}');
    // The web build has no in-app WebView: open the form in a new tab.
    if (kIsWeb) {
      await launchUrl(formUrl, webOnlyWindowName: '_blank');
      return null;
    }
    final formResult = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NeoLeapPaymentScreen(paymentUrl: formUrl.toString()),
      ),
    );
    if (formResult == false) return false;

    // Paymob may need a few seconds to settle — retry while the form said
    // paid; a single check otherwise (cancelled after paying, pending).
    final attempts = formResult == true ? 4 : 1;
    for (var i = 0; i < attempts; i++) {
      if (i > 0) await Future.delayed(const Duration(seconds: 2));
      if (await state.verifyPayment(bookingId) == true) return true;
    }
    return formResult;
  }

  if (!context.mounted) return null;
  return Navigator.of(context).push<bool?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => NeoLeapPaymentScreen(paymentUrl: paymentUrl),
    ),
  );
}
