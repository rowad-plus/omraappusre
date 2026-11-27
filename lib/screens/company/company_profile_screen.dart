import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/api_company.dart';
import '../../models/api_trip.dart';
import '../../models/trip.dart';
import '../../state/app_state.dart';
import '../../widgets/sub_page_header.dart';
import '../../widgets/trip_card_uc.dart';
import '../booking/booking_sheet.dart';
import '../trip_detail/trip_detail_screen.dart';

/// A provider company's public profile — opened by tapping a featured
/// company card (لقطات page) or a provider scroller card (Umrah tab).
/// Loads the company record and its active trips from the real backend
/// (`/companies/{id}` + `/umrah-trips?company_id={id}`).
class CompanyProfileScreen extends StatefulWidget {
  final int companyId;
  final String? fallbackName;

  const CompanyProfileScreen({super.key, required this.companyId, this.fallbackName});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  bool _loading = true;
  ApiCompany? _company;
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final results = await Future.wait([
      state.fetchCompany(widget.companyId),
      state.fetchTrips(companyId: widget.companyId),
    ]);
    if (!mounted) return;
    setState(() {
      _company = results[0] as ApiCompany?;
      _trips = (results[1] as List<ApiTrip>).map((t) => t.toTrip()).toList();
      _loading = false;
    });
  }

  void _openDetail(Trip trip) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));
  }

  void _openBooking(Trip trip) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => BookingSheet(trip: trip)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: _company?.name ?? widget.fallbackName ?? tr('company_profile.title')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _company == null
              ? Center(
                  child: Text(tr('company_profile.not_found'),
                      style: const TextStyle(color: AppColors.muted)))
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    _buildHeaderCard(_company!),
                    if ((_company!.about ?? '').isNotEmpty) _buildAboutCard(_company!),
                    const SizedBox(height: 4),
                    Text(tr('company_profile.trips_title'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
                    const SizedBox(height: 10),
                    if (_trips.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: Text(tr('company_profile.no_trips'),
                                style: const TextStyle(color: AppColors.muted))),
                      )
                    else
                      for (final t in expandRoomCards(_trips))
                        TripCardUC(trip: t, onTap: () => _openDetail(t), onBook: () => _openBooking(t)),
                  ],
                ),
    );
  }

  Widget _buildHeaderCard(ApiCompany c) {
    final color = AppColors.avatarColorFor(c.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: c.logo != null
              ? CachedNetworkImage(
                  imageUrl: c.logo!,
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _initialAvatar(c.name, color),
                )
              : _initialAvatar(c.name, color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
            if ((c.slogan ?? '').isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(c.slogan!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
            ],
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (c.rank == 'featured')
                _pill(tr('company_profile.verified_badge'), AppColors.green, AppColors.greenLight),
              _pill('${c.tripsCount} ${tr('company_profile.trips_count')}', AppColors.blue, AppColors.blueLight),
            ]),
            if ((c.cityName ?? c.countryName) != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const FaIcon(FontAwesomeIcons.locationDot, size: 10, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                    [c.cityName, c.countryName].where((s) => (s ?? '').isNotEmpty).join('، '),
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _initialAvatar(String name, Color color) => Container(
      width: 62,
      height: 62,
      color: color,
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name[0] : '؟',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)));

  Widget _pill(String label, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)));

  Widget _buildAboutCard(ApiCompany c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('company_profile.about_title'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 8),
        Text(c.about!, style: const TextStyle(fontSize: 12.5, color: AppColors.text, height: 1.5)),
        if (c.foundedYear != null) ...[
          const SizedBox(height: 8),
          Text('${tr('company_profile.founded_year')} ${c.foundedYear}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ],
      ]),
    );
  }

}
