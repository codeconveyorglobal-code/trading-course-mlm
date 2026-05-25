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
  EdgeInsets get secPad => EdgeInsets.fromLTRB(hPad, 72, hPad, 0);
}

Widget _constrained(Widget child, {double max = _kMaxWidth}) =>
    Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: max), child: child));

extension _IndexedMap<T> on List<T> {
  Iterable<R> mapIndexed<R>(R Function(int i, T e) fn) =>
      asMap().entries.map((e) => fn(e.key, e.value));
}

// ─── Live ticker data ─────────────────────────────────────────────────────────
const _kTickers = [
  _TickerItem('BTC/USDT', '67,482.50', '+2.34%', true),
  _TickerItem('ETH/USDT', '3,847.20', '+1.87%', true),
  _TickerItem('BNB/USDT', '612.40', '-0.42%', false),
  _TickerItem('SOL/USDT', '189.75', '+4.12%', true),
  _TickerItem('XRP/USDT', '0.8234', '+1.23%', true),
  _TickerItem('ADA/USDT', '0.6127', '-1.05%', false),
  _TickerItem('AVAX/USDT', '42.18', '+3.67%', true),
  _TickerItem('DOT/USDT', '9.87', '+0.94%', true),
  _TickerItem('MATIC/USDT', '1.1240', '-0.78%', false),
  _TickerItem('LINK/USDT', '18.92', '+2.56%', true),
  _TickerItem('DOGE/USDT', '0.1842', '+5.21%', true),
  _TickerItem('LTC/USDT', '89.34', '-1.32%', false),
];

class _TickerItem {
  final String symbol, price, change;
  final bool up;
  const _TickerItem(this.symbol, this.price, this.change, this.up);
}

// ─── Candle data ──────────────────────────────────────────────────────────────
class _Candle {
  final double open, high, low, close;
  const _Candle(this.open, this.high, this.low, this.close);
  bool get bullish => close >= open;
}

// ─── Order book entry ─────────────────────────────────────────────────────────
class _OrderEntry {
  final double price, qty, depth;
  final bool isBid;
  const _OrderEntry(this.price, this.qty, this.depth, this.isBid);
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _bgCtrl;       // particle network + slow pulse
  late AnimationController _heroCtrl;     // hero fade-in
  late AnimationController _candleCtrl;   // candlestick animation
  late AnimationController _tickerCtrl;   // ticker tape scroll
  late AnimationController _pulseCtrl;    // BUY/SELL signal pulse
  late AnimationController _typeCtrl;     // typewriter

  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  // Data
  List _featuredCourses = [];
  Map<String, dynamic> _stats = {};
  bool _statsLoaded = false;
  final _scrollCtrl = ScrollController();

  // Typewriter
  int _typeIndex = 0;
  bool _typeCursorVisible = true;
  String _typedDisplay = '';
  Timer? _typeTimer;
  Timer? _cursorTimer;
  static const _headlines = [
    'Master Crypto Trading',
    'Build Passive Income',
    'Trade. Refer. Earn.',
    'Join 10,000+ Traders',
  ];

  // Order book simulation
  late List<_OrderEntry> _orderBook;
  Timer? _obTimer;

  // Candle data
  late List<_Candle> _candles;
  double _livePrice = 67482.50;

  // Slide
  int _slide = 0;
  Timer? _slideTimer;

  @override
  void initState() {
    super.initState();
    _candles = _genCandles();
    _orderBook = _genOrderBook();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _candleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _tickerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _typeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));

    _heroCtrl.forward();

    // Typewriter
    _startTypewriter();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _typeCursorVisible = !_typeCursorVisible);
    });

    // Order book refresh
    _obTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) setState(() {
        _orderBook = _genOrderBook();
        _livePrice += (math.Random().nextDouble() - 0.48) * 18;
      });
    });

    // Slide
    _slideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _slide = (_slide + 1) % 3);
    });

    // Candle update every 3s
    Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _candles = _genCandles());
    });

    _loadData();
  }

  void _startTypewriter() {
    int charIdx = 0;
    final target = _headlines[_typeIndex];
    _typedDisplay = '';
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      if (!mounted) { t.cancel(); return; }
      if (charIdx < target.length) {
        charIdx++;
        setState(() => _typedDisplay = target.substring(0, charIdx));
      } else {
        t.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            _typeIndex = (_typeIndex + 1) % _headlines.length;
            _typedDisplay = '';
          });
          _startTypewriter();
        });
      }
    });
  }

  List<_Candle> _genCandles() {
    final rng = math.Random();
    double price = 67000;
    return List.generate(28, (_) {
      final o = price;
      final move = (rng.nextDouble() - 0.46) * 400;
      final c = (o + move).clamp(60000.0, 75000.0);
      final h = math.max(o, c) + rng.nextDouble() * 200;
      final l = math.min(o, c) - rng.nextDouble() * 200;
      price = c;
      return _Candle(o, h, l, c);
    });
  }

  List<_OrderEntry> _genOrderBook() {
    final rng = math.Random();
    final mid = _livePrice;
    final asks = List.generate(6, (i) {
      final p = mid + (i + 1) * 12 + rng.nextDouble() * 8;
      final q = 0.05 + rng.nextDouble() * 2.5;
      return _OrderEntry(p, q, (6 - i) / 6.0, false);
    });
    final bids = List.generate(6, (i) {
      final p = mid - (i + 1) * 12 - rng.nextDouble() * 8;
      final q = 0.05 + rng.nextDouble() * 2.5;
      return _OrderEntry(p, q, (6 - i) / 6.0, true);
    });
    return [...asks.reversed, ...bids];
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
    _bgCtrl.dispose();
    _heroCtrl.dispose();
    _candleCtrl.dispose();
    _tickerCtrl.dispose();
    _pulseCtrl.dispose();
    _typeCtrl.dispose();
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    _obTimer?.cancel();
    _slideTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // Ticker tape — always visible above app bar
          SliverToBoxAdapter(child: _buildTickerTape()),
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverToBoxAdapter(child: _buildStatsBar(context)),
          SliverToBoxAdapter(child: _buildTradingSignals(context)),
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

  // ─── Ticker Tape ─────────────────────────────────────────────────────────
  Widget _buildTickerTape() {
    return Container(
      height: 36,
      color: const Color(0xFF060B14),
      child: AnimatedBuilder(
        animation: _tickerCtrl,
        builder: (_, __) {
          return ClipRect(
            child: OverflowBox(
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: Offset(-_tickerCtrl.value * 1200, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._buildTickerItems(),
                    ..._buildTickerItems(), // repeat for seamless loop
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildTickerItems() => _kTickers.map((t) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(
        color: t.up ? AppColors.success : AppColors.danger,
        shape: BoxShape.circle,
      )),
      const SizedBox(width: 6),
      Text(t.symbol, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(width: 8),
      Text(t.price, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
      const SizedBox(width: 6),
      Text(t.change, style: TextStyle(color: t.up ? AppColors.success : AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(width: 20),
      Container(width: 1, height: 14, color: AppColors.border),
    ]),
  )).toList();

  // ─── AppBar ───────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context) {
    final isDesktop = context.isDesktop;
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.dark.withOpacity(0.96),
      elevation: 0,
      toolbarHeight: isDesktop ? 64 : 56,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border.withOpacity(0.5)),
      ),
      title: _constrained(Row(children: [
        // Logo
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
          child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
          child: Text('TradeMaster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: isDesktop ? 20 : 18, letterSpacing: -0.5)),
        ),
        // Live dot
        const SizedBox(width: 8),
        _LiveDot(),
        const Spacer(),
        if (isDesktop) ...[
          _NavLink('Markets', onTap: () {}),
          _NavLink('Courses', onTap: () {}),
          _NavLink('Earn', onTap: () {}),
          _NavLink('FAQ', onTap: () {}),
          const SizedBox(width: 16),
        ],
        TextButton(
          onPressed: () => context.go('/auth/login'),
          child: const Text('Login', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.go('/auth/register'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)]),
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
    final h = isDesktop ? 640.0 : 620.0;

    return SizedBox(
      height: h,
      child: Stack(children: [
        // Particle network background
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => CustomPaint(
            size: Size(double.infinity, h),
            painter: _ParticleNetworkPainter(_bgCtrl.value),
          ),
        ),
        // Glow orbs
        Positioned(top: -60, right: -60,
          child: _GlowOrb(size: 420, color: AppColors.primary.withOpacity(0.09))),
        Positioned(bottom: -80, left: -80,
          child: _GlowOrb(size: 360, color: AppColors.secondary.withOpacity(0.08))),
        Positioned(top: 100, left: isDesktop ? 600 : 200,
          child: _GlowOrb(size: 150, color: AppColors.success.withOpacity(0.06))),

        // Content
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.hPad),
          child: _constrained(
            isDesktop ? _buildHeroDesktop() : _buildHeroMobile(),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeroDesktop() {
    return FadeTransition(
      opacity: _heroFade,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(flex: 52, child: SlideTransition(position: _heroSlide, child: _buildHeroText(isDesktop: true))),
        const SizedBox(width: 48),
        Expanded(flex: 48, child: _buildHeroPanel()),
      ]),
    );
  }

  Widget _buildHeroMobile() {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(position: _heroSlide, child: _buildHeroText(isDesktop: false)),
    );
  }

  Widget _buildHeroText({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isDesktop ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        SizedBox(height: isDesktop ? 0 : 40),
        // Status badge
        _StatusBadge(),
        SizedBox(height: isDesktop ? 22 : 18),
        // Typewriter headline
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: _typedDisplay,
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 54 : 34,
                fontWeight: FontWeight.w900,
                height: 1.08,
                letterSpacing: -1.5,
              ),
            ),
            TextSpan(
              text: _typeCursorVisible ? '|' : ' ',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: isDesktop ? 54 : 34,
                fontWeight: FontWeight.w300,
              ),
            ),
          ]),
        ),
        SizedBox(height: isDesktop ? 8 : 6),
        // Gradient accent word
        ShaderMask(
          shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
          child: Text(
            'With AI-Powered Education',
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 54 : 34,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: -1.5,
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 22 : 18),
        Text(
          'Learn from top crypto traders. Earn multi-level referral commissions. Get paid instantly in crypto.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: isDesktop ? 16 : 14, height: 1.75),
        ),
        SizedBox(height: isDesktop ? 36 : 28),
        // CTA buttons
        Wrap(spacing: 12, runSpacing: 12, children: [
          GestureDetector(
            onTap: () => context.go('/auth/register'),
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Container(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 24, vertical: isDesktop ? 16 : 14),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withOpacity(0.25 + _pulseCtrl.value * 0.2),
                    blurRadius: 20 + _pulseCtrl.value * 16,
                    spreadRadius: 1 + _pulseCtrl.value * 3,
                  )],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('Start Trading Free', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: isDesktop ? 16 : 15)),
                ]),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/auth/login'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 20, vertical: isDesktop ? 15 : 13),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(34),
                color: AppColors.card.withOpacity(0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.login_rounded, color: AppColors.textSecondary, size: 15),
                const SizedBox(width: 7),
                Text('Sign In', style: TextStyle(color: AppColors.textSecondary, fontSize: isDesktop ? 15 : 14)),
              ]),
            ),
          ),
        ]),
        SizedBox(height: isDesktop ? 36 : 28),
        // Trust row
        Wrap(spacing: 18, runSpacing: 8, children: const [
          _TrustBadge(icon: Icons.verified_rounded, label: 'Certified Courses', color: AppColors.primary),
          _TrustBadge(icon: Icons.shield_rounded, label: 'Crypto-Native', color: AppColors.success),
          _TrustBadge(icon: Icons.groups_rounded, label: '10,000+ Traders', color: AppColors.warning),
        ]),
      ],
    );
  }

  // ─── Hero Trading Panel ───────────────────────────────────────────────────
  Widget _buildHeroPanel() {
    return Column(children: [
      // Candlestick chart card
      _buildCandleCard(),
      const SizedBox(height: 12),
      // Order book + signal row
      Row(children: [
        Expanded(child: _buildOrderBook()),
        const SizedBox(width: 12),
        Expanded(child: _buildSignalPanel()),
      ]),
    ]);
  }

  Widget _buildCandleCard() {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 24)],
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            const Icon(Icons.currency_bitcoin, color: AppColors.warning, size: 16),
            const SizedBox(width: 6),
            const Text('BTC/USDT', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Text(
                '\$${_livePrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Color.lerp(AppColors.success, const Color(0xFF00FF9F), _pulseCtrl.value)!,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('+2.34%', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        // Candlestick chart
        Expanded(
          child: AnimatedBuilder(
            animation: _candleCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _CandlestickPainter(_candles, _candleCtrl.value),
            ),
          ),
        ),
        // Volume bar hint
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(children: [
            const Text('VOL', style: TextStyle(color: AppColors.textHint, fontSize: 10)),
            const SizedBox(width: 6),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: 0.72,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 3,
              ),
            )),
            const SizedBox(width: 8),
            const Text('1D', style: TextStyle(color: AppColors.textHint, fontSize: 10)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildOrderBook() {
    final asks = _orderBook.where((e) => !e.isBid).take(4).toList();
    final bids = _orderBook.where((e) => e.isBid).take(4).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.menu_book_rounded, color: AppColors.textSecondary, size: 12),
          SizedBox(width: 5),
          Text('ORDER BOOK', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        // Asks
        ...asks.map((e) => _buildOBRow(e)),
        // Spread
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            const Expanded(child: Divider(color: AppColors.border, height: 1)),
            const SizedBox(width: 6),
            Text('\$${_livePrice.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            const Expanded(child: Divider(color: AppColors.border, height: 1)),
          ]),
        ),
        // Bids
        ...bids.map((e) => _buildOBRow(e)),
      ]),
    );
  }

  Widget _buildOBRow(_OrderEntry e) {
    final color = e.isBid ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(children: [
        Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: e.depth * 0.85,
            child: Container(height: 16, color: color.withOpacity(0.07)),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(e.price.toStringAsFixed(1), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
          Text(e.qty.toStringAsFixed(3), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
        ]),
      ]),
    );
  }

  Widget _buildSignalPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.bolt_rounded, color: AppColors.warning, size: 12),
          SizedBox(width: 5),
          Text('SIGNALS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        _SignalRow(pair: 'BTC', action: 'BUY', confidence: 87, pulseCtrl: _pulseCtrl),
        const SizedBox(height: 6),
        _SignalRow(pair: 'ETH', action: 'BUY', confidence: 74, pulseCtrl: _pulseCtrl),
        const SizedBox(height: 6),
        _SignalRow(pair: 'BNB', action: 'SELL', confidence: 68, pulseCtrl: _pulseCtrl, sell: true),
        const SizedBox(height: 6),
        _SignalRow(pair: 'SOL', action: 'BUY', confidence: 91, pulseCtrl: _pulseCtrl),
        const Spacer(),
        // RSI gauge
        const Text('RSI', style: TextStyle(color: AppColors.textHint, fontSize: 10)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: 0.63,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.warning),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 3),
        const Text('63 — Bullish Momentum', style: TextStyle(color: AppColors.textHint, fontSize: 9)),
      ]),
    );
  }

  // ─── Stats Bar ────────────────────────────────────────────────────────────
  Widget _buildStatsBar(BuildContext context) {
    final users = _stats['totalUsers'] ?? 0;
    final courses = _stats['totalCourses'] ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hPad, 24, context.hPad, 0),
      child: _constrained(Container(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: context.isDesktop ? 48 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.card, const Color(0xFF0D1526)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 30)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatItem(value: _statsLoaded ? '${users}+' : '12K+', label: 'Active Traders', icon: Icons.people_rounded, color: AppColors.primary),
          _StatDivider(),
          _StatItem(value: _statsLoaded ? '$courses' : '24+', label: 'Expert Courses', icon: Icons.school_rounded, color: AppColors.secondary),
          _StatDivider(),
          _StatItem(value: '\$2.1M+', label: 'Commissions Paid', icon: Icons.account_balance_wallet_rounded, color: AppColors.success),
          _StatDivider(),
          _StatItem(value: '98.4%', label: 'Satisfaction Rate', icon: Icons.star_rounded, color: AppColors.warning),
        ]),
      )),
    );
  }

  // ─── Trading Signals Section ──────────────────────────────────────────────
  Widget _buildTradingSignals(BuildContext context) {
    final isDesktop = context.isDesktop;
    const signals = [
      (pair: 'BTC/USDT', tf: '4H', action: 'STRONG BUY', conf: 0.91, pattern: 'Golden Cross + RSI 68', color: AppColors.success),
      (pair: 'ETH/USDT', tf: '1D', action: 'BUY', conf: 0.78, pattern: 'MACD Crossover', color: AppColors.primary),
      (pair: 'SOL/USDT', tf: '1H', action: 'STRONG BUY', conf: 0.85, pattern: 'Breakout + Volume', color: AppColors.success),
      (pair: 'BNB/USDT', tf: '4H', action: 'SELL', conf: 0.62, pattern: 'Death Cross', color: AppColors.danger),
    ];
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _SectionLabel('LIVE SIGNALS'),
          const SizedBox(width: 10),
          _LiveDot(),
          const SizedBox(width: 6),
          const Text('Updated every 15s', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        Text('AI-Powered Market Signals',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Our algorithms scan 200+ indicators in real-time to surface high-probability setups.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        if (isDesktop)
          Row(children: signals.mapIndexed((i, s) => [
            Expanded(child: _SignalCard(pair: s.pair, tf: s.tf, action: s.action, conf: s.conf, pattern: s.pattern, color: s.color, pulseCtrl: _pulseCtrl)),
            if (i < signals.length - 1) const SizedBox(width: 14),
          ]).expand((e) => e).toList())
        else
          SizedBox(
            height: 165,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: signals.length,
              itemBuilder: (_, i) {
                final s = signals[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 180,
                    child: _SignalCard(pair: s.pair, tf: s.tf, action: s.action, conf: s.conf, pattern: s.pattern, color: s.color, pulseCtrl: _pulseCtrl),
                  ),
                );
              },
            ),
          ),
      ])),
    );
  }

  // ─── How It Works ─────────────────────────────────────────────────────────
  Widget _buildHowItWorks(BuildContext context) {
    final isDesktop = context.isDesktop;
    const steps = [
      (num: '01', title: 'Create Your Account', desc: 'Sign up with referral link. Your position in the binary network activates instantly.', icon: Icons.fingerprint_rounded, color: AppColors.primary),
      (num: '02', title: 'Pick a Trading Course', desc: 'Pay in crypto. Unlock beginner to advanced strategies, technical analysis, and DeFi.', icon: Icons.auto_graph_rounded, color: AppColors.secondary),
      (num: '03', title: 'Refer & Stack Commissions', desc: 'Share your link. Earn direct bonuses + binary matching + level overrides in real-time.', icon: Icons.account_tree_rounded, color: AppColors.success),
    ];
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('HOW IT WORKS'),
        const SizedBox(height: 10),
        Text('3 Steps to Financial Freedom',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 28),
        if (isDesktop)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ...steps.mapIndexed((i, s) => [
                Expanded(child: _StepCard(num: s.num, title: s.title, desc: s.desc, icon: s.icon, color: s.color)),
                if (i < steps.length - 1) ...[
                  const SizedBox(width: 8),
                  Padding(padding: const EdgeInsets.only(top: 40),
                    child: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.border, size: 16)),
                  const SizedBox(width: 8),
                ],
              ]).expand((e) => e),
            ]),
          )
        else
          Column(children: steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _StepCard(num: s.num, title: s.title, desc: s.desc, icon: s.icon, color: s.color),
          )).toList()),
      ])),
    );
  }

  // ─── Featured Courses ─────────────────────────────────────────────────────
  Widget _buildFeaturedCourses(BuildContext context) {
    final isDesktop = context.isDesktop;
    final count = _featuredCourses.isEmpty ? 6 : math.min(_featuredCourses.length, 6);
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('COURSES'),
        const SizedBox(height: 10),
        Text('Battle-Tested Trading Courses',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('From raw beginner to institutional-grade strategy. Every skill level covered.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        if (isDesktop)
          LayoutBuilder(builder: (_, c) {
            final cols = c.maxWidth > 780 ? 3 : 2;
            final w = (c.maxWidth - (cols - 1) * 16) / cols;
            return Wrap(spacing: 16, runSpacing: 16, children: List.generate(count, (i) => SizedBox(
              width: w,
              child: _featuredCourses.isEmpty
                  ? _PlaceholderCourseCard(i, isDesktop: true)
                  : _CourseCard(course: _featuredCourses[i], isDesktop: true),
            )));
          })
        else
          SizedBox(
            height: 230,
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(30),
              color: AppColors.primary.withOpacity(0.05),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Explore All Courses', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
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
      _Feature(icon: Icons.candlestick_chart_rounded, title: 'Pro-Grade Charts', desc: 'Interactive TradingView-style charts with 50+ indicators, drawing tools, and multi-timeframe analysis.', color: AppColors.primary),
      _Feature(icon: Icons.currency_bitcoin_rounded, title: 'Crypto-Native Payments', desc: 'Pay in USDT, BTC, ETH and 100+ coins via NOWPayments. Instant on-chain confirmation.', color: AppColors.warning),
      _Feature(icon: Icons.account_tree_rounded, title: 'Binary MLM Engine', desc: 'Dual-leg network with matching bonus, override commissions, and rank-based multipliers.', color: AppColors.secondary),
      _Feature(icon: Icons.bolt_rounded, title: 'Real-Time Signals', desc: 'AI-scanned alerts across 200+ indicators. Never miss a high-probability setup again.', color: AppColors.warning),
      _Feature(icon: Icons.verified_user_rounded, title: 'Institutional-Grade Security', desc: 'JWT auth, end-to-end encrypted wallets, IPN-verified payments, 2FA support.', color: AppColors.success),
      _Feature(icon: Icons.workspace_premium_rounded, title: 'Certified by Traders', desc: 'Industry-recognized completion certificates. Add credibility to your trading profile.', color: AppColors.primary),
    ];
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('PLATFORM'),
        const SizedBox(height: 10),
        Text('Built for Serious Traders',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isDesktop ? 1.1 : 0.88,
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
    const rows = [
      (icon: Icons.person_add_rounded, title: 'Direct Referral', value: '10%', desc: 'Instant when your referral buys a course', color: AppColors.success),
      (icon: Icons.layers_rounded, title: 'Level Overrides', value: '2–5%', desc: 'Levels 1–4 of your entire downline', color: AppColors.primary),
      (icon: Icons.compare_arrows_rounded, title: 'Binary Match', value: '10%', desc: 'Weaker leg CV matching each cycle', color: AppColors.secondary),
      (icon: Icons.military_tech_rounded, title: 'Rank Bonuses', value: 'Up to 5×', desc: 'Bronze → Silver → Gold → Diamond', color: AppColors.warning),
    ];
    final ctaBtn = GestureDetector(
      onTap: () => context.go('/auth/register'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 20)],
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Activate My Commission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
      ),
    );
    final left = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('EARN'),
      const SizedBox(height: 10),
      Text('Multiple Income Streams',
        style: TextStyle(color: Colors.white, fontSize: isDesktop ? 34 : 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      const Text('Every referral you make stacks across 4 commission types — simultaneously.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.65)),
      if (isDesktop) ...[const SizedBox(height: 28), ctaBtn],
    ]);
    final right = Column(children: [
      ...rows.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _CommissionRow(icon: r.icon, title: r.title, value: r.value, desc: r.desc, color: r.color),
      )),
      if (!isDesktop) ...[const SizedBox(height: 8), ctaBtn],
    ]);
    return Padding(
      padding: context.secPad,
      child: _constrained(Container(
        padding: EdgeInsets.all(isDesktop ? 44 : 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.secondary.withOpacity(0.12), const Color(0xFF060B14), AppColors.primary.withOpacity(0.06)],
          ),
        ),
        child: isDesktop
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 4, child: left),
                const SizedBox(width: 52),
                Expanded(flex: 5, child: right),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 24), right]),
      )),
    );
  }

  // ─── Testimonials ─────────────────────────────────────────────────────────
  Widget _buildTestimonials(BuildContext context) {
    final isDesktop = context.isDesktop;
    const tms = [
      _Testimonial('Sarah Mitchell', 'Forex Trader • \$4.2K earned', 'The courses re-wired how I think about the market. The RSI + MACD combo strategy alone paid back my investment in week one.', 5),
      _Testimonial('Carlos Mendez', 'Crypto Investor • \$8.7K earned', 'Cleanest MLM structure I\'ve seen. Payouts hit my USDT wallet in minutes. The binary matching bonus is extremely generous.', 5),
      _Testimonial('Aisha Patel', 'Part-time Trader • \$2.9K earned', 'Zero experience when I joined. After the Beginner course, I was placing real trades with confidence. The community is fire.', 5),
    ];
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('TRADERS SPEAK'),
        const SizedBox(height: 10),
        Text('Real Results. Real People.',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 28),
        if (isDesktop)
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tms.mapIndexed((i, t) => [
              Expanded(child: _TestimonialCard(testimonial: t)),
              if (i < tms.length - 1) const SizedBox(width: 16),
            ]).expand((e) => e).toList()))
        else
          Column(children: tms.map((t) => _TestimonialCard(testimonial: t)).toList()),
      ])),
    );
  }

  // ─── FAQ ──────────────────────────────────────────────────────────────────
  Widget _buildFAQ(BuildContext context) {
    final isDesktop = context.isDesktop;
    const faqs = [
      _FAQ('How do commissions get paid?', 'Earned commissions are credited to your in-app crypto wallet in real-time. Withdraw anytime to BTC, ETH, USDT, BNB and 100+ chains.'),
      _FAQ('Do I need trading experience?', 'None. Our beginner track covers charts, indicators, risk management and crypto fundamentals from scratch — step by step.'),
      _FAQ('How does binary MLM work?', 'Your network splits into two legs. You earn a matching bonus when both legs generate equal volume. Plus direct referral (10%) and level overrides (2–5%).'),
      _FAQ('Is there a monthly fee?', 'No subscriptions. One-time course purchase activates your full MLM position. No hidden fees, no recurring charges.'),
      _FAQ('What coins can I use?', 'USDT (TRC20/ERC20), BTC, ETH, BNB, SOL, MATIC, AVAX and 100+ currencies powered by NOWPayments.'),
      _FAQ('How fast are withdrawals?', 'Near-instant. Crypto withdrawals are processed on-chain and typically confirm within minutes. No lockup period.'),
    ];
    return Padding(
      padding: context.secPad,
      child: _constrained(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('FAQ'),
        const SizedBox(height: 10),
        Text('Got Questions? We\'ve Got Answers.',
          style: TextStyle(color: Colors.white, fontSize: isDesktop ? 36 : 24, fontWeight: FontWeight.w900)),
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
      child: _constrained(AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          padding: EdgeInsets.all(isDesktop ? 56 : 32),
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.2 + _pulseCtrl.value * 0.1), blurRadius: 50, spreadRadius: 4),
              BoxShadow(color: AppColors.secondary.withOpacity(0.1), blurRadius: 80, spreadRadius: -10),
            ],
          ),
          child: isDesktop
              ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('The Market Doesn\'t Wait.', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1)),
                    SizedBox(height: 10),
                    Text('Start learning, start earning — your first referral commission could arrive today.', style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.55)),
                  ])),
                  const SizedBox(width: 48),
                  Row(children: [
                    GestureDetector(
                      onTap: () => context.go('/auth/register'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(34)),
                        child: const Text('Create Free Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => context.go('/auth/login'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                        decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(34)),
                        child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 15)),
                      ),
                    ),
                  ]),
                ])
              : Column(children: [
                  const Icon(Icons.show_chart_rounded, color: Colors.white, size: 44),
                  const SizedBox(height: 16),
                  const Text('The Market Doesn\'t Wait.', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text('Start learning, start earning — your first commission could arrive today.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.55), textAlign: TextAlign.center),
                  const SizedBox(height: 26),
                  GestureDetector(
                    onTap: () => context.go('/auth/register'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                      child: const Text('Create Free Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 15), textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => context.go('/auth/login'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(30)),
                      child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.center),
                    ),
                  ),
                ]),
        ),
      )),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Container(
      margin: const EdgeInsets.only(top: 72),
      padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 40),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: Color(0xFF060B14),
      ),
      child: _constrained(Column(children: [
        if (isDesktop)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _logoWidget(18),
              const SizedBox(height: 14),
              const Text('The all-in-one platform for crypto trading education, AI-powered signals, and multi-level referral income.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.65)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: [
                _ChainBadge('BTC'), _ChainBadge('ETH'), _ChainBadge('USDT'), _ChainBadge('BNB'),
              ]),
            ])),
            const SizedBox(width: 40),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Platform', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 14),
              _footerLink('Get Started', () => context.go('/auth/register')),
              _footerLink('Sign In', () => context.go('/auth/login')),
              _footerLink('Trading Courses', () {}),
            ])),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Earn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 14),
              _footerLink('Commission Plan', () {}),
              _footerLink('Binary MLM', () {}),
              _footerLink('Crypto Payouts', () {}),
              _footerLink('Rank Rewards', () {}),
            ])),
          ])
        else
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _logoWidget(16),
            const SizedBox(height: 10),
            const Text('Crypto trading education + multi-level referral income.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
          ]),
        const SizedBox(height: 28),
        const Divider(color: AppColors.border),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('© 2026 TradeMaster Pro. All rights reserved.', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          Row(children: [
            GestureDetector(onTap: () => context.go('/auth/login'), child: const Text('Login', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            const Text('  ·  ', style: TextStyle(color: AppColors.border)),
            GestureDetector(onTap: () => context.go('/auth/register'), child: const Text('Register', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          ]),
        ]),
      ])),
    );
  }

  Widget _logoWidget(double fontSize) => Row(children: [
    Container(width: 32, height: 32,
      decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
      child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 18)),
    const SizedBox(width: 10),
    ShaderMask(
      shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
      child: Text('TradeMaster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: fontSize, letterSpacing: -0.5)),
    ),
  ]);
}

// ─── Standalone helpers ───────────────────────────────────────────────────────
Widget _footerLink(String label, VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
  ),
);

// ─── NavLink ──────────────────────────────────────────────────────────────────
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

// ─── Live dot ─────────────────────────────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}
class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.success, AppColors.success.withOpacity(0.2), _c.value),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.5 - _c.value * 0.3), blurRadius: 6)],
      ),
    ),
  );
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.success.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.success.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _LiveDot(),
      const SizedBox(width: 7),
      const Text('Markets Open  •  BTC +2.34%  •  12,847 Active Traders', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ─── Trust badge ──────────────────────────────────────────────────────────────
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TrustBadge({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: color, size: 13),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  ]);
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.09),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.primary.withOpacity(0.22)),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
  );
}

// ─── Stat item ────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: color, size: 18),
    const SizedBox(height: 6),
    ShaderMask(
      shaderCallback: (b) => LinearGradient(colors: [color, color.withOpacity(0.6)]).createShader(b),
      child: Text(value, style: TextStyle(color: Colors.white, fontSize: context.isDesktop ? 24 : 19, fontWeight: FontWeight.w900)),
    ),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
  ]);
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 40, color: AppColors.border);
}

// ─── Signal card ──────────────────────────────────────────────────────────────
class _SignalCard extends StatelessWidget {
  final String pair, tf, action, pattern;
  final double conf;
  final Color color;
  final AnimationController pulseCtrl;
  const _SignalCard({required this.pair, required this.tf, required this.action, required this.conf, required this.pattern, required this.color, required this.pulseCtrl});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulseCtrl,
    builder: (_, __) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25 + pulseCtrl.value * 0.15)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05 + pulseCtrl.value * 0.06), blurRadius: 16)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(pair, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6)),
            child: Text(tf, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(8)),
          child: Text(action, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 10),
        Text(pattern, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Confidence', style: TextStyle(color: AppColors.textHint, fontSize: 10)),
          const Spacer(),
          Text('${(conf * 100).toInt()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: conf, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(color), minHeight: 5),
        ),
      ]),
    ),
  );
}

// ─── Signal row (mini, inside panel) ─────────────────────────────────────────
class _SignalRow extends StatelessWidget {
  final String pair, action;
  final int confidence;
  final AnimationController pulseCtrl;
  final bool sell;
  const _SignalRow({required this.pair, required this.action, required this.confidence, required this.pulseCtrl, this.sell = false});
  @override
  Widget build(BuildContext context) {
    final color = sell ? AppColors.danger : AppColors.success;
    return Row(children: [
      Text(pair, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600)),
      const Spacer(),
      AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1 + pulseCtrl.value * 0.06),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(action, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
        ),
      ),
      const SizedBox(width: 6),
      Text('$confidence%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    ]);
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────
class _Feature {
  final IconData icon;
  final String title, desc;
  final Color color;
  const _Feature({required this.icon, required this.title, required this.desc, required this.color});
}

class _Testimonial {
  final String name, role, text;
  final int rating;
  const _Testimonial(this.name, this.role, this.text, this.rating);
}

class _FAQ {
  final String q, a;
  const _FAQ(this.q, this.a);
}

// ─── Step card ────────────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final String num, title, desc;
  final IconData icon;
  final Color color;
  const _StepCard({required this.num, required this.title, required this.desc, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: color.withOpacity(0.2)),
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [color.withOpacity(0.05), AppColors.card]),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Text(num, style: TextStyle(color: color.withOpacity(0.3), fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
      ]),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 7),
      Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.65)),
    ]),
  );
}

// ─── Feature card ─────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final bool isDesktop;
  const _FeatureCard({required this.feature, this.isDesktop = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(isDesktop ? 24 : 18),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: feature.color.withOpacity(0.15)),
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [feature.color.withOpacity(0.05), AppColors.card]),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 48, height: 48,
        decoration: BoxDecoration(color: feature.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
        child: Icon(feature.icon, color: feature.color, size: 24)),
      const SizedBox(height: 14),
      Text(feature.title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: isDesktop ? 15 : 13)),
      const SizedBox(height: 7),
      Text(feature.desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6)),
    ]),
  );
}

// ─── Commission row ───────────────────────────────────────────────────────────
class _CommissionRow extends StatelessWidget {
  final IconData icon;
  final String title, value, desc;
  final Color color;
  const _CommissionRow({required this.icon, required this.title, required this.value, required this.desc, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.dark.withOpacity(0.6),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.18)),
    ),
    child: Row(children: [
      Container(width: 42, height: 42,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        Text(desc, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.08)]), borderRadius: BorderRadius.circular(20)),
        child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    ]),
  );
}

// ─── Testimonial card ─────────────────────────────────────────────────────────
class _TestimonialCard extends StatelessWidget {
  final _Testimonial testimonial;
  const _TestimonialCard({required this.testimonial});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AppColors.cardLight, AppColors.card]),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 28),
        const Spacer(),
        Row(children: List.generate(testimonial.rating,
          (_) => const Icon(Icons.star_rounded, color: AppColors.warning, size: 14))),
      ]),
      const SizedBox(height: 12),
      Text(testimonial.text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.7, fontStyle: FontStyle.italic)),
      const SizedBox(height: 16),
      Row(children: [
        CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withOpacity(0.18),
          child: Text(testimonial.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(testimonial.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(testimonial.role, style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ]),
  );
}

// ─── FAQ tile ─────────────────────────────────────────────────────────────────
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
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _open ? AppColors.cardLight : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _open ? AppColors.primary.withOpacity(0.4) : AppColors.border),
        boxShadow: _open ? [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 12)] : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.faq.q, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: _open ? AppColors.primary.withOpacity(0.15) : AppColors.border.withOpacity(0.4),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(_open ? Icons.remove_rounded : Icons.add_rounded, color: _open ? AppColors.primary : AppColors.textSecondary, size: 16),
          ),
        ]),
        if (_open) ...[
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Text(widget.faq.a, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.65)),
        ],
      ]),
    ),
  );
}

// ─── Chain badge ─────────────────────────────────────────────────────────────
class _ChainBadge extends StatelessWidget {
  final String symbol;
  const _ChainBadge(this.symbol);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: AppColors.border.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
    child: Text(symbol, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

// ─── Course cards ─────────────────────────────────────────────────────────────
class _PlaceholderCourseCard extends StatelessWidget {
  final int index;
  final bool isDesktop;
  const _PlaceholderCourseCard(this.index, {this.isDesktop = false});
  static const _names = ['Crypto Trading Masterclass', 'Technical Analysis Pro', 'DeFi & Yield Farming', 'Options & Futures', 'Crypto Risk Management', 'Advanced Price Action'];
  static const _tags = ['Beginner', 'Intermediate', 'Advanced', 'Expert', 'Intermediate', 'Advanced'];
  static const _prices = ['\$199', '\$249', '\$299', '\$349', '\$229', '\$279'];
  static const _icons = [Icons.currency_bitcoin, Icons.candlestick_chart_rounded, Icons.hub_rounded, Icons.trending_up_rounded, Icons.security_rounded, Icons.bar_chart_rounded];
  static const _colors = [AppColors.warning, AppColors.primary, AppColors.secondary, AppColors.success, AppColors.danger, AppColors.primary];
  @override
  Widget build(BuildContext context) {
    final i = index % 6;
    final c = _colors[i];
    return Container(
      width: isDesktop ? double.infinity : 200,
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.18)),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [c.withOpacity(0.06), AppColors.card]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: isDesktop ? 100 : 80,
          decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Icon(_icons[i], color: c, size: isDesktop ? 40 : 32)),
        ),
        const SizedBox(height: 12),
        Text(_names[i], style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: isDesktop ? 14 : 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(_tags[i], style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700))),
          const Spacer(),
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          const Text('Live', style: TextStyle(color: AppColors.success, fontSize: 10)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_prices[i], style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 16)),
          GestureDetector(
            onTap: () => context.go('/auth/register'),
            child: Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13)),
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
    final lc = level == 'Beginner' ? AppColors.success : level == 'Intermediate' ? AppColors.primary : AppColors.secondary;
    return Container(
      width: isDesktop ? double.infinity : 200,
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lc.withOpacity(0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: isDesktop ? 100 : 80,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: course['thumbnail'] != null
              ? ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: Image.network(course['thumbnail'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 32))))
              : const Center(child: Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 32)),
        ),
        const SizedBox(height: 12),
        Text(course['title'] ?? '', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: isDesktop ? 14 : 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: lc.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(level, style: TextStyle(color: lc, fontSize: 10, fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('\$${price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 16)),
          GestureDetector(
            onTap: () => context.go('/auth/register'),
            child: Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13)),
          ),
        ]),
      ]),
    );
  }
}

// ─── Glow orb ─────────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: size * 0.5, spreadRadius: size * 0.05)]),
  );
}

// ─── Custom Painters ──────────────────────────────────────────────────────────

// Particle network with animated connections
class _ParticleNetworkPainter extends CustomPainter {
  final double t;
  static final _rng = math.Random(42);
  static late final List<Offset> _positions;
  static bool _inited = false;

  _ParticleNetworkPainter(this.t) {
    if (!_inited) {
      _positions = List.generate(40, (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));
      _inited = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5;

    final pts = _positions.mapIndexed((i, p) {
      final ox = math.sin(t * 2 * math.pi + i * 0.7) * 0.02;
      final oy = math.cos(t * 2 * math.pi + i * 1.1) * 0.02;
      return Offset((p.dx + ox) * size.width, (p.dy + oy) * size.height);
    }).toList();

    // Draw connections
    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        final d = (pts[i] - pts[j]).distance;
        if (d < 120) {
          linePaint.color = AppColors.primary.withOpacity((1 - d / 120) * 0.08);
          canvas.drawLine(pts[i], pts[j], linePaint);
        }
      }
    }

    // Draw dots
    for (int i = 0; i < pts.length; i++) {
      final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi + i * 0.5);
      dotPaint.color = AppColors.primary.withOpacity(0.1 + pulse * 0.15);
      canvas.drawCircle(pts[i], 1.5 + pulse * 1.0, dotPaint);
    }

    // Horizontal scan line
    final scanY = (t % 1.0) * size.height;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, AppColors.primary.withOpacity(0.05), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, scanY - 2, size.width, 4));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 2, size.width, 4), scanPaint);
  }

  @override
  bool shouldRepaint(_ParticleNetworkPainter old) => old.t != t;
}

// Animated candlestick chart
class _CandlestickPainter extends CustomPainter {
  final List<_Candle> candles;
  final double progress; // 0..1 animation progress

  _CandlestickPainter(this.candles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final pad = const EdgeInsets.fromLTRB(12, 8, 12, 8);
    final w = size.width - pad.left - pad.right;
    final h = size.height - pad.top - pad.bottom;

    double minP = candles.map((c) => c.low).reduce(math.min);
    double maxP = candles.map((c) => c.high).reduce(math.max);
    final range = maxP - minP;
    if (range == 0) return;

    // Price scale lines
    final gridPaint = Paint()..color = AppColors.border.withOpacity(0.5)..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final y = pad.top + h * (1 - i / 4);
      canvas.drawLine(Offset(pad.left, y), Offset(pad.left + w, y), gridPaint);
    }

    final cw = w / candles.length;
    final bodyW = (cw * 0.55).clamp(3.0, 10.0);

    // Draw candles — animate reveal left to right
    final revealCount = (candles.length * progress).ceil();
    for (int i = 0; i < revealCount && i < candles.length; i++) {
      final c = candles[i];
      final cx = pad.left + (i + 0.5) * cw;
      final openY = pad.top + h * (1 - (c.open - minP) / range);
      final closeY = pad.top + h * (1 - (c.close - minP) / range);
      final highY = pad.top + h * (1 - (c.high - minP) / range);
      final lowY = pad.top + h * (1 - (c.low - minP) / range);

      final color = c.bullish ? AppColors.success : AppColors.danger;
      final bodyPaint = Paint()..color = color..style = PaintingStyle.fill;
      final wickPaint = Paint()..color = color.withOpacity(0.7)..strokeWidth = 1;

      // Wick
      canvas.drawLine(Offset(cx, highY), Offset(cx, lowY), wickPaint);

      // Body
      final bodyTop = math.min(openY, closeY);
      final bodyH = (openY - closeY).abs().clamp(1.0, double.infinity);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyW / 2, bodyTop, bodyW, bodyH),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rect, bodyPaint);

      // Highlight last candle
      if (i == revealCount - 1) {
        final glowPaint = Paint()..color = color.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(rect, glowPaint);
      }
    }

    // Moving average line (simplified)
    if (revealCount > 5) {
      final maPaint = Paint()..color = AppColors.warning.withOpacity(0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke;
      final maPath = Path();
      bool started = false;
      for (int i = 4; i < revealCount; i++) {
        final avg = candles.sublist(i - 4, i + 1).map((c) => c.close).reduce((a, b) => a + b) / 5;
        final x = pad.left + (i + 0.5) * cw;
        final y = pad.top + h * (1 - (avg - minP) / range);
        if (!started) { maPath.moveTo(x, y); started = true; }
        else maPath.lineTo(x, y);
      }
      canvas.drawPath(maPath, maPaint);
    }
  }

  @override
  bool shouldRepaint(_CandlestickPainter old) => old.progress != progress || old.candles != candles;
}
