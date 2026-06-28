import 'package:flutter/material.dart';
import '../constants/theme.dart';
import 'features/timeline_screen.dart';
import 'features/checkin_screen.dart';
import 'features/wishlist_screen.dart';
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
    CheckInScreen(),
    WishlistScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_tab],
      extendBody: true,
      bottomNavigationBar: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0E8E3), width: 0.5)),
        ),
        child: Row(children: [
          _navItem(0, Icons.auto_stories_outlined, Icons.auto_stories, '糖罐'),
          _navItem(1, Icons.check_circle_outline, Icons.check_circle, '打卡'),
          _buildCenterButton(),
          _navItem(3, Icons.person_outline, Icons.person, '我的'),
          const Spacer(),
        ]),
      ),
    );
  }

  Widget _navItem(int index, IconData outlined, IconData filled, String label) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            selected ? filled : outlined,
            color: selected ? AppColors.peach : AppColors.caramel,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 11,
            color: selected ? AppColors.peach : AppColors.caramel,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          )),
        ]),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: GestureDetector(
        onTap: () => _showSugarDrop(),
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.button,
          ),
          child: const Center(child: Icon(Icons.add, color: Colors.white, size: 28)),
        ),
      ),
    );
  }

  void _showSugarDrop() {
    final ctl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.dialog)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.greyText.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('撒颗糖', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          TextField(
            controller: ctl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '今天想分享什么？',
              border: InputBorder.none,
              fillColor: AppColors.frostingWhite,
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              _iconBtn(Icons.emoji_emotions_outlined),
              const SizedBox(width: 8),
              _iconBtn(Icons.photo_library_outlined),
              const SizedBox(width: 8),
              _iconBtn(Icons.location_on_outlined),
            ]),
            SizedBox(
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(22), boxShadow: AppShadows.button),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                  child: const Text('撒颗糖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(12)),
    child: IconButton(icon: Icon(icon, color: AppColors.caramel, size: 20), onPressed: () {}, padding: EdgeInsets.zero),
  );
}
