import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/umrah/umrah_screen.dart';
import 'screens/umrah_results/umrah_results_screen.dart';
import 'screens/design/design_hub_screen.dart';
import 'screens/photos/photos_screen.dart';
import 'screens/more/more_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'data/country_catalog.dart';
import 'services/location_service.dart';
import 'state/country_state.dart';
import 'state/nav_state.dart';
import 'widgets/country_picker_sheet.dart';

/// Mirrors the `<nav class="bnav">` + the 4 top-level `.pg` pages it
/// switches between (umrah / design / photos / more).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// The app opens straight onto the search screen — once per app launch
  /// (AppShell is re-created on every language switch).
  static bool _openedSearchOnLaunch = false;

  /// Tabs are built only once first visited. They all used to be built at
  /// launch inside the IndexedStack, so the photos feed downloaded and
  /// decoded its videos and full-size images while the user was elsewhere.
  final Set<int> _builtTabs = {};

  void _goToTab(int i) => NavState.tab.value = i;

  @override
  void initState() {
    super.initState();
    NavState.tab.value = _openedSearchOnLaunch ? 0 : NavState.searchTab;
    _openedSearchOnLaunch = true;
    // AppShell is re-created (via a locale-keyed `home:` in main.dart) on
    // every language switch, but CountryState itself is app-lifetime static
    // state — `detecting` only stays true before the very first detection
    // attempt ever runs, so this guard prevents re-hitting the geolocation
    // API on every subsequent language change.
    if (CountryState.detecting.value) {
      _detectCountry();
    }
  }

  static const _countryKey = 'selected_country_code';
  static const _cityIdKey = 'selected_city_id';
  static const _cityNameKey = 'selected_city_name';

  /// Startup used to wait on an IP-geolocation lookup (ipwho.is, up to 5s)
  /// before a single trip could load — on every launch. The country/city
  /// is now remembered, so a returning user's trips start loading at once.
  Future<void> _detectCountry() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_countryKey);
      final savedCountry = saved == null ? null : CountryCatalog.byCode(saved);
      if (savedCountry != null) {
        CountryState.selected.value = savedCountry;
        CountryState.selectedCityId.value = prefs.getInt(_cityIdKey);
        CountryState.selectedCityName.value = prefs.getString(_cityNameKey);
        CountryState.detecting.value = false;
        _rememberSelection(prefs);
        return;
      }
    } catch (_) {}
    final result = await LocationService.detect();
    final country = result.countryCode == null
        ? null
        : CountryCatalog.byCode(result.countryCode!);
    CountryState.selected.value =
        country; // stays null if unresolved/unmatched — no silent default
    // City is deliberately left unset here (meaning "every city in the
    // country") rather than guessed — the geo API's free-text city name
    // (e.g. "Riyadh") can't be reliably matched against the real backend
    // city catalog's already-localized names (e.g. "الرياض") without
    // false positives, and an unset city is itself a perfectly good
    // default now that it actually means "no narrowing", not "broken".
    CountryState.detecting.value = false;
    if (prefs != null) _rememberSelection(prefs);
    if (country == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) openCountryPickerSheet(context);
      });
    }
  }

  /// Saves the country/city whenever it changes (auto-detected or picked).
  static void _rememberSelection(SharedPreferences prefs) {
    void save() {
      final c = CountryState.selected.value;
      if (c == null) return;
      prefs.setString(_countryKey, c.code);
      final cityId = CountryState.selectedCityId.value;
      if (cityId == null) {
        prefs.remove(_cityIdKey);
        prefs.remove(_cityNameKey);
      } else {
        prefs.setInt(_cityIdKey, cityId);
        final name = CountryState.selectedCityName.value;
        if (name != null) prefs.setString(_cityNameKey, name);
      }
    }

    save();
    CountryState.selected.addListener(save);
    CountryState.selectedCityId.addListener(save);
    CountryState.selectedCityName.addListener(save);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const UmrahScreen(),
      const DesignHubScreen(),
      const PhotosScreen(),
      const MoreScreen(),
      const UmrahResultsScreen(), // NavState.searchTab
    ];
    return ValueListenableBuilder<int>(
      valueListenable: NavState.tab,
      builder: (context, index, _) {
        _builtTabs.add(index);
        // Back on any tab other than the first goes to the first tab
        // instead of closing the app.
        return PopScope(
          canPop: index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _goToTab(0);
          },
          // Not Scaffold.bottomNavigationBar: the search circle rises above
          // the bar, and only a widget whose own bounds cover it can take
          // taps there. So the nav is laid over the page in a Stack; the
          // page ends at the white bar, under the nav's transparent strip.
          child: Scaffold(
            body: Builder(builder: (bodyContext) {
              // Hidden while the keyboard is up, like a bottomNavigationBar.
              // Read above the Scaffold: it zeroes viewInsets for its body.
              final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
              final pages = IndexedStack(index: index, children: [
                for (var i = 0; i < screens.length; i++)
                  _builtTabs.contains(i) ? screens[i] : const SizedBox.shrink(),
              ]);
              // Same tree either way, so the tabs keep their state.
              final barSpace = keyboardUp
                  ? 0.0
                  : AppBottomNavBar.barHeight +
                      MediaQuery.paddingOf(bodyContext).bottom;
              return Stack(children: [
                Positioned.fill(
                  bottom: barSpace,
                  child: MediaQuery.removePadding(
                      context: bodyContext,
                      removeBottom: !keyboardUp,
                      child: pages),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Offstage(
                    offstage: keyboardUp,
                    child: AppBottomNavBar(
                      currentIndex: index,
                      searchActive: index == NavState.searchTab,
                      onTap: _goToTab,
                      onSearchTap: () => _goToTab(NavState.searchTab),
                    ),
                  ),
                ),
              ]);
            }),
          ),
        );
      },
    );
  }
}
