import React, { useState, useEffect, useRef } from 'react';
import { Form, Input, Button, message } from 'antd';
import {
  UserOutlined, LockOutlined, LineChartOutlined,
  RiseOutlined, FallOutlined, SafetyOutlined, ThunderboltFilled,
  TeamOutlined, DollarOutlined, TrophyOutlined,
} from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';

// ── Static data ───────────────────────────────────────────────────────────────
const TICKERS = [
  { pair: 'BTC/USDT', price: '67,482.50', change: '+2.34%', up: true },
  { pair: 'ETH/USDT', price: '3,847.20',  change: '+1.87%', up: true },
  { pair: 'SOL/USDT', price: '189.75',    change: '+4.12%', up: true },
  { pair: 'BNB/USDT', price: '612.40',    change: '-0.42%', up: false },
  { pair: 'XRP/USDT', price: '0.8234',    change: '+1.23%', up: true },
  { pair: 'AVAX/USDT',price: '42.18',     change: '+3.67%', up: true },
];

const PHRASES = ['ADMIN CONTROL PANEL', 'TRADING DASHBOARD', 'SECURE ACCESS'];

const STATS = [
  { label: 'Active Users',    value: '12,847', icon: <TeamOutlined />,    color: '#00d2ff' },
  { label: 'Total Volume',    value: '$2.4M',  icon: <DollarOutlined />,  color: '#00c48c' },
  { label: 'Courses Sold',    value: '8,293',  icon: <TrophyOutlined />,  color: '#7b2ff7' },
  { label: 'Commissions Out', value: '$1.2M',  icon: <LineChartOutlined />, color: '#ffa94d' },
];

// ── CSS injected once ─────────────────────────────────────────────────────────
const CSS = `
  @keyframes tm-pulse {
    0%,100% { opacity:1; box-shadow: 0 0 30px rgba(0,210,255,.18); }
    50%      { opacity:.88; box-shadow: 0 0 54px rgba(0,210,255,.34); }
  }
  @keyframes tm-border-spin {
    to { background-position: 200% center; }
  }
  @keyframes tm-float {
    0%,100% { transform: translateY(0px); }
    50%      { transform: translateY(-8px); }
  }
  @keyframes tm-ticker-in {
    from { opacity:0; transform:translateY(8px); }
    to   { opacity:1; transform:translateY(0); }
  }
  @keyframes tm-glow-pulse {
    0%,100% { box-shadow: 0 0 0 0 rgba(0,210,255,0); }
    50%      { box-shadow: 0 0 18px 4px rgba(0,210,255,.22); }
  }
  @keyframes tm-scan {
    from { top: -4px; }
    to   { top: 100%; }
  }
  @keyframes tm-grid-move {
    from { background-position: 0 0; }
    to   { background-position: 0 40px; }
  }
  @keyframes tm-slide-right {
    from { transform:translateX(-24px); opacity:0; }
    to   { transform:translateX(0);    opacity:1; }
  }
  @keyframes tm-fade-up {
    from { transform:translateY(20px); opacity:0; }
    to   { transform:translateY(0);   opacity:1; }
  }
  @keyframes tm-blink { 0%,100%{opacity:1} 49%{opacity:1} 50%{opacity:0} }
  @keyframes tm-bar-grow { from{width:0} to{width:var(--bar-w)} }
  @keyframes tm-spin-slow { to { transform: rotate(360deg); } }
  @keyframes tm-line-draw {
    from { stroke-dashoffset: 300; }
    to   { stroke-dashoffset: 0; }
  }

  .tm-input .ant-input,
  .tm-input .ant-input-affix-wrapper {
    background: #080e1c !important;
    border: 1px solid #1e2d40 !important;
    border-radius: 10px !important;
    color: #e8ecf4 !important;
    transition: border-color .25s, box-shadow .25s !important;
    font-family: 'Courier New', monospace !important;
  }
  .tm-input .ant-input::placeholder,
  .tm-input .ant-input-affix-wrapper input::placeholder {
    color: #4a5568 !important;
  }
  .tm-input .ant-input-affix-wrapper:focus,
  .tm-input .ant-input-affix-wrapper-focused,
  .tm-input .ant-input:focus {
    border-color: #00d2ff !important;
    box-shadow: 0 0 0 3px rgba(0,210,255,.12) !important;
  }
  .tm-input .ant-input-prefix { color: #4a5568 !important; margin-right: 8px; }
  .tm-input.focused .ant-input-prefix { color: #00d2ff !important; }

  .tm-form .ant-form-item { margin-bottom: 16px !important; }
  .tm-form .ant-form-item-explain-error { color: #ff4757 !important; font-size: 11px; }

  .tm-btn:not([disabled]):hover {
    filter: brightness(1.12) !important;
    transform: translateY(-1px) !important;
    box-shadow: 0 8px 32px rgba(0,210,255,.28) !important;
  }
  .tm-btn { transition: all .2s !important; }

  .tm-stat-card:hover {
    border-color: rgba(0,210,255,.35) !important;
    background: rgba(0,210,255,.05) !important;
    transform: translateY(-2px);
    transition: all .2s;
  }
  .tm-ticker-row { animation: tm-ticker-in .35s ease both; }
`;

// ── Chart line SVG helper ─────────────────────────────────────────────────────
function MiniChart({ color = '#00d2ff', up = true }) {
  const pts = up
    ? '10,50 30,40 50,45 70,30 90,35 110,20 130,25 150,10'
    : '10,10 30,22 50,18 70,32 90,28 110,42 130,38 150,50';
  return (
    <svg width={150} height={60} style={{ display: 'block' }}>
      <defs>
        <linearGradient id={`cg-${color}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.28" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      <polyline
        points={pts}
        fill="none"
        stroke={color}
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        style={{ strokeDasharray: 300, strokeDashoffset: 300, animation: 'tm-line-draw 1.8s ease forwards' }}
      />
      <polygon
        points={`10,60 ${pts} 150,60`}
        fill={`url(#cg-${color})`}
      />
    </svg>
  );
}

// ── Main component ────────────────────────────────────────────────────────────
export default function Login() {
  const { login, admin } = useAuth();
  const [loading, setLoading] = useState(false);
  const [typedText, setTypedText] = useState('');
  const [cursorOn, setCursorOn] = useState(true);
  const [tickerIdx, setTickerIdx] = useState(0);
  const [inputFocus, setInputFocus] = useState({ email: false, pass: false });
  const [btnHover, setBtnHover] = useState(false);
  const [statsVisible, setStatsVisible] = useState(false);
  const canvasRef = useRef(null);
  const animRef = useRef(null);
  const timerRef = useRef(null);

  useEffect(() => { if (admin) window.location.replace('/'); }, [admin]);

  // ── Inject CSS once
  useEffect(() => {
    const el = document.createElement('style');
    el.textContent = CSS;
    document.head.appendChild(el);
    return () => document.head.removeChild(el);
  }, []);

  // ── Canvas particle network
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let W = (canvas.width = window.innerWidth);
    let H = (canvas.height = window.innerHeight);

    const resize = () => {
      W = canvas.width = window.innerWidth;
      H = canvas.height = window.innerHeight;
    };
    window.addEventListener('resize', resize);

    const N = 55;
    const particles = Array.from({ length: N }, () => ({
      x: Math.random() * W, y: Math.random() * H,
      vx: (Math.random() - 0.5) * 0.35,
      vy: (Math.random() - 0.5) * 0.35,
      r: Math.random() * 1.8 + 0.8,
      phase: Math.random() * Math.PI * 2,
    }));

    let t = 0;
    const draw = () => {
      ctx.clearRect(0, 0, W, H);
      t += 0.005;

      particles.forEach(p => {
        p.x += p.vx; p.y += p.vy;
        if (p.x < 0 || p.x > W) p.vx *= -1;
        if (p.y < 0 || p.y > H) p.vy *= -1;
      });

      // Connections
      for (let i = 0; i < N; i++) {
        for (let j = i + 1; j < N; j++) {
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const d = Math.sqrt(dx * dx + dy * dy);
          if (d < 130) {
            ctx.beginPath();
            ctx.strokeStyle = `rgba(0,210,255,${(1 - d / 130) * 0.08})`;
            ctx.lineWidth = 0.6;
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.stroke();
          }
        }
      }

      // Dots
      particles.forEach((p, i) => {
        const pulse = 0.5 + 0.5 * Math.sin(t * 2.5 + p.phase);
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r * (0.8 + pulse * 0.4), 0, Math.PI * 2);
        ctx.fillStyle = `rgba(0,210,255,${0.08 + pulse * 0.18})`;
        ctx.fill();
        // Occasional purple dot
        if (i % 7 === 0) {
          ctx.beginPath();
          ctx.arc(p.x, p.y, p.r * 0.7, 0, Math.PI * 2);
          ctx.fillStyle = `rgba(123,47,247,${0.12 + pulse * 0.12})`;
          ctx.fill();
        }
      });

      // Horizontal scan line
      const scanY = (t * 60) % H;
      const grad = ctx.createLinearGradient(0, scanY - 6, 0, scanY + 6);
      grad.addColorStop(0, 'transparent');
      grad.addColorStop(0.5, 'rgba(0,210,255,0.035)');
      grad.addColorStop(1, 'transparent');
      ctx.fillStyle = grad;
      ctx.fillRect(0, scanY - 6, W, 12);

      animRef.current = requestAnimationFrame(draw);
    };
    animRef.current = requestAnimationFrame(draw);

    return () => {
      cancelAnimationFrame(animRef.current);
      window.removeEventListener('resize', resize);
    };
  }, []);

  // ── Typewriter effect
  useEffect(() => {
    let phraseIdx = 0, charIdx = 0, deleting = false;
    const tick = () => {
      const current = PHRASES[phraseIdx];
      if (!deleting && charIdx < current.length) {
        charIdx++;
        setTypedText(current.slice(0, charIdx));
        timerRef.current = setTimeout(tick, 80);
      } else if (!deleting && charIdx === current.length) {
        deleting = true;
        timerRef.current = setTimeout(tick, 1800);
      } else if (deleting && charIdx > 0) {
        charIdx--;
        setTypedText(current.slice(0, charIdx));
        timerRef.current = setTimeout(tick, 45);
      } else {
        deleting = false;
        phraseIdx = (phraseIdx + 1) % PHRASES.length;
        timerRef.current = setTimeout(tick, 350);
      }
    };
    timerRef.current = setTimeout(tick, 600);
    return () => clearTimeout(timerRef.current);
  }, []);

  // ── Cursor blink
  useEffect(() => {
    const iv = setInterval(() => setCursorOn(c => !c), 530);
    return () => clearInterval(iv);
  }, []);

  // ── Ticker rotation
  useEffect(() => {
    const iv = setInterval(() => setTickerIdx(i => (i + 1) % TICKERS.length), 2800);
    return () => clearInterval(iv);
  }, []);

  // ── Stats visible after mount
  useEffect(() => {
    const t = setTimeout(() => setStatsVisible(true), 300);
    return () => clearTimeout(t);
  }, []);

  const onFinish = async ({ email, password }) => {
    setLoading(true);
    try {
      await login(email, password);
      window.location.replace('/');
    } catch (err) {
      const msg = err.response?.data?.message || err.message || 'Login failed.';
      message.error(msg);
      setLoading(false);
    }
  };

  const ticker = TICKERS[tickerIdx];

  // ── Styles
  const S = {
    root: {
      minHeight: '100vh',
      background: '#060b14',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      position: 'relative', overflow: 'hidden',
      fontFamily: "'Segoe UI', system-ui, sans-serif",
    },
    canvas: {
      position: 'absolute', inset: 0,
      pointerEvents: 'none', zIndex: 0,
    },
    // Radial glows
    glowBlue: {
      position: 'absolute', top: '15%', left: '5%',
      width: 500, height: 500, borderRadius: '50%',
      background: 'radial-gradient(circle, rgba(0,210,255,0.06) 0%, transparent 70%)',
      pointerEvents: 'none', zIndex: 0,
      animation: 'tm-float 7s ease-in-out infinite',
    },
    glowPurple: {
      position: 'absolute', bottom: '10%', right: '5%',
      width: 400, height: 400, borderRadius: '50%',
      background: 'radial-gradient(circle, rgba(123,47,247,0.07) 0%, transparent 70%)',
      pointerEvents: 'none', zIndex: 0,
      animation: 'tm-float 9s ease-in-out infinite reverse',
    },
    // Animated grid overlay
    grid: {
      position: 'absolute', inset: 0, pointerEvents: 'none', zIndex: 0,
      backgroundImage: `
        linear-gradient(rgba(0,210,255,0.022) 1px, transparent 1px),
        linear-gradient(90deg, rgba(0,210,255,0.022) 1px, transparent 1px)
      `,
      backgroundSize: '40px 40px',
      animation: 'tm-grid-move 8s linear infinite',
    },
    // Main card wrapper
    card: {
      position: 'relative', zIndex: 10,
      display: 'flex',
      background: 'rgba(10,14,26,0.92)',
      backdropFilter: 'blur(24px)',
      border: '1px solid rgba(0,210,255,0.18)',
      borderRadius: 24,
      overflow: 'hidden',
      boxShadow: '0 0 80px rgba(0,210,255,0.1), 0 0 0 1px rgba(255,255,255,0.04)',
      animation: 'tm-fade-up .7s ease both',
      maxWidth: 900,
      width: '95vw',
    },
    // Top glow line on card
    cardTopLine: {
      position: 'absolute', top: 0, left: 0, right: 0,
      height: 2,
      background: 'linear-gradient(90deg, transparent, #00d2ff, #7b2ff7, transparent)',
      backgroundSize: '200% auto',
      animation: 'tm-border-spin 3s linear infinite',
    },
    // Scan line inside card
    cardScan: {
      position: 'absolute', left: 0, right: 0, height: 3,
      background: 'linear-gradient(transparent, rgba(0,210,255,0.06), transparent)',
      pointerEvents: 'none', zIndex: 5,
      animation: 'tm-scan 4s linear infinite',
    },
    // Left panel
    leftPanel: {
      width: 340,
      minWidth: 340,
      background: 'linear-gradient(160deg, rgba(0,210,255,0.06) 0%, rgba(123,47,247,0.04) 100%)',
      borderRight: '1px solid rgba(0,210,255,0.1)',
      padding: '40px 28px',
      display: 'flex', flexDirection: 'column',
      position: 'relative', overflow: 'hidden',
    },
    // Right panel (form)
    rightPanel: {
      flex: 1, padding: '44px 40px',
      display: 'flex', flexDirection: 'column', justifyContent: 'center',
    },
    // Logo row
    logoRow: {
      display: 'flex', alignItems: 'center', gap: 12, marginBottom: 28,
    },
    logoIcon: {
      width: 44, height: 44, borderRadius: 12,
      background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 22, color: '#fff',
      boxShadow: '0 0 20px rgba(0,210,255,0.3)',
      animation: 'tm-pulse 2.5s ease-in-out infinite',
    },
    logoText: {
      fontSize: 22, fontWeight: 900, letterSpacing: -0.5,
      background: 'linear-gradient(90deg, #00d2ff, #7b2ff7)',
      WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
    },
    // Typewriter block
    typewriterBlock: {
      marginBottom: 24,
    },
    typewriterLabel: {
      fontSize: 10, letterSpacing: 2.5, color: '#00d2ff',
      fontWeight: 700, marginBottom: 8, opacity: 0.7,
      fontFamily: 'Courier New, monospace',
    },
    typewriterText: {
      fontSize: 15, fontWeight: 800, color: '#e8ecf4',
      fontFamily: 'Courier New, monospace',
      letterSpacing: 1,
      minHeight: 22,
    },
    cursor: {
      display: 'inline-block', width: 10, height: 16,
      background: '#00d2ff', marginLeft: 2,
      verticalAlign: 'text-bottom',
      borderRadius: 2,
      opacity: cursorOn ? 1 : 0,
      transition: 'opacity .1s',
    },
    // Live ticker box
    tickerBox: {
      background: 'rgba(0,210,255,0.04)',
      border: '1px solid rgba(0,210,255,0.14)',
      borderRadius: 12,
      padding: '12px 14px',
      marginBottom: 20,
      position: 'relative', overflow: 'hidden',
    },
    tickerLabel: {
      fontSize: 9, letterSpacing: 2, color: '#4a5568',
      fontWeight: 700, marginBottom: 8,
      fontFamily: 'Courier New, monospace',
    },
    tickerRow: {
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    },
    tickerPair: {
      fontSize: 13, fontWeight: 800, color: '#e8ecf4',
    },
    tickerPrice: {
      fontSize: 13, fontWeight: 700, color: '#e8ecf4',
    },
    tickerChange: (up) => ({
      fontSize: 12, fontWeight: 700,
      color: up ? '#00c48c' : '#ff4757',
      display: 'flex', alignItems: 'center', gap: 3,
    }),
    // Stats grid
    statsGrid: {
      display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8,
      marginBottom: 20,
    },
    statCard: {
      background: 'rgba(255,255,255,0.025)',
      border: '1px solid rgba(255,255,255,0.07)',
      borderRadius: 10, padding: '10px 12px',
      cursor: 'default',
      transition: 'all .2s',
    },
    statIcon: (color) => ({
      fontSize: 14, color,
      marginBottom: 4, display: 'block',
    }),
    statValue: {
      fontSize: 16, fontWeight: 900, color: '#e8ecf4', lineHeight: 1.2,
    },
    statLabel: {
      fontSize: 9, color: '#8899aa', letterSpacing: 0.5, marginTop: 2,
    },
    // Security badges
    badgeRow: {
      display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 'auto',
    },
    badge: {
      display: 'flex', alignItems: 'center', gap: 5,
      background: 'rgba(0,196,140,0.08)',
      border: '1px solid rgba(0,196,140,0.2)',
      borderRadius: 20, padding: '4px 10px',
      fontSize: 10, color: '#00c48c', fontWeight: 600,
    },
    // Right panel title
    rTitle: {
      fontSize: 26, fontWeight: 900, color: '#fff',
      marginBottom: 4, letterSpacing: -0.5,
    },
    rSub: {
      fontSize: 13, color: '#8899aa', marginBottom: 28,
    },
    // Form section label
    sectionLabel: {
      fontSize: 9, letterSpacing: 2, color: '#4a5568',
      fontWeight: 700, marginBottom: 14,
      fontFamily: 'Courier New, monospace',
    },
    // Submit btn
    submitBtn: {
      height: 48, borderRadius: 12,
      background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)',
      border: 'none', fontSize: 15, fontWeight: 700,
      boxShadow: '0 4px 24px rgba(0,210,255,0.22)',
      cursor: 'pointer', color: '#fff',
      transition: 'all .2s',
      width: '100%',
      marginTop: 8,
    },
    // Info row below form
    infoRow: {
      display: 'flex', justifyContent: 'center', alignItems: 'center',
      gap: 8, marginTop: 20,
    },
    infoDot: {
      width: 6, height: 6, borderRadius: '50%',
      background: '#00c48c',
      boxShadow: '0 0 8px #00c48c',
      animation: 'tm-pulse 1.5s ease-in-out infinite',
    },
    infoText: {
      fontSize: 11, color: '#4a5568',
    },
    // Mobile hide
    leftPanelHide: { display: 'none' },
  };

  // Responsive: hide left panel below 700px
  const isWide = window.innerWidth >= 700;

  return (
    <div style={S.root}>
      {/* Injected styles are handled by useEffect */}
      <canvas ref={canvasRef} style={S.canvas} />
      <div style={S.glowBlue} />
      <div style={S.glowPurple} />
      <div style={S.grid} />

      {/* Main card */}
      <div style={S.card}>
        {/* Animated top border */}
        <div style={S.cardTopLine} />
        {/* Scan line */}
        <div style={S.cardScan} />

        {/* ── Left panel ── */}
        {isWide && (
          <div style={S.leftPanel}>
            {/* Subtle noise overlay on left */}
            <div style={{
              position: 'absolute', inset: 0, pointerEvents: 'none',
              background: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,210,255,0.007) 2px, rgba(0,210,255,0.007) 4px)',
            }} />

            {/* Logo */}
            <div style={S.logoRow}>
              <div style={S.logoIcon}><ThunderboltFilled /></div>
              <span style={S.logoText}>TradeMaster</span>
            </div>

            {/* Typewriter */}
            <div style={S.typewriterBlock}>
              <div style={S.typewriterLabel}>// SYSTEM ACCESS</div>
              <div style={S.typewriterText}>
                {typedText}
                <span style={S.cursor} />
              </div>
            </div>

            {/* Live ticker */}
            <div style={S.tickerBox}>
              <div style={S.tickerLabel}>◆ LIVE MARKET</div>
              <div
                key={tickerIdx}
                className="tm-ticker-row"
                style={S.tickerRow}
              >
                <span style={S.tickerPair}>{ticker.pair}</span>
                <span style={S.tickerPrice}>${ticker.price}</span>
                <span style={S.tickerChange(ticker.up)}>
                  {ticker.up ? <RiseOutlined /> : <FallOutlined />}
                  {ticker.change}
                </span>
              </div>
              <div style={{ marginTop: 8 }}>
                <MiniChart color={ticker.up ? '#00c48c' : '#ff4757'} up={ticker.up} />
              </div>
            </div>

            {/* Stats */}
            <div style={S.statsGrid}>
              {STATS.map((s, i) => (
                <div
                  key={s.label}
                  className="tm-stat-card"
                  style={{
                    ...S.statCard,
                    opacity: statsVisible ? 1 : 0,
                    transform: statsVisible ? 'translateY(0)' : 'translateY(10px)',
                    transition: `all .4s ease ${i * 0.1}s`,
                  }}
                >
                  <span style={S.statIcon(s.color)}>{s.icon}</span>
                  <div style={S.statValue}>{s.value}</div>
                  <div style={S.statLabel}>{s.label}</div>
                </div>
              ))}
            </div>

            {/* Security badges */}
            <div style={S.badgeRow}>
              <div style={S.badge}><SafetyOutlined /> JWT Secured</div>
              <div style={S.badge}><SafetyOutlined /> 256-bit</div>
              <div style={S.badge}><SafetyOutlined /> Encrypted</div>
            </div>
          </div>
        )}

        {/* ── Right panel (form) ── */}
        <div style={S.rightPanel}>
          {/* Mobile logo */}
          {!isWide && (
            <div style={{ ...S.logoRow, justifyContent: 'center', marginBottom: 20 }}>
              <div style={S.logoIcon}><ThunderboltFilled /></div>
              <span style={S.logoText}>TradeMaster</span>
            </div>
          )}

          <div style={S.sectionLabel}>// AUTHENTICATE</div>
          <div style={S.rTitle}>Welcome Back</div>
          <div style={S.rSub}>Sign in to the admin control panel</div>

          {/* Animated divider */}
          <div style={{
            height: 1, marginBottom: 28,
            background: 'linear-gradient(90deg, #00d2ff44, #7b2ff744, transparent)',
          }} />

          <Form
            layout="vertical"
            onFinish={onFinish}
            size="large"
            className="tm-form"
          >
            {/* Email */}
            <Form.Item
              name="email"
              rules={[{ required: true, type: 'email', message: 'Enter a valid email' }]}
              style={{ marginBottom: 14 }}
            >
              <div
                className={`tm-input${inputFocus.email ? ' focused' : ''}`}
                onFocus={() => setInputFocus(f => ({ ...f, email: true }))}
                onBlur={() => setInputFocus(f => ({ ...f, email: false }))}
              >
                <Input
                  prefix={
                    <UserOutlined style={{ color: inputFocus.email ? '#00d2ff' : '#4a5568', transition: 'color .25s' }} />
                  }
                  placeholder="admin@tradingmlm.com"
                  style={{
                    background: '#080e1c',
                    border: `1px solid ${inputFocus.email ? '#00d2ff' : '#1e2d40'}`,
                    color: '#e8ecf4', borderRadius: 10,
                    boxShadow: inputFocus.email ? '0 0 0 3px rgba(0,210,255,0.1)' : 'none',
                    transition: 'all .25s',
                    fontFamily: 'Courier New, monospace',
                    height: 46,
                  }}
                />
              </div>
            </Form.Item>

            {/* Password */}
            <Form.Item
              name="password"
              rules={[{ required: true, message: 'Password is required' }]}
              style={{ marginBottom: 22 }}
            >
              <div
                className={`tm-input${inputFocus.pass ? ' focused' : ''}`}
                onFocus={() => setInputFocus(f => ({ ...f, pass: true }))}
                onBlur={() => setInputFocus(f => ({ ...f, pass: false }))}
              >
                <Input.Password
                  prefix={
                    <LockOutlined style={{ color: inputFocus.pass ? '#00d2ff' : '#4a5568', transition: 'color .25s' }} />
                  }
                  placeholder="••••••••••••"
                  style={{
                    background: '#080e1c',
                    border: `1px solid ${inputFocus.pass ? '#00d2ff' : '#1e2d40'}`,
                    color: '#e8ecf4', borderRadius: 10,
                    boxShadow: inputFocus.pass ? '0 0 0 3px rgba(0,210,255,0.1)' : 'none',
                    transition: 'all .25s',
                    fontFamily: 'Courier New, monospace',
                    height: 46,
                  }}
                />
              </div>
            </Form.Item>

            {/* Submit */}
            <Button
              type="primary"
              htmlType="submit"
              loading={loading}
              block
              className="tm-btn"
              style={S.submitBtn}
            >
              {loading ? 'AUTHENTICATING...' : '⚡  SIGN IN TO ADMIN'}
            </Button>
          </Form>

          {/* System status row */}
          <div style={S.infoRow}>
            <div style={S.infoDot} />
            <span style={S.infoText}>All systems operational</span>
            <span style={{ color: '#1e2d40', fontSize: 11 }}>•</span>
            <span style={S.infoText}>v2.4.1</span>
            <span style={{ color: '#1e2d40', fontSize: 11 }}>•</span>
            <span style={S.infoText}>SSL active</span>
          </div>

          {/* Terminal line */}
          <div style={{
            marginTop: 24,
            background: 'rgba(0,0,0,0.35)',
            border: '1px solid #0d1a2e',
            borderRadius: 8, padding: '10px 14px',
            fontFamily: 'Courier New, monospace',
            fontSize: 11, color: '#4a5568',
            lineHeight: 1.7,
          }}>
            <span style={{ color: '#00d2ff' }}>▶</span> system.init() — TradeMaster Admin v2.4<br />
            <span style={{ color: '#00d2ff' }}>▶</span> auth.module loaded — <span style={{ color: '#00c48c' }}>OK</span><br />
            <span style={{ color: '#00d2ff' }}>▶</span> db.connect() — <span style={{ color: '#00c48c' }}>ACTIVE</span> — awaiting credentials<span style={{ animation: 'tm-blink 1s step-end infinite' }}>_</span>
          </div>
        </div>
      </div>
    </div>
  );
}

