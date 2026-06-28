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
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _send() async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('糖已加密送达'), backgroundColor: AppTheme.successGreen));
      _load();
    }
  }

  Future<void> _onRead(String id) async {
    await _api.readSecretMessage(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✉️ 悄悄话信箱'),
        actions: [IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _send)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryStart))
          : _msgs.isEmpty ? _empty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _msgs.length,
                reverse: true,
                itemBuilder: (_, i) {
                  final msg = _msgs[i];
                  final isRead = msg['is_read'] == true;
                  return Dismissible(
                    key: Key(msg['id'] ?? i.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                      color: isRead ? Colors.green : AppTheme.primaryStart,
                      child: Text(isRead ? '已读 ✓' : '长按解锁', style: const TextStyle(color: Colors.white))),
                    onDismissed: (_) => _onRead(msg['id']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : AppTheme.primaryStart.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(isRead ? '🔓' : '🔒', style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(isRead ? '糖衣已化，是TA的悄悄话' : '收到一颗加密的糖，长按解锁',
                            style: TextStyle(fontSize: 13, color: isRead ? AppTheme.successGreen : AppTheme.primaryStart)),
                          const Spacer(),
                          Text(_fmt(msg['created_at']), style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                        ]),
                        if (isRead)
                          Padding(padding: const EdgeInsets.only(top: 12),
                            child: Text(msg['content'] ?? '', style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary))),
                      ]),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _send,
        backgroundColor: AppTheme.primaryStart,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('✉️', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('还没有悄悄话', style: TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      const Text('点击右下角给 TA 发一封加密信', style: TextStyle(color: AppTheme.textHint)),
    ]),
  );

  String _fmt(String? ts) {
    if (ts == null) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}分钟前';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
