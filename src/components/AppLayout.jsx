import { NavLink, Link, useLocation } from 'react-router-dom'
import { accountStorage, logoutAccount } from '../auth'

function getProfileName() {
  try {
    const profile = JSON.parse(accountStorage.getItem('cocoapp.profile.v1') || 'null')
    return typeof profile?.fullName === 'string'
      ? profile.fullName.trim() || 'Sinh viên'
      : 'Sinh viên'
  } catch {
    return 'Sinh viên'
  }
}

export function Icon({ name }) {
  const paths = {
    dashboard: <><path d="M4 13h6V4H4v9Zm10 7h6v-9h-6v9ZM4 20h6v-3H4v3Zm10-13h6V4h-6v3Z"/></>,
    discover: <><circle cx="11" cy="11" r="7"/><path d="m16.5 16.5 4 4"/><path d="m13.5 8.5-1.4 3.6-3.6 1.4 1.4-3.6 3.6-1.4Z"/></>,
    study: <><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H11v17H6.5A2.5 2.5 0 0 0 4 22V5.5Z"/><path d="M20 5.5A2.5 2.5 0 0 0 17.5 3H13v17h4.5A2.5 2.5 0 0 1 20 22V5.5Z"/></>,
    team: <><circle cx="9" cy="8" r="3"/><path d="M3 21v-2a6 6 0 0 1 12 0v2"/><path d="M16 5.2a3 3 0 0 1 0 5.6"/><path d="M18 13.4A6 6 0 0 1 21 19v2"/></>,
    room: <><path d="m3 11 9-7 9 7"/><path d="M5.5 9.5V20h13V9.5"/><path d="M9 14h6"/></>,
    connection: <><path d="M8.5 12a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"/><path d="M2.5 21v-2a6 6 0 0 1 12 0v2"/><path d="M16 8h5m-2.5-2.5V10.5"/></>,
    profile: <><circle cx="12" cy="8" r="3.2"/><path d="M5 21v-2a7 7 0 0 1 14 0v2"/></>,
    bell: <><path d="M18 8a6 6 0 1 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/><path d="M10 21h4"/></>,
    logout: <><path d="M10 17l5-5-5-5"/><path d="M15 12H3"/><path d="M14 3h4a3 3 0 0 1 3 3v12a3 3 0 0 1-3 3h-4"/></>,
  }

  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {paths[name]}
    </svg>
  )
}

const menuItems = [
  { to: '/dashboard', icon: 'dashboard', label: 'Tổng quan', hint: 'Trang chủ' },
  { to: '/discover', icon: 'discover', label: 'Khám phá', hint: 'Tìm người phù hợp' },
  { to: '/study', icon: 'study', label: 'Học nhóm', hint: 'Cùng tiến bộ' },
  { to: '/team', icon: 'team', label: 'Team Project', hint: 'Cùng làm dự án' },
  { to: '/roommates', icon: 'room', label: 'Ghép trọ', hint: 'Ở cùng an toàn' },
  { to: '/matches', icon: 'connection', label: 'Kết nối', hint: 'Lời mời & chat' },
]

const mobileMenuItems = [
  menuItems[0],
  menuItems[1],
  menuItems[5],
  { to: '/profile', icon: 'profile', label: 'Hồ sơ', hint: 'Thông tin của cậu' },
]

const pageTitles = {
  '/dashboard': 'Tổng quan',
  '/discover': 'Khám phá cộng đồng',
  '/study': 'Tìm bạn học',
  '/team': 'Tìm team project',
  '/roommates': 'Tìm bạn ghép trọ',
  '/matches': 'Kết nối của bạn',
  '/profile': 'Hồ sơ cá nhân',
}

export default function AppLayout({ children }) {
  const location = useLocation()
  const fullName = getProfileName()
  const avatarLetter = fullName.split(/\s+/).pop()[0].toUpperCase()
  const pageTitle = pageTitles[location.pathname] || 'CocoApp'

  function handleLogout(event) {
    try {
      logoutAccount()
    } catch {
      event.preventDefault()
      alert('Không thể đăng xuất. Hãy tải lại trang và thử lại.')
    }
  }

  return (
    <div className="app-shell product-shell">
      <aside className="app-sidebar product-sidebar">
        <Link to="/dashboard" className="app-brand product-brand" aria-label="CocoApp">
          <span className="app-brand-icon">C</span>
          <span className="app-brand-name">Coco<span>.</span></span>
        </Link>

        <div className="workspace-pill">
          <span className="workspace-dot" />
          <div>
            <strong>Campus space</strong>
            <span>Cộng đồng sinh viên</span>
          </div>
        </div>

        <p className="sidebar-label">ĐIỀU HƯỚNG</p>

        <nav className="sidebar-nav" aria-label="Điều hướng chính">
          {menuItems.map((item) => (
            <NavLink key={item.to} to={item.to} className={({ isActive }) => `sidebar-link ${isActive ? 'active' : ''}`}>
              <span className="sidebar-icon"><Icon name={item.icon}/></span>
              <span className="sidebar-link-copy">
                <strong>{item.label}</strong>
                <small>{item.hint}</small>
              </span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-promo">
          <span>✨ GỢI Ý</span>
          <strong>Hồ sơ tốt tạo kết nối tốt hơn</strong>
          <Link to="/profile">Hoàn thiện hồ sơ</Link>
        </div>

        <div className="sidebar-bottom">
          <NavLink to="/profile" className="student-card sidebar-user-link">
            <div className="student-avatar">{avatarLetter}</div>
            <div><strong>{fullName}</strong><span>Xem hồ sơ</span></div>
          </NavLink>

          <Link to="/login" replace className="logout-button" onClick={handleLogout} aria-label="Đăng xuất">
            <Icon name="logout"/><span>Đăng xuất</span>
          </Link>
        </div>
      </aside>

      <div className="product-main">
        <header className="product-topbar">
          <div className="topbar-title">
            <span>COCO COMMUNITY</span>
            <strong>{pageTitle}</strong>
          </div>

          <div className="topbar-actions">
            <span className="demo-status"><i /> Prototype</span>
            <Link to="/matches" className="topbar-icon-button" aria-label="Mở kết nối"><Icon name="bell"/><b /></Link>
            <Link to="/profile" className="topbar-account">
              <span className="mobile-avatar">{avatarLetter}</span>
              <span><strong>{fullName}</strong><small>Sinh viên</small></span>
            </Link>
          </div>
        </header>

        <main className="app-content">{children}</main>
      </div>

      <nav className="mobile-bottom-nav" aria-label="Điều hướng điện thoại">
        {mobileMenuItems.map((item) => (
          <NavLink key={item.to} to={item.to} className={({ isActive }) => isActive ? 'active' : ''}>
            <Icon name={item.icon}/><span>{item.label}</span>
          </NavLink>
        ))}
      </nav>
    </div>
  )
}
