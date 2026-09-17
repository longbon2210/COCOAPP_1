import { useEffect, useRef, useState } from 'react'
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
  const [fieldErrors, setFieldErrors] = useState({})
  const errorRef = useRef(null)

  useEffect(() => {
    if (error) errorRef.current?.focus({ preventScroll: true })
  }, [error])

  function handleFieldChange(field, value) {
    if (field === 'email') setEmail(value)
    if (field === 'password') setPassword(value)
    setError('')
    setFieldErrors((current) => {
      if (!current[field]) return current
      const next = { ...current }
      delete next[field]
      return next
    })
  }

  async function handleSubmit(event) {
    event.preventDefault()

    if (isLoading) return

    setError('')

    const nextErrors = {}
    if (!email.trim()) nextErrors.email = 'Nhập email để tiếp tục.'
    if (!password) nextErrors.password = 'Nhập mật khẩu để tiếp tục.'

    if (Object.keys(nextErrors).length > 0) {
      setFieldErrors(nextErrors)
      setError('Hãy kiểm tra các thông tin bắt buộc bên dưới.')
      return
    }

    setFieldErrors({})
    setIsLoading(true)

    try {
      await loginAccount(email, password)
      navigate('/dashboard', { replace: true })
    } catch (error) {
      setError(
        error.message || 'Không đăng nhập được. Hãy thử lại sau.'
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

            {location.state?.requiresEmailConfirmation ? (
              <div className="discover-demo-note" role="status">
                Tài khoản đã được tạo. Hãy kiểm tra email để xác nhận
                tài khoản trước khi đăng nhập.
              </div>
            ) : location.state?.registered ? (
              <div className="discover-demo-note" role="status">
                Đăng ký thành công! Nhập email và mật khẩu vừa tạo
                để đăng nhập.
              </div>
            ) : null}

            {error && (
              <div ref={errorRef} className="form-error-banner auth-error-summary" role="alert" tabIndex="-1">
                <strong>{error}</strong>
                {Object.keys(fieldErrors).length > 0 && (
                  <ul>
                    {Object.entries(fieldErrors).map(([field, message]) => (
                      <li key={field}><a href={`#login-${field}`}>{message}</a></li>
                    ))}
                  </ul>
                )}
              </div>
            )}

            <form onSubmit={handleSubmit} noValidate>
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
                    onChange={(event) => handleFieldChange('email', event.target.value)}
                    autoComplete="username"
                    disabled={isLoading}
                    aria-invalid={Boolean(fieldErrors.email)}
                    aria-describedby={fieldErrors.email ? 'login-email-error' : undefined}
                  />
                </div>
                {fieldErrors.email && <small id="login-email-error" className="auth-field-error">{fieldErrors.email}</small>}
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
                    onChange={(event) => handleFieldChange('password', event.target.value)}
                    autoComplete="current-password"
                    disabled={isLoading}
                    aria-invalid={Boolean(fieldErrors.password)}
                    aria-describedby={fieldErrors.password ? 'login-password-error' : undefined}
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
                {fieldErrors.password && <small id="login-password-error" className="auth-field-error">{fieldErrors.password}</small>}
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