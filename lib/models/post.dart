import 'package:flutter/material.dart';

class PostComment {
  final String name;
  final String avatar;
  final Color avatarBg;
  final String text;

  const PostComment({
    required this.name,
    required this.avatar,
    required this.avatarBg,
    required this.text,
  });
}

class PostMedia {
  final Gradient bg;
  final String emoji;
  final String? videoLabel;
  final String? videoAsset;
  final String? imageAsset;
  /// A real photo/video URL from the backend — takes priority over
  /// [imageAsset]/[videoAsset] wherever the media is shown.
  final String? networkImage;
  final String? networkVideo;
  const PostMedia({
    required this.bg,
    required this.emoji,
    this.videoLabel,
    this.videoAsset,
    this.imageAsset,
    this.networkImage,
    this.networkVideo,
  });
  bool get isVideo => videoLabel != null || networkVideo != null;
}

/// A feed post on the "لقطات" (Photos/Snapshots) page.
class Post {
  /// Backend post id — null for local seed/demo posts.
  final int? apiId;
  final int id;
  final String avatar;
  final Color avatarBg;
  /// The author's uploaded photo; when null the initials in [avatar] show.
  final String? avatarUrl;
  final String name;
  final String time;
  /// Empty when the post isn't a company review (real posts can be plain
  /// text/photos with no associated company).
  final String company;
  /// Null when there's no company, or the company has no logo uploaded.
  final String? companyLogo;
  /// 0 when the post has no rating (real posts aren't always reviews).
  final int stars;
  final String text;
  final PostMedia? media;
  int likes;
  bool liked;
  final List<PostComment> comments;
  int commentsCount;

  Post({
    this.apiId,
    required this.id,
    required this.avatar,
    required this.avatarBg,
    this.avatarUrl,
    required this.name,
    required this.time,
    this.company = '',
    this.companyLogo,
    this.stars = 0,
    required this.text,
    this.media,
    this.likes = 0,
    this.liked = false,
    List<PostComment>? comments,
    int? commentsCount,
  })  : comments = comments ?? [],
        commentsCount = commentsCount ?? (comments?.length ?? 0);
}
