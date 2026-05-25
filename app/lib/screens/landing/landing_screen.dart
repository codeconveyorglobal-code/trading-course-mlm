import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

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
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
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
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.dark.withOpacity(0.95),
            elevation: 0,
            title: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                child: const Text('TradeMaster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => context.go('/auth/login'),
                child: const Text('Login', style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.go('/auth/register'),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Get Started', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildStatsBar()),
          SliverToBoxAdapter(child: _buildHowItWorks()),
          SliverToBoxAdapter(child: _buildFeaturedCourses()),
          SliverToBoxAdapter(child: _buildWhyChooseUs()),
          SliverToBoxAdapter(child: _buildCommissionPlan()),
          SliverToBoxAdapter(child: _buildTestimonials()),
          SliverToBoxAdapter(child: _buildFAQ()),
          SliverToBoxAdapter(child: _buildCTA()),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  // ─── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    final slide = _heroSlides[_currentHeroSlide];
    return SizedBox(
      height: 580,
      child: Stack(
        children: [
          // Animated background grid
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 580),
              painter: _GridPainter(_particleCtrl.value),
            ),
          ),
          // Glowing orbs
          Positioned(top: -60, right: -80, child: _GlowOrb(size: 300, color: AppColors.primary.withOpacity(0.15))),
          Positioned(bottom: -40, left: -60, child: _GlowOrb(size: 250, color: AppColors.secondary.withOpacity(0.12))),
          Positioned(top: 100, right: 80, child: _GlowOrb(size: 120, color: AppColors.success.withOpacity(0.1))),
          // Floating crypto icons
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) {
              final v = _particleCtrl.value;
              return Stack(children: [
                Positioned(top: 120 + 12 * math.sin(v * 2 * math.pi), right: 40,
                  child: _FloatingCoin(icon: Icons.currency_bitcoin, color: AppColors.warning, size: 40)),
                Positioned(top: 200 + 10 * math.sin(v * 2 * math.pi + 1), right: 120,
                  child: _FloatingCoin(symbol: 'ETH', color: AppColors.secondary, size: 34)),
                Positioned(top: 320 + 8 * math.sin(v * 2 * math.pi + 2), right: 60,
                  child: _FloatingCoin(symbol: 'USDT', color: AppColors.success, size: 30)),
                Positioned(top: 80 + 14 * math.sin(v * 2 * math.pi + 0.5), left: 30,
                  child: _FloatingCoin(symbol: 'BNB', color: AppColors.warning, size: 28)),
              ]);
            },
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _heroFade,
              child: SlideTransition(
                position: _heroSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    // Slide indicator dots
                    Row(children: List.generate(_heroSlides.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _currentHeroSlide ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentHeroSlide ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ))),
                    const SizedBox(height: 20),
                    // Tag
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
                    const SizedBox(height: 16),
                    // Headline
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        key: ValueKey(slide.headline),
                        slide.headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        key: ValueKey(slide.sub),
                        slide.sub,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(children: [
                      GestureDetector(
                        onTap: () => context.go('/auth/register'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Get Started Free', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.go('/auth/login'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text('Sign In', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 40),
                    // Trust badges
                    Row(children: [
                      _TrustBadge(icon: Icons.verified_rounded, label: 'Certified Courses'),
                      const SizedBox(width: 16),
                      _TrustBadge(icon: Icons.lock_outline_rounded, label: 'Secure Crypto'),
                      const SizedBox(width: 16),
                      _TrustBadge(icon: Icons.people_outline_rounded, label: 'Active Community'),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    final users = _stats['totalUsers'] ?? 0;
    final courses = _stats['totalCourses'] ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _StatItem(value: _statsLoaded ? '${users}+' : '...', label: 'Students', color: AppColors.primary),
        _Divider(),
        _StatItem(value: _statsLoaded ? '$courses' : '...', label: 'Courses', color: AppColors.secondary),
        _Divider(),
        _StatItem(value: '\$500K+', label: 'Paid Out', color: AppColors.success),
        _Divider(),
        _StatItem(value: '98%', label: 'Satisfaction', color: AppColors.warning),
      ]),
    );
  }

  // ─── How It Works ──────────────────────────────────────────────────────────
  Widget _buildHowItWorks() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('HOW IT WORKS'),
          const SizedBox(height: 8),
          const Text('Start Earning in 3 Simple Steps', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('No experience needed. Learn, refer, and earn.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          _StepCard(step: '01', title: 'Create Your Account', desc: 'Sign up in minutes. Use a referral link from your sponsor to join the network and unlock commissions.', icon: Icons.person_add_rounded, color: AppColors.primary),
          const SizedBox(height: 14),
          _StepCard(step: '02', title: 'Enroll in a Course', desc: 'Choose from expert-led trading courses. Pay securely with crypto (USDT, BTC, ETH) and start learning immediately.', icon: Icons.school_rounded, color: AppColors.secondary),
          const SizedBox(height: 14),
          _StepCard(step: '03', title: 'Refer & Earn Commissions', desc: 'Share your referral link. Earn direct + binary commissions for every new member your network brings in.', icon: Icons.trending_up_rounded, color: AppColors.success),
        ],
      ),
    );
  }

  // ─── Featured Courses ──────────────────────────────────────────────────────
  Widget _buildFeaturedCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionLabel('COURSES'),
            const SizedBox(height: 8),
            const Text('Expert-Led Trading Courses', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Master the markets with structured, beginner-friendly content.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 24),
        if (_featuredCourses.isEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              itemBuilder: (_, i) => _PlaceholderCourseCard(i),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _featuredCourses.length,
              itemBuilder: (_, i) => _CourseCard(course: _featuredCourses[i]),
            ),
          ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => context.go('/auth/register'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('View All Courses', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 16),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Why Choose Us ─────────────────────────────────────────────────────────
  Widget _buildWhyChooseUs() {
    const features = [
      _Feature(icon: Icons.workspace_premium_rounded, title: 'Expert Mentors', desc: 'Learn from professional traders with years of market experience.', color: AppColors.warning),
      _Feature(icon: Icons.currency_bitcoin_rounded, title: 'Crypto Payments', desc: 'Pay & receive payouts in 100+ cryptocurrencies via NOWPayments.', color: AppColors.warning),
      _Feature(icon: Icons.account_tree_rounded, title: 'Binary MLM System', desc: 'Earn from both your left and right network legs with matching bonuses.', color: AppColors.primary),
      _Feature(icon: Icons.verified_user_rounded, title: 'Certified Courses', desc: 'Get completion certificates recognized by the trading community.', color: AppColors.primary),
      _Feature(icon: Icons.support_agent_rounded, title: '24/7 Support', desc: 'Our team is always available to help you succeed.', color: AppColors.secondary),
      _Feature(icon: Icons.lock_rounded, title: 'Secure Platform', desc: 'JWT-secured accounts, encrypted wallets, IPN-verified payments.', color: AppColors.secondary),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('WHY US'),
        const SizedBox(height: 8),
        const Text('Everything You Need to Succeed', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Built for traders, by traders. A complete ecosystem for growth.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: features.length,
          itemBuilder: (_, i) => _FeatureCard(feature: features[i]),
        ),
      ]),
    );
  }

  // ─── Commission Plan ───────────────────────────────────────────────────────
  Widget _buildCommissionPlan() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary.withOpacity(0.15), AppColors.primary.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('EARNINGS'),
        const SizedBox(height: 8),
        const Text('Commission Structure', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Multiple income streams from a single membership.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        _CommissionRow(icon: Icons.person_add_rounded, title: 'Direct Referral Bonus', desc: 'Earn % when someone joins using your link', badge: '10%', color: AppColors.success),
        const SizedBox(height: 12),
        _CommissionRow(icon: Icons.layers_rounded, title: 'Level Override Bonus', desc: 'Earn from multiple levels deep in your network', badge: 'Multi-Level', color: AppColors.primary),
        const SizedBox(height: 12),
        _CommissionRow(icon: Icons.compare_arrows_rounded, title: 'Binary Matching Bonus', desc: 'Earn when left & right legs match in volume', badge: '10%', color: AppColors.secondary),
        const SizedBox(height: 12),
        _CommissionRow(icon: Icons.star_rounded, title: 'Rank Advancement Bonus', desc: 'Hit targets to unlock Bronze → Diamond rewards', badge: 'Up to 5x', color: AppColors.warning),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => context.go('/auth/register'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Start Earning Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                SizedBox(width: 8),
                Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── Testimonials ──────────────────────────────────────────────────────────
  Widget _buildTestimonials() {
    const testimonials = [
      _Testimonial(name: 'Sarah Mitchell', role: 'Forex Trader', text: 'The courses completely changed how I approach the market. Earned back my investment in 2 weeks from referral commissions alone!', rating: 5),
      _Testimonial(name: 'Carlos Mendez', role: 'Crypto Investor', text: 'Best MLM platform I\'ve used. The binary system is transparent and payouts hit my USDT wallet within hours.', rating: 5),
      _Testimonial(name: 'Aisha Patel', role: 'Part-time Trader', text: 'Started with zero experience. After the beginner course, I was making consistent trades. The community is incredibly supportive.', rating: 5),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('TESTIMONIALS'),
        const SizedBox(height: 8),
        const Text('What Our Members Say', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        ...testimonials.map((t) => _TestimonialCard(testimonial: t)),
      ]),
    );
  }

  // ─── FAQ ───────────────────────────────────────────────────────────────────
  Widget _buildFAQ() {
    const faqs = [
      _FAQ('How do I get paid?', 'Earnings are credited to your in-app wallet. You can withdraw at any time to your personal crypto wallet (USDT, BTC, ETH, and more) with no minimum delay.'),
      _FAQ('Do I need trading experience?', 'No. Our courses start from absolute basics — technical analysis, chart reading, risk management — everything is taught step by step.'),
      _FAQ('How does the MLM commission work?', 'You earn a direct referral bonus when someone joins via your link, plus override commissions from multiple levels in your downline, and a binary matching bonus when left/right volumes align.'),
      _FAQ('Is there a joining fee?', 'You only pay for the course you want to take. There is no separate joining or membership fee. The course purchase activates your network position.'),
      _FAQ('What cryptocurrencies are supported?', 'We accept 100+ cryptocurrencies via NOWPayments, including USDT (TRC20/ERC20), BTC, ETH, BNB, MATIC, and more.'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('FAQ'),
        const SizedBox(height: 8),
        const Text('Frequently Asked Questions', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        ...faqs.map((f) => _FAQTile(faq: f)),
      ]),
    );
  }

  // ─── CTA ───────────────────────────────────────────────────────────────────
  Widget _buildCTA() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30, spreadRadius: 2)],
      ),
      child: Column(children: [
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
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF060B14),
      child: Column(children: [
        Row(children: [
          Container(width: 28, height: 28, decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle), child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 16)),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
            child: const Text('TradeMaster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 12),
        const Text('The all-in-one platform for crypto trading education and referral income.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
        const SizedBox(height: 20),
        const Divider(color: AppColors.border),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('© 2026 TradeMaster. All rights reserved.', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          Row(children: [
            GestureDetector(onTap: () => context.go('/auth/login'), child: const Text('Login', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            const Text('  ·  ', style: TextStyle(color: AppColors.border)),
            GestureDetector(onTap: () => context.go('/auth/register'), child: const Text('Register', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          ]),
        ]),
      ]),
    );
  }
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

// ─── Custom Painter ───────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final double progress;
  _GridPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Animated scan line
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, AppColors.primary.withOpacity(0.06), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final scanY = size.height * progress;
    canvas.drawRect(Rect.fromLTWH(0, scanY - 2, size.width, 4), scanPaint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.progress != progress;
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
  const _FloatingCoin({this.icon, this.symbol, required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(0.12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Center(child: icon != null
      ? Icon(icon, color: color, size: size * 0.5)
      : Text(symbol ?? '', style: TextStyle(color: color, fontSize: size * 0.25, fontWeight: FontWeight.w800)),
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
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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
      child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
    ),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
  ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 32, color: AppColors.border);
}

class _StepCard extends StatelessWidget {
  final String step, title, desc;
  final IconData icon;
  final Color color;
  const _StepCard({required this.step, required this.title, required this.desc, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(step, style: TextStyle(color: color.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15))),
        ]),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
      ])),
    ]),
  );
}

class _PlaceholderCourseCard extends StatelessWidget {
  final int index;
  const _PlaceholderCourseCard(this.index);
  static const _names = ['Crypto Trading Masterclass', 'Technical Analysis Pro', 'DeFi & Yield Farming', 'Options & Futures'];
  static const _levels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
  static const _prices = ['\$199', '\$249', '\$299', '\$349'];
  static const _colors = [AppColors.primary, AppColors.secondary, AppColors.success, AppColors.warning];
  @override
  Widget build(BuildContext context) => Container(
    width: 200,
    margin: const EdgeInsets.only(right: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 80, width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_colors[index % 4].withOpacity(0.2), _colors[index % 4].withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.auto_graph_rounded, color: _colors[index % 4], size: 36),
      ),
      const SizedBox(height: 12),
      Text(_names[index % 4], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _colors[index % 4].withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(_levels[index % 4], style: TextStyle(color: _colors[index % 4], fontSize: 10))),
      const Spacer(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(_prices[index % 4], style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 16)),
        GestureDetector(
          onTap: () => context.go('/auth/register'),
          child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14)),
        ),
      ]),
    ]),
  );
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseCard({required this.course});
  @override
  Widget build(BuildContext context) {
    final price = (course['discountPrice'] ?? course['price'] ?? 0).toDouble();
    final level = course['level'] ?? 'Beginner';
    Color levelColor = level == 'Beginner' ? AppColors.success : level == 'Intermediate' ? AppColors.primary : AppColors.secondary;
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 80, width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: course['thumbnail'] != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(course['thumbnail'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 36)))
            : const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 12),
        Text(course['title'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: levelColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(level, style: TextStyle(color: levelColor, fontSize: 10))),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('\$${price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 16)),
          GestureDetector(
            onTap: () => context.go('/auth/register'),
            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14)),
          ),
        ]),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: feature.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(feature.icon, color: feature.color, size: 22),
      ),
      const SizedBox(height: 14),
      Text(feature.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
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
  Widget build(BuildContext context) => Row(children: [
    Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ])),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(badge, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    ),
  ]);
}

class _TestimonialCard extends StatelessWidget {
  final _Testimonial testimonial;
  const _TestimonialCard({required this.testimonial});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(testimonial.rating, (_) => const Icon(Icons.star_rounded, color: AppColors.warning, size: 16))),
      const SizedBox(height: 10),
      Text('"${testimonial.text}"', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic)),
      const SizedBox(height: 12),
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
