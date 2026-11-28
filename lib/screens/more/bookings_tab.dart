import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../state/app_state.dart';
import '../../widgets/sub_page_header.dart';
import '../auth/login_sheet.dart';
import 'orders_screen.dart';

/// «حجوزاتي» bottom-bar tab (2026-11-28, replaces «صمّم عمرتك» there;
/// the design page still opens from the home page).
class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AppState>().isLoggedIn;
    if (loggedIn) return const OrdersScreen(key: ValueKey('bookings-tab'), inTab: true);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: tr('orders.title'), showBack: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const FaIcon(FontAwesomeIcons.calendarCheck, size: 44, color: Color(0xFFB8892F)),
            const SizedBox(height: 14),
            Text(tr('orders.title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8892F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => openLoginSheet(context, toSearch: false),
              child: Text(tr('nav.login_to_see_bookings'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }
}
