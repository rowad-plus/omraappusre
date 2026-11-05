import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_colors.dart';

/// Trip card picture area: the company's video plays muted on a loop; else
/// several photos slide by themselves (every 3 s, swipeable, dots); else the
/// card's normal single image ([fallback]).
class CardMedia extends StatelessWidget {
  final String? video;
  final List<String> photos;
  final Widget fallback;
  const CardMedia(
      {super.key, this.video, this.photos = const [], required this.fallback});

  @override
  Widget build(BuildContext context) {
    if ((video ?? '').isNotEmpty) {
      return _MutedLoopVideo(url: video!, poster: photos.isNotEmpty ? photos.first : null, fallback: fallback);
    }
    if (photos.length > 1) return _AutoPhotos(photos: photos);
    return fallback;
  }
}

class _MutedLoopVideo extends StatefulWidget {
  final String url;
  final String? poster;
  final Widget fallback;
  const _MutedLoopVideo({required this.url, this.poster, required this.fallback});

  @override
  State<_MutedLoopVideo> createState() => _MutedLoopVideoState();
}

class _MutedLoopVideoState extends State<_MutedLoopVideo> {
  late final VideoPlayerController _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    _c.setVolume(0);
    _c.setLooping(true);
    _c.initialize().then((_) {
      if (!mounted) return;
      _c.setVolume(0);
      _c.play();
      setState(() => _ready = true);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return widget.poster != null
          ? CachedNetworkImage(imageUrl: widget.poster!, fit: BoxFit.cover)
          : widget.fallback;
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _c.value.size.width,
        height: _c.value.size.height,
        child: VideoPlayer(_c),
      ),
    );
  }
}

class _AutoPhotos extends StatefulWidget {
  final List<String> photos;
  const _AutoPhotos({required this.photos});

  @override
  State<_AutoPhotos> createState() => _AutoPhotosState();
}

class _AutoPhotosState extends State<_AutoPhotos> {
  final _pc = PageController();
  Timer? _t;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pc.hasClients) return;
      final next = (_i + 1) % widget.photos.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        controller: _pc,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _i = i),
        itemBuilder: (_, i) =>
            CachedNetworkImage(imageUrl: widget.photos[i], fit: BoxFit.cover),
      ),
      Positioned(
        top: 10,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.photos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == _i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _i ? AppColors.brand : Colors.white70,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}
