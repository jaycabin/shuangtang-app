import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/api_service.dart';

final _api = ApiService();

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  int _step = 0;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailCtl.dispose(); _codeCtl.dispose(); _passCtl.dispose(); _confirmCtl.dispose();
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
      await _api.forgotPassword(_emailCtl.text);
      _startCountdown();
      setState(() => _step = 1);
    } catch (_) {
      _showToast(AppLocalizations.of(context)!.toast_send_fail);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _reset() async {
    if (_passCtl.text.length < 6 || _passCtl.text != _confirmCtl.text) {
      _showToast(_passCtl.text != _confirmCtl.text ? '两次密码不一致' : '密码至少6位');
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.resetPassword(_emailCtl.text, _codeCtl.text, _passCtl.text);
      _showToast('密码已重置');
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      String msg = AppLocalizations.of(context)!.toast_reset_fail;
      try { final body = (e as dynamic).response?.data;
        if (body != null) {
          final m = body['message'] ?? '';
          if (m.toString().contains('过期')) msg = AppLocalizations.of(context)!.toast_code_expired;
          else if (m.toString().contains('错误')) msg = AppLocalizations.of(context)!.toast_code_error;
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
      appBar: AppBar(leading: const BackButton(), title: const Text('找回密码')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 8),
            const Text('重置密码后可使用新密码登录', style: TextStyle(fontSize: 14, color: AppColors.caramel)),
            const SizedBox(height: 24),

            if (_step == 0) _buildStep0() else _buildStep1(),
          ]),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(children: [
      TextField(
        controller: _emailCtl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: '注册时使用的邮箱',
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
              : const Text('发送验证码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStep1() {
    return Column(children: [
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
            child: Text(_countdown > 0 ? '${_countdown}s' : '重新获取',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: _countdown > 0 ? AppColors.greyText : AppColors.peach)),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _passCtl,
        obscureText: _obscure,
        decoration: InputDecoration(
          hintText: '新密码（至少6位）',
          prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.caramel, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.greyText, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _confirmCtl,
        obscureText: true,
        decoration: const InputDecoration(
          hintText: '再次输入新密码',
          prefixIcon: Icon(Icons.lock_outlined, color: AppColors.caramel, size: 20),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.button), boxShadow: AppShadows.button),
          child: ElevatedButton(
            onPressed: _loading ? null : _reset,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
            child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('重置密码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }
}
