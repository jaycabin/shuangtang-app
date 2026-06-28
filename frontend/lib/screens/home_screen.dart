import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/theme.dart';
import '../services/supabase_service.dart';

final _svc = SupabaseService();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  Map<String, dynamic>? _couple;
  Map<String, dynamic>? _partner;
  List<Map<String, dynamic>> _moments = [];
  bool _loading = true;
  RealtimeChannel? _timelineChannel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await _loadCouple();
    if (_couple != null) {
      await _loadMoments();
      _subscribeTimeline();
    }
    setState(() => _loading = false);
  }

  Future<void> _loadCouple() async {
    _couple = await _svc.getMyCouple();
    _partner = await _svc.getPartner();
  }

  Future<void> _loadMoments() async {
    if (_couple == null) return;
    _moments = await _svc.getTimeline(_couple!['id']);
  }

  void _subscribeTimeline() {
    _timelineChannel?.unsubscribe();
    _timelineChannel = _svc.subscribeTimeline(_couple!['id'], (_) {
      _loadMoments();
    });
  }

  @override
  void dispose() {
    _timelineChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryStart))
          : _couple == null ? _buildCoupleSetup() : _buildMainScreen(),
      bottomNavigationBar: _couple != null ? _buildNavBar() : null,
    );
  }

  // ===================== 情侣空间设置 =====================

  Widget _buildCoupleSetup() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍬', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            const Text('创建你们的双糖空间',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('两颗心，双倍糖', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity, height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: ElevatedButton(
                  onPressed: _createCouple,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                  child: const Text('🍬 我创建空间', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton(
                onPressed: _joinCoupleDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryStart),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                child: const Text('🔗 我加入空间', style: TextStyle(fontSize: 16, color: AppTheme.primaryStart)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCouple() async {
    final result = await _svc.createCouple();
    if (!mounted) return;
    _showInviteCode(result['invitation_code'] as String);
    await _loadCouple();
    setState(() {});
  }

  void _showInviteCode(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('🎉 空间已创建'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('邀请对方输入此代码：'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryStart.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(code,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 4, color: AppTheme.primaryStart)),
            ),
            const SizedBox(height: 8),
            const Text('对方在 App 中选择 "加入空间" 输入此代码即可',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了'))],
      ),
    );
  }

  Future<void> _joinCoupleDialog() async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('加入空间'),
        content: TextField(
          controller: ctl,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(hintText: '输入邀请码', border: InputBorder.none),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('不了')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('嗯')),
        ],
      ),
    );
    if (ok == true && ctl.text.isNotEmpty) {
      final success = await _svc.joinCouple(ctl.text.trim().toUpperCase());
      if (!mounted) return;
      if (success) {
        await _loadCouple();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('邀请码无效，请确认后重试')),
        );
      }
    }
  }

  // ===================== 主界面 =====================

  Widget _buildMainScreen() {
    switch (_tab) {
      case 0: return _buildTimeline();
      case 1: return _buildSugarAlbum();
      case 2: return _buildSugarJar();
      case 3: return _buildProfile();
      default: return _buildTimeline();
    }
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent, elevation: 0,
          selectedItemColor: AppTheme.primaryStart, unselectedItemColor: AppTheme.textHint,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: '时光轴'),
            BottomNavigationBarItem(icon: Icon(Icons.photo_album), label: '相册'),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: '藏糖罐'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          ],
        ),
      ),
    );
  }

  // ---------- 时光轴 ----------
  Widget _buildTimeline() {
    final days = _couple?['started_at'] != null
        ? DateTime.now().difference(DateTime.parse(_couple!['started_at'])).inDays
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('🍬 双糖'),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_outline), onPressed: _showPartnerInfo),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryStart,
        onRefresh: () async { await _loadMoments(); setState(() {}); },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 顶部氛围区
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(children: [
                const Text('🍯', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text('攒了 $days 颗糖的日子',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                if (_partner != null)
                  Text('和 ${_partner!['nickname'] ?? 'TA'} 一起',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
              ]),
            ),
            const SizedBox(height: 16),
            // 快速发瞬间
            _buildQuickMoment(),
            const SizedBox(height: 16),
            // 时光轴列表
            ..._moments.map((m) => _buildMomentCard(m)).toList(),
            if (_moments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  const Text('📝', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('这里还没有糖，快撒第一颗吧',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMoment() {
    final ctl = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
      child: Column(children: [
        TextField(
          controller: ctl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '今天想撒什么糖？',
            border: InputBorder.none,
          ),
        ),
        const Divider(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: AppTheme.textHint), onPressed: () {}),
            IconButton(icon: const Icon(Icons.photo_library_outlined, color: AppTheme.textHint), onPressed: () {}),
            IconButton(icon: const Icon(Icons.location_on_outlined, color: AppTheme.textHint), onPressed: () {}),
          ]),
          Container(
            decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(20)),
            child: TextButton(
              onPressed: () async {
                if (ctl.text.trim().isEmpty) return;
                await _svc.createMoment(_couple!['id'], content: ctl.text.trim());
                ctl.clear();
                await _loadMoments();
                setState(() {});
              },
              child: const Text('撒颗糖', style: TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildMomentCard(Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(m['type'] == 'moment' ? '📸' : m['type'] == 'checkin' ? '✅' : '💝', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(child: Text(m['content'] ?? '', style: const TextStyle(fontSize: 15))),
        ]),
        if (m['mood_tag'] != null && m['mood_tag'] != '')
          Padding(padding: const EdgeInsets.only(top: 8),
            child: Text('#${m['mood_tag']}', style: TextStyle(color: AppTheme.primaryStart, fontSize: 12))),
        Padding(padding: const EdgeInsets.only(top: 4),
          child: Text(_formatTime(m['created_at']), style: const TextStyle(color: AppTheme.textHint, fontSize: 12))),
      ]),
    );
  }

  // ---------- 相册 ----------
  Widget _buildSugarAlbum() {
    return Scaffold(
      appBar: AppBar(title: const Text('糖分相册')),
      body: const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('📸', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('还没有糖，拍一张合影吧', style: TextStyle(color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }

  // ---------- 藏糖罐 ----------
  Widget _buildSugarJar() {
    return Scaffold(
      appBar: AppBar(title: const Text('藏糖罐')),
      body: const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🏺', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('把想去的地方、想要的东西，悄悄放进藏糖罐', style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ---------- 我的 ----------
  Widget _buildProfile() {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(AppTheme.radiusLarge), boxShadow: AppTheme.cardShadow),
            child: Row(children: [
              CircleAvatar(radius: 30, backgroundColor: Colors.white.withOpacity(0.3), child: const Text('🍬', style: TextStyle(fontSize: 28))),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_svc.currentUser?.email ?? '用户', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                if (_partner != null)
                  Text('和 ${_partner!['nickname'] ?? 'TA'} 连着呢', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          _buildMenuItem(Icons.language, '语言', '中文', () => Navigator.pushNamed(context, '/settings/language')),
          _buildMenuItem(Icons.notifications_outlined, '通知', '', () {}),
          _buildMenuItem(Icons.info_outline, '关于双糖', 'v1.0', () {}),
          const SizedBox(height: 24),
          Container(
            width: double.infinity, height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTheme.radiusMedium), border: Border.all(color: AppTheme.errorRed.withOpacity(0.3))),
            child: TextButton(
              onPressed: () async {
                await _svc.signOut();
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryStart),
        title: Text(title),
        trailing: trailing.isNotEmpty ? Text(trailing, style: const TextStyle(color: AppTheme.textHint, fontSize: 13)) : const Icon(Icons.chevron_right, color: AppTheme.textHint),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      ),
    );
  }

  void _showPartnerInfo() {
    if (_partner == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('💕 你的另一半'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🍬', style: TextStyle(fontSize: 48)),
          Text(_partner!['nickname'] ?? 'TA', style: const TextStyle(fontSize: 20)),
          Text(_partner!['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
          if (_couple!['started_at'] != null)
            Text('从 ${_couple!['started_at'].toString().substring(0, 10)} 开始',
              style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('嗯'))],
      ),
    );
  }

  String _formatTime(String? ts) {
    if (ts == null) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}
