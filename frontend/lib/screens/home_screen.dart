import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    TimelinePage(),
    SugarAlbumPage(),
    SugarJarPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppTheme.primaryStart,
              unselectedItemColor: AppTheme.textHint,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: '时光轴'),
                BottomNavigationBarItem(icon: Icon(Icons.photo_album), label: '相册'),
                BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: '藏糖罐'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍬 双糖'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryStart,
        onRefresh: () => Future.delayed(const Duration(seconds: 1)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Days counter
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  const Text('🍯', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text(
                    '攒了 127 颗糖的日子',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2025-01-15 · 在一起的第127天',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick drop sugar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '今天想撒什么糖？',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ),
                  const Icon(Icons.emoji_emotions_outlined, color: AppTheme.textHint),
                  const SizedBox(width: 8),
                  const Icon(Icons.photo_library_outlined, color: AppTheme.textHint),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeline items
            _buildTimelineCard(
              icon: '💪',
              title: '今日打卡',
              subtitle: '喝够8杯水 · TA已完成',
              time: '10分钟前',
              tag: '领糖',
            ),
            _buildTimelineCard(
              icon: '📸',
              title: '撒了一颗糖',
              subtitle: '今天的晚餐好棒！一起做饭的快乐时光~',
              time: '2小时前',
              tag: '撒糖',
              imageUrl: null,
            ),
            _buildTimelineCard(
              icon: '🎂',
              title: '纪念日',
              subtitle: '在一起100天',
              time: '3天前',
              tag: '纪念日',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard({
    required String icon,
    required String title,
    required String subtitle,
    required String time,
    required String tag,
    String? imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryStart.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryStart,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SugarAlbumPage extends StatelessWidget {
  const SugarAlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('糖分相册')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📸', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              '还没有糖，拍一张合影吧',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class SugarJarPage extends StatelessWidget {
  const SugarJarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('藏糖罐')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏺', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              '把想去的地方、想要的东西，悄悄放进藏糖罐',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: const Text('🍬', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '宝贝',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'love@shuangtang.app',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildMenuItem(Icons.language, '语言', '中文', () {
            Navigator.pushNamed(context, '/settings/language');
          }),
          _buildMenuItem(Icons.notifications_outlined, '通知', '', () {}),
          _buildMenuItem(Icons.lock_outlined, '隐私', '', () {}),
          _buildMenuItem(Icons.info_outline, '关于双糖', 'v1.0.0', () {}),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
            ),
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('退出登录'),
                    content: const Text('确定要退出双糖吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('不了')),
                      TextButton(onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushReplacementNamed(context, '/login');
                      }, child: const Text('嗯', style: TextStyle(color: AppTheme.errorRed))),
                    ],
                  ),
                );
              },
              child: const Text('退出登录', style: TextStyle(color: AppTheme.errorRed)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String trailing, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryStart),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: trailing.isNotEmpty
            ? Text(trailing, style: const TextStyle(color: AppTheme.textHint, fontSize: 13))
            : const Icon(Icons.chevron_right, color: AppTheme.textHint),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      ),
    );
  }
}
