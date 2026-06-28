import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';
import '../../generated/l10n/app_localizations.dart';

final _api = ApiService();

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});
  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final _descCtl = TextEditingController();
  bool _loading = false;

  Future<void> _createAlarm() async {
    if (_descCtl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final now = DateTime.now().add(const Duration(minutes: 1));
      await _api.createAlarm({
        'alarm_time': now.toIso8601String(),
        'task_description': _descCtl.text,
        'task_type': 'record',
      });
      if (!mounted) return;
      _descCtl.clear();
      _showToast('⏰ 闹钟已设置');
    } catch (_) {
      _showToast(AppLocalizations.of(context)!.toast_create_fail);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      backgroundColor: AppColors.darkText,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tag)),
      duration: const Duration(milliseconds: 800),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⏰ 双糖闹钟')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
            child: Column(children: [
              const Text('⏰', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('双糖闹钟，只有你能关', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('为对方设置一个TA才能关闭的闹钟', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
            ]),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
            child: Column(children: [
              TextField(
                controller: _descCtl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '对方需要完成什么任务才能关闭闹钟？\n例如：说一句"我爱你"并录音',
                  border: InputBorder.none,
                  fillColor: AppColors.creamWhite,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.button), boxShadow: AppShadows.button),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _createAlarm,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
                    child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('设置闹钟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
