import 'package:flutter/material.dart';
import '../l10n/translations.dart';

/// «غرفة خاصة لشخصين» pill on a private-room trip card (2026-11-27).
class RoomBadge extends StatelessWidget {
  final int persons;
  final Color accent;
  const RoomBadge({super.key, required this.persons, required this.accent});

  static String label(int persons) => persons == 1
      ? tr('trip.room.badge_1')
      : persons == 2
          ? tr('trip.room.badge_2')
          : tr('trip.room.badge_n').replaceAll(':n', '$persons');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bed_outlined, size: 14, color: accent),
        const SizedBox(width: 5),
        Flexible(
          child: Text(label(persons),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: accent)),
        ),
      ]),
    );
  }
}
