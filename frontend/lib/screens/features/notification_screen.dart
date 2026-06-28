import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';

final _api = ApiService();

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔔 通知中心')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🔔', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('暂无新通知', style: TextStyle(fontSize: 16, color: AppColors.caramel)),
          const SizedBox(height: 8),
          const Text('打卡提醒、新动态等会出现在这里', style: TextStyle(fontSize: 13, color: AppColors.greyText)),
        ]),
      ),
    );
  }
}
