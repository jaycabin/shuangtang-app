import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';

final _api = ApiService();

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getWishlist();
      _items = (r['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) { debugPrint("err: $e"); }
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('放进一颗想吃的糖'),
        content: TextField(controller: ctl, decoration: const InputDecoration(hintText: '写下一个心愿...'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('不了')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('放进藏糖罐')),
        ],
      ),
    );
    if (ok == true && ctl.text.isNotEmpty) {
      await _api.addWish({'title': {'zh': ctl.text}});
      _load();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'claimed': return AppTheme.primaryEnd;
      case 'completed': return AppTheme.successGreen;
      default: return AppTheme.textHint;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'claimed': return 'TA已经在准备了';
      case 'completed': return '这颗糖，吃到了 ❤️';
      default: return '等待认领';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏺 藏糖罐'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _add)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryStart))
          : _items.isEmpty ? _empty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final status = item['status'] ?? 'pending';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(item['title']?['zh'] ?? '心愿', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(_statusText(status), style: TextStyle(fontSize: 11, color: _statusColor(status))),
                        ),
                      ]),
                      if (item['description'] != null && item['description'] != '')
                        Padding(padding: const EdgeInsets.only(top: 8), child: Text(item['description'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                      if (status == 'pending')
                        Align(alignment: Alignment.centerRight,
                          child: TextButton(onPressed: () async {
                            await _api.claimWish(item['id']);
                            _load();
                          }, child: const Text('我来准备', style: TextStyle(color: AppTheme.primaryStart)))),
                      if (status == 'claimed')
                        Align(alignment: Alignment.centerRight,
                          child: TextButton(onPressed: () async {
                            await _api.completeWish(item['id']);
                            _load();
                          }, child: const Text('已完成 ❤️', style: TextStyle(color: AppTheme.successGreen)))),
                    ]),
                  );
                },
              ),
            ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🏺', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('还没有愿望', style: TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      const Text('把想去的地方、想要的东西悄悄放进藏糖罐', style: TextStyle(color: AppTheme.textHint), textAlign: TextAlign.center),
    ]),
  );
}
