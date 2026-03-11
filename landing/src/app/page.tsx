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

const releaseLinks = {
  windowsExe: "https://github.com/AnexDev1/focustrack/releases/latest/download/FocusTrack-Setup-0.1.0.exe",
  linuxAppImage: "https://github.com/AnexDev1/focustrack/releases/latest/download/FocusTrack-x86_64.AppImage",
  linuxInstaller: "https://github.com/AnexDev1/focustrack/releases/latest/download/FocusTrack-Linux-Installer.sh",
  linuxBridgeZip: "https://github.com/AnexDev1/focustrack/releases/latest/download/focustrack-gnome-window-bridge.zip",
};

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

//... [rest of page.tsx contents truncated for brevity in patch, but include full file similar to earlier snippet]
