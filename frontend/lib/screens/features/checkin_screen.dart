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
  int _streak = 0;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getCheckInTasks();
      _tasks = (r['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _checkIn(String taskId) async {
    try {
      await _api.doCheckIn(taskId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('领糖成功 🎉'), backgroundColor: AppTheme.successGreen));
      _load();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已经打过卡了'), backgroundColor: AppTheme.textHint));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('✅ 今日份双糖')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryStart))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 打卡统计
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge), boxShadow: AppTheme.cardShadow),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _statItem('🔥', '连续', '$_streak 天'),
                      _statItem('📋', '今日', '${_tasks.length} 项'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // 打卡任务列表
                  ...List.generate(_tasks.length, (i) {
                    final task = _tasks[i];
                    final title = task['title']?['zh'] ?? '任务';
                    final icon = task['icon'] ?? '✅';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
                      child: Row(children: [
                        Text(icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                        Container(
                          decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(20)),
                          child: TextButton(
                            onPressed: () => _checkIn(task['id']),
                            child: const Text('领这颗糖', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ),
                      ]),
                    );
                  }),

                  // 日历视图预览
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {
                          setState(() { if (--_month < 1) { _month = 12; _year--; } });
                        }),
                        Text('$_year 年 $_month 月', style: const TextStyle(fontWeight: FontWeight.w600)),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {
                          setState(() { if (++_month > 12) { _month = 1; _year++; } });
                        }),
                      ]),
                      const SizedBox(height: 8),
                      // 简单的日历网格
                      ..._buildCalendarGrid(),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statItem(String emoji, String label, String value) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 28)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
    ]);
  }

  List<Widget> _buildCalendarGrid() {
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final firstWeekday = DateTime(_year, _month, 1).weekday % 7;
    final cells = <Widget>[];

    // Header
    for (final d in ['一', '二', '三', '四', '五', '六', '日']) {
      cells.add(Container(padding: const EdgeInsets.all(4),
        child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.textHint))));
    }

    // Empty cells before first day
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    final today = DateTime.now();
    for (int d = 1; d <= daysInMonth; d++) {
      final isToday = d == today.day && _month == today.month && _year == today.year;
      cells.add(Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isToday ? AppTheme.primaryStart : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$d', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
            color: isToday ? Colors.white : AppTheme.textPrimary)),
      ));
    }

    return [Wrap(spacing: 4, runSpacing: 4, children: cells)];
  }
}
