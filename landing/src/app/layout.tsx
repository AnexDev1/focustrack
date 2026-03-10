import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "FocusTrack — Reclaim Your Focus. Understand Your Time.",
  description:
    "The powerful, privacy-first desktop screen time tracker for Windows & Linux. Accurate app detection, smart limits, beautiful insights. 100% local.",
  openGraph: {
    title: "FocusTrack — Reclaim Your Focus",
    description:
      "Advanced desktop screen time & focus tracker. Detects every app, no cloud, no telemetry.",
    type: "website",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "FocusTrack — Reclaim Your Focus",
    description:
      "Advanced desktop screen time & focus tracker. 100% local, zero tracking.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
