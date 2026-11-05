import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_colors.dart';

/// Company-uploaded trip video: tap to play / pause, 16:9 until the real
/// aspect ratio is known.
class TripVideoPlayer extends StatefulWidget {
  final String url;
  const TripVideoPlayer({super.key, required this.url});

  @override
  State<TripVideoPlayer> createState() => _TripVideoPlayerState();
}

class _TripVideoPlayerState extends State<TripVideoPlayer> {
  late final VideoPlayerController _c;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ready && _c.value.aspectRatio > 0 ? _c.value.aspectRatio : 16 / 9;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: ratio,
        child: Container(
          color: Colors.black,
          child: _failed
              ? const Center(
                  child: Icon(Icons.videocam_off, color: Colors.white54, size: 36))
              : !_ready
                  ? const Center(
                      child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.brand)))
                  : GestureDetector(
                      onTap: () => _c.value.isPlaying ? _c.pause() : _c.play(),
                      child: Stack(alignment: Alignment.center, children: [
                        VideoPlayer(_c),
                        if (!_c.value.isPlaying)
                          Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                                color: Colors.black45, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 40),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: VideoProgressIndicator(_c,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                  playedColor: AppColors.brand)),
                        ),
                      ]),
                    ),
        ),
      ),
    );
  }
}
