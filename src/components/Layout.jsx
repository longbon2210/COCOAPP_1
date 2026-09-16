import { Link } from 'react-router-dom'

export default function Layout({ children }) {
  return (
    <div className="coco-app">
      {/* Header */}
      <header className="coco-header">
        <Link to="/login" className="brand-container" title="Coco App Home">
          <div className="logo-badge" aria-hidden="true">
            <svg width="25" height="25" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <circle cx="7" cy="8" r="2.5" fill="currentColor" />
              <circle cx="17" cy="7" r="2.5" fill="currentColor" />
              <circle cx="12" cy="17" r="2.5" fill="currentColor" />
              <path d="M9.2 9.2 11 14.6M14.4 14.8l1.8-5.4M9.4 7.8h5.1" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
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
          <span>Student Community</span>
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
