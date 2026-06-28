import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import 'features/timeline_screen.dart';
import 'features/checkin_screen.dart';
import 'features/wishlist_screen.dart';
import 'features/more_screen.dart';

final _api = ApiService();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _loading = true;
  bool _hasCouple = false;
  String? _inviteCode;

  @override
  void initState() {
    super.initState();
    _checkCouple();
  }

  Future<void> _checkCouple() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getCoupleInfo();
      _hasCouple = r['data'] != null && r['data']['couple'] != null;
    } catch (_) {
      _hasCouple = false;
    }
    setState(() => _loading = false);
  }

  Future<void> _createCouple() async {
    try {
      // 先检查是否已有情侣空间
      final check = await _api.getCoupleInfo();
      if (check['data'] != null && check['data']['couple'] != null) {
        _showToast('已经有情侣空间了');
        await _checkCouple();
        return;
      }
      final r = await _api.createCouple();
      _inviteCode = r['data']?['invitation_code'] as String?;
      if (!mounted) return;
      await _showInviteDialog();
      await _checkCouple();
    } catch (e) {
      _showToast('创建失败');
    }
  }

  Future<void> _joinCouple(String code) async {
    try {
      await _api.joinCouple(code.trim().toUpperCase());
      _showToast('🎉 加入成功');
      await _checkCouple();
    } catch (e) {
      _showToast('邀请码无效');
    }
  }

  Future<void> _showInviteDialog() async {
    final code = _inviteCode ?? '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
        title: const Text('🎉 空间已创建', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('邀请码（点击复制）：'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () { _showToast('已复制'); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: AppColors.frostingWhite, borderRadius: BorderRadius.circular(AppRadius.input)),
              child: Text(code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6, color: AppColors.peach)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('对方在 App 中选择"加入空间"输入此代码', style: TextStyle(fontSize: 13, color: AppColors.caramel), textAlign: TextAlign.center),
        ]),
        actions: [Center(
          child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('进入双糖空间', style: TextStyle(color: AppColors.peach, fontWeight: FontWeight.bold)),
          ),
        )],
      ),
    );
  }

  void _showJoinDialog() {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
        title: const Text('加入空间'),
        content: TextField(
          controller: ctl,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(hintText: '输入邀请码', border: InputBorder.none),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('不了', style: TextStyle(color: AppColors.caramel))),
          TextButton(onPressed: () { Navigator.pop(ctx); _joinCouple(ctl.text); }, child: const Text('嗯', style: TextStyle(color: AppColors.peach, fontWeight: FontWeight.bold))),
        ],
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
      duration: const Duration(milliseconds: 800),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.peach)));
    }
    if (!_hasCouple) return _buildSetup();

    return Scaffold(
      body: IndexedStack(index: _tab, children: const [
        TimelineScreen(),
        CheckInScreen(),
        WishlistScreen(),
        MoreScreen(),
      ]),
      extendBody: true,
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ========== 情侣空间设置 ==========
  Widget _buildSetup() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🍬', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            const Text('创建你们的双糖空间', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text('两颗心，双倍糖', style: TextStyle(color: AppColors.caramel)),
            const SizedBox(height: 48),
            SizedBox(width: double.infinity, height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.button), boxShadow: AppShadows.button),
                child: ElevatedButton(
                  onPressed: _createCouple,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
                  child: const Text('🍬 我创建空间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton(
                onPressed: _showJoinDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.peach),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                child: const Text('🔗 我加入空间', style: TextStyle(fontSize: 16, color: AppColors.peach)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ========== 底部导航 ==========
  Widget _buildNavBar() {
    return Container(
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
    );
  }

  Widget _navItem(int index, IconData outlined, IconData filled, String label) {
    final s = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(s ? filled : outlined, color: s ? AppColors.peach : AppColors.caramel, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: s ? AppColors.peach : AppColors.caramel, fontWeight: s ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: GestureDetector(onTap: _showSugarDrop, child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.button),
        child: const Center(child: Icon(Icons.add, color: Colors.white, size: 28)),
      )),
    );
  }

  void _showSugarDrop() {
    final ctl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.dialog))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.greyText.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('撒颗糖', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          TextField(controller: ctl, maxLines: 4,
            decoration: const InputDecoration(hintText: '今天想分享什么？', border: InputBorder.none, fillColor: AppColors.frostingWhite, filled: true)),
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
                  onPressed: () async {
                    if (ctl.text.trim().isEmpty) return;
                    try {
                      await _api.createMoment({'content': ctl.text.trim()});
                      Navigator.pop(ctx);
                      _showToast('糖已撒出 🍬');
                    } catch (e) { _showToast('发送失败'); }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                  child: const Text('撒颗糖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ),
          ]),
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
