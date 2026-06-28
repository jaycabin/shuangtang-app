import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';

final _api = ApiService();

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});
  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<Map<String, dynamic>> _photos = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getAlbums();
      _photos = (r['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📸 糖分相册')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryStart))
          : _photos.isEmpty ? _empty()
          : RefreshIndicator(
              onRefresh: _load,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                itemCount: _photos.length,
                itemBuilder: (_, i) {
                  return GestureDetector(
                    onTap: () => _preview(_photos[i]['image_url'] ?? ''),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.primaryStart.withOpacity(0.05),
                      ),
                      child: const Center(child: Text('📷', style: TextStyle(fontSize: 32))),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _preview(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(height: 300, width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black),
            child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 64))),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭', style: TextStyle(color: Colors.white))),
        ]),
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📸', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('还没有糖，拍一张合影吧', style: TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.camera_alt),
        label: const Text('拍一张'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryStart, foregroundColor: Colors.white),
      ),
    ]),
  );
}
