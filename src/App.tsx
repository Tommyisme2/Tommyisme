import { useEffect, useMemo, useState, type ReactNode } from "react";
import "./App.css";
import { useActiveSection } from "./hooks/useActiveSection";
import { useReveal } from "./hooks/useReveal";
import { useScrolled } from "./hooks/useScrolled";

const NAV = [
  { id: "focus", label: "Focus" },
  { id: "practice", label: "Practice" },
  { id: "signal", label: "Signal" },
  { id: "connect", label: "Connect" },
] as const;

const FOCUS = [
  {
    title: "Product clarity",
    body: "Interfaces that read as one idea—tight hierarchy, honest copy, and no decorative noise.",
  },
  {
    title: "Crafted motion",
    body: "Motion that marks presence and state, never spectacle. Small, timed, and purposeful.",
  },
  {
    title: "Finished feel",
    body: "Spacing, focus, and edge cases treated as first-class so the product feels buttoned up.",
  },
] as const;

const PRACTICE = [
  {
    title: "Frame the job",
    body: "Start with the one thing the screen must do, then cut everything that competes with it.",
  },
  {
    title: "Build in the open",
    body: "Ship interactive structure early. Refine type, rhythm, and response once the path is clear.",
  },
  {
    title: "Tighten the last mile",
    body: "Hover, focus, scroll, and empty states get equal attention—polish is cumulative.",
  },
] as const;

const SIGNALS = [
  {
    title: "Atelier OS",
    year: "2026",
    desc: "A calm operations surface for small studios—lists first, cards nowhere.",
  },
  {
    title: "Northline",
    year: "2025",
    desc: "Editorial commerce with a full-bleed hero and a scroll that earns every section.",
  },
  {
    title: "Pulse Ledger",
    year: "2025",
    desc: "Dense data made legible through pacing, not chrome.",
  },
] as const;

function Reveal({
  children,
  className = "",
  delay = 0,
}: {
  children: ReactNode;
  className?: string;
  delay?: number;
}) {
  const ref = useReveal<HTMLDivElement>();

  return (
    <div
      ref={ref}
      className={`reveal ${className}`.trim()}
      style={delay ? { transitionDelay: `${delay}ms` } : undefined}
    >
      {children}
    </div>
  );
}

function useScrollProgress() {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const onScroll = () => {
      const doc = document.documentElement;
      const max = doc.scrollHeight - doc.clientHeight;
      setProgress(max > 0 ? doc.scrollTop / max : 0);
    };

    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);
    return () => {
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
    };
  }, []);

  return progress;
}

function scrollToId(id: string) {
  const el = document.getElementById(id);
  if (!el) return;
  el.scrollIntoView({ behavior: "smooth", block: "start" });
}

export default function App() {
  const sectionIds = useMemo(() => NAV.map((item) => item.id), []);
  const activeId = useActiveSection(sectionIds);
  const scrolled = useScrolled(20);
  const progress = useScrollProgress();
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    document.body.style.overflow = menuOpen ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [menuOpen]);

  const goTo = (id: string) => {
    setMenuOpen(false);
    scrollToId(id);
  };

  return (
    <div className="app">
      <div
        className="scroll-progress"
        style={{ ["--progress" as string]: progress }}
        aria-hidden="true"
      />

      <a className="skip-link" href="#main">
        Skip to content
      </a>

      <header className={`site-header${scrolled ? " is-scrolled" : ""}`}>
        <div className="header-inner">
          <a className="brand-mark" href="#top" onClick={() => setMenuOpen(false)}>
            Tommyisme
          </a>

          <nav className="nav" aria-label="Primary">
            {NAV.map((item) => (
              <a
                key={item.id}
                className={`nav-link${activeId === item.id ? " is-active" : ""}`}
                href={`#${item.id}`}
                onClick={(event) => {
                  event.preventDefault();
                  goTo(item.id);
                }}
              >
                {item.label}
              </a>
            ))}
          </nav>

          <button
            type="button"
            className="menu-toggle"
            aria-label={menuOpen ? "Close menu" : "Open menu"}
            aria-expanded={menuOpen}
            aria-controls="mobile-nav"
            onClick={() => setMenuOpen((open) => !open)}
          >
            <span className="menu-toggle-bars" aria-hidden="true">
              <span />
              <span />
              <span />
            </span>
          </button>
        </div>

        <nav
          id="mobile-nav"
          className={`mobile-nav${menuOpen ? " is-open" : ""}`}
          aria-label="Mobile"
        >
          {NAV.map((item) => (
            <a
              key={item.id}
              className={`nav-link${activeId === item.id ? " is-active" : ""}`}
              href={`#${item.id}`}
              onClick={(event) => {
                event.preventDefault();
                goTo(item.id);
              }}
            >
              {item.label}
            </a>
          ))}
        </nav>
      </header>

      <main id="main">
        <section className="hero" id="top" aria-label="Introduction">
          <div className="hero-media" aria-hidden="true">
            <img
              src="https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=2400&q=80"
              alt=""
              width={2400}
              height={1600}
              fetchPriority="high"
            />
            <div className="hero-veil" />
          </div>

          <div className="hero-content">
            <h1 className="hero-brand">Tommyisme</h1>
            <p className="hero-line">
              Considered digital craft for products that feel finished from the first scroll.
            </p>
            <div className="hero-actions">
              <a
                className="btn btn-primary"
                href="#connect"
                onClick={(event) => {
                  event.preventDefault();
                  goTo("connect");
                }}
              >
                Start a project
                <span className="btn-arrow" aria-hidden="true">
                  →
                </span>
              </a>
              <a
                className="btn btn-ghost"
                href="#signal"
                onClick={(event) => {
                  event.preventDefault();
                  goTo("signal");
                }}
              >
                See the work
              </a>
            </div>
          </div>
        </section>

        <section className="section" id="focus" aria-labelledby="focus-title">
          <Reveal>
            <p className="section-label">Focus</p>
            <h2 className="section-title" id="focus-title">
              One composition, then the rest earns its place.
            </h2>
            <p className="section-copy">
              Tommyisme is a practice of restraint: brand first, clear hierarchy, and interaction
              that feels precise rather than flashy.
            </p>
          </Reveal>

          <div className="focus-grid">
            {FOCUS.map((item, index) => (
              <Reveal key={item.title} delay={index * 80}>
                <article className="focus-item">
                  <h3>{item.title}</h3>
                  <p>{item.body}</p>
                </article>
              </Reveal>
            ))}
          </div>
        </section>

        <section className="practice" id="practice" aria-labelledby="practice-title">
          <div className="section">
            <Reveal>
              <p className="section-label">Practice</p>
              <h2 className="section-title" id="practice-title">
                A short path from intent to polish.
              </h2>
              <p className="section-copy">
                Fewer handoffs. Tighter loops. Every pass makes the product more deliberate.
              </p>
            </Reveal>

            <div className="practice-steps">
              {PRACTICE.map((step, index) => (
                <Reveal key={step.title} delay={index * 70}>
                  <article className="practice-step">
                    <span className="practice-index" aria-hidden="true">
                      {String(index + 1).padStart(2, "0")}
                    </span>
                    <div>
                      <h3>{step.title}</h3>
                      <p>{step.body}</p>
                    </div>
                  </article>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

        <section className="section" id="signal" aria-labelledby="signal-title">
          <Reveal>
            <p className="section-label">Signal</p>
            <h2 className="section-title" id="signal-title">
              Selected work, kept lean.
            </h2>
            <p className="section-copy">
              Projects chosen for clarity of purpose—not a wall of case-study cards.
            </p>
          </Reveal>

          <div className="signal-list">
            {SIGNALS.map((item, index) => (
              <Reveal key={item.title} delay={index * 60}>
                <button
                  type="button"
                  className="signal-row"
                  onClick={() => goTo("connect")}
                >
                  <div className="signal-meta">
                    <span className="signal-title">{item.title}</span>
                    <span className="signal-year">{item.year}</span>
                  </div>
                  <p className="signal-desc">{item.desc}</p>
                </button>
              </Reveal>
            ))}
          </div>
        </section>

        <section className="section connect" id="connect" aria-labelledby="connect-title">
          <Reveal>
            <p className="section-label">Connect</p>
            <h2 className="section-title" id="connect-title">
              Ready when you are.
            </h2>
          </Reveal>

          <Reveal delay={90}>
            <div className="connect-panel">
              <p className="connect-note">
                Share the product, the constraint, and the feeling you want people to leave with.
                We’ll tighten the rest.
              </p>
              <div className="connect-actions">
                <a className="btn btn-accent" href="mailto:hello@tommyisme.com">
                  Email Tommyisme
                  <span className="btn-arrow" aria-hidden="true">
                    →
                  </span>
                </a>
                <a
                  className="btn btn-quiet"
                  href="#top"
                  onClick={(event) => {
                    event.preventDefault();
                    window.scrollTo({ top: 0, behavior: "smooth" });
                  }}
                >
                  Back to top
                </a>
              </div>
            </div>
          </Reveal>
        </section>
      </main>

      <footer className="site-footer">
        <div className="footer-inner">
          <span className="footer-brand">Tommyisme</span>
          <span>Digital craft · {new Date().getFullYear()}</span>
        </div>
      </footer>
    </div>
  );
}
