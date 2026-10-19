import 'package:flutter/material.dart';
import 'package:flutter_paymob_sdk/flutter_paymob_sdk.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../screens/booking/neoleap_payment_screen.dart';
import '../state/app_state.dart';

/// Opens the payment for a `payment_url` returned by
/// `POST /bookings/{id}/pay`.
///
/// Paymob Unified Checkout URLs (`.../unifiedcheckout/?publicKey=..&
/// clientSecret=..`) run in Paymob's native SDK — no web page, no
/// redirect back into our website. Anything else (e.g. NeoLeap) falls back
/// to the in-app WebView.
///
/// Returns `true` when paid, `false` when the payment failed, `null` when
/// the customer cancelled or the result is still pending. After the SDK
/// closes, the server is asked to confirm with Paymob ([AppState.
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
    final result = await PaymobService().payWithPaymob(
      publicKey: publicKey,
      clientSecret: clientSecret,
      customization: const PaymobCustomization(
        appName: 'Omraway',
        buttonBackgroundColor: AppColors.brand,
        buttonTextColor: Colors.white,
        showSaveCard: false,
        showTransactionResult: false,
      ),
    );
    final sdkResult = switch (result.status) {
      PaymentStatus.successful => true,
      PaymentStatus.failure => false,
      _ => null,
    };
    if (sdkResult == false) return false;

    // Paymob may need a few seconds to settle — retry while the SDK said
    // paid; a single check otherwise (cancelled after paying, pending).
    final attempts = sdkResult == true ? 4 : 1;
    for (var i = 0; i < attempts; i++) {
      if (i > 0) await Future.delayed(const Duration(seconds: 2));
      if (await state.verifyPayment(bookingId) == true) return true;
    }
    return sdkResult;
  }

  if (!context.mounted) return null;
  return Navigator.of(context).push<bool?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => NeoLeapPaymentScreen(paymentUrl: paymentUrl),
    ),
  );
}
