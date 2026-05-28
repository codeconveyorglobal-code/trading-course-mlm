import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _walletCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone ?? '';
      _walletCtrl.text = user.cryptoWalletAddress ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _walletCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final api = context.read<ApiService>();
      final data = <String, dynamic>{'name': _nameCtrl.text.trim()};
      if (_phoneCtrl.text.trim().isNotEmpty) data['phone'] = _phoneCtrl.text.trim();
      if (_walletCtrl.text.trim().isNotEmpty) data['cryptoWalletAddress'] = _walletCtrl.text.trim();
      await api.updateProfile(data);
      await auth.refreshUser();
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      }
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data?['message'] ?? 'Update failed')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const Scaffold(backgroundColor: AppColors.dark);

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.dark,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(_editing ? 'Cancel' : 'Edit', style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, spreadRadius: 2)],
                    ),
                    child: Center(
                      child: Text(user.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(20)),
              child: Text(user.rank, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 28),

            // Stats
            Row(children: [
              Expanded(child: _ProfileStat('Wallet', '\$${user.walletBalance.toStringAsFixed(2)}')),
              Expanded(child: _ProfileStat('Earned', '\$${user.totalEarnings.toStringAsFixed(2)}')),
              Expanded(child: _ProfileStat('Courses', '${user.purchasedCourses.length}')),
            ]),
            const SizedBox(height: 24),

            if (_editing) ...[
              AppTextField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline),
              const SizedBox(height: 12),
              AppTextField(controller: _phoneCtrl, label: 'Phone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              AppTextField(controller: _walletCtrl, label: 'Crypto Wallet Address', icon: Icons.account_balance_wallet_outlined),
              const SizedBox(height: 20),
              GradientButton(label: 'Save Changes', loading: _saving, onPressed: _save),
              const SizedBox(height: 16),
            ] else ...[
              _InfoCard(user: user),
              const SizedBox(height: 16),
            ],

            // Actions
            _ActionTile(icon: Icons.wallet_rounded, label: 'Request Withdrawal', onTap: () => context.go('/profile/withdraw')),
            _ActionTile(icon: Icons.account_balance_wallet_rounded, label: 'My Wallet & Commissions', onTap: () => context.go('/profile/wallet')),
            _ActionTile(icon: Icons.lock_outline, label: 'Change Password', onTap: () => _showChangePassword(context)),
            _ActionTile(icon: Icons.share_rounded, label: 'Share Referral Link', onTap: () {
              final code = context.read<AuthProvider>().user?.referralCode ?? '';
              final link = 'https://app-orcin-beta-93.vercel.app/auth/register?ref=$code';
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Referral link copied!\n$link'), duration: const Duration(seconds: 3)),
              );
            }),
            _ActionTile(icon: Icons.logout_rounded, label: 'Sign Out', color: AppColors.danger, onTap: () async { await auth.logout(); }),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Change Password', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          AppTextField(controller: currentCtrl, label: 'Current Password', icon: Icons.lock_outline, obscureText: true),
          const SizedBox(height: 12),
          AppTextField(controller: newCtrl, label: 'New Password', icon: Icons.lock_reset_outlined, obscureText: true),
          const SizedBox(height: 20),
          GradientButton(label: 'Update Password', onPressed: () async {
            try {
              final api = context.read<ApiService>();
              await api.changePassword(currentCtrl.text, newCtrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!')));
            } on DioException catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data?['message'] ?? 'Failed')));
            }
          }),
        ]),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      ShaderMask(
        shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
        child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  final user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Row(Icons.badge_outlined, 'Referral Code', user.referralCode),
      _Row(Icons.phone_outlined, 'Phone', user.phone ?? 'Not set'),
      _Row(Icons.account_balance_wallet_outlined, 'Wallet Address', user.cryptoWalletAddress ?? 'Not set'),
      _Row(Icons.calendar_today_outlined, 'Member Since', _fmt(user.joinDate)),
    ]),
  );

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
      ]),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500))),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      ]),
    ),
  );
}

