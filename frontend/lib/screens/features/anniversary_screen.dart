import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/sugar_particles.dart';

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
      // 检查今天是否有纪念日
      for (final a in _list) {
        try {
          final d = DateTime.parse(a['date']);
          if (d.month == DateTime.now().month && d.day == DateTime.now().day) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _showCelebration(a));
          }
        } catch (e) { debugPrint("err: $e"); }
      }
    } catch (e) { debugPrint("err: $e"); }
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final tCtl = TextEditingController();
    final dCtl = TextEditingController();
    DateTime? picked;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
        title: const Text('创建纪念日'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: tCtl, decoration: const InputDecoration(labelText: '标题')),
          const SizedBox(height: 8),
          TextField(controller: dCtl, readOnly: true, decoration: const InputDecoration(labelText: '日期'),
            onTap: () async {
              picked = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null) dCtl.text = picked.toString().substring(0, 10);
            }),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('不了')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('嗯')),
        ],
      ),
    );
    if (ok == true && tCtl.text.isNotEmpty && picked != null) {
      await _api.createAnniversary({'title': {'zh': tCtl.text}, 'date': picked.toString().substring(0, 10)});
      _load();
    }
  }

  void _showCelebration(Map<String, dynamic> a) {
    final title = a['title']?['zh'] ?? '纪念日';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SugarParticles(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('就是今天！', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.peach)),
            const SizedBox(height: 8),
            Text('这颗糖很甜 🍬', style: TextStyle(fontSize: 18, color: AppColors.warmOrange)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 15, color: AppColors.darkText)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.peach, foregroundColor: Colors.white),
              child: const Text('嗯！'),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🍰 糖分纪念簿'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _create)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.peach))
          : _list.isEmpty ? _empty()
          : RefreshIndicator(onRefresh: _load,
              child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _list.length,
                itemBuilder: (_, i) => _buildCard(_list[i]))),
    );
  }

  Widget _buildCard(Map<String, dynamic> a) {
    final date = DateTime.parse(a['date']);
    final diff = date.difference(DateTime.now()).inDays;
    final isToday = diff == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isToday ? AppColors.peach.withOpacity(0.1) : AppColors.frostingWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: isToday ? Border.all(color: AppColors.peach, width: 2) : null,
        boxShadow: AppShadows.card,
      ),
      child: Row(children: [
        Text(a['icon'] ?? '❤️', style: TextStyle(fontSize: isToday ? 40 : 32)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['title']?['zh'] ?? '纪念日', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isToday ? AppColors.peach : AppColors.darkText)),
          Text(isToday ? '🎉 就是今天！这颗糖很甜' : diff < 0 ? '已过去 ${-diff} 天' : '还剩 $diff 天',
            style: TextStyle(color: isToday ? AppColors.peach : AppColors.caramel, fontSize: 13)),
          Text(a['date'], style: AppTextStyles.caption),
        ])),
        if (diff > 0)
          Text('$diff', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.peach)),
      ]),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📅', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('还没有纪念日，去标记你们的第一颗糖吧', style: TextStyle(fontSize: 15, color: AppColors.caramel)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _create, child: const Text('标记纪念日')),
    ]),
  );
}
