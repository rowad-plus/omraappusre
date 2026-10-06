import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/api_post.dart';
import '../../state/app_state.dart';
import '../../widgets/app_toast.dart';

/// Mirrors `#postSheet` — the "إنشاء منشور" composer modal, including the
/// optional "tag a company + rate it" flow (turns the post into a review).
class PostModal extends StatefulWidget {
  final VoidCallback onPosted;
  const PostModal({super.key, required this.onPosted});

  @override
  State<PostModal> createState() => _PostModalState();
}

class _PostModalState extends State<PostModal> {
  final _textCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  XFile? _video;
  Uint8List? _videoBytes;
  bool _submitting = false;

  int? _companyId;
  String _companyName = '';
  int _rating = 0;
  List<ApiFeaturedCompany> _companyResults = [];
  bool _companySearchOpen = false;
  Timer? _companyDebounce;

  static const _ratingKeys = [
    'photos.rating.poor',
    'photos.rating.fair',
    'photos.rating.good',
    'photos.rating.excellent',
    'photos.rating.amazing',
  ];

  void _onCompanyQueryChanged(String query) {
    _companyDebounce?.cancel();
    _companyDebounce =
        Timer(const Duration(milliseconds: 300), () => _searchCompanies(query.trim()));
  }

  Future<void> _searchCompanies(String query) async {
    final results = await context.read<AppState>().searchCompanies(query);
    if (!mounted) return;
    setState(() {
      _companyResults = results;
      _companySearchOpen = true;
    });
  }

  void _selectCompany(ApiFeaturedCompany c) {
    setState(() {
      _companyId = c.id;
      _companyName = c.name;
      _companySearchOpen = false;
      _companyCtrl.clear();
    });
  }

  void _removeCompany() {
    setState(() {
      _companyId = null;
      _companyName = '';
      _rating = 0;
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _image = picked;
      _imageBytes = bytes;
      // Photo and video are mutually exclusive — a post is one or the other.
      _video = null;
      _videoBytes = null;
    });
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker()
        .pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _video = picked;
      _videoBytes = bytes;
      _image = null;
      _imageBytes = null;
    });
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    final error = await context.read<AppState>().createTimelinePost(
          type: _companyId != null
              ? 'review'
              : _videoBytes != null
                  ? 'video'
                  : _imageBytes != null
                      ? 'photos'
                      : 'text',
          content: text,
          companyId: _companyId,
          rating: _rating > 0 ? _rating : null,
          imageBytes: _imageBytes,
          videoBytes: _videoBytes,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      showAppToast(context, error);
      return;
    }
    widget.onPosted();
    Navigator.of(context).pop();
    showAppToast(context, tr('photos.post_published_toast'));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _companyCtrl.dispose();
    _companyDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(tr('photos.create_post_title'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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
              const SizedBox(height: 14),
              TextField(
                controller: _textCtrl,
                maxLines: 4,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: tr('photos.post_text_hint'),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.border, width: 1.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.border, width: 1.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.blue, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              if (_image != null) ...[
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_imageBytes!,
                        height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _image = null;
                        _imageBytes = null;
                      }),
                      child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const FaIcon(FontAwesomeIcons.xmark,
                              size: 13, color: Colors.white)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
              ],
              if (_video != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.bg,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const FaIcon(FontAwesomeIcons.video,
                        size: 16, color: Color(0xFFE84040)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_video!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.text)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _video = null;
                        _videoBytes = null;
                      }),
                      child: const FaIcon(FontAwesomeIcons.xmark,
                          size: 14, color: AppColors.muted),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              Row(children: [
                Expanded(
                    child: _mediaBtn(
                        FontAwesomeIcons.solidCamera,
                        const Color(0xFFB8892F),
                        tr('photos.add_photos'),
                        _pickImage)),
                const SizedBox(width: 8),
                Expanded(
                    child: _mediaBtn(
                        FontAwesomeIcons.video,
                        const Color(0xFFE84040),
                        tr('photos.add_video'),
                        _pickVideo)),
              ]),
              const SizedBox(height: 14),
              _buildCompanySection(),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                            color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11))),
                    child: Text(tr('common.cancel'),
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11))),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(FontAwesomeIcons.check,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 7),
                              Text(tr('photos.publish_button'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ]),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('photos.tag_company_label'),
          style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.text)),
      const SizedBox(height: 8),
      if (_companyId != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.blueLight, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const FaIcon(FontAwesomeIcons.building, size: 12, color: AppColors.blue),
            const SizedBox(width: 6),
            Expanded(
                child: Text(_companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.text))),
            GestureDetector(
              onTap: _removeCompany,
              child: const FaIcon(FontAwesomeIcons.xmark, size: 13, color: AppColors.muted),
            ),
          ]),
        )
      else ...[
        TextField(
          controller: _companyCtrl,
          textAlign: TextAlign.right,
          onChanged: _onCompanyQueryChanged,
          onTap: () => setState(() => _companySearchOpen = true),
          decoration: InputDecoration(
            hintText: tr('photos.tag_company_hint'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
          ),
        ),
        if (_companySearchOpen) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10)),
            child: _companyResults.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(tr('photos.no_results'),
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)))
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      for (final c in _companyResults)
                        GestureDetector(
                          onTap: () => _selectCompany(c),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            child: Text(c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.text)),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ],
      if (_companyId != null) ...[
        const SizedBox(height: 12),
        Text(tr('photos.rate_company_label'),
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < _ratingKeys.length; i++) _ratingPill(i + 1),
        ]),
      ],
    ]);
  }

  Widget _ratingPill(int value) {
    final selected = _rating == value;
    return GestureDetector(
      onTap: () => setState(() => _rating = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: selected ? AppColors.blueLight : AppColors.bg,
            border: Border.all(color: selected ? AppColors.blue : AppColors.border),
            borderRadius: BorderRadius.circular(20)),
        child: Text(tr(_ratingKeys[value - 1]),
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.blue : AppColors.text)),
      ),
    );
  }

  Widget _mediaBtn(
      FaIconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.bg,
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FaIcon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
        ]),
      ),
    );
  }
}
