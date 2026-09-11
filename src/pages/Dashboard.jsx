import { useState } from 'react'
import { Link } from 'react-router-dom'
import AppLayout from '../components/AppLayout'

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
    icon: '📚',
    title: 'Tìm bạn học',
    text: 'Cùng ôn bài, luyện đề và trao đổi kiến thức.',
    color: 'blue',
  },
  {
    to: '/team',
    icon: '💡',
    title: 'Tìm team project',
    text: 'Tìm người có kỹ năng phù hợp với dự án.',
    color: 'orange',
  },
  {
    to: '/roommates',
    icon: '🏠',
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
    const raw = localStorage.getItem('cocoapp.profile.v1')

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
    const raw = localStorage.getItem('cocoapp.connections.v1')

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
        </header>

        {warnings.length > 0 && (
          <div className="form-error-banner" role="alert">
            {warnings.join(' ')} Dữ liệu hiện có chưa bị thay đổi.
          </div>
        )}

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
                : 'Bổ sung thông tin để dùng các bộ lọc phù hợp hơn.'}
            </p>

            <Link
              to={completion === 100 ? '/discover' : '/profile'}
              className="banner-button"
            >
              {completion === 100 ? 'Khám phá ngay →' : 'Cập nhật hồ sơ →'}
            </Link>
          </div>

          <div className="banner-illustration" aria-hidden="true">
            ✦
          </div>
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
                {action.icon}
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
              <div style={{ marginTop: 18 }}>
                {recentConnections.map((item) => (
                  <Link
                    key={item.id}
                    to="/matches"
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      flexWrap: 'wrap',
                      gap: 8,
                      padding: '14px 0',
                      borderBottom: '1px solid #eee8df',
                      color: '#202331',
                      textDecoration: 'none',
                    }}
                  >
                    <strong>{item.name}</strong>
                    <span style={{ color: '#52665c', fontSize: 13 }}>
                      {item.status === 'pending'
                        ? 'Đang chờ'
                        : 'Đã kết nối'}
                    </span>
                  </Link>
                ))}

                <Link
                  to="/matches"
                  style={{
                    display: 'inline-block',
                    marginTop: 18,
                    color: '#a43e2d',
                    fontWeight: 600,
                  }}
                >
                  Xem tất cả kết nối →
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