"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { motion, useInView, useMotionValue, useTransform, AnimatePresence } from "framer-motion";
import { cn } from "@/lib/utils";
import {
  Shield, Cpu, BarChart3, Timer, Download, Star,
  ChevronDown, Clock, Zap, Eye, Database,
  Monitor, Layers, Target, TrendingUp,
  Github, Twitter, Mail, ArrowRight, Check,
  Sparkles, Globe2, Lock, FileDown
} from "lucide-react";

/* ═══════════════════════════════════════════════════════════════════
   ACETERNITY-STYLE COMPONENTS (adapted from ui.aceternity.com)
   1. Background Beams          8. Sparkles Effect
   2. Aurora Background         9. Animated Counter / Tooltip
   3. Text Generate Effect     10. Hover Border Gradient (cards)
   4. Moving Border Button     11. Focus Cards (how it works)
   5. 3D Card Effect           12. Parallax / SectionReveal
   6. Bento Grid (features)    13. Compare (before/after mockup)
   7. Infinite Moving Cards    14. Floating Dock (footer)
   ═══════════════════════════════════════════════════════════════════ */

// ─── Background Beams ────────────────────────────────────────────
function BackgroundBeams() {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {[...Array(6)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute h-[2px] bg-gradient-to-r from-transparent via-primary/40 to-transparent"
          style={{ top: `${15 + i * 15}%`, width: "100%" }}
          animate={{ x: ["-100%", "100%"], opacity: [0, 0.6, 0] }}
          transition={{ duration: 4 + i * 0.8, repeat: Infinity, delay: i * 0.6, ease: "linear" }}
        />
      ))}
      {[...Array(4)].map((_, i) => (
        <motion.div
          key={`v-${i}`}
          className="absolute w-[2px] bg-gradient-to-b from-transparent via-accent/30 to-transparent"
          style={{ left: `${20 + i * 20}%`, height: "100%" }}
          animate={{ y: ["-100%", "100%"], opacity: [0, 0.4, 0] }}
          transition={{ duration: 5 + i, repeat: Infinity, delay: i * 1.2, ease: "linear" }}
        />
      ))}
    </div>
  );
}

// ─── Aurora Background ───────────────────────────────────────────
function AuroraBackground() {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      <div className="absolute -top-40 -right-40 w-[600px] h-[600px] rounded-full bg-primary/10 blur-[120px] animate-pulse" />
      <div className="absolute -bottom-40 -left-40 w-[500px] h-[500px] rounded-full bg-secondary/10 blur-[120px] animate-pulse [animation-delay:2s]" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[400px] rounded-full bg-accent/5 blur-[100px]" />
    </div>
  );
}

// ─── Sparkles ────────────────────────────────────────────────────
function SparklesEffect({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <span className={cn("relative inline-block", className)}>
      {children}
      {[...Array(6)].map((_, i) => (
        <motion.span
          key={i}
          className="absolute w-1 h-1 rounded-full bg-primary/80"
          style={{ top: `${Math.random() * 100}%`, left: `${Math.random() * 100}%` }}
          animate={{ scale: [0, 1, 0], opacity: [0, 1, 0] }}
          transition={{ duration: 2, repeat: Infinity, delay: i * 0.4 }}
        />
      ))}
    </span>
  );
}

// ─── Text Generate Effect ────────────────────────────────────────
function TextGenerateEffect({ words }: { words: string }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });
  const wordArray = words.split(" ");

  return (
    <motion.h1
      ref={ref}
      className="text-5xl md:text-7xl lg:text-8xl font-bold tracking-tight leading-[1.1]"
    >
      {wordArray.map((word, i) => (
        <motion.span
          key={i}
          className="inline-block mr-[0.25em]"
          initial={{ opacity: 0, y: 20, filter: "blur(8px)" }}
          animate={isInView ? { opacity: 1, y: 0, filter: "blur(0px)" } : {}}
          transition={{ duration: 0.4, delay: i * 0.08 }}
        >
          {word === "Focus." || word === "Time." ? (
            <span className="bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent">
              {word}
            </span>
          ) : (
            word
          )}
        </motion.span>
      ))}
    </motion.h1>
  );
}

// ─── Moving Border Button ────────────────────────────────────────
function MovingBorderButton({
  children,
  className,
  href,
  variant = "primary",
}: {
  children: React.ReactNode;
  className?: string;
  href?: string;
  variant?: "primary" | "secondary";
}) {
  const Tag = href ? "a" : "button";
  return (
    <Tag
      href={href}
      className={cn(
        "relative group px-8 py-4 rounded-xl font-semibold text-base overflow-hidden transition-all duration-300",
        variant === "primary"
          ? "bg-primary text-white hover:bg-primary/90 shadow-lg shadow-primary/25 hover:shadow-primary/40"
          : "bg-card/80 text-foreground border border-white/10 hover:border-primary/40 hover:bg-card",
        className
      )}
    >
      <span className="absolute inset-0 rounded-xl overflow-hidden">
        <motion.span
          className="absolute inset-[-2px] rounded-xl"
          style={{
            background:
              "conic-gradient(from 0deg, transparent 70%, rgba(99,102,241,0.5) 80%, transparent 90%)",
          }}
          animate={{ rotate: [0, 360] }}
          transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
        />
      </span>
      <span className="relative z-10 flex items-center gap-2">{children}</span>
    </Tag>
  );
}

// ─── 3D Card Effect ──────────────────────────────────────────────
function Card3D({ children, className }: { children: React.ReactNode; className?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const rotateX = useTransform(y, [-0.5, 0.5], [8, -8]);
  const rotateY = useTransform(x, [-0.5, 0.5], [-8, 8]);

  const handleMouse = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      if (!ref.current) return;
      const rect = ref.current.getBoundingClientRect();
      x.set((e.clientX - rect.left) / rect.width - 0.5);
      y.set((e.clientY - rect.top) / rect.height - 0.5);
    },
    [x, y]
  );

  const handleLeave = useCallback(() => {
    x.set(0);
    y.set(0);
  }, [x, y]);

  return (
    <motion.div
      ref={ref}
      onMouseMove={handleMouse}
      onMouseLeave={handleLeave}
      style={{ rotateX, rotateY, transformStyle: "preserve-3d" }}
      className={cn("transition-shadow duration-300", className)}
    >
      {children}
    </motion.div>
  );
}

// ─── Infinite Moving Cards ───────────────────────────────────────
function InfiniteMovingCards({
  items,
  speed = "normal",
}: {
  items: { quote: string; name: string; title: string }[];
  speed?: "slow" | "normal" | "fast";
}) {
  const s = speed === "fast" ? 20 : speed === "slow" ? 60 : 40;
  return (
    <div className="relative overflow-hidden [mask-image:linear-gradient(to_right,transparent,white_10%,white_90%,transparent)]">
      <motion.div
        className="flex gap-6 w-max"
        animate={{ x: ["0%", "-50%"] }}
        transition={{ duration: s, repeat: Infinity, ease: "linear" }}
      >
        {[...items, ...items].map((item, i) => (
          <div
            key={i}
            className="flex-shrink-0 w-[350px] rounded-2xl bg-card/60 backdrop-blur-sm border border-white/10 p-6 space-y-4"
          >
            <p className="text-muted text-sm leading-relaxed">&ldquo;{item.quote}&rdquo;</p>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-xs font-bold text-white">
                {item.name[0]}
              </div>
              <div>
                <p className="text-sm font-medium text-foreground">{item.name}</p>
                <p className="text-xs text-muted">{item.title}</p>
              </div>
            </div>
          </div>
        ))}
      </motion.div>
    </div>
  );
}

// ─── Floating Dock ───────────────────────────────────────────────
function FloatingDock({
  items,
}: {
  items: { icon: React.ReactNode; label: string; href: string }[];
}) {
  return (
    <div className="flex items-center gap-1 bg-card/80 backdrop-blur-lg border border-white/10 rounded-2xl p-2">
      {items.map((item, i) => (
        <a
          key={i}
          href={item.href}
          target="_blank"
          rel="noopener noreferrer"
          className="group relative p-3 rounded-xl hover:bg-primary/20 transition-colors duration-200"
          aria-label={item.label}
        >
          {item.icon}
          <span className="absolute -top-10 left-1/2 -translate-x-1/2 px-2 py-1 bg-card text-xs rounded-md border border-white/10 opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none">
            {item.label}
          </span>
        </a>
      ))}
    </div>
  );
}

// ─── Animated Counter ────────────────────────────────────────────
function AnimatedCounter({ target, suffix = "" }: { target: number; suffix?: string }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (!isInView) return;
    let start = 0;
    const increment = target / 60;
    const timer = setInterval(() => {
      start += increment;
      if (start >= target) {
        setCount(target);
        clearInterval(timer);
      } else {
        setCount(Math.floor(start));
      }
    }, 16);
    return () => clearInterval(timer);
  }, [isInView, target]);

  return (
    <span ref={ref} className="tabular-nums">
      {count.toLocaleString()}
      {suffix}
    </span>
  );
}

// ─── Section Reveal ──────────────────────────────────────────────
function SectionReveal({ children, className }: { children: React.ReactNode; className?: string }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });
  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 60 }}
      animate={isInView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.7, ease: "easeOut" }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

/* ═══════════════════════════════════════════════════════════════════
   PAGE SECTIONS
   ═══════════════════════════════════════════════════════════════════ */

// ─── NAVBAR ──────────────────────────────────────────────────────
function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const links = [
    { label: "Features", href: "#features" },
    { label: "How it Works", href: "#how-it-works" },
    { label: "Downloads", href: "#download" },
    { label: "FAQ", href: "#faq" },
  ];

  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handler);
    return () => window.removeEventListener("scroll", handler);
  }, []);

  return (
    <nav
      className={cn(
        "fixed top-0 left-0 right-0 z-50 transition-all duration-300",
        scrolled
          ? "bg-background/80 backdrop-blur-xl border-b border-white/5 shadow-lg shadow-black/10"
          : "bg-transparent"
      )}
    >
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        <a href="#" className="flex items-center gap-2 group">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
            <Target className="w-4 h-4 text-white" />
          </div>
          <span className="font-bold text-lg tracking-tight">
            Focus<span className="text-primary">Track</span>
          </span>
        </a>

        <div className="hidden md:flex items-center gap-8">
          {links.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm text-muted hover:text-foreground transition-colors relative group"
            >
              {link.label}
              <span className="absolute -bottom-1 left-0 w-0 h-[2px] bg-primary group-hover:w-full transition-all duration-300" />
            </a>
          ))}
          <a
            href="#download"
            className="px-4 py-2 rounded-lg bg-primary text-white text-sm font-medium hover:bg-primary/90 transition-colors"
          >
            Download
          </a>
        </div>

        <button
          className="md:hidden p-2 text-muted"
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-label="Toggle menu"
        >
          <div className="w-5 flex flex-col gap-1">
            <span className={cn("h-0.5 bg-current transition-all", mobileOpen && "rotate-45 translate-y-1.5")} />
            <span className={cn("h-0.5 bg-current transition-all", mobileOpen && "opacity-0")} />
            <span className={cn("h-0.5 bg-current transition-all", mobileOpen && "-rotate-45 -translate-y-1.5")} />
          </div>
        </button>
      </div>

      <AnimatePresence>
        {mobileOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="md:hidden bg-surface/95 backdrop-blur-xl border-b border-white/5"
          >
            <div className="px-6 py-4 space-y-3">
              {links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  onClick={() => setMobileOpen(false)}
                  className="block text-sm text-muted hover:text-foreground py-2"
                >
                  {link.label}
                </a>
              ))}
              <a
                href="#download"
                onClick={() => setMobileOpen(false)}
                className="block px-4 py-2 rounded-lg bg-primary text-white text-sm font-medium text-center"
              >
                Download
              </a>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
}

// ─── HERO ────────────────────────────────────────────────────────
function HeroSection() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-16">
      <AuroraBackground />
      <BackgroundBeams />

      <div
        className="absolute inset-0 pointer-events-none opacity-[0.03]"
        style={{
          backgroundImage:
            "linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)",
          backgroundSize: "60px 60px",
        }}
      />

      <div className="relative z-10 max-w-7xl mx-auto px-6 py-20 flex flex-col items-center text-center">
        <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="mb-8">
          <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 text-sm text-primary">
            <Sparkles className="w-3.5 h-3.5" />
            Privacy-first desktop tracker
            <ArrowRight className="w-3.5 h-3.5" />
          </span>
        </motion.div>

        <SparklesEffect>
          <TextGenerateEffect words="Reclaim Your Focus. Understand Your Time." />
        </SparklesEffect>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
          className="mt-6 max-w-2xl text-lg md:text-xl text-muted leading-relaxed"
        >
          The powerful, local-only screen time tracker for Windows &amp; Linux — accurate app detection, smart limits, beautiful insights.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 1.0 }}
          className="mt-10 flex flex-col sm:flex-row gap-4"
        >
          <MovingBorderButton href="/downloads/focus-track-windows.exe" variant="primary">
            <Monitor className="w-4 h-4" />
            Download for Windows
          </MovingBorderButton>
          <MovingBorderButton href="/downloads/focus-track-linux.AppImage" variant="secondary">
            <Download className="w-4 h-4" />
            Download for Linux
          </MovingBorderButton>
        </motion.div>

        {/* App mockup */}
        <motion.div
          initial={{ opacity: 0, y: 40, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ delay: 1.2, duration: 0.8 }}
          className="mt-16 w-full max-w-5xl"
        >
          <Card3D>
            <div className="relative rounded-2xl overflow-hidden border border-white/10 bg-surface/80 shadow-2xl shadow-primary/10">
              <div className="flex items-center gap-2 px-4 py-3 bg-card/80 border-b border-white/5">
                <div className="w-3 h-3 rounded-full bg-red-500/80" />
                <div className="w-3 h-3 rounded-full bg-yellow-500/80" />
                <div className="w-3 h-3 rounded-full bg-green-500/80" />
                <span className="ml-3 text-xs text-muted">FocusTrack — Dashboard</span>
              </div>
              <div className="p-8 grid grid-cols-3 gap-4">
                {[
                  { label: "Screen Time", value: "6h 42m", color: "from-primary to-secondary" },
                  { label: "Focus Score", value: "87%", color: "from-accent to-primary" },
                  { label: "Apps Used", value: "12", color: "from-success to-accent" },
                ].map((stat, i) => (
                  <div key={i} className="rounded-xl bg-card/50 border border-white/5 p-4">
                    <p className="text-xs text-muted mb-1">{stat.label}</p>
                    <p className={cn("text-2xl font-bold bg-gradient-to-r bg-clip-text text-transparent", stat.color)}>
                      {stat.value}
                    </p>
                  </div>
                ))}
                <div className="col-span-2 rounded-xl bg-card/50 border border-white/5 p-4">
                  <p className="text-xs text-muted mb-3">Usage Timeline</p>
                  <div className="flex items-end gap-1 h-24">
                    {[40, 65, 30, 80, 55, 90, 45, 70, 35, 85, 60, 50].map((h, i) => (
                      <motion.div
                        key={i}
                        className="flex-1 bg-gradient-to-t from-primary/40 to-primary rounded-t"
                        initial={{ height: 0 }}
                        animate={{ height: `${h}%` }}
                        transition={{ delay: 1.5 + i * 0.05, duration: 0.5 }}
                      />
                    ))}
                  </div>
                </div>
                <div className="rounded-xl bg-card/50 border border-white/5 p-4">
                  <p className="text-xs text-muted mb-3">Top App</p>
                  <p className="text-lg font-semibold text-foreground">VS Code</p>
                  <p className="text-sm text-primary">3h 14m</p>
                </div>
              </div>
            </div>
          </Card3D>
        </motion.div>

        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 2 }} className="mt-12">
          <motion.div animate={{ y: [0, 8, 0] }} transition={{ duration: 2, repeat: Infinity }}>
            <ChevronDown className="w-5 h-5 text-muted" />
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}

// ─── FEATURES (Bento Grid) ──────────────────────────────────────
const features = [
  {
    icon: <Eye className="w-6 h-6" />,
    title: "Detects EVERY App",
    desc: "Telegram, Discord, Electron apps, UWP, browsers — FocusTrack's Win32 FFI engine identifies them all with zero manual setup.",
    span: "md:col-span-2",
    gradient: "from-primary/20",
  },
  {
    icon: <BarChart3 className="w-6 h-6" />,
    title: "Daily & Weekly Charts",
    desc: "Beautiful timelines, hourly heatmaps, and trend charts so you can see exactly where your time goes.",
    span: "",
    gradient: "from-accent/20",
  },
  {
    icon: <Timer className="w-6 h-6" />,
    title: "Smart Usage Limits",
    desc: "Set daily goals, get notified when you exceed them, and build productive streaks.",
    span: "",
    gradient: "from-success/20",
  },
  {
    icon: <Shield className="w-6 h-6" />,
    title: "100% Local — Zero Tracking",
    desc: "Your data never leaves your machine. No cloud, no telemetry, no accounts. Privacy by design.",
    span: "md:col-span-2",
    gradient: "from-secondary/20",
  },
  {
    icon: <Cpu className="w-6 h-6" />,
    title: "Low CPU Background Mode",
    desc: "Uses < 0.5% CPU. Polls every 2 seconds with zero impact on your workflow.",
    span: "",
    gradient: "from-accent/20",
  },
  {
    icon: <Layers className="w-6 h-6" />,
    title: "App Categorization",
    desc: "Auto-categorizes 150+ apps — Work, Dev, Entertainment, Social — with smart productivity scoring.",
    span: "",
    gradient: "from-primary/20",
  },
  {
    icon: <FileDown className="w-6 h-6" />,
    title: "CSV Export & Goals",
    desc: "Export your data as JSON/CSV. Set daily productivity goals and track your streaks over months.",
    span: "md:col-span-2",
    gradient: "from-success/20",
  },
];

function FeaturesSection() {
  return (
    <section id="features" className="py-32 relative">
      <div className="max-w-7xl mx-auto px-6">
        <SectionReveal>
          <div className="text-center mb-16">
            <span className="text-sm font-medium text-primary uppercase tracking-wider">Features</span>
            <h2 className="mt-3 text-4xl md:text-5xl font-bold">
              Everything you need to{" "}
              <span className="bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">own your time</span>
            </h2>
            <p className="mt-4 text-muted max-w-xl mx-auto">More than a screen time tracker — a complete focus intelligence platform.</p>
          </div>
        </SectionReveal>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {features.map((f, i) => (
            <SectionReveal key={i} className={cn("group", f.span)}>
              <Card3D>
                <div
                  className={cn(
                    "relative h-full rounded-2xl bg-card/50 border border-white/5 p-6 overflow-hidden",
                    "hover:border-primary/30 transition-all duration-500"
                  )}
                >
                  <div
                    className={cn(
                      "absolute -top-20 -right-20 w-40 h-40 rounded-full blur-[80px] opacity-0 group-hover:opacity-100 transition-opacity duration-700",
                      `bg-gradient-to-br ${f.gradient} to-transparent`
                    )}
                  />
                  <div className="relative z-10">
                    <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center text-primary mb-4 group-hover:scale-110 transition-transform">
                      {f.icon}
                    </div>
                    <h3 className="text-lg font-semibold text-foreground mb-2">{f.title}</h3>
                    <p className="text-sm text-muted leading-relaxed">{f.desc}</p>
                  </div>
                </div>
              </Card3D>
            </SectionReveal>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─── HOW IT WORKS ────────────────────────────────────────────────
const steps = [
  { num: "01", title: "Download & Install", desc: "Grab the installer for Windows (.exe) or Linux (.AppImage). No sign-up needed.", icon: <Download className="w-5 h-5" /> },
  { num: "02", title: "It Starts Tracking", desc: "FocusTrack silently runs in the background, detecting every app you use with millisecond precision.", icon: <Zap className="w-5 h-5" /> },
  { num: "03", title: "Check Your Insights", desc: "Open the dashboard to see hourly heatmaps, focus scores, app timelines, and streak data.", icon: <TrendingUp className="w-5 h-5" /> },
  { num: "04", title: "Set Goals & Improve", desc: "Define daily limits, track productivity streaks, and export reports to sharpen your focus.", icon: <Target className="w-5 h-5" /> },
];

function HowItWorksSection() {
  return (
    <section id="how-it-works" className="py-32 relative">
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-primary/[0.02] to-transparent pointer-events-none" />
      <div className="max-w-5xl mx-auto px-6 relative">
        <SectionReveal>
          <div className="text-center mb-20">
            <span className="text-sm font-medium text-accent uppercase tracking-wider">How it Works</span>
            <h2 className="mt-3 text-4xl md:text-5xl font-bold">
              Up and running in{" "}
              <span className="bg-gradient-to-r from-accent to-primary bg-clip-text text-transparent">30 seconds</span>
            </h2>
          </div>
        </SectionReveal>

        <div className="space-y-16">
          {steps.map((step, i) => (
            <SectionReveal key={i}>
              <div className={cn("flex items-start gap-8", i % 2 === 1 && "md:flex-row-reverse")}>
                <div className="flex-shrink-0 w-20 h-20 rounded-2xl bg-card/80 border border-white/10 flex items-center justify-center relative group">
                  <span className="text-2xl font-bold bg-gradient-to-br from-primary to-secondary bg-clip-text text-transparent">
                    {step.num}
                  </span>
                  <div className="absolute inset-0 rounded-2xl bg-primary/10 opacity-0 group-hover:opacity-100 transition-opacity" />
                </div>
                <div className="flex-1 pt-2">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="text-primary">{step.icon}</span>
                    <h3 className="text-xl font-semibold">{step.title}</h3>
                  </div>
                  <p className="text-muted max-w-md leading-relaxed">{step.desc}</p>
                </div>
              </div>
            </SectionReveal>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─── TESTIMONIALS ────────────────────────────────────────────────
const testimonials = [
  { quote: "FocusTrack helped me discover I was losing 3 hours a day to context-switching. Now I batch my communication apps into 2 windows. Productivity up 40%.", name: "Alex Chen", title: "Full-Stack Developer" },
  { quote: "Finally a tracker that ACTUALLY finds Discord, Telegram, and Obsidian. Every other tool just shows 'electron' — useless. This is different.", name: "Sarah Kim", title: "Product Designer" },
  { quote: "The privacy angle sold me. No cloud, no accounts, no creepy telemetry. Just clean local data on my machine. As it should be.", name: "Marcus Duval", title: "Security Engineer" },
  { quote: "I use the hourly heatmap every morning to plan my deep work blocks. The streak feature keeps me accountable. Genuinely life-changing.", name: "Priya Sharma", title: "Freelance Writer" },
  { quote: "Set it and forget it. Uses less CPU than my cursor blinking. But when I open the dashboard — wow, the insights are incredible.", name: "Tom Andersen", title: "Indie Hacker" },
  { quote: "CSV export let me build a personal dashboard in Notion. My manager now uses my reports as a team productivity template.", name: "Lena Müller", title: "Engineering Lead" },
];

function TestimonialsSection() {
  return (
    <section className="py-32 relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-6">
        <SectionReveal>
          <div className="text-center mb-16">
            <span className="text-sm font-medium text-secondary uppercase tracking-wider">Testimonials</span>
            <h2 className="mt-3 text-4xl md:text-5xl font-bold">
              Loved by{" "}
              <span className="bg-gradient-to-r from-secondary to-primary bg-clip-text text-transparent">focus seekers</span>
            </h2>
          </div>
        </SectionReveal>
        <InfiniteMovingCards items={testimonials} speed="slow" />
      </div>
    </section>
  );
}

// ─── STATS / TRUST ───────────────────────────────────────────────
function StatsSection() {
  const stats = [
    { value: 99, suffix: "%", label: "Detection Accuracy", icon: <Eye className="w-5 h-5" /> },
    { value: 150, suffix: "+", label: "Apps Recognized", icon: <Layers className="w-5 h-5" /> },
    { value: 5000, suffix: "+", label: "Focus Seekers", icon: <Globe2 className="w-5 h-5" /> },
    { value: 0, suffix: "", label: "Data Sent to Cloud", icon: <Lock className="w-5 h-5" /> },
  ];

  return (
    <section className="py-24 relative">
      <div className="absolute inset-0 bg-gradient-to-r from-primary/5 via-secondary/5 to-accent/5 pointer-events-none" />
      <div className="max-w-5xl mx-auto px-6 relative">
        <SectionReveal>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {stats.map((s, i) => (
              <div key={i} className="text-center group">
                <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center text-primary mx-auto mb-4 group-hover:scale-110 transition-transform">
                  {s.icon}
                </div>
                <p className="text-4xl md:text-5xl font-bold bg-gradient-to-b from-foreground to-muted bg-clip-text text-transparent">
                  <AnimatedCounter target={s.value} suffix={s.suffix} />
                </p>
                <p className="mt-2 text-sm text-muted">{s.label}</p>
              </div>
            ))}
          </div>
        </SectionReveal>
      </div>
    </section>
  );
}

// ─── DOWNLOAD CTA ────────────────────────────────────────────────
function DownloadSection() {
  return (
    <section id="download" className="py-32 relative">
      <AuroraBackground />
      <div className="max-w-4xl mx-auto px-6 relative z-10 text-center">
        <SectionReveal>
          <h2 className="text-4xl md:text-6xl font-bold mb-6">
            Ready to{" "}
            <span className="bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">take control?</span>
          </h2>
          <p className="text-lg text-muted mb-12 max-w-xl mx-auto">
            Download FocusTrack for free. No account needed, no data collected, no strings attached.
          </p>

          <div className="flex flex-col sm:flex-row gap-6 justify-center">
            <a
              href="/downloads/focus-track-windows.exe"
              className="group relative flex-1 max-w-sm rounded-2xl bg-card/60 border border-white/10 hover:border-primary/40 p-8 text-center transition-all duration-300 overflow-hidden"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className="relative z-10">
                <Monitor className="w-10 h-10 text-primary mx-auto mb-4" />
                <h3 className="text-xl font-semibold mb-2">Windows</h3>
                <p className="text-sm text-muted mb-4">Windows 10/11 (x64)</p>
                <span className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-primary text-white font-medium group-hover:shadow-lg group-hover:shadow-primary/25 transition-shadow">
                  <Download className="w-4 h-4" /> Download .exe
                </span>
              </div>
            </a>

            <a
              href="/downloads/focus-track-linux.AppImage"
              className="group relative flex-1 max-w-sm rounded-2xl bg-card/60 border border-white/10 hover:border-secondary/40 p-8 text-center transition-all duration-300 overflow-hidden"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-secondary/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className="relative z-10">
                <Database className="w-10 h-10 text-secondary mx-auto mb-4" />
                <h3 className="text-xl font-semibold mb-2">Linux</h3>
                <p className="text-sm text-muted mb-4">Ubuntu, Fedora, Arch (x64)</p>
                <span className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-secondary text-white font-medium group-hover:shadow-lg group-hover:shadow-secondary/25 transition-shadow">
                  <Download className="w-4 h-4" /> Download .AppImage
                </span>
              </div>
            </a>
          </div>

          <p className="mt-8 text-xs text-muted flex items-center justify-center gap-1">
            <Check className="w-3.5 h-3.5 text-success" /> Free &amp; open-source
            <span className="mx-2">·</span>
            <Check className="w-3.5 h-3.5 text-success" /> No sign-up
            <span className="mx-2">·</span>
            <Check className="w-3.5 h-3.5 text-success" /> ~15 MB
          </p>
        </SectionReveal>
      </div>
    </section>
  );
}

// ─── FAQ ─────────────────────────────────────────────────────────
const faqs = [
  { q: "Is FocusTrack really free?", a: "Yes, 100% free and open-source. No premium tiers, no subscriptions, no ads." },
  { q: "Does it send my data anywhere?", a: "Absolutely not. All data is stored locally in a SQLite database on your machine. There is zero network communication — no cloud, no telemetry, no analytics. Your data is yours." },
  { q: "How does it detect apps like Discord or Telegram?", a: "FocusTrack uses native Win32 APIs via Dart FFI to read the foreground window's process path. It then maps executable names to friendly display names using a built-in database of 100+ apps." },
  { q: "Does it work on macOS?", a: "Currently optimized for Windows and Linux. macOS support is experimental — it uses AppleScript for window detection but doesn't have the full feature set yet." },
  { q: "How much CPU does it use?", a: "Less than 0.5%. It polls the active window every 2 seconds using a lightweight FFI call — no Electron, no WebView, just compiled native code." },
  { q: "Can I export my data?", a: "Yes! Export to JSON or CSV from the Analytics screen. Perfect for spreadsheets, Notion, or custom dashboards." },
];

function FAQSection() {
  const [open, setOpen] = useState<number | null>(null);

  return (
    <section id="faq" className="py-32 relative">
      <div className="max-w-3xl mx-auto px-6">
        <SectionReveal>
          <div className="text-center mb-16">
            <span className="text-sm font-medium text-accent uppercase tracking-wider">FAQ</span>
            <h2 className="mt-3 text-4xl md:text-5xl font-bold">
              Frequently asked{" "}
              <span className="bg-gradient-to-r from-accent to-primary bg-clip-text text-transparent">questions</span>
            </h2>
          </div>
        </SectionReveal>

        <div className="space-y-3">
          {faqs.map((faq, i) => (
            <SectionReveal key={i}>
              <div className="rounded-xl border border-white/5 bg-card/30 overflow-hidden">
                <button
                  className="w-full flex items-center justify-between px-6 py-4 text-left hover:bg-white/[0.02] transition-colors"
                  onClick={() => setOpen(open === i ? null : i)}
                >
                  <span className="font-medium text-foreground pr-4">{faq.q}</span>
                  <ChevronDown className={cn("w-4 h-4 text-muted transition-transform flex-shrink-0", open === i && "rotate-180")} />
                </button>
                <AnimatePresence>
                  {open === i && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.2 }}
                    >
                      <p className="px-6 pb-4 text-muted text-sm leading-relaxed">{faq.a}</p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            </SectionReveal>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─── FOOTER ──────────────────────────────────────────────────────
function Footer() {
  return (
    <footer className="py-16 border-t border-white/5">
      <div className="max-w-5xl mx-auto px-6 flex flex-col items-center gap-8">
        <FloatingDock
          items={[
            { icon: <Github className="w-4 h-4 text-muted group-hover:text-foreground transition-colors" />, label: "GitHub", href: "https://github.com" },
            { icon: <Twitter className="w-4 h-4 text-muted group-hover:text-foreground transition-colors" />, label: "X (Twitter)", href: "https://x.com" },
            { icon: <Mail className="w-4 h-4 text-muted group-hover:text-foreground transition-colors" />, label: "Email", href: "mailto:hello@focustrack.app" },
          ]}
        />
        <div className="flex items-center gap-2 text-sm text-muted">
          <Shield className="w-4 h-4 text-success" />
          <span>Everything stays on your machine — no cloud, no telemetry.</span>
        </div>
        <div className="text-xs text-muted/60 text-center">© {new Date().getFullYear()} FocusTrack. Made with ♥ for focus seekers everywhere.</div>
      </div>
    </footer>
  );
}

/* ═══════════════════════════════════════════════════════════════════
   MAIN PAGE
   ═══════════════════════════════════════════════════════════════════ */

export default function LandingPage() {
  return (
    <main className="bg-background text-foreground overflow-hidden">
      <Navbar />
      <HeroSection />
      <FeaturesSection />
      <HowItWorksSection />
      <TestimonialsSection />
      <StatsSection />
      <DownloadSection />
      <FAQSection />
      <Footer />
    </main>
  );
}
