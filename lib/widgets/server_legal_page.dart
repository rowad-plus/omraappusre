import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../state/app_state.dart';
import 'legal_section.dart';
import 'sub_page_header.dart';

/// A legal page (privacy / terms / refund) whose text is managed in the
/// admin (Admin → Pages) — the same content the website shows. Until it
/// loads, or if it can't be loaded, the text built into the app is shown.
class ServerLegalPage extends StatefulWidget {
  final String type; // privacy | terms | refund
  final String title;
  final List<Widget> fallback;
  const ServerLegalPage(
      {super.key,
      required this.type,
      required this.title,
      required this.fallback});

  @override
  State<ServerLegalPage> createState() => _ServerLegalPageState();
}

class _ServerLegalPageState extends State<ServerLegalPage> {
  List<_Block>? _blocks;
  String? _serverTitle;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().fetchContentPage(widget.type).then((page) {
      if (!mounted || page == null) return;
      final blocks = _parse(page.html);
      if (blocks.isEmpty) return;
      setState(() {
        _blocks = blocks;
        _serverTitle = page.title.isEmpty ? null : page.title;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: _serverTitle ?? widget.title),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: blocks == null
            ? widget.fallback
            : [
                for (final b in blocks)
                  LegalSection(
                    icon: FontAwesomeIcons.circleInfo,
                    title: b.title ?? _serverTitle ?? widget.title,
                    text: b.paragraphs.isEmpty ? null : b.paragraphs.join('\n\n'),
                    bullets: b.bullets.isEmpty ? null : b.bullets,
                  ),
              ],
      ),
    );
  }
}

class _Block {
  String? title;
  final paragraphs = <String>[];
  final bullets = <String>[];
  _Block([this.title]);
  bool get isEmpty => paragraphs.isEmpty && bullets.isEmpty;
}

/// Turns the admin's simple HTML (headings, paragraphs, lists) into
/// sections: each heading starts a section; p / li fill it.
List<_Block> _parse(String html) {
  final blocks = <_Block>[];
  var current = _Block();
  final tag = RegExp(r'<(h[1-6]|p|li)\b[^>]*>(.*?)</\1>',
      caseSensitive: false, dotAll: true);
  for (final m in tag.allMatches(html)) {
    final name = m.group(1)!.toLowerCase();
    final text = _plain(m.group(2)!);
    if (text.isEmpty) continue;
    if (name.startsWith('h')) {
      if (!current.isEmpty || current.title != null) blocks.add(current);
      current = _Block(text);
    } else if (name == 'li') {
      current.bullets.add(text);
    } else {
      current.paragraphs.add(text);
    }
  }
  if (!current.isEmpty) blocks.add(current);
  // Plain text without any of those tags: one section of paragraphs.
  if (blocks.isEmpty) {
    final text = _plain(html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n'));
    if (text.isNotEmpty) blocks.add(_Block()..paragraphs.add(text));
  }
  return blocks;
}

String _plain(String s) => s
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&#039;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'[ \t]+'), ' ')
    .trim();
