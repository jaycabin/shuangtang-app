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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _codeCtl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtl.text.isEmpty) return;
    if (_tabCtrl.index == 0 && _passCtl.text.isEmpty) return;
    if (_tabCtrl.index == 1 && _codeCtl.text.length != 6) return;

    setState(() => _loading = true);
    try {
      if (_tabCtrl.index == 0) {
        await _api.login(_emailCtl.text, _passCtl.text);
      } else {
        await _api.login(_emailCtl.text, _codeCtl.text);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      _showToast('邮箱或密码错误');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          // 顶部品牌区
          const SizedBox(height: 40),
          const Text('🍬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text('双糖', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkText)),
          const SizedBox(height: 4),
          Text('两颗心，双倍糖', style: TextStyle(fontSize: 15, color: AppColors.caramel)),
          const SizedBox(height: 24),

          // Tab 切换
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            decoration: BoxDecoration(
              color: AppColors.frostingWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.caramel,
              labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 15),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '邮箱注册'),
                Tab(text: '验证码登录'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 表单
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                TextField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: '邮箱',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.caramel, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                if (_tabCtrl.index == 0) ...[
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
                  TextField(
                    controller: _codeCtl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '验证码',
                      prefixIcon: const Icon(Icons.sms_outlined, color: AppColors.caramel, size: 20),
                      counterText: '',
                      suffixIcon: TextButton(
                        onPressed: () {},
                        child: const Text('获取', style: TextStyle(color: AppColors.peach)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // 主按钮
                SizedBox(
                  width: double.infinity, height: 52,
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
                          : Text(_tabCtrl.index == 0 ? '注册' : '登录', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 切换方式
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    _tabCtrl.index == 0 ? '已有账号？' : '没有账号？',
                    style: const TextStyle(color: AppColors.caramel, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_tabCtrl.index == 0) {
                        _tabCtrl.animateTo(1);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                      }
                    },
                    child: Text(
                      _tabCtrl.index == 0 ? '去登录' : '去注册',
                      style: const TextStyle(color: AppColors.linkBlue, fontWeight: FontWeight.w600),
                    ),
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
}
