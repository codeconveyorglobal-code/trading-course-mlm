import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mlm_provider.dart';
import '../../widgets/stat_card.dart';
import '../../models/mlm_model.dart';

class MLMDashboardScreen extends StatefulWidget {
  const MLMDashboardScreen({super.key});

  @override
  State<MLMDashboardScreen> createState() => _MLMDashboardScreenState();
}

class _MLMDashboardScreenState extends State<MLMDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MLMProvider>().fetchStats();
      context.read<MLMProvider>().fetchCommissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mlm = context.watch<MLMProvider>();
    final auth = context.watch<AuthProvider>();
    final stats = mlm.stats;
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: const Text('MLM Dashboard'),
        backgroundColor: AppColors.dark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_rounded),
            onPressed: () => context.go('/mlm/tree'),
            tooltip: 'View Binary Tree',
          ),
        ],
      ),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<MLMProvider>().fetchStats();
                await context.read<MLMProvider>().fetchCommissions();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 18), SizedBox(width: 6), Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 13))]),
                        const SizedBox(height: 8),
                        Text('\$${stats.walletBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        Row(children: [
                          _EarningItem('Total Earned', '\$${stats.totalEarnings.toStringAsFixed(2)}'),
                          const SizedBox(width: 20),
                          _EarningItem('Withdrawn', '\$${stats.totalWithdrawn.toStringAsFixed(2)}'),
                          const SizedBox(width: 20),
                          _EarningItem('Pending', '\$${stats.pendingCommission.toStringAsFixed(2)}'),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Referral Link
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Your Referral Link', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: Text(stats.referralLink, style: const TextStyle(color: AppColors.primary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: stats.referralLink));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral link copied!')));
                            },
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Team Stats Grid
                    const Text('Team Statistics', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        StatCard(label: 'Team Size', value: '${stats.teamStats.totalTeamSize}', icon: Icons.people_outline, color: AppColors.primary),
                        StatCard(label: 'Direct Referrals', value: '${stats.teamStats.totalDirectReferrals}', icon: Icons.person_add_outlined, color: AppColors.secondary),
                        StatCard(label: 'Left Leg', value: '${stats.teamStats.leftCount}', icon: Icons.arrow_back_ios_rounded, color: AppColors.success),
                        StatCard(label: 'Right Leg', value: '${stats.teamStats.rightCount}', icon: Icons.arrow_forward_ios_rounded, color: AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Volume
                    Row(children: [
                      Expanded(child: _VolumeCard('Left Volume', '\$${stats.teamStats.leftVolume.toStringAsFixed(2)}', AppColors.success)),
                      const SizedBox(width: 12),
                      Expanded(child: _VolumeCard('Right Volume', '\$${stats.teamStats.rightVolume.toStringAsFixed(2)}', AppColors.warning)),
                    ]),
                    const SizedBox(height: 20),

                    // Action Buttons Row
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/profile/withdraw'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF00A878)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 12)],
                            ),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Withdraw', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/profile/wallet'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                            ),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('My Wallet', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // Recent Commissions
                    const Text('Recent Commissions', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (mlm.commissions.isEmpty)
                      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Center(child: Text('No commissions yet', style: TextStyle(color: AppColors.textSecondary))))
                    else
                      ...mlm.commissions.take(10).map((c) => _CommissionTile(commission: c)),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EarningItem extends StatelessWidget {
  final String label;
  final String value;
  const _EarningItem(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
  ]);
}

class _VolumeCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _VolumeCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _CommissionTile extends StatelessWidget {
  final Commission commission;
  const _CommissionTile({required this.commission});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (commission.status) {
      case 'paid': statusColor = AppColors.success; break;
      case 'pending': statusColor = AppColors.warning; break;
      default: statusColor = AppColors.textSecondary;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_formatType(commission.type), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
          Text(commission.fromUserName != null ? 'From: ${commission.fromUserName}' : 'Level ${commission.level}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+\$${commission.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
          Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(commission.status, style: TextStyle(color: statusColor, fontSize: 11))),
        ]),
      ]),
    );
  }

  String _formatType(String type) {
    switch (type) {
      case 'direct_referral': return 'Direct Referral';
      case 'level_override': return 'Level Override';
      case 'binary_matching': return 'Binary Matching';
      case 'rank_bonus': return 'Rank Bonus';
      default: return type;
    }
  }
}
