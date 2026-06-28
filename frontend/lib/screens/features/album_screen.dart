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
        ? const Center(child: CircularProgressIndicator(color: AppColors.peach))
        : _photos.isEmpty ? _empty()
        : RefreshIndicator(
            onRefresh: _load,
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemCount: _photos.length,
              itemBuilder: (_, i) => Container(
                decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Icon(Icons.image, color: AppColors.caramel, size: 32)),
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showToast('请从相册选择照片'),
        backgroundColor: AppColors.peach,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      backgroundColor: AppColors.darkText,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tag)),
    ));
  }

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📸', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('还没有糖，拍一张合影吧', style: TextStyle(color: AppColors.caramel, fontSize: 15)),
      const SizedBox(height: 24),
      Container(height: 48,
        decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.button), boxShadow: AppShadows.button),
        child: ElevatedButton.icon(
          onPressed: () => _showToast('请从相册选择照片'),
          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          label: const Text('存一颗糖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
        ),
      ),
    ]),
  );
}
