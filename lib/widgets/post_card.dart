import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../core/constants/app_dims.dart';
import '../core/theme/app_colors.dart';
import '../l10n/translations.dart';
import '../models/post.dart';

/// Mirrors `.snap-post` — a single feed card on the لقطات (Photos) page.
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLikeToggle;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback? onMediaTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.onCommentTap,
    required this.onShareTap,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    final stars = '★' * post.stars + '☆' * (5 - post.stars);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppDims.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(color: post.avatarBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: post.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: post.avatarUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Text(post.avatar,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  )
                : Text(post.avatar,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(post.name),
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
              Text(tr(post.time),
                  style:
                      const TextStyle(fontSize: 10.5, color: AppColors.muted)),
              // With media the company sits on the photo instead (_CompanyBadge).
              if (post.company.isNotEmpty && post.media == null) ...[
                const SizedBox(height: 3),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (post.companyLogo != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: post.companyLogo!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (post.companyLogo == null) ...[
                        const FaIcon(FontAwesomeIcons.solidBuilding,
                            size: 9, color: AppColors.green),
                        const SizedBox(width: 4),
                      ],
                      Text(tr(post.company),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green)),
                    ]),
                  ),
                ]),
              ],
            ]),
          ),
        ]),
        if (post.stars > 0) ...[
          const SizedBox(height: 10),
          Row(children: [
            Text(stars,
                style: const TextStyle(color: AppColors.gold, fontSize: 14)),
            const SizedBox(width: 6),
            Text('${post.stars}.0',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
          ]),
        ],
        const SizedBox(height: 8),
        Text(tr(post.text),
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.text, height: 1.75)),
        if (post.media != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onMediaTap,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                  gradient: post.media!.bg,
                  borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias,
              child: Stack(children: [
                Positioned.fill(
                  child: _PostMediaBox(
                      media: post.media!,
                      visibilityKey: 'post-media-${post.id}'),
                ),
                if (post.company.isNotEmpty)
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: _CompanyBadge(
                        name: tr(post.company), logo: post.companyLogo),
                  ),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(
              child: _actionBtn(
                icon: post.liked
                    ? FontAwesomeIcons.solidHeart
                    : FontAwesomeIcons.solidHeart,
                label: '${post.likes}',
                color: post.liked ? const Color(0xFFE84040) : AppColors.muted,
                onTap: onLikeToggle,
              ),
            ),
            Expanded(
              child: _actionBtn(
                  icon: FontAwesomeIcons.solidComment,
                  label: '${post.commentsCount}',
                  color: AppColors.muted,
                  onTap: onCommentTap),
            ),
            Expanded(
              child: _actionBtn(
                  icon: FontAwesomeIcons.solidShareFromSquare,
                  label: tr('photos.share_label'),
                  color: AppColors.muted,
                  onTap: onShareTap),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(
      {required FaIconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FaIcon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

/// White pill with the tagged company's logo + name, laid over the post's
/// photo/video (mirrors `.media-co-badge` on the site).
class _CompanyBadge extends StatelessWidget {
  final String name;
  final String? logo;
  const _CompanyBadge({required this.name, this.logo});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(5, 4, 10, 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18), blurRadius: 8),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (logo != null)
            ClipOval(
              child: CachedNetworkImage(
                  imageUrl: logo!, width: 20, height: 20, fit: BoxFit.cover),
            )
          else
            const FaIcon(FontAwesomeIcons.solidBuilding,
                size: 11, color: AppColors.green),
          const SizedBox(width: 6),
          Flexible(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
          ),
        ]),
      ),
    );
  }
}

/// The media area of a feed card: shows a real image for photos, and for
/// videos, plays the actual clip muted (paused on its first frame as a
/// thumbnail until scrolled into view, per [VisibilityDetector]).
class _PostMediaBox extends StatefulWidget {
  final PostMedia media;
  final String visibilityKey;
  const _PostMediaBox({required this.media, required this.visibilityKey});

  @override
  State<_PostMediaBox> createState() => _PostMediaBoxState();
}

class _PostMediaBoxState extends State<_PostMediaBox> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final videoAsset = widget.media.videoAsset;
    final networkVideo = widget.media.networkVideo;
    if (videoAsset != null || networkVideo != null) {
      final controller = networkVideo != null
          ? VideoPlayerController.networkUrl(Uri.parse(networkVideo))
          : VideoPlayerController.asset(videoAsset!);
      _controller = controller;
      controller.setLooping(true);
      controller.setVolume(0);
      controller.initialize().then((_) async {
        if (!mounted) return;
        await controller.play();
        await controller.pause();
        await controller.seekTo(Duration.zero);
        if (!mounted) return;
        setState(() => _ready = true);
      }).catchError((Object e) {
        // ignore: avoid_print
        print('Feed video thumbnail failed to load: $videoAsset — $e');
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final controller = _controller;
    if (controller == null || !_ready) return;
    if (info.visibleFraction > 0.6) {
      if (!controller.value.isPlaying) controller.play();
    } else {
      if (controller.value.isPlaying) controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final controller = _controller;
    final videoReady = controller != null && _ready;
    return Stack(alignment: Alignment.center, children: [
      if (videoReady)
        VisibilityDetector(
          key: Key(widget.visibilityKey),
          onVisibilityChanged: _onVisibilityChanged,
          child: IgnorePointer(
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
        )
      else if (!media.isVideo && media.networkImage != null)
        Positioned.fill(
            child: CachedNetworkImage(
                imageUrl: media.networkImage!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (_, __, ___) =>
                    Text(media.emoji, style: const TextStyle(fontSize: 60))))
      else if (!media.isVideo && media.imageAsset != null)
        Positioned.fill(
            child: Image.asset(media.imageAsset!, fit: BoxFit.cover))
      else
        Text(media.emoji, style: const TextStyle(fontSize: 60)),
      if (media.isVideo && !videoReady)
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const FaIcon(FontAwesomeIcons.play,
              color: AppColors.blue, size: 20),
        ),
      if (media.isVideo)
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const FaIcon(FontAwesomeIcons.video,
                  size: 10, color: Colors.white),
              const SizedBox(width: 4),
              Text(tr(media.videoLabel!),
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
            ]),
          ),
        ),
    ]);
  }
}
