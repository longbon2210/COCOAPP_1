import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Layout from '../components/Layout'

export default function Login() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')

  function handleSubmit(event) {
    event.preventDefault()
    setError('')

    const correctEmail =
      email.trim().toLowerCase() === 'demo@coco.app'
    const correctPassword = password === 'CocoDemo123'

    if (!correctEmail || !correctPassword) {
      setError('Email hoặc mật khẩu demo chưa đúng.')
      return
    }

    try {
      sessionStorage.setItem('cocoapp.demoSession.v1', 'active')
      navigate('/dashboard', { replace: true })
    } catch {
      setError('Không tạo được phiên demo. Trình duyệt có thể đang chặn lưu trữ.')
    }
  }

  return (
    <Layout>
      <section className="login-stage">
        <div className="login-intro">
          <div className="intro-decoration intro-decoration-one" />
          <div className="intro-decoration intro-decoration-two" />

          <div className="intro-content">
            <span className="intro-label">DÀNH CHO SINH VIÊN</span>

            <h1>
              Gặp đúng người.
              <span> Đồng hành đúng mục tiêu.</span>
            </h1>

            <p className="intro-description">
              Tìm bạn học, đồng đội làm dự án và người ở ghép
              phù hợp với nhu cầu của cậu.
            </p>

            <div className="purpose-list">
              <div className="purpose-item purpose-study">
                <span className="purpose-number">01</span>
                <div>
                  <strong>Học nhóm</strong>
                  <p>Tìm bạn theo ngành học và kỹ năng.</p>
                </div>
              </div>

              <div className="purpose-item purpose-project">
                <span className="purpose-number">02</span>
                <div>
                  <strong>Team Project</strong>
                  <p>Tìm người cùng thực hiện ý tưởng.</p>
                </div>
              </div>

              <div className="purpose-item purpose-room">
                <span className="purpose-number">03</span>
                <div>
                  <strong>Ghép trọ</strong>
                  <p>Lọc theo giới tính, thành phố và khu vực.</p>
                </div>
              </div>
            </div>

            <p className="privacy-note">
              Hồ sơ mẫu không công khai số điện thoại hoặc số nhà.
            </p>
          </div>
        </div>

        <div className="login-panel">
          <div className="login-form-box">
            <div className="login-heading">
              <span className="login-small-title">COCOAPP</span>
              <h2>Chào mừng quay lại</h2>
              <p>Đăng nhập bằng tài khoản demo bên dưới.</p>
            </div>

            <div className="discover-demo-note">
              <strong>Tài khoản dùng thử</strong>
              <div>Email: demo@coco.app</div>
              <div>Mật khẩu: CocoDemo123</div>
            </div>

            {error && (
              <div className="form-error-banner" role="alert">
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit}>
              <div className="login-field">
                <label htmlFor="login-email">Email demo</label>
                <div className="login-input-wrapper">
                  <input
                    id="login-email"
                    name="email"
                    type="email"
                    placeholder="demo@coco.app"
                    value={email}
                    onChange={(event) => {
                      setEmail(event.target.value)
                      setError('')
                    }}
                    autoComplete="username"
                    required
                  />
                </div>
              </div>

              <div className="login-field">
                <label htmlFor="login-password">Mật khẩu demo</label>
                <div className="login-input-wrapper">
                  <input
                    id="login-password"
                    name="password"
                    type={showPassword ? 'text' : 'password'}
                    placeholder="Nhập mật khẩu demo"
                    value={password}
                    onChange={(event) => {
                      setPassword(event.target.value)
                      setError('')
                    }}
                    autoComplete="current-password"
                    style={{ paddingRight: 68 }}
                    required
                  />

                  <button
                    type="button"
                    className="password-toggle"
                    aria-label={showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
                    aria-pressed={showPassword}
                    onClick={() => setShowPassword((current) => !current)}
                  >
                    {showPassword ? 'Ẩn' : 'Hiện'}
                  </button>
                </div>
              </div>

              <button type="submit" className="login-submit">
                Đăng nhập demo <span aria-hidden="true">→</span>
              </button>
            </form>

            <div className="login-register">
              <span>Lần đầu trải nghiệm?</span>
              <Link to="/register">Tạo hồ sơ demo</Link>
            </div>

            <p className="login-safety">
              Bản mô phỏng một tài khoản, chưa có xác thực từ máy chủ.
            </p>
          </div>
        </div>
      </section>
    </Layout>
  )
}