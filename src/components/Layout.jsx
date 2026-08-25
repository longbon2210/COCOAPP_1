import { Link } from 'react-router-dom'

export default function Layout({ children }) {
  return (
    <div className="coco-app">
      {/* Header */}
      <header className="coco-header">
        <Link to="/login" className="brand-container" title="Coco App Home">
          <div className="logo-badge" aria-hidden="true">
            {/* Custom Coco heart/connection spark SVG icon */}
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path
                d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"
                fill="currentColor"
              />
            </svg>
          </div>
          <span className="brand-name">
            Coco<span className="brand-dot">.</span>
          </span>
        </Link>

        <div className="header-tagline">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
            <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
          </svg>
          <span>Campus Portal</span>
        </div>
      </header>

      {/* Main Container */}
      <main className="coco-main">
        {children}
      </main>

      {/* Footer */}
      <footer className="coco-footer">
        <p>© 2026 Coco App. Connecting university students worldwide.</p>
        <div className="footer-links">
          <a href="#privacy" className="footer-link">Privacy Policy</a>
          <span>•</span>
          <a href="#terms" className="footer-link">Terms of Service</a>
          <span>•</span>
          <a href="#help" className="footer-link">Campus Support</a>
        </div>
      </footer>
    </div>
  )
}
