import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_colors.dart';
import 'trip_video_player.dart';

/// The trip's photos and videos as square tiles (3 per row) — shown at the
/// very bottom of the booking screen, under the booking and payment parts.
/// Tap a photo: full-screen swipeable viewer (pinch to zoom). Tap a video:
/// full-screen player.
class TripMediaGrid extends StatelessWidget {
  final List<String> images;
  final List<String> videos;
  const TripMediaGrid({super.key, required this.images, required this.videos});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (var i = 0; i < images.length; i++)
        _tile(
          context,
          child: CachedNetworkImage(
            imageUrl: images[i],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.bg),
            errorWidget: (_, __, ___) => Container(
                color: AppColors.bg,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.muted)),
          ),
          onTap: () => _openImages(context, i),
        ),
      for (final v in videos)
        _tile(
          context,
          child: Container(
            color: Colors.black,
            child: const Center(
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: FaIcon(FontAwesomeIcons.play,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
          onTap: () => _openVideo(context, v),
        ),
    ];
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: tiles,
    );
  }

  Widget _tile(BuildContext context,
          {required Widget child, required VoidCallback onTap}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.expand(child: child),
          ),
        ),
      );

  void _openImages(BuildContext context, int start) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ImageViewer(images: images, start: start),
    ));
  }

  void _openVideo(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(child: TripVideoPlayer(url: url)),
      ),
    ));
  }
}

class _ImageViewer extends StatefulWidget {
  final List<String> images;
  final int start;
  const _ImageViewer({required this.images, required this.start});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _pc = PageController(initialPage: widget.start);
  late int _index = widget.start;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}',
            style: const TextStyle(fontSize: 14)),
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
                imageUrl: widget.images[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
