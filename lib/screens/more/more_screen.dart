import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../services/live_updates.dart';
import '../../state/app_state.dart';
import '../../widgets/app_header.dart';
import '../auth/login_sheet.dart';
import '../umrah_results/umrah_results_screen.dart';
import 'comparisons_screen.dart';
import 'favorites_screen.dart';
import 'my_trips_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'contact_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'about_screen.dart';

/// Mirrors `#pg-more` — the "المزيد" menu page.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with LiveReload<MoreScreen> {
  @override
  Future<void> onLiveUpdate() => _loadUnreadCount();

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final state = context.read<AppState>();
    if (!state.isLoggedIn) return;
    final count = await state.fetchUnreadNotificationsCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loggedIn = state.isLoggedIn;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppHeader(
        onSearchTap: () => _push(context, const UmrahResultsScreen()),
        onSignInTap: () => openLoginSheet(context),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          GestureDetector(
            onTap: () => loggedIn
                ? _push(context, const ProfileScreen())
                : openLoginSheet(context),
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: AppColors.blueGradient,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(
                    width: 46,
                    height: 46,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2)),
                    alignment: Alignment.center,
                    child: (loggedIn &&
                            (state.userAvatarUrl ?? '').isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: state.userAvatarUrl!,
                            fit: BoxFit.cover,
                            width: 46,
                            height: 46,
                            errorWidget: (_, __, ___) => const FaIcon(
                                FontAwesomeIcons.solidUser,
                                color: Colors.white,
                                size: 20))
                        : const FaIcon(FontAwesomeIcons.solidUser,
                            color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            loggedIn
                                ? state.userName
                                : tr('more_menu.login_prompt'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Text(
                            loggedIn
                                ? tr('more_menu.view_profile')
                                : tr('more_menu.login_subtitle'),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ]),
                ),
                FaIcon(
                    Directionality.of(context) == TextDirection.rtl
                        ? FontAwesomeIcons.chevronLeft
                        : FontAwesomeIcons.chevronRight,
                    color: Colors.white70,
                    size: 13),
              ]),
            ),
          ),
          _MenuSection(items: [
            _MenuItem(FontAwesomeIcons.solidHeart, const Color(0xFFFFE4E4),
                const Color(0xFFE84040), tr('more_menu.favorites'),
                onTap: () => loggedIn
                    ? _push(context, const FavoritesScreen())
                    : openLoginSheet(context)),
            _MenuItem(FontAwesomeIcons.planeDeparture, AppColors.blueLight,
                AppColors.blue, tr('more_menu.my_trips'),
                onTap: () => loggedIn
                    ? _push(context, const MyTripsScreen())
                    : openLoginSheet(context)),
            _MenuItem(FontAwesomeIcons.calendarDays, const Color(0xFFF3F4F6),
                AppColors.muted, tr('more_menu.my_bookings'),
                onTap: () => loggedIn
                    ? _push(context, const OrdersScreen())
                    : openLoginSheet(context)),
            _MenuItem(FontAwesomeIcons.scaleBalanced, const Color(0xFFFBF5E8),
                const Color(0xFFB8892F), tr('more_menu.comparisons'),
                onTap: () => loggedIn
                    ? _push(context, const ComparisonsScreen())
                    : openLoginSheet(context)),
          ]),
          _MenuSection(items: [
            _MenuItem(FontAwesomeIcons.solidUser, AppColors.greenLight,
                AppColors.green, tr('more_menu.profile'),
                onTap: () => _push(context, const ProfileScreen())),
            _MenuItem(FontAwesomeIcons.solidBell, const Color(0xFFEEE8FF),
                const Color(0xFF7C3AED), tr('more_menu.notifications'),
                badge: _unreadCount > 0 ? '$_unreadCount' : null,
                badgeColor: const Color(0xFFE84040), onTap: () async {
              if (!loggedIn) {
                openLoginSheet(context);
                return;
              }
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()));
              _loadUnreadCount();
            }),
            _MenuItem(FontAwesomeIcons.gear, const Color(0xFFF3F4F6),
                AppColors.muted, tr('more_menu.settings'),
                onTap: () => _push(context, const SettingsScreen())),
          ]),
          _MenuSection(items: [
            _MenuItem(FontAwesomeIcons.solidCircleQuestion, AppColors.blueLight,
                AppColors.blue, tr('more_menu.help_center'),
                onTap: () => _push(context, const HelpScreen())),
            _MenuItem(FontAwesomeIcons.headset, AppColors.greenLight,
                AppColors.green, tr('more_menu.contact_us'),
                onTap: () => _push(context, const ContactScreen())),
          ]),
          _MenuSection(items: [
            _MenuItem(FontAwesomeIcons.fileContract, const Color(0xFFFEF3C7),
                const Color(0xFFD97706), tr('more_menu.terms'),
                onTap: () => _push(context, const TermsScreen())),
            _MenuItem(FontAwesomeIcons.shieldHalved, const Color(0xFFEEE8FF),
                const Color(0xFF7C3AED), tr('more_menu.privacy'),
                onTap: () => _push(context, const PrivacyScreen())),
            _MenuItem(FontAwesomeIcons.circleInfo, AppColors.blueLight,
                AppColors.blue, tr('more_menu.about'),
                onTap: () => _push(context, const AboutScreen())),
          ]),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(tr('more_menu.footer'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final FaIconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? badge;
  final Color badgeColor;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.iconBg, this.iconColor, this.label,
      {this.badge, this.badgeColor = AppColors.blue, required this.onTap});
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < items.length; i++)
          _row(context, items[i], isLast: i == items.length - 1),
      ]),
    );
  }

  Widget _row(BuildContext context, _MenuItem item, {required bool isLast}) {
    return InkWell(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: item.iconBg, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: FaIcon(item.icon, size: 16, color: item.iconColor)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(item.label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text))),
          if (item.badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: item.badgeColor,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(item.badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
          ],
          FaIcon(
              Directionality.of(context) == TextDirection.rtl
                  ? FontAwesomeIcons.chevronLeft
                  : FontAwesomeIcons.chevronRight,
              size: 12,
              color: AppColors.muted),
        ]),
      ),
    );
  }
}
