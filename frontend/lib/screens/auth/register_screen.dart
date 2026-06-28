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
      _showToast('验证码已发送');
    } catch (_) {
      _showToast('发送失败');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _register() async {
    if (_codeCtl.text.length != 6 || _passCtl.text.length < 6) return;
    setState(() => _loading = true);
    try {
      await _api.register(_emailCtl.text, _passCtl.text, _codeCtl.text, nickname: _nameCtl.text);
      // 注册成功后自动登录（保存 token）
      await _api.login(_emailCtl.text, _passCtl.text);
      if (!mounted) return;
      _showToast('🎉 注册成功');
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      String msg = '注册失败';
      try {
        final body = (e as dynamic).response?.data;
        if (body != null) {
          final m = body['message'] ?? '';
          if (m.toString().contains('已注册')) msg = '邮箱已注册';
          else if (m.toString().contains('过期')) msg = '验证码已过期';
          else if (m.toString().contains('错误')) msg = '验证码错误';
          else msg = m;
        }
      } catch (e) { debugPrint("err: $e"); }
      _showToast(msg);
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
            const SizedBox(height: 8),
            const Text('创建属于你们的双糖空间', style: TextStyle(fontSize: 14, color: AppColors.caramel)),
            const SizedBox(height: 24),

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

            // 昵称
            TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(
                hintText: '对方怎么称呼你',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.caramel, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // 验证码 + 获取按钮
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _codeCtl,
                  keyboardType: TextInputType.number, maxLength: 6,
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
            const SizedBox(height: 12),

            // 密码
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

            // 注册按钮
            SizedBox(width: double.infinity, height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  boxShadow: AppShadows.button,
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                  child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('嗯，注册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('已有账号？', style: TextStyle(color: AppColors.caramel, fontSize: 14)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('去登录', style: TextStyle(color: AppColors.linkBlue, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}
