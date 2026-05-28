import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await context.read<AuthProvider>().login(_emailCtrl.text.trim(), _passCtrl.text);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? 'Login failed. Please try again.');
    } catch (_) {
      setState(() => _error = 'An unexpected error occurred.');
    }
  }

  void _showForgotPassword(BuildContext context) {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reset Password', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Enter your email and our support team will send you reset instructions.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 20),
          AppTextField(controller: emailCtrl, label: 'Email Address', hint: 'you@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Send Reset Request',
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Reset instructions sent to ${emailCtrl.text.isEmpty ? 'your email' : emailCtrl.text}'),
                duration: const Duration(seconds: 4),
              ));
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, spreadRadius: 3)],
                    ),
                    child: const Icon(Icons.candlestick_chart_rounded, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
                  child: const Text('Welcome Back', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(height: 8),
                Text('Sign in to continue your journey', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 40),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withOpacity(0.3))),
                    child: Row(children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)))]),
                  ),
                  const SizedBox(height: 16),
                ],

                AppTextField(controller: _emailCtrl, label: 'Email Address', hint: 'you@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Email required' : null),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscureText: _obscure,
                  validator: (v) => v!.isEmpty ? 'Password required' : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _showForgotPassword(context),
                    child: const Text('Forgot password?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),

                GradientButton(
                  label: 'Sign In',
                  loading: auth.loading,
                  onPressed: _login,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.go('/auth/register'),
                      behavior: HitTestBehavior.opaque,
                      child: ShaderMask(
                        shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                        child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
