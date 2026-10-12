import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/api_tracking.dart';
import '../../services/live_updates.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/order_actions.dart';

/// "تتبع الرحلة" — where the app lands right after a booking is placed or
/// paid, and what "تتبع الرحلة" on a booking card opens. Mirrors the
/// website's /bookings/{id}/track page: a stage timeline (booked → payment
/// → company confirmation → accommodation → bus → departure → in trip →
/// completed), a departure countdown, the booking's own updates, and the
/// hotel / bus / payment / organizer details. All stage text comes from the
/// server already translated, so the two never disagree.
class TripTrackingScreen extends StatefulWidget {
  final int bookingId;

  /// Shows the "تم الحجز بنجاح" banner (only on arrival from the booking flow).
  final bool justBooked;
  final bool justPaid;

  const TripTrackingScreen({
    super.key,
    required this.bookingId,
    this.justBooked = false,
    this.justPaid = false,
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen>
    with LiveReload<TripTrackingScreen> {
  @override
  Future<void> onLiveUpdate() => _load();

  ApiTracking? _data;
  bool _loading = true;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context.read<AppState>().fetchTracking(widget.bookingId);
    if (!mounted) return;
    setState(() {
      // Keep what's on screen if a refresh fails.
      if (data != null) _data = data;
      _loading = false;
    });
  }

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    await payForBooking(context, widget.bookingId);
    if (!mounted) return;
    setState(() => _paying = false);
    await _load();
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) showAppToast(context, tr('orders.map_open_failed'));
  }

  String _fmtDate(String? ymd) {
    final d = ymd == null ? null : DateTime.tryParse(ymd);
    if (d == null) return '—';
    try {
      return DateFormat('EEEE d MMMM y', LocaleState.locale.value.languageCode).format(d);
    } catch (_) {
      return ymd!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(d?.label('page_title', tr('orders.track_trip')) ?? tr('orders.track_trip'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
      body: _loading && d == null
          ? const Center(
              child: SizedBox(
                  width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
          : d == null
              ? _error()
              : RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                    children: [
                      if (widget.justBooked && !d.isTerminated) _successBanner(d),
                      _hero(d),
                      const SizedBox(height: 14),
                      _stagesCard(d),
                      _updatesCard(d),
                      _detailsCard(d),
                      _hotelCard(d),
                      _busCard(d),
                      _paymentCard(d),
                      if ((d.companyName ?? '').isNotEmpty) _companyCard(d),
                    ],
                  ),
                ),
    );
  }

  Widget _error() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FaIcon(FontAwesomeIcons.triangleExclamation, color: AppColors.muted, size: 28),
          const SizedBox(height: 10),
          Text(tr('orders.track_load_error'), style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            child: const FaIcon(FontAwesomeIcons.rotateRight, size: 16, color: AppColors.brand),
          ),
        ]),
      );

  Widget _successBanner(ApiTracking d) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const FaIcon(FontAwesomeIcons.check, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.label('success_title'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF14532D))),
              const SizedBox(height: 3),
              Text(d.label(widget.justPaid ? 'success_paid' : 'success_request'),
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF166534), height: 1.5)),
            ]),
          ),
        ]),
      );

  Widget _hero(ApiTracking d) {
    final bad = d.isTerminated;
    final good = d.status == 'completed' || d.status == 'in_trip';
    final (hlBg, hlFg) = bad
        ? (const Color(0xFFFEF2F2), const Color(0xFFDC2626))
        : good
            ? (const Color(0xFFF0FDF4), const Color(0xFF15803D))
            : (AppColors.brandSoft, AppColors.brand);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.brandLine, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (d.trip.thumbnail != null)
          SizedBox(
            height: 130,
            child: CachedNetworkImage(
              imageUrl: d.trip.thumbnail!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: AppColors.brandSoft),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${d.label('booking_ref')} ${d.ref}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(d.trip.title,
                style: const TextStyle(
                    fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.text)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration:
                  BoxDecoration(color: hlBg, borderRadius: BorderRadius.circular(99)),
              child: Text(d.headline,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: hlFg)),
            ),
            if (!bad) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: d.progress / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1EAD8),
                      color: AppColors.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${d.progress}%',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.brand)),
              ]),
            ],
            if ((d.daysLeft ?? 0) > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${d.daysLeft}',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.brand)),
                    const SizedBox(width: 8),
                    Text(d.label('days_left_label'),
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  static const _stageIcons = <String, FaIconData>{
    'booked': FontAwesomeIcons.clipboardCheck,
    'payment': FontAwesomeIcons.creditCard,
    'confirmed': FontAwesomeIcons.shieldHalved,
    'accommodation': FontAwesomeIcons.bed,
    'transport': FontAwesomeIcons.bus,
    'departure': FontAwesomeIcons.planeDeparture,
    'in_trip': FontAwesomeIcons.kaaba,
    'completed': FontAwesomeIcons.award,
  };

  Widget _card({required String title, required FaIconData icon, required List<Widget> children}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            FaIcon(icon, size: 14, color: AppColors.brand),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.text)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ]),
      );

  Widget _stagesCard(ApiTracking d) => _card(
        title: d.label('stages_title'),
        icon: FontAwesomeIcons.route,
        children: [
          for (var i = 0; i < d.stages.length; i++)
            _stageRow(d, d.stages[i], isLast: i == d.stages.length - 1),
        ],
      );

  Widget _stageRow(ApiTracking d, TrackingStage s, {required bool isLast}) {
    final done = s.state == 'done';
    final current = s.state == 'current';
    final dim = s.state == 'upcoming' || s.state == 'skipped';
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 34,
          child: Column(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: done ? AppColors.brand : (current ? Colors.white : const Color(0xFFF4F1EA)),
                shape: BoxShape.circle,
                border: Border.all(
                    color: done || current ? AppColors.brand : AppColors.border, width: 2),
                boxShadow: current
                    ? [BoxShadow(color: AppColors.brand.withValues(alpha: .18), spreadRadius: 4)]
                    : null,
              ),
              alignment: Alignment.center,
              child: FaIcon(
                done ? FontAwesomeIcons.check : (_stageIcons[s.key] ?? FontAwesomeIcons.circle),
                size: 13,
                color: done
                    ? Colors.white
                    : current
                        ? AppColors.brand
                        : const Color(0xFFB6AD9A).withValues(alpha: s.state == 'skipped' ? .5 : 1),
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: done ? AppColors.brand : AppColors.border,
                ),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 5, bottom: isLast ? 0 : 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(s.title,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: dim ? const Color(0xFF9CA3AF) : AppColors.text)),
                  if (current)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.brand, borderRadius: BorderRadius.circular(99)),
                      child: Text(d.label('now'),
                          style: const TextStyle(
                              fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                ],
              ),
              if (s.subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(s.subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.45)),
              ],
              if (s.date != null) ...[
                const SizedBox(height: 3),
                Text(_fmtDate(s.date),
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
              ],
              if (s.key == 'payment' && current && d.needsPayment) ...[
                const SizedBox(height: 8),
                _pill(d.label('pay_now'), FontAwesomeIcons.creditCard, filled: true,
                    loading: _paying, onTap: _pay),
              ],
              if (s.key == 'departure' && d.trip.mapUrl != null && !d.isTerminated) ...[
                const SizedBox(height: 8),
                _pill(d.label('open_map'), FontAwesomeIcons.locationDot,
                    onTap: () => _open(d.trip.mapUrl!)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _pill(String label, FaIconData icon,
      {bool filled = false, bool loading = false, required VoidCallback onTap}) {
    final fg = filled ? Colors.white : AppColors.brand;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? AppColors.brand : AppColors.brandSoft,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          loading
              ? SizedBox(
                  width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
              : FaIcon(icon, size: 12, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: fg)),
        ]),
      ),
    );
  }

  Widget _empty(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5)),
      );

  Widget _row(String k, String? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text((v == null || v.isEmpty) ? '—' : v,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.text)),
          ),
        ]),
      );

  Widget _updatesCard(ApiTracking d) => _card(
        title: d.label('updates_title'),
        icon: FontAwesomeIcons.bullhorn,
        children: d.updates.isEmpty
            ? [_empty(d.label('no_updates'))]
            : [
                for (final u in d.updates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: AppColors.brandSoft, borderRadius: BorderRadius.circular(9)),
                        alignment: Alignment.center,
                        child: const FaIcon(FontAwesomeIcons.bullhorn,
                            size: 13, color: AppColors.brand),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u.title,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.text)),
                          if ((u.body ?? '').isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(u.body!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.text, height: 1.5)),
                          ],
                          if (u.timeAgo != null) ...[
                            const SizedBox(height: 3),
                            Text(u.timeAgo!,
                                style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                          ],
                        ]),
                      ),
                    ]),
                  ),
              ],
      );

  Widget _detailsCard(ApiTracking d) => _card(
        title: d.label('details_title'),
        icon: FontAwesomeIcons.calendarDays,
        children: [
          _row(d.label('departure_date'), _fmtDate(d.trip.departureDate)),
          _row(d.label('return_date'), _fmtDate(d.trip.returnDate)),
          _row(d.label('duration'),
              d.label('days').replaceAll(':n', '${d.trip.durationDays}')),
          _row(d.label('persons'), '${d.personsCount}'),
          _row(d.label('departure_point'),
              d.trip.departureLocation ?? d.trip.departureCity),
        ],
      );

  Widget _hotelCard(ApiTracking d) {
    final h = d.hotel;
    final stars = (h?['stars'] as num?)?.toInt() ?? 0;
    return _card(
      title: d.label('hotel_title'),
      icon: FontAwesomeIcons.bed,
      children: h == null
          ? [_empty(d.label('stage_accommodation_wait'))]
          : [
              _row('${h['name'] ?? ''}', stars > 0 ? '★' * stars.clamp(0, 5) : ''),
              _row(d.label('room').replaceAll(':n', '').trim(),
                  (h['room_number'] as String?) ?? d.label('not_assigned')),
              if (h['room_capacity'] != null)
                _row(d.label('room_capacity'), '${h['room_capacity']}'),
              // After housing: how many share the room, and their names.
              if (h['room_persons'] != null) ...[
                _row(d.label('room_persons', 'عدد الأشخاص في الغرفة'), '${h['room_persons']}'),
                const SizedBox(height: 6),
                Text(d.label('roommates_title', 'زملاء الغرفة'),
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 6),
                if (((h['roommates'] as List?) ?? const []).isEmpty)
                  _empty(d.label('no_roommates', 'لا يوجد معك أحد في الغرفة حتى الآن'))
                else
                  for (final mate in (h['roommates'] as List).map((e) => '$e'))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                              color: AppColors.brandSoft, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(mate.trim().isEmpty ? '؟' : mate.trim().characters.first,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.brand)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(mate,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                        ),
                      ]),
                    ),
              ],
            ],
    );
  }

  Widget _busCard(ApiTracking d) {
    final b = d.bus;
    final phone = b?['driver_phone'] as String?;
    return _card(
      title: d.label('transport_title'),
      icon: FontAwesomeIcons.bus,
      children: b == null
          ? [_empty(d.label('stage_transport_wait'))]
          : [
              _row(d.label('bus').replaceAll(':n', '').trim(), '${b['number'] ?? ''}'),
              if (b['company'] != null) _row(d.label('company_title'), '${b['company']}'),
              if (b['driver_name'] != null) _row(d.label('driver'), '${b['driver_name']}'),
              if ((phone ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                _pill('${d.label('call')} ${d.label('driver')}', FontAwesomeIcons.phone,
                    onTap: () => _open('tel:$phone')),
              ],
            ],
    );
  }

  Widget _paymentCard(ApiTracking d) => _card(
        title: d.label('payment_title'),
        icon: FontAwesomeIcons.receipt,
        children: [
          _row(d.label('total'), '${d.total.toStringAsFixed(0)} ${d.currency}'),
          if (d.paid > 0) _row(d.label('paid_amount'), '${d.paid.toStringAsFixed(0)} ${d.currency}'),
          if (d.paymentStatusLabel != null) _row(d.label('payment_title'), d.paymentStatusLabel),
          if (d.needsPayment) ...[
            const SizedBox(height: 8),
            _pill(d.label('pay_now'), FontAwesomeIcons.creditCard,
                filled: true, loading: _paying, onTap: _pay),
          ],
        ],
      );

  Widget _companyInitial(ApiTracking d) => Container(
        color: AppColors.brandSoft,
        alignment: Alignment.center,
        child: Text(
            (d.companyName ?? '').isNotEmpty ? d.companyName!.characters.first : '',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brand)),
      );

  Widget _companyCard(ApiTracking d) => _card(
        title: d.label('company_title'),
        icon: FontAwesomeIcons.building,
        children: [
          // Logo + name + city always; phone / call / WhatsApp only when the
          // admin allows it for this company or its country.
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: d.companyLogo != null
                    ? CachedNetworkImage(
                        imageUrl: d.companyLogo!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _companyInitial(d),
                      )
                    : _companyInitial(d),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.companyName!,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                if ((d.companyCity ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const FaIcon(FontAwesomeIcons.locationDot, size: 11, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(d.companyCity!,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
                ],
              ]),
            ),
          ]),
          if (d.companyContactVisible && (d.companyPhone ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            _row(d.label('call'), d.companyPhone),
          ],
          if (d.companyContactVisible &&
              ((d.companyPhone ?? '').isNotEmpty || (d.companyWhatsapp ?? '').isNotEmpty)) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if ((d.companyPhone ?? '').isNotEmpty)
                _pill(d.label('call'), FontAwesomeIcons.phone,
                    onTap: () => _open('tel:${d.companyPhone}')),
              if ((d.companyWhatsapp ?? '').isNotEmpty)
                _pill(d.label('whatsapp'), FontAwesomeIcons.whatsapp,
                    onTap: () => _open(
                        'https://wa.me/${d.companyWhatsapp}?text=${Uri.encodeComponent(d.ref)}')),
            ]),
          ],
        ],
      );
}
