import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

final _api = ApiService();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  int _tab = 0; // 0=密码登录, 1=验证码登录
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailCtl.dispose(); _passCtl.dispose(); _codeCtl.dispose();
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
    try {
      await _api.sendCode(_emailCtl.text);
      _startCountdown();
      _showToast('验证码已发送');
    } catch (_) {
      _showToast('发送失败');
    }
  }

  Future<void> _login() async {
    if (_emailCtl.text.isEmpty) return;
    if (_tab == 0 && _passCtl.text.isEmpty) return;
    if (_tab == 1 && _codeCtl.text.length != 6) return;

    setState(() => _loading = true);
    try {
      if (_tab == 0) {
        await _api.login(_emailCtl.text, _passCtl.text);
      } else {
        await _api.login(_emailCtl.text, _codeCtl.text);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showToast('邮箱或密码错误');
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
      body: SafeArea(
        child: Column(children: [
          // 顶部品牌
          const SizedBox(height: 32),
          const Text('🍬', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 6),
          const Text('双糖', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkText, letterSpacing: 4)),
          const SizedBox(height: 4),
          Text('两颗心，双倍糖', style: TextStyle(fontSize: 14, color: AppColors.caramel)),
          const SizedBox(height: 28),

          // Tab 切换
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Expanded(child: _tabItem(0, '密码登录')),
              const SizedBox(width: 12),
              Expanded(child: _tabItem(1, '验证码登录')),
            ]),
          ),
          const SizedBox(height: 28),

          // 表单
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                // 邮箱
                TextField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: '邮箱',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.caramel, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // 密码或验证码
                if (_tab == 0) ...[
                  TextField(
                    controller: _passCtl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: '密码',
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.caramel, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.greyText, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('忘记密码？', style: TextStyle(fontSize: 13, color: AppColors.greyText)),
                    ),
                  ),
                ] else ...[
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(hintText: '验证码', counterText: '',
                          prefixIcon: Icon(Icons.sms_outlined, color: AppColors.caramel, size: 20)),
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
                        child: Text(_countdown > 0 ? '${_countdown}s' : '获取',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: _countdown > 0 ? AppColors.greyText : AppColors.peach)),
                      ),
                    ),
                  ]),
                ],
                const SizedBox(height: 24),

                // 主按钮
                SizedBox(width: double.infinity, height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: AppShadows.button,
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                      child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 切换注册
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('没有账号？', style: TextStyle(color: AppColors.caramel, fontSize: 14)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('去注册', style: TextStyle(color: AppColors.linkBlue, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tabItem(int index, String label) {
    final s = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.frostingWhite,
          borderRadius: BorderRadius.circular(12),
          border: s ? Border.all(color: AppColors.peach, width: 1.5) : null,
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontSize: 15,
            fontWeight: s ? FontWeight.w600 : FontWeight.normal,
            color: s ? AppColors.peach : AppColors.caramel,
          )),
        ),
      ),
    );
  }
}
