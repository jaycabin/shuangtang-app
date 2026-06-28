import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';

final _api = ApiService();

class SecretMessageScreen extends StatefulWidget {
  const SecretMessageScreen({super.key});
  @override
  State<SecretMessageScreen> createState() => _SecretMessageScreenState();
}

class _SecretMessageScreenState extends State<SecretMessageScreen> {
  List<Map<String, dynamic>> _msgs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getSecretMessages();
      _msgs = (r['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) { debugPrint("err: $e"); }
    setState(() => _loading = false);
  }

  Future<void> _send() async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
        title: const Text('💌 发送悄悄话'),
        content: TextField(controller: ctl, maxLines: 4, decoration: const InputDecoration(hintText: '写下你的悄悄话...'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('不了')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('加密发送')),
        ],
      ),
    );
    if (ok == true && ctl.text.isNotEmpty) {
      await _api.sendSecretMessage(ctl.text);
      if (mounted) _showToast('糖已加密送达');
      _load();
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      backgroundColor: AppColors.darkText, behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tag)),
    ));
  }

  Future<void> _revealMessage(String id) async {
    // 弹出长按解密动画
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LongPressReveal(
        onRevealed: () async {
          await _api.readSecretMessage(id);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('✉️ 悄悄话信箱')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.peach))
          : _msgs.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('✉️', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    const Text('还没有悄悄话', style: TextStyle(color: AppColors.caramel)),
                    const SizedBox(height: 8),
                    const Text('点击右下角给 TA 发一封加密信', style: TextStyle(color: AppColors.greyText)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _msgs.length,
                    reverse: true,
                    itemBuilder: (_, i) {
                      final msg = _msgs[i];
                      final isRead = msg['is_read'] == true;
                      return GestureDetector(
                        onLongPressStart: isRead ? null : (_) => _revealMessage(msg['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead ? AppColors.frostingWhite : AppColors.peach.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(isRead ? '🔓' : '🔒', style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                isRead ? '糖衣已化，是TA的悄悄话' : '收到一颗加密的糖，长按解锁',
                                style: TextStyle(fontSize: 13, color: isRead ? AppColors.successGreen : AppColors.peach),
                              ),
                              const Spacer(),
                              Text(_fmt(msg['created_at']), style: AppTextStyles.caption),
                            ]),
                            if (isRead)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(msg['content'] ?? '', style: AppTextStyles.body),
                              ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _send,
        backgroundColor: AppColors.peach,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  String _fmt(String? ts) {
    if (ts == null) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}分钟前';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 长按解密动画组件 — 按住1.5秒"糖衣融化"
class _LongPressReveal extends StatefulWidget {
  final VoidCallback onRevealed;
  const _LongPressReveal({required this.onRevealed});

  @override
  State<_LongPressReveal> createState() => _LongPressRevealState();
}

class _LongPressRevealState extends State<_LongPressReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _ctrl.forward().then((_) {
      widget.onRevealed();
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                _ctrl.value < 0.3 ? '正在化开糖衣...' :
                _ctrl.value < 0.7 ? '糖衣快要化开了...' : '马上就能看到了...',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _ctrl.value,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.peach),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('${(_ctrl.value * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
