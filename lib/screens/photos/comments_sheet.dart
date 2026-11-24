import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/post.dart';
import '../../state/app_state.dart';
import '../auth/login_sheet.dart';

/// Mirrors `#cmtSheet` — the comments list + input for a feed post.
class CommentsSheet extends StatefulWidget {
  final Post post;
  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late List<PostComment> _comments = List.of(widget.post.comments);
  bool _loading = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.apiId != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final comments = await context.read<AppState>().fetchTimelineComments(widget.post.apiId!);
    if (!mounted) return;
    setState(() {
      _comments = comments.map((c) => c.toPostComment()).toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    if (!context.read<AppState>().isLoggedIn) {
      openLoginSheet(context, toSearch: false);
      return;
    }

    final apiId = widget.post.apiId;
    if (apiId == null) {
      setState(() {
        _comments.add(PostComment(
            name: tr('photos.you_label'), avatar: tr('photos.me_avatar_label'), avatarBg: AppColors.blue, text: text));
        _ctrl.clear();
      });
      _scrollToEnd();
      return;
    }

    setState(() => _sending = true);
    final comment = await context.read<AppState>().addTimelineComment(apiId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (comment != null) {
      setState(() {
        _comments.add(comment.toPostComment());
        widget.post.commentsCount++;
        _ctrl.clear();
      });
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(children: [
          Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '${tr('photos.comments_title')} (${_comments.length})',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: AppColors.bg, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const FaIcon(FontAwesomeIcons.xmark,
                            size: 14, color: AppColors.muted)),
                  ),
                ]),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : ListView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _comments.length,
              itemBuilder: (context, i) {
                final c = _comments[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: c.avatarBg, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(c.avatar,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 8),
                            decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr(c.name),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text)),
                                  Text(tr(c.text),
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.text)),
                                ]),
                          ),
                        ),
                      ]),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                14, 10, 14, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border))),
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
                    size: 13, color: AppColors.muted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.right,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: tr('photos.comment_hint'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppColors.border, width: 1.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppColors.border, width: 1.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppColors.blue, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                        color: AppColors.blue, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: _sending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : FaIcon(FontAwesomeIcons.solidPaperPlane,
                            size: 14,
                            color: Colors.white,
                            semanticLabel: tr('photos.comment_submit'))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
