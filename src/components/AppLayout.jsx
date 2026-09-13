import { NavLink, Link } from 'react-router-dom'
import { accountStorage, logoutAccount } from '../auth'
function getProfileName() {
  try {
    const profile = JSON.parse(
      accountStorage.getItem('cocoapp.profile.v1') || 'null'
    )

    return typeof profile?.fullName === 'string'
      ? profile.fullName.trim() || 'Sinh viên'
      : 'Sinh viên'
  } catch {
    return 'Sinh viên'
  }
}

const menuItems = [
  { to: '/dashboard', icon: '⌂', label: 'Tổng quan' },
  { to: '/discover', icon: '◌', label: 'Khám phá' },
  { to: '/study', icon: '◫', label: 'Học nhóm' },
  { to: '/team', icon: '♧', label: 'Team Project' },
  { to: '/roommates', icon: '⌂', label: 'Ghép trọ' },
 {
  to: '/matches',
  label: 'Kết nối',
  icon: (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <circle cx="9" cy="8" r="3" />
      <path d="M3 21v-2a6 6 0 0 1 12 0v2" />
      <path d="M16 5a3 3 0 0 1 0 6" />
      <path d="M21 21v-2a6 6 0 0 0-4-5.65" />
    </svg>
  ),
},
]

export default function AppLayout({ children }) {
    const fullName = getProfileName()
  const avatarLetter = fullName.split(/\s+/).pop()[0].toUpperCase()
  return (
    <div className="app-shell">
      <aside className="app-sidebar">
        <Link to="/dashboard" className="app-brand">
          <span className="app-brand-icon">C</span>
          <span>Coco<span>.</span></span>
        </Link>

        <p className="sidebar-label">KHÔNG GIAN CỦA BẠN</p>

        <nav className="sidebar-nav">
          {menuItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `sidebar-link ${isActive ? 'active' : ''}`
              }
            >
              <span className="sidebar-icon">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-bottom">
          <NavLink to="/profile" className="sidebar-link">
            <span className="sidebar-icon">◎</span>
            Hồ sơ của tôi
          </NavLink>

      <Link
  to="/login"
  replace
  className="logout-button"
  onClick={(event) => {
    try {
      logoutAccount()
    } catch {
      event.preventDefault()
      alert('Không thể đăng xuất. Hãy tải lại trang và thử lại.')
    }
  }}
  style={{
    display: 'block',
    boxSizing: 'border-box',
    textDecoration: 'none',
  }}
>
  Đăng xuất
</Link>

          <div className="student-card">
          <div className="student-avatar">{avatarLetter}</div>
            <div>
             <strong>{fullName}</strong>
              <span>Sinh viên</span>
            </div>
          </div>
        </div>
      </aside>

      <main className="app-content">{children}</main>
    </div>
  )
}