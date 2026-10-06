import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../l10n/translations.dart';
import '../models/country.dart';
import '../screens/more/profile_screen.dart';
import '../state/app_state.dart';
import '../state/country_state.dart';
import 'country_picker_sheet.dart';

/// Mirrors `.hdr` — the 54px top bar with logo, search icon and the
/// sign-in / "حسابي" pill.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSignInTap;
  final Color? bg;

  const AppHeader({super.key, this.onSearchTap, this.onSignInTap, this.bg});

  @override
  Size get preferredSize => const Size.fromHeight(54);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      // Logo/title block sits 14px from its edge; the icon group's own 10px
      // edge gap is applied on the group itself (see below), independent of
      // this padding.
      padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      // Exactly two blocks, pushed to opposite ends by spaceBetween — which
      // end each lands on flips automatically with Directionality, no
      // manual RTL/LTR branching needed.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/omraway_kaaba.png',
                    width: 40, fit: BoxFit.contain),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(tr('header.appName'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text)),
                ),
              ],
            ),
          ),
          _HeaderIconGroup(onSearchTap: onSearchTap, onSignInTap: onSignInTap),
        ],
      ),
    );
  }
}

/// The country/search/account icon trio, always moved and spaced as one
/// unit. Internal gaps between the three icons are fixed here and never
/// change with direction or position — only the group's placement (via the
/// parent's spaceBetween) responds to RTL/LTR.
class _HeaderIconGroup extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSignInTap;

  const _HeaderIconGroup({this.onSearchTap, this.onSignInTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loggedIn = state.isLoggedIn;
    final avatarUrl = loggedIn ? state.userAvatarUrl : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CountryButton(),
        const SizedBox(width: 12),
        _HdrIcon(icon: FontAwesomeIcons.magnifyingGlass, onTap: onSearchTap),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: loggedIn
              ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()))
              : onSignInTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
                border: avatarUrl != null
                    ? Border.all(color: AppColors.brandLine, width: 1.5)
                    : null),
            // Profile photo uploaded on the website, else the person icon.
            child: avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const FaIcon(
                        FontAwesomeIcons.userCheck,
                        color: Colors.white,
                        size: 13),
                  )
                : FaIcon(
                    loggedIn
                        ? FontAwesomeIcons.userCheck
                        : FontAwesomeIcons.solidUser,
                    color: Colors.white,
                    size: 13),
          ),
        ),
      ],
    );
  }
}

class _CountryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openCountryPickerSheet(context),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: CountryState.detecting,
            builder: (context, detecting, _) {
              if (detecting) {
                return const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return ValueListenableBuilder<Country?>(
                valueListenable: CountryState.selected,
                builder: (context, country, __) {
                  if (country == null) {
                    return const FaIcon(FontAwesomeIcons.globe,
                        size: 14, color: AppColors.muted);
                  }
                  return Text(country.flagEmoji,
                      style: const TextStyle(fontSize: 18));
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HdrIcon extends StatelessWidget {
  final FaIconData icon;
  final VoidCallback? onTap;
  const _HdrIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: FaIcon(icon, size: 14, color: AppColors.muted),
      ),
    );
  }
}
