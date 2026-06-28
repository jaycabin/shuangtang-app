import 'package:flutter/material.dart';
import '../constants/theme.dart';
import 'features/timeline_screen.dart';
import 'features/anniversary_screen.dart';
import 'features/checkin_screen.dart';
import 'features/more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _pages = const [
    TimelineScreen(),
    AnniversaryScreen(),
    CheckInScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, elevation: 0,
            selectedItemColor: AppTheme.primaryStart, unselectedItemColor: AppTheme.textHint,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: '时光轴'),
              BottomNavigationBarItem(icon: Icon(Icons.cake_outlined), label: '纪念日'),
              BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: '打卡'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: '更多'),
            ],
          ),
        ),
      ),
    );
  }
}
