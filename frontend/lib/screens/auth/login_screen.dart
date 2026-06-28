import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePass = true;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    _nameCtl.dispose();
    _codeCtl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _emailCtl.text.trim(),
          password: _passCtl.text,
        );
      } else {
        await supabase.auth.signUp(
          email: _emailCtl.text.trim(),
          password: _passCtl.text,
          data: {'nickname': _nameCtl.text.trim()},
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorRed),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('连接失败，请检查网络'), backgroundColor: AppTheme.errorRed),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(children: [
              const SizedBox(height: 60),
              Text('🍬', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(_isLogin ? '欢迎回来' : '加入双糖',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text(_isLogin ? '两颗心，双倍糖' : '创建一个专属于你们的空间',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 48),

              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '邮箱', hintText: '请输入邮箱', prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryStart)),
                validator: (v) => (v == null || !v.contains('@')) ? '请输入有效邮箱' : null,
              ),
              const SizedBox(height: 16),

              if (!_isLogin)
                TextFormField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(labelText: '昵称', hintText: '你想被怎么称呼', prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryStart)),
                ),
              if (!_isLogin) const SizedBox(height: 16),

              TextFormField(
                controller: _passCtl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: _isLogin ? '密码' : '设置密码',
                  hintText: '至少6位密码',
                  prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primaryStart),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: AppTheme.textHint),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? '密码至少6位' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                    ),
                    child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isLogin ? '嗯，登录' : '嗯，注册',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? '还没有账号？去注册' : '已有账号？去登录',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
