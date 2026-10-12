import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';

/// Drop-in for [showDatePicker] without the "حسناً / إلغاء" step: tapping a
/// day picks it and closes the dialog straight away. Dismiss by tapping
/// outside or the close button (returns null, like cancelling).
Future<DateTime?> showInstantDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  SelectableDayPredicate? selectableDayPredicate,
  String? title,
}) {
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final first = day(firstDate);
  final last = day(lastDate);

  // CalendarDatePicker asserts its initial date is in range and selectable —
  // fall back to "nothing selected yet" instead of crashing.
  DateTime? initial = initialDate == null ? null : day(initialDate);
  if (initial != null &&
      (initial.isBefore(first) ||
          initial.isAfter(last) ||
          (selectableDayPredicate != null && !selectableDayPredicate(initial)))) {
    initial = null;
  }
  // The month shown first: the initial date's, else the first selectable day.
  var shown = initial ?? first;
  if (initial == null && selectableDayPredicate != null) {
    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      if (selectableDayPredicate(d)) {
        shown = d;
        break;
      }
    }
  }

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 8, 0),
            child: Row(children: [
              const FaIcon(FontAwesomeIcons.calendarDays, size: 14, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
              ),
              IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const FaIcon(FontAwesomeIcons.xmark, size: 16, color: AppColors.muted),
              ),
            ]),
          ),
          Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                    primary: AppColors.brand,
                    onPrimary: Colors.white,
                  ),
            ),
            child: CalendarDatePicker(
              initialDate: initial,
              // Only steers which month opens when nothing is selected yet.
              currentDate: initial == null ? shown : null,
              firstDate: first,
              lastDate: last,
              selectableDayPredicate: selectableDayPredicate,
              onDateChanged: (picked) => Navigator.of(ctx).pop(picked),
            ),
          ),
        ]),
      ),
    ),
  );
}
