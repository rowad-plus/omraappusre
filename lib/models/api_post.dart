import 'package:flutter/material.dart';
import 'post.dart';

Color _colorFromHex(String hex) {
  final clean = hex.replaceAll('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

/// A timeline post as returned by the real Front API (`/timeline/posts`).
/// [toPost] adapts it into the display-only [Post] model the existing
/// feed widgets already know how to render.
class ApiPost {
  final int id;
  final String userName;
  final String userInit;
  final String userColor;
  final String? userAvatar;
  final String? companyName;
  final String? companyLogo;
  final int? companyId;
  final int? rating;
  final String content;
  final String type; // text | photos | video | review
  final List<String> media;
  final int likesCount;
  final int commentsCount;
  final bool liked;
  final String time;

  const ApiPost({
    required this.id,
    required this.userName,
    required this.userInit,
    required this.userColor,
    this.userAvatar,
    this.companyName,
    this.companyLogo,
    this.companyId,
    this.rating,
    required this.content,
    required this.type,
    this.media = const [],
    required this.likesCount,
    required this.commentsCount,
    required this.liked,
    required this.time,
  });

  factory ApiPost.fromJson(Map<String, dynamic> j) => ApiPost(
        id: j['id'] as int,
        userName: j['user_name'] as String? ?? '',
        userInit: j['user_init'] as String? ?? '',
        userColor: j['user_color'] as String? ?? '#999999',
        userAvatar: j['user_avatar'] as String?,
        companyName: j['company_name'] as String?,
        companyLogo: j['company_logo'] as String?,
        companyId: j['company_id'] as int?,
        rating: j['rating'] as int?,
        content: j['content'] as String? ?? '',
        type: j['type'] as String? ?? 'text',
        media: (j['media'] as List<dynamic>?)?.cast<String>() ?? const [],
        likesCount: j['likes_count'] as int? ?? 0,
        commentsCount: j['comments_count'] as int? ?? 0,
        liked: j['liked'] as bool? ?? false,
        time: j['time'] as String? ?? '',
      );

  bool get _isVideo => type == 'video';

  Post toPost() {
    final firstMedia = media.isNotEmpty ? media.first : null;
    return Post(
      apiId: id,
      id: id,
      avatar: userInit,
      avatarBg: _colorFromHex(userColor),
      avatarUrl: userAvatar,
      name: userName,
      time: time,
      company: companyName ?? '',
      companyLogo: companyLogo,
      stars: rating ?? 0,
      text: content,
      likes: likesCount,
      liked: liked,
      commentsCount: commentsCount,
      media: firstMedia != null
          ? PostMedia(
              bg: const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF334155)]),
              emoji: _isVideo ? '🎬' : '📷',
              videoLabel: _isVideo ? 'photos.type_video' : null,
              networkVideo: _isVideo ? firstMedia : null,
              networkImage: _isVideo ? null : firstMedia,
            )
          : null,
    );
  }
}

class ApiFeaturedCompany {
  final int id;
  final String name;
  final String? logo;
  const ApiFeaturedCompany({required this.id, required this.name, this.logo});

  factory ApiFeaturedCompany.fromJson(Map<String, dynamic> j) => ApiFeaturedCompany(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        logo: j['logo'] as String?,
      );
}

class ApiNearbyTrip {
  final int id;
  final String title;
  final String type;
  final double price;
  final String currency;
  final int hotelStars;
  final String? thumbnail;
  const ApiNearbyTrip({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
    required this.currency,
    required this.hotelStars,
    this.thumbnail,
  });

  factory ApiNearbyTrip.fromJson(Map<String, dynamic> j) => ApiNearbyTrip(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        type: j['type'] as String? ?? 'economy',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? '',
        hotelStars: j['hotel_stars'] as int? ?? 0,
        thumbnail: j['thumbnail'] as String?,
      );
}

class ApiPostComment {
  final int id;
  final String userName;
  final String userColor;
  final String userInit;
  final String? userAvatar;
  final String content;
  final String time;

  const ApiPostComment({
    required this.id,
    required this.userName,
    required this.userColor,
    required this.userInit,
    this.userAvatar,
    required this.content,
    required this.time,
  });

  factory ApiPostComment.fromJson(Map<String, dynamic> j) => ApiPostComment(
        id: j['id'] as int,
        userName: j['user_name'] as String? ?? '',
        userColor: j['user_color'] as String? ?? '#999999',
        userInit: j['user_init'] as String? ?? '',
        userAvatar: j['user_avatar'] as String?,
        content: j['content'] as String? ?? '',
        time: j['time'] as String? ?? '',
      );

  PostComment toPostComment() => PostComment(
        name: userName,
        avatar: userInit,
        avatarBg: _colorFromHex(userColor),
        text: content,
      );
}
