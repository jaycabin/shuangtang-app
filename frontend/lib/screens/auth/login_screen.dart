import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';

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
  final _nameCtl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _useCode = false;

  @override
  void dispose() {
    _emailCtl.dispose(); _passCtl.dispose(); _codeCtl.dispose(); _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtl.text.isEmpty || (!_useCode && _passCtl.text.isEmpty)) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _api.login(_emailCtl.text, _passCtl.text);
      } else {
        await _api.register(_emailCtl.text, _passCtl.text, _codeCtl.text, nickname: _nameCtl.text);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('email_exists') ? '邮箱已注册' :
                  e.toString().contains('invalid_credentials') ? '邮箱或密码错误' :
                  e.toString().contains('code_invalid') ? '验证码错误' : '连接失败';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.errorRed));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(children: [
          const SizedBox(height: 60),
          const Text('🍬', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(_isLogin ? '欢迎回来' : '加入双糖', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(_isLogin ? '两颗心，双倍糖' : '创建专属于你们的空间', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 40),

          TextField(controller: _emailCtl, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: '邮箱', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 16),

          if (!_isLogin) TextField(controller: _nameCtl,
            decoration: const InputDecoration(labelText: '昵称', prefixIcon: Icon(Icons.person_outline))),
          if (!_isLogin) const SizedBox(height: 16),

          if (!_useCode)
            TextField(controller: _passCtl, obscureText: true,
              decoration: InputDecoration(
                labelText: _isLogin ? '密码' : '设置密码',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: TextButton(onPressed: () => setState(() => _useCode = !_useCode),
                  child: const Text('验证码', style: TextStyle(fontSize: 12, color: AppTheme.primaryStart))),
              ))
          else
            TextField(controller: _codeCtl, keyboardType: TextInputType.number, maxLength: 6,
              decoration: InputDecoration(
                labelText: '验证码', prefixIcon: const Icon(Icons.sms_outlined),
                suffixIcon: TextButton(onPressed: () async {
                  if (_emailCtl.text.isEmpty) return;
                  try {
                    await _api.sendCode(_emailCtl.text);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('验证码已发送')));
                  } catch (_) {}
                }, child: const Text('获取', style: TextStyle(color: AppTheme.primaryStart))),
              )),
          const SizedBox(height: 24),

          SizedBox(width: double.infinity, height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.buttonGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium), boxShadow: AppTheme.cardShadow),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium))),
                child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isLogin ? '嗯，登录' : '嗯，注册', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            )),
          const SizedBox(height: 16),
          TextButton(onPressed: () => setState(() { _isLogin = !_isLogin; _useCode = false; }),
            child: Text(_isLogin ? '没有账号？去注册' : '已有账号？去登录', style: const TextStyle(color: AppTheme.textSecondary))),
        ]),
      )),
    );
  }
}
