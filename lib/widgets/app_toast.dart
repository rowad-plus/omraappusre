import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/translations.dart';

/// Copies a general link to the لقطات feed to the clipboard — there's no
/// per-post detail page on the site to deep-link to (only feed/API routes
/// exist), so this shares the feed itself rather than fabricate a URL that
/// doesn't resolve. Shared by the feed's post cards and the fullscreen
/// TikTok-style viewer.
Future<void> sharePost(BuildContext context) async {
  await Clipboard.setData(
      const ClipboardData(text: 'https://omraway.com/ar/timeline'));
  if (context.mounted) {
    showAppToast(context, tr('photos.link_copied_toast'));
  }
}

/// Mirrors the `.toast-msg` pill in rehlaty.html: a dark rounded pill
/// centered near the bottom of the screen that fades in/out.
void showAppToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _ToastWidget(
      message: message,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDone;
  const _ToastWidget({required this.message, required this.onDone});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _opacity,
        // Overlay entries have no Material ancestor; without one Flutter
        // draws its yellow double underline under the text.
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
