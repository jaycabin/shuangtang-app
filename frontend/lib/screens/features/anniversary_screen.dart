import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';

final _api = ApiService();

class AnniversaryScreen extends StatefulWidget {
  const AnniversaryScreen({super.key});
  @override
  State<AnniversaryScreen> createState() => _AnniversaryScreenState();
}

class _AnniversaryScreenState extends State<AnniversaryScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getAnniversaries();
      _list = (r['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final ctl1 = TextEditingController();
    final ctl2 = TextEditingController();
    DateTime? picked;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建纪念日'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctl1, decoration: const InputDecoration(labelText: '标题（如：在一起的日子')),
          const SizedBox(height: 8),
          TextField(controller: ctl2, readOnly: true, decoration: const InputDecoration(labelText: '日期'),
            onTap: () async {
              picked = await showDatePicker(context: ctx, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: DateTime.now());
              if (picked != null) ctl2.text = picked.toString().substring(0, 10);
            }),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('不了')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('嗯')),
        ],
      ),
    );

    if (ok == true && ctl1.text.isNotEmpty && picked != null) {
      await _api.createAnniversary({'title': {'zh': ctl1.text}, 'date': picked.toString().substring(0, 10)});
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍰 糖分纪念簿'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _create)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryStart))
          : _list.isEmpty ? _empty() : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _list.length,
                itemBuilder: (_, i) => _buildCard(_list[i]),
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> a) {
    final date = DateTime.parse(a['date']);
    final diff = date.difference(DateTime.now()).inDays;
    final isToday = diff == 0;
    final past = diff < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.primaryStart.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: isToday ? Border.all(color: AppTheme.primaryStart, width: 2) : null,
        boxShadow: isToday ? AppTheme.cardShadow : null,
      ),
      child: Row(children: [
        Text(a['icon'] ?? '❤️', style: TextStyle(fontSize: isToday ? 40 : 32)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['title']?['zh'] ?? '纪念日', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isToday ? AppTheme.primaryStart : AppTheme.textPrimary)),
          Text(isToday ? '🎉 就是今天！' : past ? '已过去 ${-diff} 天' : '还剩 $diff 天',
            style: TextStyle(color: isToday ? AppTheme.primaryStart : AppTheme.textSecondary, fontSize: 13)),
          Text(a['date'], style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
        ])),
        if (!past && !isToday)
          Text('$diff', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.primaryStart)),
      ]),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📅', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('还没有纪念日', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      ElevatedButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('标记第一颗糖'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryStart, foregroundColor: Colors.white)),
    ]),
  );
}
