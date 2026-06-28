import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../../constants/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _useCodeLogin = false;
  bool _isLoading = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    final box = Hive.box('settings');
    box.put('auth_token', 'mock_token');
    box.put('user_email', _emailController.text);

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo & Title
                Text('🍬', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? '欢迎回来' : '加入双糖',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? '两颗心，双倍糖' : '创建一个专属于你们的空间',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    hintText: '请输入邮箱地址',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryStart),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请输入邮箱';
                    if (!v.contains('@')) return '请输入有效的邮箱';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password or Code field
                if (!_useCodeLogin)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _isLogin ? '密码' : '设置密码',
                      hintText: _isLogin ? '请输入密码' : '至少6位密码',
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primaryStart),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '请输入密码';
                      if (v.length < 6) return '密码至少6位';
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: '验证码',
                      hintText: '输入6位验证码',
                      prefixIcon: const Icon(Icons.sms_outlined, color: AppTheme.primaryStart),
                      suffixIcon: TextButton(
                        onPressed: () {},
                        child: const Text('获取验证码', style: TextStyle(color: AppTheme.primaryStart, fontSize: 12)),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '请输入验证码';
                      if (v.length != 6) return '验证码为6位数字';
                      return null;
                    },
                  ),
                const SizedBox(height: 8),

                // Extra options
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() => _useCodeLogin = !_useCodeLogin);
                      },
                      child: Text(
                        _useCodeLogin ? '使用密码登录' : '验证码快捷登录',
                        style: const TextStyle(color: AppTheme.primaryStart, fontSize: 13),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? '嗯，登录' : '嗯，注册',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle login/register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _useCodeLogin = false;
                    });
                  },
                  child: Text(
                    _isLogin ? '还没有账号？去注册' : '已有账号？去登录',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ),
                if (_isLogin)
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '忘记密码？',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
