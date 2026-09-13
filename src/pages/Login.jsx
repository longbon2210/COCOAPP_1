import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import Layout from '../components/Layout'
import { loginAccount } from '../auth'

export default function Login() {
  const navigate = useNavigate()
  const location = useLocation()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleSubmit(event) {
    event.preventDefault()

    if (isLoading) return

    setError('')
    setIsLoading(true)

    try {
      await loginAccount(email, password)
      navigate('/dashboard', { replace: true })
    } catch (error) {
      setError(
        error.message ||
          'Không đăng nhập được. Hãy kiểm tra quyền lưu trữ của trình duyệt.'
      )
    } finally {
      setIsLoading(false)
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
              <p>Đăng nhập bằng tài khoản cậu đã đăng ký.</p>
            </div>

            {location.state?.registered && (
              <div className="discover-demo-note" role="status">
                Đăng ký thành công! Nhập email và mật khẩu vừa tạo
                để đăng nhập.
              </div>
            )}

            {error && (
              <div className="form-error-banner" role="alert">
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit}>
              <div className="login-field">
                <label htmlFor="login-email">Email</label>

                <div className="login-input-wrapper">
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    aria-hidden="true"
                  >
                    <rect x="3" y="5" width="18" height="14" rx="3" />
                    <path d="m3 7 9 6 9-6" />
                  </svg>

                  <input
                    id="login-email"
                    name="email"
                    type="email"
                    placeholder="tenban@example.com"
                    value={email}
                    onChange={(event) => {
                      setEmail(event.target.value)
                      setError('')
                    }}
                    autoComplete="username"
                    disabled={isLoading}
                    required
                  />
                </div>
              </div>

              <div className="login-field">
                <label htmlFor="login-password">Mật khẩu</label>

                <div className="login-input-wrapper">
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    aria-hidden="true"
                  >
                    <rect x="4" y="10" width="16" height="11" rx="3" />
                    <path d="M8 10V7a4 4 0 0 1 8 0v3" />
                  </svg>

                  <input
                    id="login-password"
                    name="password"
                    type={showPassword ? 'text' : 'password'}
                    placeholder="Nhập mật khẩu đã đăng ký"
                    value={password}
                    onChange={(event) => {
                      setPassword(event.target.value)
                      setError('')
                    }}
                    autoComplete="current-password"
                    disabled={isLoading}
                    required
                  />

                  <button
                    type="button"
                    className="password-toggle"
                    aria-label={
                      showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'
                    }
                    aria-pressed={showPassword}
                    onClick={() => setShowPassword((current) => !current)}
                  >
                    {showPassword ? 'Ẩn' : 'Hiện'}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                className="login-submit"
                disabled={isLoading}
              >
                {isLoading ? 'Đang đăng nhập…' : 'Đăng nhập'}
                {!isLoading && <span aria-hidden="true">→</span>}
              </button>
            </form>

            <div className="login-register">
              <span>Chưa có tài khoản?</span>
              <Link to="/register">Đăng ký tài khoản</Link>
            </div>

            <p className="login-safety">
              Tài khoản chỉ dùng trên trình duyệt đã đăng ký.
              Dùng máy khác, cậu cần đăng ký trên máy đó.
            </p>
          </div>
        </div>
      </section>
    </Layout>
  )
}