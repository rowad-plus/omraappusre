import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/api_company.dart';
import '../../state/app_state.dart';
import '../../widgets/sub_page_header.dart';
import '../company/company_profile_screen.dart';

/// «مكاتب العمرة» — every active Umrah office in the selected country,
/// filterable by city (chips) and searchable by name. Tapping an office
/// opens its public profile with its trips.
class CompaniesDirectoryScreen extends StatefulWidget {
  const CompaniesDirectoryScreen({super.key});

  @override
  State<CompaniesDirectoryScreen> createState() =>
      _CompaniesDirectoryScreenState();
}

class _CompaniesDirectoryScreenState extends State<CompaniesDirectoryScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<ApiDirectoryCity> _cities = [];
  List<ApiDirectoryCompany> _companies = [];
  int? _cityId;
  int _total = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;
  int _reqId = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _loadMore();
      }
    });
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final id = ++_reqId;
    setState(() {
      _loading = true;
      _error = false;
    });
    final res = await context.read<AppState>().fetchCompaniesDirectory(
        cityId: _cityId, search: _searchCtrl.text.trim(), page: 1);
    if (!mounted || id != _reqId) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _error = true;
        return;
      }
      _companies = res.companies;
      if (res.cities.isNotEmpty) _cities = res.cities;
      _total = res.total;
      _hasMore = res.hasMore;
      _page = 1;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final id = _reqId;
    setState(() => _loadingMore = true);
    final res = await context.read<AppState>().fetchCompaniesDirectory(
        cityId: _cityId, search: _searchCtrl.text.trim(), page: _page + 1);
    if (!mounted || id != _reqId) return;
    setState(() {
      _loadingMore = false;
      if (res == null) return;
      _companies = [..._companies, ...res.companies];
      _hasMore = res.hasMore;
      _page++;
    });
  }

  void _pickCity(int? id) {
    if (_cityId == id) return;
    setState(() => _cityId = id);
    _reload();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: tr('more_menu.companies')),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: tr('companies_dir.search'),
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: FaIcon(FontAwesomeIcons.magnifyingGlass,
                    size: 14, color: AppColors.muted),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 38, minHeight: 38),
              isDense: true,
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.brand)),
            ),
          ),
        ),
        _cityChips(),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _cityChips() {
    final all = _cities.fold<int>(0, (s, c) => s + c.count);
    return Container(
      height: 52,
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        children: [
          _chip(tr('companies_dir.all_cities'), all > 0 ? all : null,
              _cityId == null, () => _pickCity(null)),
          for (final c in _cities)
            _chip(c.name, c.count, _cityId == c.id, () => _pickCity(c.id)),
        ],
      ),
    );
  }

  Widget _chip(String label, int? count, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.brand : AppColors.brandSoft,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: active ? AppColors.brand : AppColors.brandLine),
          ),
          child: Text(count == null ? label : '$label ($count)',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.brandDark)),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brand));
    }
    if (_error || _companies.isEmpty) {
      return RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _reload,
        child: ListView(children: [
          const SizedBox(height: 90),
          const Center(
              child: FaIcon(FontAwesomeIcons.buildingCircleXmark,
                  size: 38, color: AppColors.brandLine)),
          const SizedBox(height: 12),
          Text(tr(_error ? 'companies_dir.error' : 'companies_dir.empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 30),
        itemCount: _companies.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  tr('companies_dir.count').replaceAll('{n}', '$_total'),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted)),
            );
          }
          if (i == _companies.length + 1) {
            return _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.brand))))
                : const SizedBox.shrink();
          }
          return _CompanyTile(company: _companies[i - 1]);
        },
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  final ApiDirectoryCompany company;
  const _CompanyTile({required this.company});

  @override
  Widget build(BuildContext context) {
    final c = company;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: c.featured ? AppColors.brandLine : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                CompanyProfileScreen(companyId: c.id, fallbackName: c.name))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: (c.logo ?? '').isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: c.logo!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _initial(c.name))
                  : _initial(c.name),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text)),
                      ),
                      if (c.featured) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              gradient: AppColors.vipGradient,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(tr('companies_dir.featured'),
                              style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 5),
                    Wrap(spacing: 12, runSpacing: 4, children: [
                      if ((c.cityName ?? '').isNotEmpty)
                        _meta(FontAwesomeIcons.locationDot, c.cityName!),
                      if (c.tripsCount > 0)
                        _meta(
                            FontAwesomeIcons.kaaba,
                            tr('companies_dir.trips')
                                .replaceAll('{n}', '${c.tripsCount}')),
                    ]),
                  ]),
            ),
            FaIcon(
                rtl
                    ? FontAwesomeIcons.chevronLeft
                    : FontAwesomeIcons.chevronRight,
                size: 12,
                color: AppColors.muted),
          ]),
        ),
      ),
    );
  }

  Widget _initial(String name) => Center(
        child: Text(name.isEmpty ? '?' : name.characters.first,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.brandDark)),
      );

  Widget _meta(FaIconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10.5, color: AppColors.brand),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ],
      );
}
