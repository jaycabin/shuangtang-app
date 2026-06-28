import 'dart:async';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 离线队列 — 网络断开时暂存操作，恢复后自动重试
class OfflineQueue {
  static final OfflineQueue _instance = OfflineQueue._();
  factory OfflineQueue() => _instance;
  OfflineQueue._();

  late Box _queue;
  StreamSubscription? _connectSub;
  bool _processing = false;

  Future<void> init() async {
    _queue = await Hive.openBox('offline_queue');
    // 监听网络状态
    _connectSub = Connectivity().onConnectivityChanged.listen((_) => _process());
    // 启动时立即处理一次
    _process();
  }

  /// 入队一个待重试的操作
  Future<void> enqueue(String method, String path, Map<String, dynamic>? body) async {
    await _queue.add({
      'method': method,
      'path': path,
      'body': body,
      'retries': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 处理队列中所有待重试操作
  Future<void> _process() async {
    if (_processing) return;
    _processing = true;

    final items = _queue.values.toList();
    for (final item in items) {
      if (item['retries'] >= 3) {
        await _queue.delete(item.key);
        continue;
      }
      // 重试逻辑 — 业务方注册处理器来处理各路径
      final handler = _handlers['${item['method']}_${item['path']}'];
      if (handler != null) {
        try {
          await handler(item['body']);
          await _queue.delete(item.key);
        } catch (_) {
          item['retries'] = (item['retries'] ?? 0) + 1;
          await item.save();
        }
      }
    }
    _processing = false;
  }

  final _handlers = <String, Future<void> Function(Map<String, dynamic>?)>{};

  /// 注册重试处理器
  void register(String method, String path, Future<void> Function(Map<String, dynamic>?) handler) {
    _handlers['${method}_$path'] = handler;
  }

  void dispose() {
    _connectSub?.cancel();
  }
}
