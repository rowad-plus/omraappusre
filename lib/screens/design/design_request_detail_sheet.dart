import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/design_request.dart';
import 'my_design_requests_screen.dart';

/// Details of a submitted "صمّم عمرتك" wizard request — the inputs sent from
/// the wizard plus a tracker of the admin-set status. Unlike
/// [OrderDetailSheet] this is not a confirmed booking: no bus/hotel
/// assignment, no price, no "تواصل مع المشرف".
class DesignRequestDetailSheet extends StatelessWidget {
  final UmrahDesignRequest request;
  const DesignRequestDetailSheet({super.key, required this.request});

  static List<(DesignRequestStage, String)> get _stages => [
        (DesignRequestStage.received, tr('design.tracker.received')),
        (DesignRequestStage.reviewed, tr('design.tracker.reviewed')),
        (DesignRequestStage.completed, tr('design.tracker.done')),
      ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(tr('design.detail_title'),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text)),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: AppColors.bg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const FaIcon(FontAwesomeIcons.xmark,
                        size: 14, color: AppColors.muted)),
              ),
            ]),
            Text('${request.ref} · ${formatDesignDate(request.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 16),
            _statusTracker(),
            _section(tr('design.step1.title'), FontAwesomeIcons.route, [
              (tr('design.field.start_point'), tr(request.startPoint)),
              (tr('design.field.adults'), '${request.adults}'),
              if (request.children > 0)
                (tr('design.field.children'), '${request.children}'),
              if (request.infants > 0)
                (tr('design.field.infants'), '${request.infants}'),
              (tr('design.field.travel_date'), request.travelDate ?? ''),
              (
                tr('design.field.makka_days'),
                '${request.makkaDays} ${tr('design.unit.days')}'
              ),
              if (request.madinaDays > 0)
                (
                  tr('design.field.madina_days'),
                  '${request.madinaDays} ${tr('design.unit.days')}'
                ),
            ]),
            _section(tr('design.step2.title'), FontAwesomeIcons.bed, [
              (
                tr('design.field.hotel_rating_makkah'),
                tr(request.hotelStarsMakkah)
              ),
              (
                tr('design.field.hotel_rating_madinah'),
                tr(request.hotelStarsMadinah)
              ),
              (tr('design.field.room_type'), tr(request.roomType)),
              if (request.hotelPrefs.isNotEmpty)
                (
                  tr('design.field.preferences'),
                  request.hotelPrefs.map(tr).join('، ')
                ),
            ]),
            _section(tr('design.step3.title'), FontAwesomeIcons.plane, [
              (
                tr('design.field.departure_country'),
                tr(request.departureCountry)
              ),
              (tr('design.field.departure_city'), tr(request.departureCity)),
              (tr('design.field.flight_type'), tr(request.flightType)),
              (tr('design.field.flight_class'), tr(request.flightClass)),
              if (request.transport.isNotEmpty)
                (
                  tr('design.field.transport_services'),
                  request.transport.map(tr).join('، ')
                ),
            ]),
            if (request.extras.isNotEmpty)
              _section(tr('design.section.extra_services'),
                  FontAwesomeIcons.solidStar, [
                (tr('design.field.service'), request.extras.map(tr).join('، ')),
              ]),
            _section(
                tr('design.section.contact_info'), FontAwesomeIcons.solidUser, [
              (tr('design.hint.full_name'), request.name),
              (tr('design.hint.phone_number'), request.phone),
              (tr('design.hint.email'), request.email),
            ]),
            if (request.notes.isNotEmpty)
              _section(tr('design.section.notes'),
                  FontAwesomeIcons.solidNoteSticky, [
                ('', request.notes),
              ]),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(tr('common.close'),
                      style: const TextStyle(
                          color: AppColors.muted, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTracker() {
    if (request.stage == DesignRequestStage.cancelled) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12)),
        child: DesignStageBar(stage: request.stage),
      );
    }
    final currentIndex = _stages.indexWhere((s) => s.$1 == request.stage);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < _stages.length; i++)
          _stageRow(_stages[i].$2,
              done: i <= currentIndex, isLast: i == _stages.length - 1),
        if (request.updatedAt != null) ...[
          const SizedBox(height: 10),
          Text(
              '${tr('design.my_requests.updated')}: ${formatDesignDate(request.updatedAt)}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ]),
    );
  }

  Widget _stageRow(String label, {required bool done, required bool isLast}) {
    final color = done ? AppColors.green : AppColors.muted;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
              color: done ? AppColors.green : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5)),
          alignment: Alignment.center,
          child: done
              ? const FaIcon(FontAwesomeIcons.check,
                  size: 9, color: Colors.white)
              : null,
        ),
        if (!isLast)
          Container(
              width: 1.5,
              height: 22,
              color: done ? AppColors.green : AppColors.border),
      ]),
      const SizedBox(width: 10),
      Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 1),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }

  Widget _section(
      String title, FaIconData icon, List<(String, String)> allRows) {
    final rows = allRows.where((r) => r.$2.trim().isNotEmpty).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          FaIcon(icon, size: 13, color: AppColors.blue),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text))
        ]),
        const SizedBox(height: 10),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: r.$1.isEmpty
                ? Text(r.$2,
                    style:
                        const TextStyle(fontSize: 12.5, color: AppColors.text))
                : Row(children: [
                    Text(r.$1,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(r.$2,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                    ),
                  ]),
          ),
      ]),
    );
  }
}
