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
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() { _emailCtl.dispose(); _passCtl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_emailCtl.text.isEmpty || _passCtl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _api.login(_emailCtl.text, _passCtl.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('邮箱或密码错误'), backgroundColor: AppTheme.errorRed));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          // 顶部渐变区域
          Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppTheme.primaryStart, AppTheme.primaryEnd]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🍬', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text('双糖', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 4)),
                const SizedBox(height: 4),
                Text('两颗心，双倍糖', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
              ]),
            ),
          ),

          // 登录表单卡片
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: -32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppTheme.shadowColor, blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('欢迎回来', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              // 邮箱
              TextField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '邮箱',
                  hintText: '输入注册邮箱',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryStart),
                  filled: true, fillColor: AppTheme.backgroundLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              // 密码
              TextField(
                controller: _passCtl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '输入密码',
                  prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primaryStart),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textHint, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true, fillColor: AppTheme.backgroundLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              Align(alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: const Text('忘记密码？', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                )),
              const SizedBox(height: 8),
              // 登录按钮
              SizedBox(
                width: double.infinity, height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('嗯，登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),
          // 注册入口
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('还没有账号？', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('去注册', style: TextStyle(color: AppTheme.primaryStart, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}
