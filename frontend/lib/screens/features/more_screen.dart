import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../constants/theme.dart';
import 'secret_message_screen.dart';
import 'album_screen.dart';
import 'wishlist_screen.dart';
import 'anniversary_screen.dart';

const _appVersion = '1.4.0';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _showToast(BuildContext context, String msg) {
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
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // 用户卡片
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
            child: Row(children: [
              const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Text('🍬', style: TextStyle(fontSize: 24))),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('宝贝', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(Hive.box('settings').get('user_email', defaultValue: '') as String,
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // 互动功能
          const Text('互动', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.caramel)),
          const SizedBox(height: 8),
          _menuCard(context, '🎂 纪念日', '重要日期倒计时与提醒', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnniversaryScreen()))),
          _menuCard(context, '🏺 藏糖罐', '心愿认领与完成', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()))),
          _menuCard(context, '✉️ 悄悄话信箱', '加密消息长按解密', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretMessageScreen()))),
          _menuCard(context, '📸 糖分相册', '保存每一颗糖的照片', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlbumScreen()))),
          _menuCard(context, '📍 位置共享', '实时追踪与靠近提醒', () => _showToast(context, '功能开发中')),
          _menuCard(context, '⏰ 双糖闹钟', '只有对方能关闭', () => _showToast(context, '功能开发中')),

          const SizedBox(height: 16),
          const Text('设置', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.caramel)),
          const SizedBox(height: 8),
          _menuCard(context, '🌐 语言', '中文', () => Navigator.pushNamed(context, '/settings/language')),
          _menuCard(context, 'ℹ️ 关于', 'v$_appVersion', () {}),

          const SizedBox(height: 32),
          Container(height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.button), border: Border.all(color: AppColors.alertRed.withOpacity(0.3))),
            child: TextButton(
              onPressed: () {
                Hive.box('settings').clear();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('退出登录', style: TextStyle(color: AppColors.alertRed)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.body),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.greyText, size: 20),
        ]),
      ),
    );
  }
}
