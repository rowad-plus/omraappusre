import 'package:flutter/material.dart';
import 'package:flutter_paymob_sdk/flutter_paymob_sdk.dart';
import '../core/theme/app_colors.dart';
import '../screens/booking/neoleap_payment_screen.dart';

/// Opens the payment for a `payment_url` returned by
/// `POST /bookings/{id}/pay`.
///
/// Paymob Unified Checkout URLs (`.../unifiedcheckout/?publicKey=..&
/// clientSecret=..`) run in Paymob's native SDK — no web page, no
/// redirect back into our website. Anything else (e.g. NeoLeap) falls back
/// to the in-app WebView.
///
/// Returns `true` when paid, `false` when the payment failed, `null` when
/// the customer cancelled or the result is still pending. Either way the
/// booking's real status comes from the server (Paymob's webhook), so
/// callers should re-fetch it.
Future<bool?> launchPayment(BuildContext context, String paymentUrl) async {
  final uri = Uri.tryParse(paymentUrl);
  final publicKey = uri?.queryParameters['publicKey'];
  final clientSecret = uri?.queryParameters['clientSecret'];

  if (uri != null &&
      uri.path.contains('unifiedcheckout') &&
      publicKey != null &&
      publicKey.isNotEmpty &&
      clientSecret != null &&
      clientSecret.isNotEmpty) {
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
    return switch (result.status) {
      PaymentStatus.successful => true,
      PaymentStatus.failure => false,
      _ => null,
    };
  }

  if (!context.mounted) return null;
  return Navigator.of(context).push<bool?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => NeoLeapPaymentScreen(paymentUrl: paymentUrl),
    ),
  );
}
