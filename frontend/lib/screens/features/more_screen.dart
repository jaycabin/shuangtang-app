import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';
import 'wishlist_screen.dart';
import 'secret_message_screen.dart';
import 'album_screen.dart';

final _api = ApiService();

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🍬 更多')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge), boxShadow: AppTheme.cardShadow),
            child: Row(children: [
              const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Text('🍬', style: TextStyle(fontSize: 24))),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('宝贝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(Hive.box('settings').get('user_email', defaultValue: '') as String,
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // 功能入口
          _menuItem(context, '🏺 藏糖罐', '把心愿放进藏糖罐', Icons.arrow_forward_ios, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()))),
          _menuItem(context, '✉️ 悄悄话信箱', '加密消息，长按解密', Icons.arrow_forward_ios, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretMessageScreen()))),
          _menuItem(context, '📸 糖分相册', '保存每一颗糖的照片', Icons.arrow_forward_ios, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlbumScreen()))),
          const Divider(height: 32),

          // 设置
          _menuItem(context, '🌐 语言', '中文', Icons.arrow_forward_ios, () => Navigator.pushNamed(context, '/settings/language')),
          _menuItem(context, '🔔 通知', '', Icons.arrow_forward_ios, () {}),
          _menuItem(context, 'ℹ️ 关于', 'v1.0', Icons.arrow_forward_ios, () {}),

          const SizedBox(height: 24),
          Container(
            width: double.infinity, height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTheme.radiusMedium), border: Border.all(color: AppTheme.errorRed.withOpacity(0.3))),
            child: TextButton(
              onPressed: () {
                Hive.box('settings').clear();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('退出登录', style: TextStyle(color: AppTheme.errorRed)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)) : null,
        trailing: Icon(icon, size: 16, color: AppTheme.textHint),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      ),
    );
  }
}
