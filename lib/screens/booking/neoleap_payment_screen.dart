import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';

/// Full-screen in-app WebView for a NeoLeap Bank-Hosted payment page — the
/// card form is entirely NeoLeap's own cross-origin page (never touches our
/// app or server), but it stays inside this screen instead of kicking the
/// user out to an external browser. Detects NeoLeap's own return/error
/// callback URLs (our server's `/payments/neoleap/return` and `/error`
/// routes — see `PaymentController`) and stops there rather than letting
/// those web-session-only pages actually render inside the WebView.
///
/// Pops with `true` once NeoLeap redirects to the return URL (payment
/// attempted — the caller must re-check the booking's real status via the
/// API, since the redirect alone doesn't guarantee `captured`), `false` if
/// NeoLeap redirects to the error URL, or `null` if the user closes the
/// screen manually before either happens.
class NeoLeapPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  const NeoLeapPaymentScreen({super.key, required this.paymentUrl});

  @override
  State<NeoLeapPaymentScreen> createState() => _NeoLeapPaymentScreenState();
}

class _NeoLeapPaymentScreenState extends State<NeoLeapPaymentScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resolved = false;

  /// Paymob's return (`/payments/paymob/return?...&success=true`) is let
  /// through once so the server can record it; the result is remembered
  /// and the screen closes as soon as the server redirects anywhere else
  /// on our site — the website itself must never render in here (it has
  /// no web session and would bounce to the login page).
  bool? _paymobSuccess;

  static bool _isOurSite(Uri u) =>
      u.host.endsWith('omraway.com') || u.host.endsWith('umrati.net');

  /// Shared by navigation requests and page starts (Android doesn't send
  /// POST form submissions — NeoLeap's return — through the delegate).
  NavigationDecision _route(String url) {
    final uri = Uri.tryParse(url);
    // Paymob's own completion page (used for app payments).
    if (uri != null && uri.path.contains('/api/acceptance/post_pay')) {
      _finish(uri.queryParameters['success'] == 'true');
      return NavigationDecision.prevent;
    }
    if (uri == null || !_isOurSite(uri)) return NavigationDecision.navigate;
    final path = uri.path;
    if (path.contains('/payments/neoleap/return')) {
      _finish(true);
      return NavigationDecision.prevent;
    }
    if (path.contains('/payments/neoleap/error')) {
      _finish(false);
      return NavigationDecision.prevent;
    }
    if (path.contains('/payments/paymob/return')) {
      _paymobSuccess = uri.queryParameters['success'] == 'true';
      return NavigationDecision.navigate;
    }
    // Any other page of ours = the gateway flow is over.
    _finish(_paymobSuccess ?? true);
    return NavigationDecision.prevent;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (_route(url) == NavigationDecision.prevent) return;
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) => _route(request.url),
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _finish(bool result) {
    if (_resolved || !mounted) return;
    _resolved = true;
    Navigator.of(context).pop(result);
  }

  Future<bool> _confirmClose() async {
    if (_resolved) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('booking.payment.closeConfirmTitle')),
        content: Text(tr('booking.payment.closeConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('booking.payment.closeConfirmNo')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('booking.payment.closeConfirmYes')),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmClose() && mounted) {
          Navigator.of(context).pop(null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('booking.payment.webviewTitle')),
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmClose() && mounted) {
                Navigator.of(context).pop(null);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
