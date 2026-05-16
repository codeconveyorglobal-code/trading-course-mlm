import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class PaymentResultScreen extends StatelessWidget {
  final String status;
  final String? paymentId;
  const PaymentResultScreen({super.key, required this.status, this.paymentId});

  @override
  Widget build(BuildContext context) {
    final success = status == 'success';
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: success
                      ? const LinearGradient(colors: [AppColors.success, Color(0xFF00A878)])
                      : const LinearGradient(colors: [AppColors.danger, Color(0xFFFF6B6B)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (success ? AppColors.success : AppColors.danger).withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Icon(success ? Icons.check_rounded : Icons.close_rounded, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                success ? 'Payment Successful!' : 'Payment Failed',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                success ? 'Your course has been unlocked. Start learning now!' : 'Your payment could not be processed. Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),
              if (success) ...[
                ElevatedButton(
                  onPressed: () => context.go('/courses'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Go to My Courses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.border), minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
