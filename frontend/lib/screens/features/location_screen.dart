import 'dart:async';

import 'package:flutter/material.dart';
import '../../constants/theme.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _sharing = false;
  int _remaining = 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📍 糖分追踪')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 状态卡片
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
            child: Column(children: [
              const Text('🗺️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(_sharing ? '位置共享中' : '位置共享已关闭', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('开启位置，让糖有迹可循', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
            ]),
          ),
          const SizedBox(height: 16),

          // 控制按钮
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _timeBtn(15, '15分'),
                _timeBtn(30, '30分'),
                _timeBtn(60, '1小时'),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _sharing ? null : AppColors.brandGradient,
                    color: _sharing ? AppColors.alertRed.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: _sharing ? null : AppShadows.button,
                    border: _sharing ? Border.all(color: AppColors.alertRed) : null,
                  ),
                  child: ElevatedButton(
                    onPressed: () => setState(() => _sharing = !_sharing),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
                    child: Text(_sharing ? '停止共享' : '开启位置共享',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _sharing ? AppColors.alertRed : Colors.white)),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // 对方信息
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
            child: Row(children: [
              const CircleAvatar(radius: 24, child: Text('🍬', style: TextStyle(fontSize: 20))),
              const SizedBox(width: 16),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TA的位置', style: AppTextStyles.body),
                Text('等待对方开启位置共享...', style: AppTextStyles.caption),
              ])),
              Column(children: [
                const Icon(Icons.battery_full, color: AppColors.successGreen, size: 24),
                Text('85%', style: TextStyle(fontSize: 11, color: AppColors.successGreen)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _timeBtn(int min, String label) {
    final s = _remaining == min;
    return GestureDetector(
      onTap: () => setState(() => _remaining = min),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: s ? AppColors.peach : AppColors.frostingWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: s ? AppColors.peach : AppColors.greyText.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(color: s ? Colors.white : AppColors.caramel, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
