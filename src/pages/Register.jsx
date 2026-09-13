import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Layout from '../components/Layout'
import { registerAccount } from '../auth'

export default function Register() {
  const navigate = useNavigate()

  const [form, setForm] = useState({
    fullName: '',
    email: '',
    university: '',
    password: '',
    confirmPassword: '',
  })

  const [showPassword, setShowPassword] = useState(false)
  const [understandDemo, setUnderstandDemo] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  function handleChange(event) {
    const { name, value } = event.target

    setForm((current) => ({
      ...current,
      [name]: value,
    }))

    setError('')
  }

  async function handleSubmit(event) {
    event.preventDefault()

    if (isLoading) return

    setError('')

    if (form.password !== form.confirmPassword) {
      setError('Hai ô mật khẩu chưa giống nhau. Hãy nhập lại.')
      return
    }

    if (!understandDemo) {
      setError('Hãy đánh dấu xác nhận bên dưới.')
      return
    }

    setIsLoading(true)

    try {
      await registerAccount({
        fullName: form.fullName,
        email: form.email,
        university: form.university,
        password: form.password,
      })

      navigate('/login', {
        replace: true,
        state: { registered: true },
      })
    } catch (error) {
      setError(
        error.message ||
          'Không tạo được tài khoản. Hãy kiểm tra quyền lưu trữ của trình duyệt.'
      )
    } finally {
      setIsLoading(false)
    }
  }

  const fields = [
    {
      name: 'fullName',
      label: 'Họ và tên',
      type: 'text',
      placeholder: 'Nhập họ và tên',
      autoComplete: 'name',
      maxLength: 80,
    },
    {
      name: 'email',
      label: 'Email',
      type: 'email',
      placeholder: 'tenban@example.com',
      autoComplete: 'email',
      maxLength: 254,
    },
    {
      name: 'university',
      label: 'Trường đại học',
      type: 'text',
      placeholder: 'Nhập tên trường',
      autoComplete: 'organization',
      maxLength: 120,
    },
    {
      name: 'password',
      label: 'Mật khẩu',
      type: showPassword ? 'text' : 'password',
      placeholder: 'Ít nhất 6 ký tự',
      autoComplete: 'new-password',
      maxLength: 128,
    },
    {
      name: 'confirmPassword',
      label: 'Nhập lại mật khẩu',
      type: showPassword ? 'text' : 'password',
      placeholder: 'Nhập giống mật khẩu phía trên',
      autoComplete: 'new-password',
      maxLength: 128,
    },
  ]

  return (
    <Layout>
      <div className="login-card-container register-card-container">
        <div className="login-card register-card">
          <header className="card-header">
            <h1 className="card-heading">Bắt đầu với Coco</h1>
            <p className="card-subtitle">
              Tạo tài khoản để tìm người đồng hành.
            </p>
          </header>

          <p className="discover-demo-note" id="register-note">
            Bản thử nghiệm: tài khoản chỉ được lưu trên trình duyệt
            này, chưa đồng bộ sang máy khác hoặc xác minh email.
            Hãy dùng thông tin thử nghiệm.
          </p>

          {error && (
            <div className="form-error-banner" role="alert">
              {error}
            </div>
          )}

          <form
            className="login-form register-form"
            onSubmit={handleSubmit}
            aria-describedby="register-note"
          >
            {fields.map((field) => (
              <div className="form-group" key={field.name}>
                <label
                  htmlFor={`register-${field.name}`}
                  className="form-label"
                >
                  {field.label}
                </label>

                <input
                  id={`register-${field.name}`}
                  name={field.name}
                  type={field.type}
                  className="form-input"
                  style={{
                    paddingLeft: 14,
                    paddingRight: 14,
                    boxSizing: 'border-box',
                  }}
                  value={form[field.name]}
                  onChange={handleChange}
                  placeholder={field.placeholder}
                  autoComplete={field.autoComplete}
                  maxLength={field.maxLength}
                  minLength={
                    field.name === 'password' ||
                    field.name === 'confirmPassword'
                      ? 6
                      : undefined
                  }
                  disabled={isLoading}
                  required
                />
              </div>
            ))}

            <label className="checkbox-label">
              <input
                type="checkbox"
                className="custom-checkbox"
                checked={showPassword}
                onChange={(event) =>
                  setShowPassword(event.target.checked)
                }
              />
              <span>Hiện cả hai ô mật khẩu</span>
            </label>

            <label className="checkbox-label">
              <input
                type="checkbox"
                className="custom-checkbox"
                checked={understandDemo}
                onChange={(event) => {
                  setUnderstandDemo(event.target.checked)
                  setError('')
                }}
                disabled={isLoading}
                required
              />
              <span>
                Tôi hiểu tài khoản và hồ sơ chỉ được lưu trên
                trình duyệt này.
              </span>
            </label>

            <button
              type="submit"
              className="btn-login"
              disabled={isLoading}
            >
              {isLoading
                ? 'Đang tạo tài khoản…'
                : 'Đăng ký tài khoản →'}
            </button>
          </form>

          <footer className="card-footer">
            <span>Đã có tài khoản?</span>
            <Link to="/login" className="signup-link">
              Đăng nhập
            </Link>
          </footer>
        </div>
      </div>
    </Layout>
  )
}