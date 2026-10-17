import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';

// Dark neutral tone for the dropdown's chevron/selected text — deliberately
// not the section accent color (green/blue), per design feedback.
const _darkTone = Color(0xFF3E2F26);

/// The small caption above a dropdown box.
const dropdownLabelStyle = TextStyle(
    fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w700);

/// A styled filter dropdown: labeled, tinted pill container, dark chevron,
/// and a rounded popup menu whose selected option is highlighted — used for
/// every "sort / country / city / type" filter across the app.
class AppDropdown<T> extends StatelessWidget {
  /// Shown above the box; null when the page draws the labels itself.
  final String? label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;
  final Color accent;

  const AppDropdown({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.accent = AppColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null) ...[
        Text(label!, style: dropdownLabelStyle),
        const SizedBox(height: 4),
      ],
      Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Theme(
          data: Theme.of(context)
              .copyWith(hoverColor: accent.withValues(alpha: 0.08)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: const Padding(
                  padding: EdgeInsetsDirectional.only(end: 2),
                  child: FaIcon(FontAwesomeIcons.chevronDown,
                      size: 10, color: _darkTone)),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
              elevation: 3,
              selectedItemBuilder: (context) => options.entries
                  .map((e) => Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(e.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _darkTone)),
                      ))
                  .toList(),
              items: options.entries.map((e) {
                final selected = e.key == value;
                return DropdownMenuItem<T>(
                  value: e.key,
                  child: Row(children: [
                    if (selected) ...[
                      const FaIcon(FontAwesomeIcons.check,
                          size: 11, color: _darkTone),
                      const SizedBox(width: 6)
                    ],
                    Text(e.value,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected ? _darkTone : AppColors.text)),
                  ]),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ]);
  }
}
