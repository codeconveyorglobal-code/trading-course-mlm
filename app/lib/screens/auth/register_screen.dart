import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  final String? referralCode;
  const RegisterScreen({super.key, this.referralCode});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;
  Map<String, dynamic>? _sponsorInfo;

  @override
  void initState() {
    super.initState();
    if (widget.referralCode != null) {
      _refCtrl.text = widget.referralCode!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final data = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_refCtrl.text.isNotEmpty) 'referralCode': _refCtrl.text.trim(),
    };
    try {
      await context.read<AuthProvider>().register(data);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? 'Registration failed.');
    } catch (_) {
      setState(() => _error = 'An unexpected error occurred.');
    }
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.go('/auth/login')),
                  ],
                ),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                  child: const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(height: 8),
                Text('Join the TradeMLM community today', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withOpacity(0.3))),
                    child: Row(children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)))]),
                  ),
                  const SizedBox(height: 16),
                ],

                AppTextField(controller: _nameCtrl, label: 'Full Name', hint: 'John Doe', icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Name required' : null),
                const SizedBox(height: 16),
                AppTextField(controller: _emailCtrl, label: 'Email', hint: 'you@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Email required' : null),
                const SizedBox(height: 16),
                AppTextField(controller: _phoneCtrl, label: 'Phone (optional)', hint: '+1 234 567 8900', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  hint: 'Min 6 characters',
                  icon: Icons.lock_outline,
                  obscureText: _obscure,
                  validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _refCtrl,
                  label: 'Referral Code (optional)',
                  hint: 'Enter referral code',
                  icon: Icons.link,
                  enabled: widget.referralCode == null,
                ),
                const SizedBox(height: 32),

                GradientButton(label: 'Create Account', loading: auth.loading, onPressed: _register),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.go('/auth/login'),
                      behavior: HitTestBehavior.opaque,
                      child: ShaderMask(
                        shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                        child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
