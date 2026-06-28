import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';

final _api = ApiService();

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _nameCtl = TextEditingController();

  int _step = 0; // 0 = 填邮箱, 1 = 填验证码+密码
  bool _loading = false;
  bool _obscure = true;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailCtl.dispose(); _codeCtl.dispose(); _passCtl.dispose(); _nameCtl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) { t.cancel(); return; }
      setState(() => _countdown--);
    });
  }

  Future<void> _sendCode() async {
    if (_emailCtl.text.isEmpty || !_emailCtl.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效邮箱'), backgroundColor: AppTheme.errorRed));
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.sendCode(_emailCtl.text);
      _startCountdown();
      setState(() => _step = 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发送失败，请稍后再试'), backgroundColor: AppTheme.errorRed));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _register() async {
    if (_codeCtl.text.length != 6 || _passCtl.text.length < 6) return;
    setState(() => _loading = true);
    try {
      await _api.register(_emailCtl.text, _passCtl.text, _codeCtl.text, nickname: _nameCtl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 注册成功'), backgroundColor: AppTheme.successGreen));
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      final msg = e.toString().contains('code_expired') ? '验证码已过期' :
                  e.toString().contains('code_invalid') ? '验证码错误' :
                  e.toString().contains('email_exists') ? '邮箱已注册' : '注册失败';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.errorRed));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          // 顶部
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppTheme.primaryStart, AppTheme.primaryEnd]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🍬', style: TextStyle(fontSize: 40)),
                const Text('加入双糖', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('创建专属于你们的空间', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 16),
                // 步骤指示器
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _stepDot(0, '邮箱'),
                  Container(width: 40, height: 2, color: _step >= 1 ? AppTheme.primaryStart : AppTheme.textHint),
                  _stepDot(1, '完成'),
                ]),
              ]),
            ),
          ),

          // 表单
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: -24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.shadowColor, blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: _step == 0 ? _buildStep0() : _buildStep1(),
          ),

          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('已有账号？', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('去登录', style: TextStyle(color: AppTheme.primaryStart, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _stepDot(int i, String label) {
    final active = _step >= i;
    return Column(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryStart : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: active ? AppTheme.primaryStart : AppTheme.textHint, width: 2),
        ),
        child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: active ? Colors.white : AppTheme.textHint, fontWeight: FontWeight.w600))),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: active ? AppTheme.primaryStart : AppTheme.textHint)),
    ]);
  }

  Widget _buildStep0() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('第一步：输入邮箱', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      TextField(
        controller: _emailCtl,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: '邮箱',
          hintText: '你们的共同邮箱',
          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryStart),
          filled: true, fillColor: AppTheme.backgroundLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity, height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.cardShadow),
          child: ElevatedButton(
            onPressed: _loading ? null : _sendCode,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('获取验证码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('第二步：设置密码', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      TextField(
        controller: _nameCtl,
        decoration: InputDecoration(
          labelText: '昵称',
          hintText: '对方怎么称呼你',
          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryStart),
          filled: true, fillColor: AppTheme.backgroundLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _codeCtl,
            keyboardType: TextInputType.number, maxLength: 6,
            decoration: InputDecoration(
              labelText: '验证码',
              counterText: '',
              prefixIcon: const Icon(Icons.sms_outlined, color: AppTheme.primaryStart),
              filled: true, fillColor: AppTheme.backgroundLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 52,
          child: TextButton(
            onPressed: _countdown > 0 ? null : _sendCode,
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.backgroundLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(_countdown > 0 ? '${_countdown}s' : '重新获取',
              style: TextStyle(fontSize: 13, color: _countdown > 0 ? AppTheme.textHint : AppTheme.primaryStart)),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      TextField(
        controller: _passCtl,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: '密码（至少6位）',
          hintText: '设置登录密码',
          prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primaryStart),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textHint, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          filled: true, fillColor: AppTheme.backgroundLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity, height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.cardShadow),
          child: ElevatedButton(
            onPressed: _loading ? null : _register,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('嗯，注册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }
}
