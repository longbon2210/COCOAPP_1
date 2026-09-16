import { useState } from 'react'
import { Link } from 'react-router-dom'
import AppLayout, { Icon } from '../components/AppLayout'
import { accountStorage } from '../auth'

const profileFields = [
  'fullName',
  'university',
  'major',
  'studyYear',
  'gender',
  'purpose',
  'bio',
  'city',
  'area',
  'publicLocation',
  'maxDistance',
]

const quickActions = [
  {
    to: '/study',
    icon: 'study',
    title: 'Tìm bạn học',
    text: 'Cùng ôn bài, luyện đề và trao đổi kiến thức.',
    color: 'blue',
  },
  {
    to: '/team',
    icon: 'team',
    title: 'Tìm team project',
    text: 'Tìm người có kỹ năng phù hợp với dự án.',
    color: 'orange',
  },
  {
    to: '/roommates',
    icon: 'room',
    title: 'Tìm bạn ghép trọ',
    text: 'Lọc theo giới tính, thành phố và khu vực.',
    color: 'green',
  },
]

function readDashboard() {
  const warnings = []
  let profile = {}
  let connections = []

  try {
    const raw = accountStorage.getItem('cocoapp.profile.v1')

    if (raw) {
      const parsed = JSON.parse(raw)

      if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
        throw new Error('Invalid profile')
      }

      profile = parsed
    }
  } catch {
    warnings.push('Không đọc được hồ sơ đã lưu.')
  }

  try {
    const raw = accountStorage.getItem('cocoapp.connections.v1')

    if (raw) {
      const parsed = JSON.parse(raw)

      if (
        !Array.isArray(parsed) ||
        !parsed.every(
          (item) =>
            item &&
            typeof item.id === 'number' &&
            typeof item.name === 'string' &&
            ['pending', 'accepted'].includes(item.status)
        )
      ) {
        throw new Error('Invalid connections')
      }

      connections = parsed
    }
  } catch {
    warnings.push('Không đọc được danh sách kết nối.')
  }

  return { profile, connections, warnings }
}

export default function Dashboard() {
  const [data] = useState(readDashboard)
  const { profile, connections, warnings } = data

  const fullName =
    typeof profile.fullName === 'string'
      ? profile.fullName.trim()
      : ''

  const displayName = fullName
    ? fullName.split(/\s+/).pop()
    : 'cậu'

  const completedFields = profileFields.filter(
    (key) =>
      typeof profile[key] === 'string' &&
      profile[key].trim() !== ''
  ).length

  const completion = Math.round(
    (completedFields / profileFields.length) * 100
  )

  const pending = connections.filter(
    (item) => item.status === 'pending'
  ).length

  const accepted = connections.filter(
    (item) => item.status === 'accepted'
  ).length

  const recentConnections = connections.slice(-3).reverse()

  const dateLabel = new Intl.DateTimeFormat('vi-VN', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(new Date())

  return (
    <AppLayout>
      <section className="dashboard-page">
        <header className="dashboard-topbar">
          <div>
            <p className="page-eyebrow">{dateLabel}</p>
            <h1>Chào {displayName}, hôm nay cậu muốn làm gì?</h1>
            <p className="page-description">
              Tìm người đồng hành cho việc học, dự án và cuộc sống sinh viên.
            </p>
          </div>

          <div className="dashboard-head-actions">
            <Link to="/profile" className="secondary-action">Chỉnh hồ sơ</Link>
            <Link to="/discover" className="primary-action">Khám phá ngay</Link>
          </div>
        </header>

        {warnings.length > 0 && (
          <div className="form-error-banner" role="alert">
            {warnings.join(' ')} Dữ liệu hiện có chưa bị thay đổi.
          </div>
        )}

        <div className="dashboard-hero-grid">
          <div className="dashboard-banner">
            <div>
              <span className="banner-tag">
                {completion === 100 ? 'SẴN SÀNG KẾT NỐI' : 'HỒ SƠ CỦA CẬU'}
              </span>

              <h2>
                {completion === 100
                  ? 'Hồ sơ đã đầy đủ. Tìm người đồng hành thôi!'
                  : `Cậu đã hoàn thiện ${completion}% hồ sơ`}
              </h2>

              <p>
                {completion === 100
                  ? 'Khám phá sinh viên theo mục tiêu và khu vực mong muốn.'
                  : 'Bổ sung thông tin để hệ thống gợi ý những kết nối phù hợp hơn.'}
              </p>

              <Link
                to={completion === 100 ? '/discover' : '/profile'}
                className="banner-button"
              >
                {completion === 100 ? 'Khám phá ngay' : 'Cập nhật hồ sơ'}
                <span aria-hidden="true">↗</span>
              </Link>
            </div>

            <div className="banner-orbit" aria-hidden="true">
              <span className="orbit-center">C</span>
              <i className="orbit-dot dot-one" />
              <i className="orbit-dot dot-two" />
              <i className="orbit-dot dot-three" />
            </div>
          </div>

          <aside className="dashboard-metrics" aria-label="Tóm tắt tài khoản">
            <article className="metric-card metric-purple">
              <span>Hồ sơ</span>
              <strong>{completion}%</strong>
              <small>{completedFields}/{profileFields.length} thông tin</small>
            </article>
            <article className="metric-card metric-orange">
              <span>Đang chờ</span>
              <strong>{pending}</strong>
              <small>Lời mời kết nối</small>
            </article>
            <article className="metric-card metric-green">
              <span>Đã kết nối</span>
              <strong>{accepted}</strong>
              <small>Có thể trò chuyện</small>
            </article>
          </aside>
        </div>

        <div className="section-heading">
          <h2>Cậu đang cần gì?</h2>
          <p>Chọn một mục tiêu để bắt đầu.</p>
        </div>

        <div className="quick-action-grid">
          {quickActions.map((action) => (
            <Link
              key={action.to}
              to={action.to}
              className={`quick-action-card ${action.color}`}
            >
              <span className="quick-action-icon" aria-hidden="true">
                <Icon name={action.icon} />
              </span>
              <h3>{action.title}</h3>
              <p>{action.text}</p>
              <span className="card-arrow" aria-hidden="true">→</span>
            </Link>
          ))}
        </div>

        <div className="dashboard-lower-grid">
          <section className="dashboard-panel">
            <div className="panel-title-row">
              <h2>Kết nối của cậu</h2>
              <p>
                {pending} lời mời đang chờ · {accepted} kết nối đã chấp nhận
              </p>
            </div>

            {recentConnections.length === 0 ? (
              <div className="empty-activity">
                <h3>Chưa có lời mời nào</h3>
                <p>Tìm hồ sơ phù hợp rồi gửi lời mời kết nối.</p>
                <Link to="/discover">Khám phá sinh viên →</Link>
              </div>
            ) : (
              <div className="connection-preview-list">
                {recentConnections.map((item) => (
                  <Link
                    key={item.id}
                    to="/matches"
                    className="connection-preview-item"
                  >
                    <span className="connection-mini-avatar">
                      {item.name.trim().split(/\s+/).pop()?.[0] || '?'}
                    </span>
                    <span className="connection-preview-copy">
                      <strong>{item.name}</strong>
                      <small>{item.purpose || 'Kết nối sinh viên'}</small>
                    </span>
                    <span className={`connection-status ${item.status}`}>
                      {item.status === 'pending'
                        ? 'Đang chờ'
                        : 'Đã kết nối'}
                    </span>
                  </Link>
                ))}

                <Link
                  to="/matches"
                  className="panel-text-link"
                >
                  Xem tất cả kết nối <span>→</span>
                </Link>
              </div>
            )}
          </section>

          <section className="dashboard-panel profile-progress">
            <p className="progress-label">HỒ SƠ ĐÃ LƯU</p>

            <div className="progress-number">
              <strong>{completion}%</strong>
              <span>Thông tin đã điền</span>
            </div>

            <div
              className="progress-track"
              role="progressbar"
              aria-label="Mức độ hoàn thiện hồ sơ đã lưu"
              aria-valuemin={0}
              aria-valuemax={100}
              aria-valuenow={completion}
            >
              <span style={{ width: `${completion}%` }} />
            </div>

            <p>
              {completedFields}/{profileFields.length} mục đã điền.
              Mức độ hoàn thiện không có nghĩa là tài khoản đã xác minh.
            </p>

            <Link to="/profile">Chỉnh sửa hồ sơ →</Link>
          </section>
        </div>
      </section>
    </AppLayout>
  )
}
