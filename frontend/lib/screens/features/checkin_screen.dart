import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';

final _api = ApiService();

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getCheckInTasks();
      _tasks = (r['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) { debugPrint("err: $e"); }
    setState(() => _loading = false);
  }

  Future<void> _checkIn(String id) async {
    try {
      await _api.doCheckIn(id);
      _load();
    } catch (e) { debugPrint("err: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日份双糖')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.peach))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  _buildStreakCard(),
                  const SizedBox(height: 16),
                  ...List.generate(_tasks.length, (i) => _buildTaskCard(_tasks[i])),
                  if (_tasks.isEmpty) _buildEmpty(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statItem('🔥', '连续天数', '0 天'),
        _statItem('📋', '今日任务', '${_tasks.length} 项'),
        _statItem('🏆', '成就', '0 个'),
      ]),
    );
  }

  Widget _statItem(String emoji, String label, String value) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 28)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
    ]);
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title']?['zh'] ?? '任务';
    final icon = task['icon'] ?? '✅';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.frostingWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: AppTextStyles.body)),
        SizedBox(
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.button),
            child: ElevatedButton(
              onPressed: () => _checkIn(task['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('领这颗糖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      const Text('☁️', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 12),
      const Text('今天还没有打卡任务哦', style: TextStyle(color: AppColors.caramel, fontSize: 15)),
      const SizedBox(height: 4),
      const Text('点击下方 + 创建吧', style: TextStyle(color: AppColors.greyText, fontSize: 13)),
    ]),
  );
}
