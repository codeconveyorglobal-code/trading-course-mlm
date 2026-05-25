import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

// ─── Breakpoints ──────────────────────────────────────────────────────────────
const double _kDesktop = 900;
const double _kMaxWidth = 1200;

extension _Responsive on BuildContext {
  double get screenW => MediaQuery.of(this).size.width;
  bool get isDesktop => screenW >= _kDesktop;
  double get hPad => isDesktop ? 80.0 : 20.0;
  EdgeInsets get secPad => EdgeInsets.fromLTRB(hPad, 64, hPad, 0);
}

Widget _constrained(Widget child, {double max = _kMaxWidth}) =>
    Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: max), child: child));

// ─── Screen ───────────────────────────────────────────────────────────────────
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  List _featuredCourses = [];
  Map<String, dynamic> _stats = {};
  bool _statsLoaded = false;

  final _scrollCtrl = ScrollController();
  int _currentHeroSlide = 0;
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
    _heroCtrl.forward();
    _startHeroTimer();
    _loadData();
  }

  void _startHeroTimer() {
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _currentHeroSlide = (_currentHeroSlide + 1) % _heroSlides.length);
    });
  }

  Future<void> _loadData() async {
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getPublicStats(),
        api.getPublicCourses(limit: 6),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0].data['stats'] ?? {};
          _featuredCourses = results[1].data['courses'] ?? [];
          _statsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _particleCtrl.dispose();
    _heroTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  static const _heroSlides = [
    _HeroSlide(
      tag: 'Trading Education',
      headline: 'Master Crypto Trading\n& Build Passive Income',
      sub: 'Learn from industry experts. Trade smarter, earn commissions, and grow your network with our proven MLM system.',
    ),
    _HeroSlide(
      tag: 'Earn While You Learn',
      headline: 'Refer Friends &\nEarn Real Commissions',
      sub: 'Our binary MLM system rewards you for every referral. Direct + level commissions paid instantly to your wallet.',
    ),
    _HeroSlide(
      tag: 'Crypto Powered',
      headline: 'Secure Crypto\nPayments & Payouts',
      sub: 'Pay with USDT, BTC, ETH and 100+ cryptocurrencies. Withdrawals processed directly to your wallet.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverToBoxAdapter(child: _buildStatsBar(context)),
          SliverToBoxAdapter(child: _buildHowItWorks(context)),
          SliverToBoxAdapter(child: _buildFeaturedCourses(context)),
          SliverToBoxAdapter(child: _buildWhyChooseUs(context)),
          SliverToBoxAdapter(child: _buildCommissionPlan(context)),
          SliverToBoxAdapter(child: _buildTestimonials(context)),
          SliverToBoxAdapter(child: _buildFAQ(context)),
          SliverToBoxAdapter(child: _buildCTA(context)),
          SliverToBoxAdapter(child: _buildFooter(context)),
        ],
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context) {
    final isDesktop = context.isDesktop;
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.dark.withOpacity(0.95),
      elevation: 0,
      toolbarHeight: isDesktop ? 64 : 56,
      title: _constrained(Row(children: [
        Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
          child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
          child: Text('TradeMaster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: isDesktop ? 20 : 18)),
        ),
        const Spacer(),
        if (isDesktop) ...[
          _NavLink('Features', onTap: () {}),
          _NavLink('Courses', onTap: () {}),
          _NavLink('Commission', onTap: () {}),
          _NavLink('FAQ', onTap: () {}),
          const SizedBox(width: 16),
        ],
        TextButton(
          onPressed: () => context.go('/auth/login'),
          child: const Text('Login', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.go('/auth/register'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(22)),
            child: const Text('Get Started', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ])),
      titleSpacing: context.hPad,
      actions: const [SizedBox.shrink()],
    );
  }

  // ─── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    final isDesktop = context.isDesktop;
    final heroHeight = isDesktop ? 620.0 : 580.0;
    final slide = _heroSlides[_currentHeroSlide];

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: Size(double.infinity, heroHeight),
              painter: _GridPainter(_particleCtrl.value),
            ),
          ),
          Positioned(top: -80, right: isDesktop ? 100 : -80, child: _GlowOrb(size: 400, color: AppColors.primary.withOpacity(0.12))),
          Positioned(bottom: -60, left: -80, child: _GlowOrb(size: 300, color: AppColors.secondary.withOpacity(0.1))),
          Positioned(top: 80, right: isDesktop ? 460 : 60, child: _GlowOrb(size: 120, color: AppColors.success.withOpacity(0.08))),
          // Floating coins (mobile only — desktop shows them inside visual panel)
          if (!isDesktop)
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) {
                final v = _particleCtrl.value;
                return Stack(children: [
                  Positioned(top: 120 + 12 * math.sin(v * 2 * math.pi), right: 20,
                    child: _FloatingCoin(icon: Icons.currency_bitcoin, color: AppColors.warning, size: 40)),
                  Positioned(top: 240 + 10 * math.sin(v * 2 * math.pi + 1), right: 100,
                    child: _FloatingCoin(symbol: 'ETH', color: AppColors.secondary, size: 32)),
                  Positioned(top: 360 + 8 * math.sin(v * 2 * math.pi + 2), right: 30,
                    child: _FloatingCoin(symbol: 'USDT', color: AppColors.success, size: 28)),
                ]);
              },
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.hPad),
            child: _constrained(
              isDesktop ? _buildHeroDesktop(slide) : _buildHeroMobile(slide),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroDesktop(_HeroSlide slide) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 55,
          child: FadeTransition(
            opacity: _heroFade,
            child: SlideTransition(position: _heroSlide, child: _buildHeroText(slide, isDesktop: true)),
          ),
        ),
        const SizedBox(width: 64),
        Expanded(
          flex: 45,
          child: FadeTransition(opacity: _heroFade, child: _buildHeroVisual()),
        ),
      ],
    );
  }

  Widget _buildHeroMobile(_HeroSlide slide) {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(position: _heroSlide, child: _buildHeroText(slide, isDesktop: false)),
    );
  }

  Widget _buildHeroText(_HeroSlide slide, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isDesktop ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        SizedBox(height: isDesktop ? 0 : 40),
        Row(children: List.generate(_heroSlides.length, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: i == _currentHeroSlide ? 20 : 6, height: 6,
          decoration: BoxDecoration(
            color: i == _currentHeroSlide ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
        ))),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Container(
            key: ValueKey(slide.tag),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(slide.tag, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        SizedBox(height: isDesktop ? 20 : 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            key: ValueKey(slide.headline),
            slide.headline,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 52 : 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 20 : 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            key: ValueKey(slide.sub),
            slide.sub,
            style: TextStyle(color: AppColors.textSecondary, fontSize: isDesktop ? 16 : 14, height: 1.7),
          ),
        ),
        SizedBox(height: isDesktop ? 36 : 32),
        Row(children: [
          GestureDetector(
            onTap: () => context.go('/auth/register'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 24, vertical: isDesktop ? 16 : 14),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 24, spreadRadius: 2)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Get Started Free', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: isDesktop ? 16 : 15)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/auth/login'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 20, vertical: isDesktop ? 15 : 13),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(32)),
              child: Text('Sign In', style: TextStyle(color: AppColors.textSecondary, fontSize: isDesktop ? 16 : 15)),
            ),
          ),
        ]),
        const SizedBox(height: 36),
        Wrap(spacing: 20, runSpacing: 10, children: const [
          _TrustBadge(icon: Icons.verified_rounded, label: 'Certified Courses'),
          _TrustBadge(icon: Icons.lock_outline_rounded, label: 'Secure Crypto'),
          _TrustBadge(icon: Icons.people_outline_rounded, label: 'Active Community'),
        ]),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return AnimatedBuilder(
      animation: _particleCtrl,
      builder: (_, __) {
        final v = _particleCtrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 40),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 40, spreadRadius: 4)],
              ),
              child: Column(children: [
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight,
                      colors: [AppColors.primary.withOpacity(0.08), AppColors.secondary.withOpacity(0.06)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomPaint(painter: _MiniChartPainter(v)),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  _HeroStatBox(value: '+32%', label: 'Avg. Return', color: AppColors.success),
                  const SizedBox(width: 12),
                  _HeroStatBox(value: '\$2.4K', label: 'Avg. Commission', color: AppColors.primary),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _HeroStatBox(value: '100+', label: 'Crypto Assets', color: AppColors.warning),
                  const SizedBox(width: 12),
                  _HeroStatBox(value: '4-Level', label: 'MLM Depth', color: AppColors.secondary),
                ]),
              ]),
            ),
            Positioned(top: 0, right: 0, child: _FloatingCoin(icon: Icons.currency_bitcoin, color: AppColors.warning, size: 52,
              offset: Offset(0, 14 * math.sin(v * 2 * math.pi)))),
            Positioned(top: 110, left: 0, child: _FloatingCoin(symbol: 'ETH', color: AppColors.secondary, size: 42,
              offset: Offset(0, 10 * math.sin(v * 2 * math.pi + 1)))),
            Positioned(bottom: 50, right: 0, child: _FloatingCoin(symbol: 'USDT', color: AppColors.success, size: 38,
              offset: Offset(0, 8 * math.sin(v * 2 * math.pi + 2)))),
            Positioned(bottom: 0, left: 10, child: _FloatingCoin(symbol: 'BNB', color: AppColors.warning, size: 34,
              offset: Offset(0, 12 * math.sin(v * 2 * math.pi + 3)))),
          ],
        );
      },
    );
  }

  // ─── Stats Bar ────────────────────────────────────────────────────────────
  Widget _buildStatsBar(BuildContext context) {
    final users = _stats['totalUsers'] ?? 0;
    final courses = _stats['totalCourses'] ?? 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 8),
      child: _constrained(Container(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: context.isDesktop ? 48 : 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatItem(value: _statsLoaded ? '${users}+' : '...', label: 'Students', color: AppColors.primary),
          _StatDivider(),
          _StatItem(value: _statsLoaded ? '$courses' : '...', label: 'Courses', color: AppColors.secondary),
          _StatDivider(),
          _StatItem(value: '\$500K+', label: 'Paid Out', color: AppColors.success),
          _StatDivider(),
          _StatItem(value: '98%', label: 'Satisfaction', color: AppColors.warning),
        ]),
      )),
    );
  }

  // ─── How It Works ─────────────────────────────────────────────────────────
  Widget _buildHowItWorks(BuildContext context) {
    final isDesktop = context.isDesktop;
    const steps = [
      (step: '01', title: 'Create Your Account', desc: 'Sign up in minutes. Use a referral link from your sponsor to join the network and unlock commissions.', icon: Icons.person_add_rounded, color: AppColors.primary),
      (step: '02', title: 'Enroll in a Course', desc: 'Choose from expert-led trading courses. Pay securely with crypto (USDT, BTC, ETH) and start learning immediately.', icon: Icons.school_rounded, color: AppColors.secondary),
      (step: '03', title: 'Refer & Earn', desc: 'Share your referral link. Earn direct + binary commissions for every new member your network brings in.', icon: Icons.trending_up_rounded, color: AppColors.success),
    ];
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('HOW IT WORKS'),
        const SizedBox(height: 10),
        Text('Start Earning in 3 Simple Steps',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('No experience needed. Learn, refer, and earn.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 32),
        if (isDesktop)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: steps.mapIndexed((i, s) => [
                Expanded(child: _StepCard(step: s.step, title: s.title, desc: s.desc, icon: s.icon, color: s.color)),
                if (i < steps.length - 1) const SizedBox(width: 16),
              ]).expand((e) => e).toList(),
            ),
          )
        else
          Column(children: steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _StepCard(step: s.step, title: s.title, desc: s.desc, icon: s.icon, color: s.color),
          )).toList()),
      ])),
    );
  }

  // ─── Featured Courses ─────────────────────────────────────────────────────
  Widget _buildFeaturedCourses(BuildContext context) {
    final isDesktop = context.isDesktop;
    final count = _featuredCourses.isEmpty ? 4 : math.min(_featuredCourses.length, 6);
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('COURSES'),
        const SizedBox(height: 10),
        Text('Expert-Led Trading Courses',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Master the markets with structured, beginner-friendly content.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        if (isDesktop)
          LayoutBuilder(builder: (_, c) {
            final cols = c.maxWidth > 800 ? 3 : 2;
            final w = (c.maxWidth - (cols - 1) * 16) / cols;
            return Wrap(
              spacing: 16, runSpacing: 16,
              children: List.generate(count, (i) => SizedBox(
                width: w,
                child: _featuredCourses.isEmpty
                    ? _PlaceholderCourseCard(i, isDesktop: true)
                    : _CourseCard(course: _featuredCourses[i], isDesktop: true),
              )),
            );
          })
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: count,
              itemBuilder: (_, i) => _featuredCourses.isEmpty
                  ? _PlaceholderCourseCard(i)
                  : _CourseCard(course: _featuredCourses[i]),
            ),
          ),
        const SizedBox(height: 24),
        Center(child: GestureDetector(
          onTap: () => context.go('/auth/register'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(border: Border.all(color: AppColors.primary.withOpacity(0.5)), borderRadius: BorderRadius.circular(30)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('View All Courses', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 16),
            ]),
          ),
        )),
      ])),
    );
  }

  // ─── Why Choose Us ────────────────────────────────────────────────────────
  Widget _buildWhyChooseUs(BuildContext context) {
    final isDesktop = context.isDesktop;
    const features = [
      _Feature(icon: Icons.workspace_premium_rounded, title: 'Expert Mentors', desc: 'Learn from professional traders with years of market experience.', color: AppColors.warning),
      _Feature(icon: Icons.currency_bitcoin_rounded, title: 'Crypto Payments', desc: 'Pay & receive payouts in 100+ cryptocurrencies via NOWPayments.', color: AppColors.warning),
      _Feature(icon: Icons.account_tree_rounded, title: 'Binary MLM System', desc: 'Earn from both your left and right network legs with matching bonuses.', color: AppColors.primary),
      _Feature(icon: Icons.verified_user_rounded, title: 'Certified Courses', desc: 'Get completion certificates recognized by the trading community.', color: AppColors.primary),
      _Feature(icon: Icons.support_agent_rounded, title: '24/7 Support', desc: 'Our team is always available to help you succeed.', color: AppColors.secondary),
      _Feature(icon: Icons.lock_rounded, title: 'Secure Platform', desc: 'JWT-secured accounts, encrypted wallets, IPN-verified payments.', color: AppColors.secondary),
    ];
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('WHY US'),
        const SizedBox(height: 10),
        Text('Everything You Need to Succeed',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Built for traders, by traders. A complete ecosystem for growth.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 32),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isDesktop ? 1.15 : 0.9,
          ),
          itemCount: features.length,
          itemBuilder: (_, i) => _FeatureCard(feature: features[i], isDesktop: isDesktop),
        ),
      ])),
    );
  }

  // ─── Commission Plan ──────────────────────────────────────────────────────
  Widget _buildCommissionPlan(BuildContext context) {
    final isDesktop = context.isDesktop;
    const commRows = [
      (icon: Icons.person_add_rounded, title: 'Direct Referral Bonus', desc: 'Earn % when someone joins using your link', badge: '10%', color: AppColors.success),
      (icon: Icons.layers_rounded, title: 'Level Override Bonus', desc: 'Earn from multiple levels deep in your network', badge: 'Multi-Level', color: AppColors.primary),
      (icon: Icons.compare_arrows_rounded, title: 'Binary Matching Bonus', desc: 'Earn when left & right legs match in volume', badge: '10%', color: AppColors.secondary),
      (icon: Icons.star_rounded, title: 'Rank Advancement Bonus', desc: 'Hit targets to unlock Bronze → Diamond rewards', badge: 'Up to 5x', color: AppColors.warning),
    ];
    final cta = SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => context.go('/auth/register'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(14)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Start Earning Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            SizedBox(width: 8),
            Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
          ]),
        ),
      ),
    );
    final leftCol = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('EARNINGS'),
      const SizedBox(height: 10),
      Text('Commission Structure',
        style: TextStyle(color: Colors.white, fontSize: isDesktop ? 32 : 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Multiple income streams from a single membership. Earn from every level of your network.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
      if (isDesktop) ...[const SizedBox(height: 32), cta],
    ]);
    final rightCol = Column(children: [
      ...commRows.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _CommissionRow(icon: r.icon, title: r.title, desc: r.desc, badge: r.badge, color: r.color),
      )),
      if (!isDesktop) ...[const SizedBox(height: 12), cta],
    ]);
    return Padding(
      padding: context.secPad,
      child: _constrained(Container(
        padding: EdgeInsets.all(isDesktop ? 40 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.secondary.withOpacity(0.15), AppColors.primary.withOpacity(0.08)]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: isDesktop
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 4, child: leftCol),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: rightCol),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [leftCol, const SizedBox(height: 24), rightCol]),
      )),
    );
  }

  // ─── Testimonials ─────────────────────────────────────────────────────────
  Widget _buildTestimonials(BuildContext context) {
    final isDesktop = context.isDesktop;
    const testimonials = [
      _Testimonial(name: 'Sarah Mitchell', role: 'Forex Trader', text: 'The courses completely changed how I approach the market. Earned back my investment in 2 weeks from referral commissions alone!', rating: 5),
      _Testimonial(name: 'Carlos Mendez', role: 'Crypto Investor', text: 'Best MLM platform I\'ve used. The binary system is transparent and payouts hit my USDT wallet within hours.', rating: 5),
      _Testimonial(name: 'Aisha Patel', role: 'Part-time Trader', text: 'Started with zero experience. After the beginner course, I was making consistent trades. The community is incredibly supportive.', rating: 5),
    ];
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('TESTIMONIALS'),
        const SizedBox(height: 10),
        Text('What Our Members Say',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 28),
        if (isDesktop)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: testimonials.mapIndexed((i, t) => [
                Expanded(child: _TestimonialCard(testimonial: t)),
                if (i < testimonials.length - 1) const SizedBox(width: 16),
              ]).expand((e) => e).toList(),
            ),
          )
        else
          Column(children: testimonials.map((t) => _TestimonialCard(testimonial: t)).toList()),
      ])),
    );
  }

  // ─── FAQ ──────────────────────────────────────────────────────────────────
  Widget _buildFAQ(BuildContext context) {
    final isDesktop = context.isDesktop;
    const faqs = [
      _FAQ('How do I get paid?', 'Earnings are credited to your in-app wallet. You can withdraw at any time to your personal crypto wallet (USDT, BTC, ETH, and more) with no minimum delay.'),
      _FAQ('Do I need trading experience?', 'No. Our courses start from absolute basics — technical analysis, chart reading, risk management — everything is taught step by step.'),
      _FAQ('How does the MLM commission work?', 'You earn a direct referral bonus when someone joins via your link, plus override commissions from multiple levels in your downline, and a binary matching bonus when left/right volumes align.'),
      _FAQ('Is there a joining fee?', 'You only pay for the course you want to take. There is no separate joining or membership fee. The course purchase activates your network position.'),
      _FAQ('What cryptocurrencies are supported?', 'We accept 100+ cryptocurrencies via NOWPayments, including USDT (TRC20/ERC20), BTC, ETH, BNB, MATIC, and more.'),
      _FAQ('Can I withdraw anytime?', 'Yes. Withdrawals are processed to your crypto wallet address with no lock-up period. Minimum withdrawal amount applies per currency.'),
    ];
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('FAQ'),
        const SizedBox(height: 10),
        Text('Frequently Asked Questions',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 28),
        if (isDesktop)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(children: faqs.sublist(0, 3).map((f) => _FAQTile(faq: f)).toList())),
            const SizedBox(width: 20),
            Expanded(child: Column(children: faqs.sublist(3).map((f) => _FAQTile(faq: f)).toList())),
          ])
        else
          Column(children: faqs.map((f) => _FAQTile(faq: f)).toList()),
      ])),
    );
  }

  // ─── CTA ──────────────────────────────────────────────────────────────────
  Widget _buildCTA(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Padding(
      padding: context.secPad,
      child: _constrained(Container(
        padding: EdgeInsets.all(isDesktop ? 52 : 28),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 40, spreadRadius: 4)],
        ),
        child: isDesktop
            ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Ready to Start Trading?', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                  SizedBox(height: 10),
                  Text('Join thousands of traders already earning on our platform.', style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
                ])),
                const SizedBox(width: 40),
                Row(children: [
                  GestureDetector(
                    onTap: () => context.go('/auth/register'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
                      child: const Text('Create Free Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => context.go('/auth/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                      decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(32)),
                      child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ]),
              ])
            : Column(children: [
                const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                const Text('Ready to Start Trading?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Join thousands of traders already earning on our platform. Create your free account today.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  GestureDetector(
                    onTap: () => context.go('/auth/register'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                      child: const Text('Create Free Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.go('/auth/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(30)),
                      child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                  ),
                ]),
              ]),
      )),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Container(
      margin: const EdgeInsets.only(top: 64),
      padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 36),
      color: const Color(0xFF060B14),
      child: _constrained(Column(children: [
        if (isDesktop)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 32, height: 32, decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                  child: const Text('TradeMaster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ]),
              const SizedBox(height: 14),
              const Text('The all-in-one platform for crypto trading education and referral income.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
            ])),
            const SizedBox(width: 40),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Platform', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 12),
              _footerLink('Sign Up', () => context.go('/auth/register')),
              _footerLink('Login', () => context.go('/auth/login')),
            ])),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Earn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 12),
              _footerLink('Commission Plan', () {}),
              _footerLink('MLM System', () {}),
              _footerLink('Crypto Payouts', () {}),
            ])),
          ])
        else
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 28, height: 28, decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 16)),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                child: const Text('TradeMaster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ]),
            const SizedBox(height: 12),
            const Text('The all-in-one platform for crypto trading education and referral income.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
          ]),
        const SizedBox(height: 24),
        const Divider(color: AppColors.border),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('© 2026 TradeMaster. All rights reserved.', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          Row(children: [
            GestureDetector(onTap: () => context.go('/auth/login'), child: const Text('Login', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            const Text('  ·  ', style: TextStyle(color: AppColors.border)),
            GestureDetector(onTap: () => context.go('/auth/register'), child: const Text('Register', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          ]),
        ]),
      ])),
    );
  }
}

// ─── Helper widgets / functions ───────────────────────────────────────────────
Widget _footerLink(String label, VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
  ),
);

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, {required this.onTap});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
  );
}

// ─── Data Classes ─────────────────────────────────────────────────────────────
class _HeroSlide {
  final String tag, headline, sub;
  const _HeroSlide({required this.tag, required this.headline, required this.sub});
}

class _Feature {
  final IconData icon;
  final String title, desc;
  final Color color;
  const _Feature({required this.icon, required this.title, required this.desc, required this.color});
}

class _Testimonial {
  final String name, role, text;
  final int rating;
  const _Testimonial({required this.name, required this.role, required this.text, required this.rating});
}

class _FAQ {
  final String q, a;
  const _FAQ(this.q, this.a);
}

// ─── Extension helper ─────────────────────────────────────────────────────────
extension _IndexedMap<T> on List<T> {
  Iterable<R> mapIndexed<R>(R Function(int i, T e) fn) =>
      asMap().entries.map((e) => fn(e.key, e.value));
}

// ─── Custom Painters ──────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final double progress;
  _GridPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withOpacity(0.04)..strokeWidth = 0.5;
    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += spacing) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    final scanPaint = Paint()..shader = LinearGradient(
      colors: [Colors.transparent, AppColors.primary.withOpacity(0.06), Colors.transparent],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, size.height * progress - 2, size.width, 4), scanPaint);
  }
  @override
  bool shouldRepaint(_GridPainter old) => old.progress != progress;
}

class _MiniChartPainter extends CustomPainter {
  final double progress;
  _MiniChartPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    const pts = [0.5, 0.4, 0.6, 0.35, 0.55, 0.3, 0.45, 0.25, 0.4, 0.2, 0.35, 0.15];
    final path = Path();
    final fill = Path();
    for (int i = 0; i < pts.length; i++) {
      final x = i / (pts.length - 1) * size.width;
      final y = (1 - pts[i]) * size.height * 0.8 + size.height * 0.1;
      if (i == 0) { path.moveTo(x, y); fill.moveTo(x, size.height); fill.lineTo(x, y); }
      else { path.lineTo(x, y); fill.lineTo(x, y); }
    }
    fill.lineTo(size.width, size.height); fill.close();
    canvas.drawPath(fill, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [AppColors.primary.withOpacity(0.2), Colors.transparent],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(path, Paint()..color = AppColors.primary..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    final idx = (progress * (pts.length - 1)).floor().clamp(0, pts.length - 2);
    final t = (progress * (pts.length - 1)) - idx;
    final cx = (idx + t) / (pts.length - 1) * size.width;
    final cy = (1 - (pts[idx] + (pts[idx + 1] - pts[idx]) * t)) * size.height * 0.8 + size.height * 0.1;
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = AppColors.primary);
    canvas.drawCircle(Offset(cx, cy), 9, Paint()..color = AppColors.primary.withOpacity(0.25));
  }
  @override
  bool shouldRepaint(_MiniChartPainter old) => old.progress != progress;
}

// ─── Small Widgets ────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: size * 0.6, spreadRadius: size * 0.1)]),
  );
}

class _FloatingCoin extends StatelessWidget {
  final IconData? icon;
  final String? symbol;
  final Color color;
  final double size;
  final Offset offset;
  const _FloatingCoin({this.icon, this.symbol, required this.color, required this.size, this.offset = Offset.zero});
  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: offset,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12), border: Border.all(color: color.withOpacity(0.3))),
      child: Center(child: icon != null
        ? Icon(icon, color: color, size: size * 0.5)
        : Text(symbol ?? '', style: TextStyle(color: color, fontSize: size * 0.25, fontWeight: FontWeight.w800))),
    ),
  );
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: AppColors.success, size: 14),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  ]);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  );
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    ShaderMask(
      shaderCallback: (b) => LinearGradient(colors: [color, color.withOpacity(0.7)]).createShader(b),
      child: Text(value, style: TextStyle(color: Colors.white, fontSize: context.isDesktop ? 26 : 20, fontWeight: FontWeight.w900)),
    ),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  ]);
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: AppColors.border);
}

class _HeroStatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _HeroStatBox({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ]),
  ));
}

class _StepCard extends StatelessWidget {
  final String step, title, desc;
  final IconData icon;
  final Color color;
  const _StepCard({required this.step, required this.title, required this.desc, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 12),
        Text(step, style: TextStyle(color: color.withOpacity(0.35), fontSize: 28, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 6),
      Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
    ]),
  );
}

class _PlaceholderCourseCard extends StatelessWidget {
  final int index;
  final bool isDesktop;
  const _PlaceholderCourseCard(this.index, {this.isDesktop = false});
  static const _names = ['Crypto Trading Masterclass', 'Technical Analysis Pro', 'DeFi & Yield Farming', 'Options & Futures'];
  static const _levels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
  static const _prices = ['\$199', '\$249', '\$299', '\$349'];
  static const _colors = [AppColors.primary, AppColors.secondary, AppColors.success, AppColors.warning];
  @override
  Widget build(BuildContext context) {
    final c = _colors[index % 4];
    return Container(
      width: isDesktop ? double.infinity : 200,
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: isDesktop ? 110 : 80,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.withOpacity(0.18), c.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.auto_graph_rounded, color: c, size: isDesktop ? 44 : 36),
        ),
        const SizedBox(height: 14),
        Text(_names[index % 4], style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: isDesktop ? 15 : 13), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
          child: Text(_levels[index % 4], style: TextStyle(color: c, fontSize: 11))),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_prices[index % 4], style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 16)),
          GestureDetector(
            onTap: () => context.go('/auth/register'),
            child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14)),
          ),
        ]),
      ]),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isDesktop;
  const _CourseCard({required this.course, this.isDesktop = false});
  @override
  Widget build(BuildContext context) {
    final price = (course['discountPrice'] ?? course['price'] ?? 0).toDouble();
    final level = course['level'] ?? 'Beginner';
    final levelColor = level == 'Beginner' ? AppColors.success : level == 'Intermediate' ? AppColors.primary : AppColors.secondary;
    return Container(
      width: isDesktop ? double.infinity : 200,
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: isDesktop ? 110 : 80,
          width: double.infinity,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: course['thumbnail'] != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(course['thumbnail'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 36)))
            : const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 12),
        Text(course['title'] ?? '', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: isDesktop ? 15 : 13), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: levelColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
          child: Text(level, style: TextStyle(color: levelColor, fontSize: 11))),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('\$${price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 16)),
          GestureDetector(
            onTap: () => context.go('/auth/register'),
            child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14)),
          ),
        ]),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final bool isDesktop;
  const _FeatureCard({required this.feature, this.isDesktop = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(isDesktop ? 24 : 18),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: feature.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
        child: Icon(feature.icon, color: feature.color, size: 24)),
      const SizedBox(height: 14),
      Text(feature.title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: isDesktop ? 15 : 14)),
      const SizedBox(height: 6),
      Text(feature.desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
    ]),
  );
}

class _CommissionRow extends StatelessWidget {
  final IconData icon;
  final String title, desc, badge;
  final Color color;
  const _CommissionRow({required this.icon, required this.title, required this.desc, required this.badge, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.dark.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(badge, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    ]),
  );
}

class _TestimonialCard extends StatelessWidget {
  final _Testimonial testimonial;
  const _TestimonialCard({required this.testimonial});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(testimonial.rating, (_) => const Icon(Icons.star_rounded, color: AppColors.warning, size: 16))),
      const SizedBox(height: 12),
      Text('"${testimonial.text}"', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic)),
      const SizedBox(height: 14),
      Row(children: [
        CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Text(testimonial.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(testimonial.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(testimonial.role, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
      ]),
    ]),
  );
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  const _FAQTile({required this.faq});
  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _open = !_open),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _open ? AppColors.primary.withOpacity(0.4) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.faq.q, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
          Icon(_open ? Icons.remove_rounded : Icons.add_rounded, color: AppColors.primary, size: 20),
        ]),
        if (_open) ...[
          const SizedBox(height: 10),
          Text(widget.faq.a, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
        ],
      ]),
    ),
  );
}
