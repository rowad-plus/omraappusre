import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/post.dart';
import '../../state/app_state.dart';
import '../../widgets/app_toast.dart';
import '../auth/login_sheet.dart';
import '../trip_detail/trip_detail_screen.dart';
import '../../models/trip.dart';
import 'comments_sheet.dart';

/// Mirrors `#ttViewer` — the fullscreen vertical media viewer for feed
/// posts that have a photo or video attached. [items] is the caller's own
/// already-loaded media-post list (real feed data), so the viewer stays in
/// sync with whatever the feed actually fetched instead of sourcing its own.
class TikTokViewer extends StatefulWidget {
  final int initialPostId;
  final List<Post> items;
  const TikTokViewer({super.key, required this.initialPostId, required this.items});

  @override
  State<TikTokViewer> createState() => _TikTokViewerState();
}

class _TikTokViewerState extends State<TikTokViewer> {
  late final List<Post> _items = widget.items;
  late final PageController _pageCtrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _items
        .indexWhere((p) => p.id == widget.initialPostId)
        .clamp(0, _items.length - 1);
    _pageCtrl = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _pageCtrl,
          scrollDirection: Axis.vertical,
          itemCount: _items.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) =>
              _Slide(post: _items[i], isActive: i == _index),
        ),
        Positioned(
          top: 48,
          left: 16,
          right: 16,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _circleBtn(
                FontAwesomeIcons.xmark, () => Navigator.of(context).pop()),
            Text('${_index + 1} / ${_items.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            _circleBtn(FontAwesomeIcons.shareNodes, () => sharePost(context)),
          ]),
        ),
      ]),
    );
  }

  Widget _circleBtn(FaIconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle),
          alignment: Alignment.center,
          child: FaIcon(icon, color: Colors.white, size: 16)),
    );
  }
}

class _Slide extends StatefulWidget {
  final Post post;
  final bool isActive;
  const _Slide({required this.post, required this.isActive});

  @override
  State<_Slide> createState() => _SlideState();
}

class _SlideState extends State<_Slide> {
  VideoPlayerController? _controller;
  bool _muted = true;
  bool _loading = false;
  bool _error = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _createController();
  }

  // Only ever one live VideoPlayerController/platform-view per slide, created
  // exactly when it becomes the active page and destroyed the moment it
  // isn't — keeping several web <video> elements alive across swipes is what
  // was causing missed taps / frozen frames / no-autoplay-on-swipe.
  void _createController() {
    final videoAsset = widget.post.media?.videoAsset;
    final networkVideo = widget.post.media?.networkVideo;
    if (videoAsset == null && networkVideo == null) return;
    final myGeneration = ++_generation;
    final controller = networkVideo != null
        ? VideoPlayerController.networkUrl(Uri.parse(networkVideo))
        : VideoPlayerController.asset(videoAsset!);
    _controller = controller;
    _loading = true;
    _error = false;
    controller.setLooping(true);
    // Starts muted: browsers block play() with sound unless it's called
    // synchronously inside a user-gesture handler, which this isn't (it
    // runs after `await initialize()`). Muted autoplay is always allowed;
    // the user can unmute with a tap, which is itself a valid gesture.
    controller.setVolume(_muted ? 0 : 1);
    controller.initialize().then((_) {
      if (!mounted || myGeneration != _generation) return;
      setState(() => _loading = false);
      controller.play();
    }).catchError((Object e) {
      // ignore: avoid_print
      print('Video failed to load: $videoAsset — $e');
      if (!mounted || myGeneration != _generation) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    });
  }

  void _disposeController() {
    _generation++;
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  void _retry() {
    _disposeController();
    setState(_createController);
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _muted = !_muted;
      controller.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  void didUpdateWidget(covariant _Slide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _createController();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeController();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final post = widget.post;
    if (!context.read<AppState>().isLoggedIn) {
      openLoginSheet(context, toSearch: false);
      return;
    }
    setState(() {
      post.liked = !post.liked;
      post.likes += post.liked ? 1 : -1;
    });
    if (post.apiId == null) return;
    final liked = await context.read<AppState>().toggleTimelineLike(post.apiId!);
    if (!mounted || liked == null || liked == post.liked) return;
    setState(() {
      post.liked = liked;
      post.likes += liked ? 1 : -1;
    });
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() =>
        controller.value.isPlaying ? controller.pause() : controller.play());
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final media = post.media!;
    final stars = '★' * post.stars + '☆' * (5 - post.stars);
    final controller = _controller;
    final videoReady = controller != null && controller.value.isInitialized;
    return Stack(fit: StackFit.expand, children: [
      Container(decoration: BoxDecoration(gradient: media.bg)),
      if (videoReady)
        GestureDetector(
          onTap: _togglePlay,
          child: Stack(alignment: Alignment.center, children: [
            IgnorePointer(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller)),
                ),
              ),
            ),
            if (!controller.value.isPlaying)
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6), width: 3)),
                child: const FaIcon(FontAwesomeIcons.play,
                    color: Colors.white, size: 26),
              ),
          ]),
        )
      else if (media.networkImage != null)
        SizedBox.expand(
            child: CachedNetworkImage(imageUrl: media.networkImage!, fit: BoxFit.cover))
      else if (media.imageAsset != null)
        SizedBox.expand(
            child: Image.asset(media.imageAsset!, fit: BoxFit.cover))
      else if (_error)
        Center(
          child: GestureDetector(
            onTap: _retry,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6), width: 3)),
                child: const FaIcon(FontAwesomeIcons.rotateRight,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(tr('photos.video_load_error'),
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ]),
          ),
        )
      else if (_loading)
        const Center(child: CircularProgressIndicator(color: Colors.white))
      else
        Center(
          child: media.isVideo
              ? Stack(alignment: Alignment.center, children: [
                  Opacity(
                      opacity: 0.3,
                      child: Text(media.emoji,
                          style: const TextStyle(fontSize: 130))),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 3)),
                    child: const FaIcon(FontAwesomeIcons.play,
                        color: Colors.white, size: 26),
                  ),
                ])
              : Text(media.emoji,
                  style: TextStyle(fontSize: 130, shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20)
                  ])),
        ),
      Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xD9000000), Colors.transparent],
                stops: [0, 0.5])),
      ),
      Positioned(
        bottom: 30,
        right: 70,
        left: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: post.avatarBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                alignment: Alignment.center,
                child: Text(post.avatar,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(post.name),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Row(children: [
                const FaIcon(FontAwesomeIcons.solidBuilding,
                    size: 10, color: Colors.white70),
                const SizedBox(width: 4),
                Text(tr(post.company),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11.5)),
              ]),
            ]),
          ]),
          const SizedBox(height: 8),
          Text('$stars ${post.stars}.0',
              style: const TextStyle(color: AppColors.gold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(tr(post.text),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.6)),
          const SizedBox(height: 6),
          Text(tr(post.time),
              style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
        ]),
      ),
      Positioned(
        bottom: 30,
        right: 12,
        child: Column(children: [
          if (videoReady) ...[
            _sideBtn(
              icon: _muted
                  ? FontAwesomeIcons.volumeXmark
                  : FontAwesomeIcons.volumeHigh,
              label:
                  _muted ? tr('photos.muted_label') : tr('photos.sound_label'),
              color: Colors.white,
              onTap: _toggleMute,
            ),
            const SizedBox(height: 18),
          ],
          _sideBtn(
            icon: post.liked
                ? FontAwesomeIcons.solidHeart
                : FontAwesomeIcons.solidHeart,
            label: '${post.likes}',
            color: post.liked ? const Color(0xFFFF4D6D) : Colors.white,
            onTap: _toggleLike,
          ),
          const SizedBox(height: 18),
          _sideBtn(
            icon: FontAwesomeIcons.solidComment,
            label: '${post.comments.length}',
            color: Colors.white,
            onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CommentsSheet(post: post)),
          ),
          const SizedBox(height: 18),
          _sideBtn(
              icon: FontAwesomeIcons.solidShareFromSquare,
              label: tr('photos.share_label'),
              color: Colors.white,
              onTap: () => sharePost(context)),
          const SizedBox(height: 18),
          _sideBtn(
            icon: FontAwesomeIcons.ticket,
            label: tr('photos.book_label'),
            color: Colors.white,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TripDetailScreen(
                trip: Trip(
                  title: '${tr(post.name)} ${tr(post.company)}',
                  emoji: media.emoji,
                  bg: media.bg,
                  hotel: tr(post.company),
                  stars: '★' * post.stars,
                  type: tr('photos.trip_type_label'),
                  days: '',
                  travelers: '',
                  price: '',
                  date: tr(post.time),
                  provider: tr(post.company),
                  dest: '',
                  accent: AppColors.blue,
                ),
              ),
            )),
          ),
        ]),
      ),
    ]);
  }

  Widget _sideBtn(
      {required FaIconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        FaIcon(icon, color: color, size: 28, shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 3)
        ]),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
