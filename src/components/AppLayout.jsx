import { NavLink, Link, useLocation, useNavigate } from 'react-router-dom'
import { useCallback, useEffect, useRef, useState } from 'react'
import { accountStorage, getCurrentAccount, logoutAccount } from '../auth'
import { supabase } from '../lib/supabaseClient'

const notificationSelect = 'id, recipient_id, actor_id, connection_request_id, type, read_at, created_at, actor:profiles!notifications_actor_id_fkey(full_name)'

const notificationCopy = {
  request_received: 'đã gửi cho cậu một lời mời kết nối.',
  request_accepted: 'đã chấp nhận lời mời kết nối của cậu.',
  request_declined: 'đã từ chối lời mời kết nối của cậu.',
  request_cancelled: 'đã hủy lời mời kết nối đã gửi cho cậu.',
  connection_disconnected: 'đã ngắt kết nối với cậu.',
}

function getNotificationMessage(notification) {
  const actorName = notification.actor?.full_name?.trim() || 'Một sinh viên'
  return `${actorName} ${notificationCopy[notification.type] || 'đã cập nhật kết nối với cậu.'}`
}

function formatNotificationTime(value) {
  const date = new Date(value)

  if (Number.isNaN(date.getTime())) return ''

  return new Intl.DateTimeFormat('vi-VN', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(date)
}

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
    arrow: <><path d="M5 12h13"/><path d="m13 6 6 6-6 6"/></>,
    spark: <><path d="m12 3 1.6 5.4L19 10l-5.4 1.6L12 17l-1.6-5.4L5 10l5.4-1.6L12 3Z"/><path d="m19 16 .7 2.3L22 19l-2.3.7L19 22l-.7-2.3L16 19l2.3-.7L19 16Z"/></>,
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
  const navigate = useNavigate()
  const mainRef = useRef(null)
  const notificationRootRef = useRef(null)
  const notificationButtonRef = useRef(null)
  const notificationPanelRef = useRef(null)
  const notificationChannelRef = useRef(null)
  const notificationUserIdRef = useRef(null)
  const notificationsMountedRef = useRef(false)
  const [logoutError, setLogoutError] = useState('')
  const [notifications, setNotifications] = useState([])
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [notificationsLoading, setNotificationsLoading] = useState(true)
  const [notificationsError, setNotificationsError] = useState('')
  const [notificationAnnouncement, setNotificationAnnouncement] = useState('')
  const fullName = getProfileName()
  const avatarLetter = fullName.split(/\s+/).pop()[0].toUpperCase()
  const pageTitle = pageTitles[location.pathname] || 'CocoApp'
  const unreadNotificationCount = notifications.filter(
    (notification) => notification.read_at === null
  ).length

  const loadNotifications = useCallback(async ({ silent = false } = {}) => {
    const userId = notificationUserIdRef.current
    if (!userId) return

    if (!silent && notificationsMountedRef.current) {
      setNotificationsLoading(true)
    }

    const { data, error } = await supabase
      .from('notifications')
      .select(notificationSelect)
      .eq('recipient_id', userId)
      .order('created_at', { ascending: false })
      .limit(30)

    if (!notificationsMountedRef.current) return

    if (error) {
      setNotificationsError('Chưa tải được thông báo. Hãy thử mở lại chuông.')
    } else {
      setNotifications(data || [])
      setNotificationsError('')
    }

    setNotificationsLoading(false)
  }, [])

  useEffect(() => {
    mainRef.current?.focus({ preventScroll: true })
  }, [location.pathname])

  useEffect(() => {
    let cancelled = false
    notificationsMountedRef.current = true

    async function setupNotifications() {
      try {
        const user = await getCurrentAccount()
        if (!user || cancelled) return

        notificationUserIdRef.current = user.id
        await loadNotifications()
        if (cancelled) return

        const channel = supabase
          .channel(`notifications:${user.id}`)
          .on(
            'postgres_changes',
            {
              event: '*',
              schema: 'public',
              table: 'notifications',
              filter: `recipient_id=eq.${user.id}`,
            },
            (payload) => {
              if (payload.eventType === 'INSERT') {
                const incoming = { ...payload.new, actor: null }
                setNotifications((current) => (
                  current.some((item) => item.id === incoming.id)
                    ? current
                    : [incoming, ...current].slice(0, 30)
                ))
                setNotificationAnnouncement(getNotificationMessage(incoming))
              } else if (payload.eventType === 'UPDATE') {
                setNotifications((current) => current.map((item) => (
                  item.id === payload.new.id
                    ? { ...item, read_at: payload.new.read_at }
                    : item
                )))
              }

              void loadNotifications({ silent: true })
            }
          )
          .subscribe((status) => {
            if (status === 'CHANNEL_ERROR' && notificationsMountedRef.current) {
              setNotificationsError('Kết nối thông báo trực tiếp đang gián đoạn. Dữ liệu sẽ tải lại khi cậu mở chuông.')
            }
          })

        notificationChannelRef.current = channel
      } catch {
        if (notificationsMountedRef.current) {
          setNotificationsLoading(false)
          setNotificationsError('Chưa tải được thông báo. Hãy thử mở lại chuông.')
        }
      }
    }

    function handleWindowFocus() {
      void loadNotifications({ silent: true })
    }

    window.addEventListener('focus', handleWindowFocus)
    void setupNotifications()

    return () => {
      cancelled = true
      notificationsMountedRef.current = false
      notificationUserIdRef.current = null
      window.removeEventListener('focus', handleWindowFocus)

      if (notificationChannelRef.current) {
        void supabase.removeChannel(notificationChannelRef.current)
        notificationChannelRef.current = null
      }
    }
  }, [loadNotifications])

  useEffect(() => {
    if (!notificationsOpen) return undefined

    void loadNotifications({ silent: true })
    window.requestAnimationFrame(() => {
      notificationPanelRef.current?.querySelector('button:not(:disabled)')?.focus({ preventScroll: true })
    })

    function handlePointerDown(event) {
      if (!notificationRootRef.current?.contains(event.target)) {
        setNotificationsOpen(false)
      }
    }

    function handleKeyDown(event) {
      if (event.key === 'Escape') {
        setNotificationsOpen(false)
        notificationButtonRef.current?.focus({ preventScroll: true })
      }
    }

    document.addEventListener('mousedown', handlePointerDown)
    document.addEventListener('keydown', handleKeyDown)

    return () => {
      document.removeEventListener('mousedown', handlePointerDown)
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [loadNotifications, notificationsOpen])

  async function markNotificationRead(notification) {
    setNotificationsOpen(false)

    if (notification.read_at === null) {
      const readAt = new Date().toISOString()
      setNotifications((current) => current.map((item) => (
        item.id === notification.id ? { ...item, read_at: readAt } : item
      )))

      const { error } = await supabase
        .from('notifications')
        .update({ read_at: readAt })
        .eq('id', notification.id)
        .is('read_at', null)

      if (error) {
        setNotificationsError('Chưa đánh dấu được thông báo là đã đọc.')
      }
    }

    navigate('/matches')
  }

  async function markAllNotificationsRead() {
    const userId = notificationUserIdRef.current
    if (!userId || unreadNotificationCount === 0) return

    const readAt = new Date().toISOString()
    setNotifications((current) => current.map((notification) => (
      notification.read_at === null
        ? { ...notification, read_at: readAt }
        : notification
    )))

    const { error } = await supabase
      .from('notifications')
      .update({ read_at: readAt })
      .eq('recipient_id', userId)
      .is('read_at', null)

    if (error) {
      setNotificationsError('Chưa đánh dấu được tất cả thông báo là đã đọc.')
      await loadNotifications({ silent: true })
    }
  }

  async function handleLogout(event) {
    event.preventDefault()

    try {
      await logoutAccount()

      if (notificationChannelRef.current) {
        await supabase.removeChannel(notificationChannelRef.current)
        notificationChannelRef.current = null
      }

      window.location.assign('/login')
    } catch {
      setLogoutError('Không thể đăng xuất. Hãy tải lại trang và thử lại.')
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
          <span><Icon name="spark" /> GỢI Ý</span>
          <strong>Hồ sơ tốt tạo kết nối tốt hơn</strong>
          <Link to="/profile">Hoàn thiện hồ sơ</Link>
        </div>

        <div className="sidebar-bottom">
          <NavLink to="/profile" className="student-card sidebar-user-link">
            <div className="student-avatar">{avatarLetter}</div>
            <div><strong>{fullName}</strong><span>Xem hồ sơ</span></div>
          </NavLink>

          <a href="/login" className="logout-button" onClick={handleLogout} aria-label="Đăng xuất">
            <Icon name="logout"/><span>Đăng xuất</span>
          </a>
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
            <div className="notification-menu" ref={notificationRootRef}>
              <button
                ref={notificationButtonRef}
                type="button"
                className="topbar-icon-button"
                aria-label={`Thông báo${unreadNotificationCount > 0 ? `, ${unreadNotificationCount} chưa đọc` : ''}`}
                aria-haspopup="dialog"
                aria-expanded={notificationsOpen}
                aria-controls="notification-panel"
                onClick={() => setNotificationsOpen((current) => !current)}
              >
                <Icon name="bell" />
                {unreadNotificationCount > 0 && (
                  <span className="notification-badge" aria-hidden="true">
                    {unreadNotificationCount > 99 ? '99+' : unreadNotificationCount}
                  </span>
                )}
              </button>

              {notificationsOpen && (
                <section
                  ref={notificationPanelRef}
                  id="notification-panel"
                  className="notification-panel"
                  role="dialog"
                  aria-label="Thông báo kết nối"
                >
                  <header className="notification-panel-header">
                    <div>
                      <span>COCO CAMPUS</span>
                      <h2>Thông báo</h2>
                    </div>
                    <button
                      type="button"
                      className="notification-mark-all"
                      disabled={unreadNotificationCount === 0}
                      onClick={markAllNotificationsRead}
                    >
                      Đánh dấu tất cả đã đọc
                    </button>
                  </header>

                  {notificationsError && (
                    <p className="notification-error" role="alert">{notificationsError}</p>
                  )}

                  <div className="notification-list">
                    {notificationsLoading ? (
                      <p className="notification-empty" role="status">Đang tải thông báo…</p>
                    ) : notifications.length === 0 ? (
                      <p className="notification-empty">Chưa có thông báo mới.</p>
                    ) : notifications.map((notification) => (
                      <button
                        key={notification.id}
                        type="button"
                        className={`notification-item ${notification.read_at === null ? 'is-unread' : ''}`}
                        onClick={() => markNotificationRead(notification)}
                      >
                        <span className="notification-item-icon" aria-hidden="true">
                          <Icon name="connection" />
                        </span>
                        <span className="notification-item-copy">
                          <strong>{getNotificationMessage(notification)}</strong>
                          <small>{formatNotificationTime(notification.created_at)}</small>
                        </span>
                        {notification.read_at === null && (
                          <span className="notification-unread-dot">
                            <span className="notification-sr-only">Chưa đọc</span>
                          </span>
                        )}
                      </button>
                    ))}
                  </div>
                </section>
              )}
            </div>
            <Link to="/profile" className="topbar-account">
              <span className="mobile-avatar">{avatarLetter}</span>
              <span><strong>{fullName}</strong><small>Sinh viên</small></span>
            </Link>
          </div>
        </header>

        {logoutError && (
          <div className="shell-status-message" role="alert" aria-live="assertive">
            {logoutError}
          </div>
        )}

        <p className="notification-live-region" aria-live="polite" aria-atomic="true">
          {notificationAnnouncement}
        </p>

        <main ref={mainRef} className="app-content" tabIndex="-1">{children}</main>
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
