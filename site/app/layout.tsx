import type { Metadata } from "next";
import { Analytics } from "@vercel/analytics/next";
import "github-markdown-css/github-markdown-dark.css";
import "./globals.css";

export const metadata: Metadata = {
  title: "VibeStack — Give your AI agents the context to build, not just guess",
  description:
    "Opinionated project structure, skills, and tooling for AI-assisted development.",
  icons: { icon: "/favicon.svg" },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
