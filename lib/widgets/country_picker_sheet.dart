import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../data/country_catalog.dart';
import '../l10n/translations.dart';
import '../models/country.dart';
import '../state/app_state.dart';
import '../state/country_state.dart';

/// Two-step bottom sheet: pick a country, then a real departure city
/// within it (fetched live — see `AppState.fetchDepartureCities` — instead
/// of the old hand-typed `Country.cityKeys` catalog, which capped every
/// country at 1-2 cities regardless of how many the backend actually has
/// trips departing from). Mirrors the visual pattern of
/// `_openLanguagePicker` in `lib/screens/more/settings_screen.dart`, but
/// scrolls internally since the country list (40 entries) doesn't fit on
/// screen like the 7-item language list does.
Future<void> openCountryPickerSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    isScrollControlled: true,
    builder: (_) => const _CountryPickerSheet(),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  Country? _stepTwoCountry;
  bool _loadingCities = false;
  List<CityOption> _cities = const [];

  @override
  void initState() {
    super.initState();
    // Open straight on the current (detected / chosen) country's cities,
    // like the website; the back arrow still leads to the country list.
    final current = CountryState.selected.value;
    if (current != null) {
      _stepTwoCountry = current;
      _loadingCities = true;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _selectCountry(current, keepCity: true));
    }
  }

  Future<void> _selectCountry(Country country, {bool keepCity = false}) async {
    if (!keepCity) {
      CountryState.selected.value = country;
      CountryState.selectedCityId.value = null;
      CountryState.selectedCityName.value = null;
    }
    setState(() {
      _stepTwoCountry = country;
      _loadingCities = true;
      _cities = const [];
    });
    final cities = await context.read<AppState>().fetchDepartureCities(country.code);
    if (!mounted) return;
    if (cities.isEmpty) {
      // Nothing to narrow down to: on a pick, close; when the sheet just
      // opened on the current country, show the country list instead.
      if (keepCity) {
        setState(() {
          _stepTwoCountry = null;
          _loadingCities = false;
        });
      } else {
        Navigator.of(context).pop();
      }
      return;
    }
    setState(() {
      _cities = cities;
      _loadingCities = false;
    });
  }

  void _selectCity(CityOption? city) {
    CountryState.selectedCityId.value = city?.id;
    CountryState.selectedCityName.value = city?.name;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepTwoCountry == null
                ? _buildCountryHeader()
                : _buildCityHeader(_stepTwoCountry!),
            Flexible(
              child: _stepTwoCountry == null
                  ? _buildCountryList()
                  : _buildCityList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryHeader() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Text(tr('country.picker.title'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildCityHeader(Country country) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: FaIcon(
                Directionality.of(context) == TextDirection.rtl
                    ? FontAwesomeIcons.chevronRight
                    : FontAwesomeIcons.chevronLeft,
                size: 14,
                color: AppColors.muted),
            onPressed: () => setState(() => _stepTwoCountry = null),
          ),
          Expanded(
            child: Text(
              '${country.flagEmoji}  ${tr(country.nameKey)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryList() {
    return ValueListenableBuilder<Country?>(
      valueListenable: CountryState.selected,
      builder: (context, selected, _) {
        // The current country first, then the rest in catalog order.
        final countries = [
          if (selected != null) selected,
          for (final c in CountryCatalog.all)
            if (c.code != selected?.code) c,
        ];
        return ListView(
          shrinkWrap: true,
          children: [
            for (final country in countries)
              ListTile(
                leading:
                    Text(country.flagEmoji, style: const TextStyle(fontSize: 20)),
                title: Text(tr(country.nameKey)),
                subtitle: country.hasContent
                    ? null
                    : Text(tr('country.picker.no_content'),
                        style:
                            const TextStyle(fontSize: 11, color: AppColors.muted)),
                trailing: country.code == selected?.code
                    ? const FaIcon(FontAwesomeIcons.check,
                        size: 14, color: AppColors.blue)
                    : null,
                onTap: () => _selectCountry(country),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCityList() {
    if (_loadingCities) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return ValueListenableBuilder<int?>(
      valueListenable: CountryState.selectedCityId,
      builder: (context, selectedId, _) {
        Widget cityTile(CityOption city) => ListTile(
              title: Text(city.name),
              trailing: city.id == selectedId
                  ? const FaIcon(FontAwesomeIcons.check,
                      size: 14, color: AppColors.blue)
                  : null,
              onTap: () => _selectCity(city),
            );
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(tr('country.picker.all_cities')),
              trailing: selectedId == null
                  ? const FaIcon(FontAwesomeIcons.check,
                      size: 14, color: AppColors.blue)
                  : null,
              onTap: () => _selectCity(null),
            ),
            // One list, like the website: the server orders it capital
            // first, then featured cities, then the rest.
            for (final city in _cities) cityTile(city),
          ],
        );
      },
    );
  }
}
