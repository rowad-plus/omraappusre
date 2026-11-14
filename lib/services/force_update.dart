import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Forced update (2026-11-14).
///
/// The server file `storage/app/app_versions.json` (served at
/// GET /api/v1/front/app-version) holds, per app and platform, the lowest
/// version still allowed:
///   {"customer": {"android": {"min_version": "1.0.30", "store_url": "..."}, "ios": {...}}, "business": {...}}
/// An older app shows a full screen that cannot be closed until it is updated.
/// Any network/parse error lets the app run normally (never lock users out
/// because the check failed). Re-checked whenever the app returns to the
/// foreground.
class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({
    super.key,
    required this.appKey,
    required this.defaultStoreUrls,
    required this.child,
  });

  /// 'customer' or 'business' — the key in app_versions.json.
  final String appKey;

  /// Fallback store links: {'android': ..., 'ios': ...}.
  final Map<String, String> defaultStoreUrls;
  final Widget child;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate>
    with WidgetsBindingObserver {
  static const _endpoint = 'https://omraway.com/api/v1/front/app-version';
  String? _storeUrl; // non-null = update required
  String? _messageAr;
  String? _messageEn;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  String? get _platform {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  Future<void> _check() async {
    final platform = _platform;
    if (platform == null || _checking) return;
    _checking = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final res = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final all = jsonDecode(res.body);
      final cfg = all is Map ? all[widget.appKey] : null;
      final p = cfg is Map ? cfg[platform] : null;
      if (p is! Map) return;
      final min = p['min_version']?.toString() ?? '';
      final blocked = min.isNotEmpty && compareVersions(info.version, min) < 0;
      final url = p['store_url']?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        _storeUrl = blocked
            ? (url.isNotEmpty ? url : (widget.defaultStoreUrls[platform] ?? ''))
            : null;
        _messageAr = cfg is Map ? cfg['message_ar']?.toString() : null;
        _messageEn = cfg is Map ? cfg['message_en']?.toString() : null;
      });
    } catch (_) {
      // network / parse problem -> let the app run
    } finally {
      _checking = false;
    }
  }

  /// -1 if a < b, 0 if equal, 1 if a > b ("1.0.9" < "1.0.10").
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < 3; i++) {
      final xi = i < x.length ? x[i] : 0, yi = i < y.length ? y[i] : 0;
      if (xi != yi) return xi < yi ? -1 : 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_storeUrl == null) return widget.child;
    final ar = Directionality.of(context) == TextDirection.rtl;
    final msg = ar
        ? ((_messageAr ?? '').isNotEmpty
            ? _messageAr!
            : 'يوجد إصدار جديد من التطبيق. يجب التحديث للمتابعة.')
        : ((_messageEn ?? '').isNotEmpty
            ? _messageEn!
            : 'A new version of the app is available. Please update to continue.');
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update_rounded,
                    size: 72, color: Color(0xFFB8893B)),
                const SizedBox(height: 20),
                Text(ar ? 'تحديث مطلوب' : 'Update required',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937))),
                const SizedBox(height: 12),
                Text(msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, height: 1.6, color: Color(0xFF4B5563))),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB8893B)),
                    onPressed: () => launchUrl(Uri.parse(_storeUrl!),
                        mode: LaunchMode.externalApplication),
                    child: Text(ar ? 'تحديث الآن' : 'Update now',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
