import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mlm_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _currency = 'USDT';
  String _network = 'TRC20';
  bool _loading = false;
  String? _error;
  String? _success;
  final _currencies = ['USDT', 'BTC', 'ETH', 'BNB'];
  final _networks = {'USDT': ['TRC20', 'ERC20', 'BEP20'], 'BTC': ['BTC'], 'ETH': ['ERC20'], 'BNB': ['BEP20']};

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.cryptoWalletAddress != null) {
      _addressCtrl.text = user!.cryptoWalletAddress!;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _addressCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });
    final success = await context.read<MLMProvider>().requestWithdrawal({
      'amount': double.tryParse(_amountCtrl.text) ?? 0,
      'currency': _currency,
      'cryptoAddress': _addressCtrl.text.trim(),
      'network': _network,
    });
    setState(() {
      _loading = false;
      if (success) { _success = 'Withdrawal request submitted successfully!'; _amountCtrl.clear(); }
      else _error = 'Withdrawal failed. Ensure you meet the minimum payout and have sufficient balance.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(title: const Text('Request Withdrawal'), backgroundColor: AppColors.dark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('\$${(user?.walletBalance ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 24),

            if (_error != null) ...[
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withOpacity(0.3))), child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
              const SizedBox(height: 16),
            ],
            if (_success != null) ...[
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withOpacity(0.3))), child: Text(_success!, style: const TextStyle(color: AppColors.success))),
              const SizedBox(height: 16),
            ],

            const Text('Amount (USD)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            AppTextField(controller: _amountCtrl, label: '', hint: 'Enter amount', icon: Icons.attach_money, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),

            const Text('Currency', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: _currencies.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() { _currency = c; _network = (_networks[c] ?? [''])[0]; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: _currency == c ? AppColors.gradientPrimary : null,
                      color: _currency == c ? null : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _currency == c ? Colors.transparent : AppColors.border),
                    ),
                    child: Text(c, style: TextStyle(color: _currency == c ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            const Text('Network', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: (_networks[_currency] ?? []).map((n) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _network = n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _network == n ? AppColors.primary.withOpacity(0.15) : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _network == n ? AppColors.primary.withOpacity(0.4) : AppColors.border),
                    ),
                    child: Text(n, style: TextStyle(color: _network == n ? AppColors.primary : AppColors.textSecondary, fontSize: 13)),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            AppTextField(controller: _addressCtrl, label: 'Wallet Address', hint: 'Your $_currency wallet address', icon: Icons.account_balance_wallet_outlined),
            const SizedBox(height: 28),

            GradientButton(label: 'Submit Withdrawal Request', loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
