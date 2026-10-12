import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' as intl;
import '../core/theme/app_colors.dart';
import '../l10n/translations.dart';
import '../state/locale_state.dart';
import 'instant_date_picker.dart';

/// Umrah trip types offered in the search bar, as the API's `trip_type`
/// values — same choices as the website's `/umrah` search dropdown.
const kUmrahSearchTypes = ['economy', 'premium', 'vip'];

/// Mirrors `.srch` — trip-type dropdown + date picker + go button.
class SearchBarWidget extends StatefulWidget {
  final FaIconData destIcon;
  final Color accent;
  final String? hint;
  /// Called with the picked date and trip type (null for either means
  /// "any") — the free-text field this replaced was never sent anywhere.
  final void Function(DateTime? date, String? type)? onGo;

  const SearchBarWidget({
    super.key,
    this.destIcon = FontAwesomeIcons.locationDot,
    this.accent = AppColors.blue,
    this.hint,
    this.onGo,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  DateTime? _date;
  String? _type;

  static String _typeLabel(String? type) => switch (type) {
        'economy' => tr('trip.filter.chip_economy'),
        'premium' => tr('trip.filter.chip_golden'),
        'vip' => 'VIP',
        _ => tr('filter.all'),
      };

  Future<void> _pickDate() async {
    final picked = await showInstantDatePicker(
      context: context,
      title: tr('search.pick_date'),
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null
        ? tr('search.pick_date')
        : intl.DateFormat('d MMM yyyy', LocaleState.locale.value.languageCode)
            .format(_date!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: const BoxDecoration(
                        border: BorderDirectional(
                            end: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          FaIcon(widget.destIcon,
                              size: 12, color: widget.accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _type,
                                isDense: true,
                                isExpanded: true,
                                icon: const FaIcon(FontAwesomeIcons.chevronDown,
                                    size: 10, color: AppColors.muted),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.text),
                                borderRadius: BorderRadius.circular(10),
                                items: [
                                  for (final t in [null, ...kUmrahSearchTypes])
                                    DropdownMenuItem<String?>(
                                      value: t,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        child: Text(_typeLabel(t)),
                                      ),
                                    ),
                                ],
                                selectedItemBuilder: (_) => [
                                  for (final t in [null, ...kUmrahSearchTypes])
                                    Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Text(_typeLabel(t)),
                                    ),
                                ],
                                onChanged: (v) => setState(() => _type = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.solidCalendar,
                              size: 11, color: AppColors.blue),
                          const SizedBox(width: 5),
                          Text(dateLabel,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: widget.onGo == null ? null : () => widget.onGo!(_date, _type),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: widget.accent, borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: const FaIcon(FontAwesomeIcons.magnifyingGlass,
                  size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
