import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../constants/theme.dart';
import 'anniversary_screen.dart';
import 'wishlist_screen.dart';
import 'secret_message_screen.dart';
import 'album_screen.dart';
import 'location_screen.dart';
import 'alarm_screen.dart';
import 'notification_screen.dart';

const _appVersion = '1.5.0';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _toast(BuildContext c, String m) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(
      content: Text(m, textAlign: TextAlign.center),
      backgroundColor: AppColors.darkText, behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tag)),
    ));
  }

  void _push(BuildContext c, Widget page) => Navigator.push(c, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.caramel),
            onPressed: () => _push(context, const NotificationScreen()),
          ),
        ],
      ),
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

          // 全部功能
          _section('互动', [
            _item('🎂 纪念日', '倒计时与提醒', () => _push(context, const AnniversaryScreen())),
            _item('🏺 藏糖罐', '心愿认领', () => _push(context, const WishlistScreen())),
            _item('✉️ 悄悄话', '加密消息', () => _push(context, const SecretMessageScreen())),
            _item('📸 相册', '保存照片', () => _push(context, const AlbumScreen())),
            _item('📍 位置共享', '实时追踪', () => _push(context, const LocationScreen())),
            _item('⏰ 双糖闹钟', '只有你能关', () => _push(context, const AlarmScreen())),
          ]),

          const SizedBox(height: 16),
          _section('设置', [
            _item('🌐 语言', '中文', () => Navigator.pushNamed(context, '/settings/language')),
            _item('ℹ️ 关于', 'v$_appVersion', () {}),
          ]),

          const SizedBox(height: 32),
          Container(height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.button), border: Border.all(color: AppColors.alertRed.withOpacity(0.3))),
            child: TextButton(
              onPressed: () { Hive.box('settings').clear(); Navigator.pushReplacementNamed(context, '/login'); },
              child: const Text('退出登录', style: TextStyle(color: AppColors.alertRed)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.caramel))),
      ...List.generate(items.length, (i) => Padding(
        padding: EdgeInsets.only(bottom: i < items.length - 1 ? 6 : 0),
        child: items[i],
      )),
    ]);
  }

  Widget _item(String title, String sub, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.body),
            Text(sub, style: AppTextStyles.caption),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.greyText, size: 20),
        ]),
      ),
    );
  }
}
