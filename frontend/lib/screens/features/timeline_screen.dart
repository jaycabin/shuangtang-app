import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _anniversaries = [];
  bool _loading = true;
  int _days = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final coupleR = await _api.getCoupleInfo();
      _couple = coupleR['data'];
      if (_couple?['couple']?['started_at'] != null) {
        _days = DateTime.now().difference(DateTime.parse(_couple!['couple']['started_at'])).inDays;
      }
      // 分别加载时间线和纪念日
      final tlR = await _api.getTimeline();
      _moments = (tlR['data']?['moments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _days = tlR['data']?['days_since'] ?? _days;
    } catch (e) { debugPrint("err: $e"); }
    try {
      final aR = await _api.getAnniversaries();
      _anniversaries = (aR['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) { debugPrint("err: $e"); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('糖罐首页'),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.caramel), onPressed: () {})],
      ),
      body: RefreshIndicator(
        color: AppColors.peach,
        onRefresh: _load,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.peach))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),
                _buildAtmosphereCard(),
                const SizedBox(height: 16),
                if (_anniversaries.isNotEmpty) ...[_buildAnniversaryCard(), const SizedBox(height: 16)],
                ..._moments.map((m) => _buildMomentCard(m)),
                if (_moments.isEmpty) _buildEmptyState(),
                const SizedBox(height: 80),
              ],
            ),
      ),
    );
  }

  Widget _buildAtmosphereCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      child: Column(children: [
        const Text('🍯', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text('攒了 $_days 颗糖的日子', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text('两颗心，双倍糖', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
      ]),
    );
  }

  Widget _buildAnniversaryCard() {
    if (_anniversaries.isEmpty) return const SizedBox();
    final next = _anniversaries.firstWhere(
      (a) => DateTime.parse(a['date']).isAfter(DateTime.now().subtract(const Duration(days: 1))),
      orElse: () => _anniversaries.first,
    );
    final date = DateTime.parse(next['date']);
    final diff = date.difference(DateTime.now()).inDays;
    final title = next['title']?['zh'] ?? '纪念日';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      child: Row(children: [
        Text(next['icon'] ?? '❤️', style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 2),
          Text(diff == 0 ? '🎉 就是今天！' : '还剩 $diff 天', style: TextStyle(fontSize: 13, color: diff == 0 ? AppColors.peach : AppColors.caramel)),
        ])),
        if (diff > 0) Text('$diff', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.peach)),
      ]),
    );
  }

  Widget _buildMomentCard(Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 18, backgroundColor: AppColors.peach.withOpacity(0.15),
          child: Text(m['type'] == 'moment' ? '📸' : '✅', style: const TextStyle(fontSize: 16))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['content'] ?? '', style: AppTextStyles.body),
          if (m['mood_tag'] != null && m['mood_tag'] != '')
            Padding(padding: const EdgeInsets.only(top: 6),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.peach.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.tag)),
                child: Text('#${m['mood_tag']}', style: const TextStyle(fontSize: 11, color: AppColors.peach)))),
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(_fmt(m['created_at']), style: AppTextStyles.caption)),
        ])),
      ]),
    );
  }

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      const Text('🍬', style: TextStyle(fontSize: 64)), const SizedBox(height: 16),
      const Text('你们的糖，从这里开始攒起', style: TextStyle(color: AppColors.caramel)),
      const SizedBox(height: 24),
      Container(height: 48,
        decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.button), boxShadow: AppShadows.button),
        child: ElevatedButton(
          onPressed: () { Navigator.pushReplacementNamed(context, "/home"); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
          child: const Text('撒第一颗糖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
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
