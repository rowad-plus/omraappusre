import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/translations.dart';
import '../../models/design_request.dart';
import '../../services/live_updates.dart';
import '../../state/app_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/sub_page_header.dart';
import 'design_request_detail_sheet.dart';

/// "طلبات صمّم عمرتك" — every design request the customer sent, with the
/// status the admin set, refreshed live when the status changes (push).
class MyDesignRequestsScreen extends StatefulWidget {
  /// Opens this request's tracker right away (from a notification tap).
  final int? openRequestId;
  const MyDesignRequestsScreen({super.key, this.openRequestId});

  @override
  State<MyDesignRequestsScreen> createState() => _MyDesignRequestsScreenState();
}

class _MyDesignRequestsScreenState extends State<MyDesignRequestsScreen>
    with LiveReload<MyDesignRequestsScreen> {
  @override
  Future<void> onLiveUpdate() => _load();

  bool _loading = true;
  bool _failed = false;
  List<UmrahDesignRequest> _requests = [];
  late int? _pendingOpenId = widget.openRequestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    if (!state.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    final list = await state.fetchDesignRequests();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = list == null;
      if (list != null) _requests = list;
    });
    final openId = _pendingOpenId;
    if (openId != null) {
      _pendingOpenId = null;
      for (final r in _requests) {
        if (r.apiId == openId) _open(r);
      }
    }
  }

  void _open(UmrahDesignRequest r) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DesignRequestDetailSheet(request: r),
      );

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AppState>().isLoggedIn;
    Widget body;
    if (_loading) {
      body = const Center(
          child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2)));
    } else if (!loggedIn || _requests.isEmpty) {
      body = ListView(children: [
        const SizedBox(height: 120),
        const Center(child: Text('🕋', style: TextStyle(fontSize: 44))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
              tr(!loggedIn
                  ? 'design.my_requests.login'
                  : _failed
                      ? 'design.my_requests.error'
                      : 'design.my_requests.empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.muted, height: 1.7)),
        ),
      ]);
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => DesignRequestCard(
            request: _requests[i], onTap: () => _open(_requests[i])),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: SubPageHeader(title: tr('design.my_requests.title')),
      body: RefreshIndicator(onRefresh: _load, child: body),
    );
  }
}

/// Colour + label of a request's current status.
(Color, String) designStatusStyle(DesignRequestStage s) => switch (s) {
      DesignRequestStage.received => (
          const Color(0xFFD97706),
          tr('design.status.received')
        ),
      DesignRequestStage.reviewed => (
          AppColors.blue,
          tr('design.status.reviewed')
        ),
      DesignRequestStage.completed => (
          AppColors.green,
          tr('design.status.completed')
        ),
      DesignRequestStage.cancelled => (
          const Color(0xFFDC2626),
          tr('design.status.cancelled')
        ),
    };

String formatDesignDate(DateTime? d) => d == null
    ? ''
    : intl.DateFormat('d MMMM yyyy', LocaleState.locale.value.languageCode)
        .format(d);

class DesignRequestCard extends StatelessWidget {
  final UmrahDesignRequest request;
  final VoidCallback onTap;
  const DesignRequestCard(
      {super.key, required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (color, label) = designStatusStyle(request.stage);
    final r = request;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFFFBF5E8),
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: const Text('🕋', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('design.hub.request_type_label'),
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text('${r.ref} · ${formatDesignDate(r.createdAt)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
              [
                tr(r.startPoint),
                '${r.makkaDays + r.madinaDays} ${tr('design.unit.days')}',
                '${r.adults} ${tr('design.unit.adult')}',
              ].where((s) => s.trim().isNotEmpty).join(' · '),
              style: const TextStyle(fontSize: 12, color: AppColors.text)),
          const SizedBox(height: 10),
          DesignStageBar(stage: r.stage),
        ]),
      ),
    );
  }
}

/// Compact 3-step progress bar (received → reviewed → completed).
class DesignStageBar extends StatelessWidget {
  final DesignRequestStage stage;
  const DesignStageBar({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    if (stage == DesignRequestStage.cancelled) {
      return Row(children: [
        const FaIcon(FontAwesomeIcons.circleXmark,
            size: 12, color: Color(0xFFDC2626)),
        const SizedBox(width: 6),
        Text(tr('design.tracker.cancelled'),
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626))),
      ]);
    }
    final reached = stage.index; // received=0, reviewed=1, completed=2
    return Row(children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
                color: i <= reached ? AppColors.green : AppColors.border,
                borderRadius: BorderRadius.circular(3)),
          ),
        ),
      ],
    ]);
  }
}
