import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/api_post.dart';
import '../../models/post.dart';
import '../../state/app_state.dart';
import '../../state/country_state.dart';
import '../../widgets/app_header.dart';
import '../../widgets/post_card.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/h_scroll_auto.dart';
import '../auth/login_sheet.dart';
import '../company/company_profile_screen.dart';
import '../trip_detail/trip_detail_screen.dart';
import '../umrah_results/umrah_results_screen.dart';
import 'comments_sheet.dart';
import 'post_modal.dart';
import 'tiktok_viewer.dart';

/// Mirrors `#pg-photos` — the لقطات (Snapshots) social feed page.
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final List<Post> _feed = [];
  int _nextPage = 1;
  bool _loading = false;
  bool _hasMore = true;
  final _scrollCtrl = ScrollController();
  List<ApiFeaturedCompany> _featuredCompanies = [];
  List<ApiNearbyTrip> _nearbyTrips = [];

  static const _companyColors = [
    AppColors.blue,
    AppColors.green,
    Color(0xFF7C3AED),
    Color(0xFFD97706),
    Color(0xFFE84040),
  ];

  @override
  void initState() {
    super.initState();
    _loadMore();
    _loadHome();
    // Location detection (AppShell._detectCountry) runs concurrently and
    // usually hasn't resolved yet on this first build, so the initial
    // _loadHome() above goes out country-less. Re-fetch once it lands so
    // the featured-companies strip reflects the visitor's actual country
    // instead of staying on the unscoped fallback for the whole session.
    CountryState.selected.addListener(_onCountryResolved);
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 300) {
        _loadMore();
      }
    });
  }

  void _onCountryResolved() {
    if (CountryState.selected.value != null) _loadHome();
  }

  @override
  void dispose() {
    CountryState.selected.removeListener(_onCountryResolved);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final (posts, hasMore) =
        await context.read<AppState>().fetchTimelinePosts(_nextPage);
    if (!mounted) return;
    setState(() {
      _feed.addAll(posts.map((p) => p.toPost()));
      _hasMore = hasMore;
      _nextPage++;
      _loading = false;
    });
  }

  Future<void> _loadHome() async {
    final (companies, trips) = await context.read<AppState>().fetchTimelineHome();
    if (!mounted) return;
    setState(() {
      _featuredCompanies = companies;
      _nearbyTrips = trips;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _feed.clear();
      _nextPage = 1;
      _hasMore = true;
    });
    await _loadMore();
  }

  bool _openingTrip = false;

  Future<void> _openNearbyTrip(ApiNearbyTrip t) async {
    if (_openingTrip) return;
    setState(() => _openingTrip = true);
    final full = await context.read<AppState>().fetchTripDetail(t.id);
    if (!mounted) return;
    setState(() => _openingTrip = false);
    if (full == null) {
      showAppToast(context, tr('photos.trip_load_error'));
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: full.toTrip())));
  }

  void _openViewer(Post post) {
    final mediaPosts = _feed.where((p) => p.media != null).toList();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TikTokViewer(initialPostId: post.id, items: mediaPosts),
        fullscreenDialog: true));
  }

  void _openComments(Post post) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CommentsSheet(post: post));
  }

  Future<void> _toggleLike(Post post) async {
    if (!context.read<AppState>().isLoggedIn) {
      openLoginSheet(context);
      return;
    }
    setState(() {
      post.liked = !post.liked;
      post.likes += post.liked ? 1 : -1;
    });
    if (post.apiId == null) return;
    final liked = await context.read<AppState>().toggleTimelineLike(post.apiId!);
    if (!mounted || liked == null || liked == post.liked) return;
    // Server disagreed with the optimistic flip — reconcile.
    setState(() {
      post.liked = liked;
      post.likes += liked ? 1 : -1;
    });
  }

  void _openPostModal() {
    if (!context.read<AppState>().isLoggedIn) {
      openLoginSheet(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostModal(onPosted: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppHeader(
        onSearchTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UmrahResultsScreen())),
        onSignInTap: () => openLoginSheet(context),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(bottom: 14),
            itemCount: _feed.length + 2 + (_loading ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == 0) return _buildTopSlider();
              if (i == 1) return _buildComposer();
              final feedIndex = i - 2;
              if (feedIndex < _feed.length) {
                final post = _feed[feedIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: PostCard(
                    post: post,
                    onLikeToggle: () => _toggleLike(post),
                    onCommentTap: () => _openComments(post),
                    onShareTap: () => sharePost(context),
                    onMediaTap:
                        post.media != null ? () => _openViewer(post) : null,
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.blue))),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildTopSlider() {
    if (_featuredCompanies.isEmpty && _nearbyTrips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_featuredCompanies.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Expanded(
                  child: Text(tr('photos.featured_companies'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text))),
            ]),
          ),
          const SizedBox(height: 8),
          HScrollAuto(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            spacing: 8,
            itemCount: _featuredCompanies.length,
            itemBuilder: (context, i) {
              final c = _featuredCompanies[i];
              final color = _companyColors[c.id % _companyColors.length];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CompanyProfileScreen(companyId: c.id, fallbackName: c.name))),
                child: Container(
                width: 168,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: c.logo != null
                        ? CachedNetworkImage(
                            imageUrl: c.logo!,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _companyInitial(c.name, color),
                          )
                        : _companyInitial(c.name, color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text)),
                          Text(tr('photos.verified_badge'),
                              style: const TextStyle(
                                  fontSize: 9.5, color: AppColors.green)),
                        ]),
                  ),
                ]),
                ),
              );
            },
          ),
        ],
        if (_nearbyTrips.isNotEmpty) ...[
          if (_featuredCompanies.isNotEmpty) const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Expanded(
                  child: Text(tr('photos.nearby_umrah_trips'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text))),
            ]),
          ),
          const SizedBox(height: 8),
          HScrollAuto(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            spacing: 10,
            itemCount: _nearbyTrips.length,
            itemBuilder: (context, i) {
              final t = _nearbyTrips[i];
              return GestureDetector(
                onTap: () => _openNearbyTrip(t),
                child: SizedBox(
                width: 130,
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(children: [
                          Container(
                              height: 90,
                              decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [Color(0xFF8E6A28), Color(0xFFB8892F)])),
                              alignment: Alignment.center,
                              child: t.thumbnail != null
                                  ? CachedNetworkImage(
                                      imageUrl: t.thumbnail!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorWidget: (_, __, ___) => const Text('🕋',
                                          style: TextStyle(fontSize: 36)),
                                    )
                                  : const Text('🕋', style: TextStyle(fontSize: 36))),
                          if (t.type == 'vip')
                            Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        gradient: AppColors.vipGradient,
                                        borderRadius: BorderRadius.circular(10)),
                                    child: const Text('VIP',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800)))),
                        ]),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text)),
                                Text(
                                    '${tr('photos.starting_from')} ${t.price.toStringAsFixed(0)} ${t.currency}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.green)),
                              ]),
                        ),
                      ]),
                ),
                ),
              );
            },
          ),
        ],
      ]),
    );
  }

  Widget _companyInitial(String name, Color color) => Container(
      width: 38,
      height: 38,
      color: color,
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name[0] : '؟',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)));

  Widget _buildComposer() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        GestureDetector(
          onTap: _openPostModal,
          child: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: AppColors.bg,
                    border: Border.all(color: AppColors.border),
                    shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const FaIcon(FontAwesomeIcons.solidUser,
                    size: 13, color: AppColors.muted)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.bg,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(tr('photos.composer_hint'),
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.muted)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(
                child: _typeBtn(FontAwesomeIcons.solidImage, const Color(0xFFB8892F),
                    tr('photos.type_photo'))),
            const SizedBox(width: 8),
            Expanded(
                child: _typeBtn(FontAwesomeIcons.video, const Color(0xFFE84040),
                    tr('photos.type_video'))),
            const SizedBox(width: 8),
            Expanded(
                child: _typeBtn(FontAwesomeIcons.pen, AppColors.green,
                    tr('photos.type_text'))),
          ]),
        ),
      ]),
    );
  }

  Widget _typeBtn(FaIconData icon, Color color, String label) {
    return GestureDetector(
      onTap: _openPostModal,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
            color: AppColors.bg,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FaIcon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
        ]),
      ),
    );
  }
}
