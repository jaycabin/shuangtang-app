import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';

final _api = ApiService();

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<Map<String, dynamic>> _moments = [];
  Map<String, dynamic>? _couple;
  Map<String, dynamic>? _partner;
  List<Map<String, dynamic>> _anniversaries = [];
  bool _loading = true;
  final _momentCtl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _couple = (await _api.getCoupleInfo())['data'];
      _moments = (_couple?['moments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _anniversaries = (await _api.getAnniversaries())['data'] ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadMore() async {}

  Future<void> _postMoment() async {
    if (_momentCtl.text.trim().isEmpty) return;
    try {
      await _api.createMoment({'content': _momentCtl.text.trim()});
      _momentCtl.clear();
      await _load();
    } catch (_) {}
  }

  @override
  void dispose() {
    _momentCtl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _couple?['couple']?['started_at'] != null
        ? DateTime.now().difference(DateTime.parse(_couple!['couple']['started_at'])).inDays
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('🍬', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          const Text('双糖', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_couple != null)
            Text('$days 天', style: TextStyle(color: AppTheme.primaryStart, fontSize: 13)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryStart,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryStart))
            : ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTopCard(days),
                  const SizedBox(height: 16),
                  _buildQuickMoment(),
                  const SizedBox(height: 16),
                  if (_anniversaries.isNotEmpty) _buildAnniversaryCard(),
                  const SizedBox(height: 12),
                  ..._moments.map((m) => _buildMomentCard(m)),
                  if (_moments.isEmpty) _buildEmptyState(),
                ],
              ),
      ),
    );
  }

  Widget _buildTopCard(int days) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: [
        const Text('🍯', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text('攒了 $days 颗糖的日子',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text('两颗心，双倍糖', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
      ]),
    );
  }

  Widget _buildQuickMoment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
      child: Column(children: [
        Row(children: [
          const CircleAvatar(radius: 18, backgroundColor: AppTheme.primaryStart, child: Icon(Icons.person, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: _momentCtl, maxLines: 2,
            decoration: const InputDecoration(hintText: '今天想撒什么糖？', border: InputBorder.none, isDense: true),
          )),
        ]),
        const Divider(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            _iconBtn(Icons.emoji_emotions_outlined),
            _iconBtn(Icons.photo_library_outlined),
            _iconBtn(Icons.location_on_outlined),
          ]),
          Container(
            decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(20)),
            child: TextButton(
              onPressed: _postMoment,
              child: const Text('撒颗糖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _iconBtn(IconData icon) => IconButton(
    icon: Icon(icon, color: AppTheme.textHint, size: 20),
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, onPressed: () {});

  Widget _buildAnniversaryCard() {
    final next = _anniversaries.firstWhere(
      (a) {
        final d = DateTime.parse(a['date']);
        return d.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      },
      orElse: () => _anniversaries.first,
    );
    final date = DateTime.parse(next['date']);
    final diff = date.difference(DateTime.now()).inDays;
    final title = next['title']?['zh'] ?? '纪念日';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryStart.withOpacity(0.1), AppTheme.primaryEnd.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primaryStart.withOpacity(0.2)),
      ),
      child: Row(children: [
        Text(next['icon'] ?? '❤️', style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          Text(diff == 0 ? '就是今天！' : diff < 0 ? '已过去 ${-diff} 天' : '还剩 $diff 天',
            style: TextStyle(color: diff == 0 ? AppTheme.primaryStart : AppTheme.textSecondary, fontSize: 13)),
        ])),
        Text('$diff', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.primaryStart)),
      ]),
    );
  }

  Widget _buildMomentCard(Map<String, dynamic> m) {
    final author = m['author_id']?.toString() ?? '';
    final isMe = author == Hive.box('settings').get('user_id');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 16, backgroundColor: isMe ? AppTheme.primaryStart : AppTheme.primaryEnd,
          child: Text(isMe ? '我' : 'TA', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['content'] ?? '', style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary)),
          if (m['mood_tag'] != null && m['mood_tag'] != '')
            Padding(padding: const EdgeInsets.only(top: 4),
              child: Text('#${m['mood_tag']}', style: TextStyle(color: AppTheme.primaryStart, fontSize: 12))),
          Padding(padding: const EdgeInsets.only(top: 4),
            child: Text(_fmt(m['created_at']), style: const TextStyle(color: AppTheme.textHint, fontSize: 11))),
        ])),
      ]),
    );
  }

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      const Text('📝', style: TextStyle(fontSize: 48)), const SizedBox(height: 12),
      const Text('还没有糖，快撒第一颗吧', style: TextStyle(color: AppTheme.textHint)),
    ]),
  );

  String _fmt(String? ts) {
    if (ts == null) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return '刚刚';
    if (d.inMinutes < 60) return '${d.inMinutes}分钟前';
    if (d.inHours < 24) return '${d.inHours}小时前';
    return '${d.inDays}天前';
  }
}
