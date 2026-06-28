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
  bool _loading = false;
  bool _obscure = true;
  int _step = 0;
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
    if (_emailCtl.text.isEmpty || !_emailCtl.text.contains('@')) return;
    setState(() => _loading = true);
    try {
      await _api.sendCode(_emailCtl.text);
      _startCountdown();
      setState(() => _step = 1);
    } catch (_) {
      _showToast('发送失败');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _register() async {
    if (_codeCtl.text.length != 6 || _passCtl.text.length < 6) return;
    setState(() => _loading = true);
    try {
      await _api.register(_emailCtl.text, _passCtl.text, _codeCtl.text, nickname: _nameCtl.text);
      if (!mounted) return;
      _showToast('🎉 注册成功');
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showToast(e.toString().contains('code_expired') ? '验证码已过期' :
                 e.toString().contains('email_exists') ? '邮箱已注册' : '注册失败');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showToast(String msg) {
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
      appBar: AppBar(leading: const BackButton(), title: const Text('注册')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 16),
            // 步骤指示
            Row(children: [
              _stepDot(0, '邮箱'),
              Expanded(child: Container(height: 2, color: _step >= 1 ? AppColors.peach : AppColors.greyText)),
              _stepDot(1, '资料'),
            ]),
            const SizedBox(height: 32),

            if (_step == 0) _buildStep0() else _buildStep1(),
          ]),
        ),
      ),
    );
  }

  Widget _stepDot(int i, String label) {
    final active = _step >= i;
    return Column(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: active ? AppColors.brandGradient : null,
          color: active ? null : AppColors.frostingWhite,
          shape: BoxShape.circle,
          border: Border.all(color: active ? Colors.transparent : AppColors.greyText, width: 2),
        ),
        child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.greyText))),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: active ? AppColors.peach : AppColors.greyText)),
    ]);
  }

  Widget _buildStep0() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('输入邮箱', style: AppTextStyles.h3),
      const SizedBox(height: 16),
      TextField(
        controller: _emailCtl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: '你们的共同邮箱',
          prefixIcon: Icon(Icons.email_outlined, color: AppColors.caramel, size: 20),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.button), boxShadow: AppShadows.button),
          child: ElevatedButton(
            onPressed: _loading ? null : _sendCode,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
            child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('获取验证码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('填写资料', style: AppTextStyles.h3),
      const SizedBox(height: 16),
      TextField(
        controller: _nameCtl,
        decoration: const InputDecoration(
          hintText: '对方怎么称呼你',
          prefixIcon: Icon(Icons.person_outline, color: AppColors.caramel, size: 20),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _codeCtl,
            keyboardType: TextInputType.number, maxLength: 6,
            decoration: InputDecoration(
              hintText: '验证码', counterText: '',
              prefixIcon: const Icon(Icons.sms_outlined, color: AppColors.caramel, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(height: 52,
          child: TextButton(
            onPressed: _countdown > 0 ? null : _sendCode,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.frostingWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(_countdown > 0 ? '${_countdown}s' : '重新获取',
              style: TextStyle(fontSize: 13, color: _countdown > 0 ? AppColors.greyText : AppColors.peach)),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _passCtl,
        obscureText: _obscure,
        decoration: InputDecoration(
          hintText: '密码（至少6位）',
          prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.caramel, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.greyText, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.button), boxShadow: AppShadows.button),
          child: ElevatedButton(
            onPressed: _loading ? null : _register,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
            child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('嗯，注册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }
}
