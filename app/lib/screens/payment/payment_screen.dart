import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final String courseId;
  const PaymentScreen({super.key, required this.courseId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedCurrency = 'USDT';
  List<String> _currencies = ['USDT', 'BTC', 'ETH', 'BNB', 'TRX', 'LTC', 'DOGE', 'SOL', 'XRP', 'USDC'];
  Map<String, dynamic>? _payment;
  bool _loading = false;
  bool _initiating = false;
  String? _error;
  Timer? _pollTimer;
  String _paymentStatus = 'waiting';

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    try {
      final api = context.read<ApiService>();
      final res = await api.getSupportedCurrencies();
      final currencies = res.data['currencies'];
      if (currencies is List && currencies.isNotEmpty) {
        setState(() => _currencies = currencies.cast<String>());
      }
    } catch (_) {}
  }

  Future<void> _initiatePayment() async {
    setState(() { _initiating = true; _error = null; });
    try {
      final api = context.read<ApiService>();
      final res = await api.initiatePayment(widget.courseId, _selectedCurrency);
      setState(() => _payment = res.data['payment']);
      _startPolling(res.data['payment']['paymentId']);
    } catch (e) {
      setState(() => _error = 'Failed to create payment. Please try again.');
    }
    setState(() => _initiating = false);
  }

  void _startPolling(String paymentId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        final api = context.read<ApiService>();
        final res = await api.checkPaymentStatus(paymentId);
        final status = res.data['transaction']?['paymentStatus'] ?? 'waiting';
        if (mounted) setState(() => _paymentStatus = status);
        if (['finished', 'failed', 'expired'].contains(status)) {
          timer.cancel();
          if (mounted && status == 'finished') {
            context.go('/payment/result?status=success&paymentId=$paymentId');
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: const Text('Crypto Payment'),
        backgroundColor: AppColors.dark,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: _payment == null ? _SelectionView() : _PaymentDetails(),
    );
  }

  Widget _SelectionView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Payment Currency', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Pay securely with your preferred cryptocurrency', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          if (_error != null) Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withOpacity(0.3))),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ),
          if (_error != null) const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
              itemCount: _currencies.length,
              itemBuilder: (ctx, i) {
                final cur = _currencies[i];
                final selected = cur == _selectedCurrency;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCurrency = cur),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.gradientPrimary : null,
                      color: selected ? null : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? Colors.transparent : AppColors.border),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_currencyEmoji(cur), style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(cur, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _initiating
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _initiatePayment,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Pay with $_selectedCurrency', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
        ],
      ),
    );
  }

  Widget _PaymentDetails() {
    final p = _payment!;
    final address = p['payAddress'] ?? '';
    final amount = p['payAmount']?.toString() ?? '0';
    final currency = p['payCurrency'] ?? _selectedCurrency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _StatusBanner(_paymentStatus),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
            child: Column(children: [
              Text('Send exactly', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                child: Text('$amount $currency', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Text('to the address below', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 20),

          if (address.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: address, size: 200, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Wallet Address', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text(address, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!')));
                  },
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
            child: Column(children: [
              Row(children: const [Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18), SizedBox(width: 8), Text('Important', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600))]),
              const SizedBox(height: 8),
              const Text('• Send only the exact amount shown\n• Payment expires in 60 minutes\n• Do not close this screen while payment is processing', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
            ]),
          ),
        ],
      ),
    );
  }

  String _currencyEmoji(String currency) {
    switch (currency) {
      case 'BTC': return '₿';
      case 'ETH': return 'Ξ';
      case 'USDT': return '💵';
      case 'BNB': return '⭕';
      case 'SOL': return '◎';
      default: return '🪙';
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;
    switch (status) {
      case 'finished': color = AppColors.success; icon = Icons.check_circle_rounded; label = 'Payment Confirmed!'; break;
      case 'confirming': color = AppColors.primary; icon = Icons.sync_rounded; label = 'Confirming...'; break;
      case 'failed': color = AppColors.danger; icon = Icons.error_rounded; label = 'Payment Failed'; break;
      case 'expired': color = AppColors.danger; icon = Icons.access_time_filled_rounded; label = 'Payment Expired'; break;
      default: color = AppColors.warning; icon = Icons.hourglass_empty_rounded; label = 'Waiting for Payment'; break;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
