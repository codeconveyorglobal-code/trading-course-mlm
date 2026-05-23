import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _wallet;
  List _commissions = [];
  List _withdrawals = [];
  bool _loading = true;
  bool _savingAddress = false;
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final res = await api.getWallet();
      final data = res.data;
      setState(() {
        _wallet = data['wallet'];
        _commissions = data['recentCommissions'] ?? [];
        _withdrawals = data['recentWithdrawals'] ?? [];
        _addressCtrl.text = _wallet?['cryptoWalletAddress'] ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load wallet: $e'), backgroundColor: AppColors.danger),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _saveAddress() async {
    final address = _addressCtrl.text.trim();
    if (address.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid wallet address'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _savingAddress = true);
    try {
      final api = context.read<ApiService>();
      await api.saveWalletAddress(address);
      setState(() => _wallet = {...?_wallet, 'cryptoWalletAddress': address});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet address saved!'), backgroundColor: AppColors.success),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save address'), backgroundColor: AppColors.danger),
      );
    }
    setState(() => _savingAddress = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: AppColors.dark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadWallet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadWallet,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BalanceCard(wallet: _wallet),
                    const SizedBox(height: 20),
                    _ActionButtons(balance: (_wallet?['balance'] ?? 0).toDouble()),
                    const SizedBox(height: 24),
                    _AddressSection(
                      controller: _addressCtrl,
                      loading: _savingAddress,
                      onSave: _saveAddress,
                    ),
                    const SizedBox(height: 24),
                    if (_withdrawals.isNotEmpty) ...[
                      const _SectionHeader('Recent Withdrawals'),
                      const SizedBox(height: 12),
                      ..._withdrawals.map((w) => _WithdrawalTile(w)),
                      const SizedBox(height: 24),
                    ],
                    const _SectionHeader('Recent Commissions'),
                    const SizedBox(height: 12),
                    if (_commissions.isEmpty)
                      _EmptyCard('No commissions yet.\nInvite people to start earning!')
                    else
                      ..._commissions.map((c) => _CommissionTile(c)),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final Map<String, dynamic>? wallet;
  const _BalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final balance = (wallet?['balance'] ?? 0).toDouble();
    final earned = (wallet?['totalEarnings'] ?? 0).toDouble();
    final withdrawn = (wallet?['totalWithdrawn'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _BalanceStat('Total Earned', '\$${earned.toStringAsFixed(2)}'),
            const SizedBox(width: 24),
            _BalanceStat('Withdrawn', '\$${withdrawn.toStringAsFixed(2)}'),
            const SizedBox(width: 24),
            _BalanceStat('Pending Payout', '\$${(earned - withdrawn).clamp(0, double.infinity).toStringAsFixed(2)}'),
          ]),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  const _BalanceStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
    ],
  );
}

// ─── Action Buttons ───────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final double balance;
  const _ActionButtons({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => context.go('/profile/withdraw'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF00A878)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 12)],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.send_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Withdraw', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GestureDetector(
          onTap: () => context.go('/mlm'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('MLM Stats', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ─── Crypto Address Section ───────────────────────────────────────────────────
class _AddressSection extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSave;
  const _AddressSection({required this.controller, required this.loading, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.currency_bitcoin_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            const Text('Default Withdrawal Address', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          ]),
          const SizedBox(height: 6),
          const Text('This address is pre-filled when you request a withdrawal.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          AppTextField(
            controller: controller,
            label: '',
            hint: 'Enter your USDT / crypto wallet address',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GradientButton(label: 'Save Address', loading: loading, onPressed: onSave),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
  );
}

// ─── Commission Tile ──────────────────────────────────────────────────────────
class _CommissionTile extends StatelessWidget {
  final Map<String, dynamic> c;
  const _CommissionTile(this.c);

  @override
  Widget build(BuildContext context) {
    final type = (c['type'] ?? '').toString().replaceAll('_', ' ');
    final fromUser = c['fromUserId'];
    final course = c['courseId'];
    final amount = (c['amount'] ?? 0).toDouble();
    final status = c['status'] ?? 'pending';
    final statusColor = status == 'paid' ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            if (fromUser != null)
              Text('From: ${fromUser['name'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            if (course != null)
              Text(course['title'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+\$${amount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 14)),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }
}

// ─── Withdrawal Tile ──────────────────────────────────────────────────────────
class _WithdrawalTile extends StatelessWidget {
  final Map<String, dynamic> w;
  const _WithdrawalTile(this.w);

  Color get _statusColor {
    switch (w['status']) {
      case 'completed': return AppColors.success;
      case 'processing': return AppColors.primary;
      case 'rejected': return AppColors.danger;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = (w['amount'] ?? 0).toDouble();
    final currency = w['currency'] ?? 'USDT';
    final address = w['cryptoAddress'] ?? '';
    final status = w['status'] ?? 'pending';
    final network = w['network'];
    final txHash = w['txHash'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: _statusColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.call_made_rounded, color: _statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Withdrawal Request', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              Text('$currency${network != null ? ' · $network' : ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('-\$${amount.toStringAsFixed(2)}', style: TextStyle(color: _statusColor, fontWeight: FontWeight.w700, fontSize: 14)),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary, size: 13),
              const SizedBox(width: 4),
              Expanded(child: Text(
                address.length > 30 ? '${address.substring(0, 16)}...${address.substring(address.length - 8)}' : address,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
              )),
              GestureDetector(
                onTap: () { Clipboard.setData(ClipboardData(text: address)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied'))); },
                child: const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 13),
              ),
            ]),
          ],
          if (txHash != null && txHash.toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 13),
              const SizedBox(width: 4),
              Expanded(child: Text(
                'TX: ${txHash.toString().substring(0, 16)}...',
                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontFamily: 'monospace'),
              )),
              GestureDetector(
                onTap: () { Clipboard.setData(ClipboardData(text: txHash.toString())); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TX hash copied'))); },
                child: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 13),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ─── Empty Card ───────────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard(this.message);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
    child: Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
  );
}
