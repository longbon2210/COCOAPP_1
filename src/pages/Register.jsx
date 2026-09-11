import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Layout from '../components/Layout'

const PROFILE_KEY = 'cocoapp.profile.v1'

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
  const [error, setError] = useState('')
  const [existingProfile, setExistingProfile] = useState(false)

  function handleChange(event) {
    const { name, value } = event.target

    setForm((current) => ({
      ...current,
      [name]: value,
    }))

    setError('')
  }

  function handleSubmit(event) {
    event.preventDefault()
    setError('')
    setExistingProfile(false)

    const fullName = form.fullName.trim()
    const university = form.university.trim()
    const email = form.email.trim()

    if (!fullName || !university || !email) {
      setError('Hãy điền họ tên, email và trường đại học.')
      return
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError('Email chưa đúng định dạng. Ví dụ: sinhvien@example.com.')
      return
    }

    if (form.password.length < 6 || !form.password.trim()) {
      setError('Mật khẩu demo cần ít nhất 6 ký tự và không chỉ chứa dấu cách.')
      return
    }

    if (form.password !== form.confirmPassword) {
      setError('Hai ô mật khẩu chưa giống nhau. Hãy nhập lại.')
      return
    }

    if (!understandDemo) {
      setError('Hãy đánh dấu xác nhận trải nghiệm demo.')
      return
    }

    try {
      const currentProfile = localStorage.getItem(PROFILE_KEY)

      if (currentProfile !== null) {
        setExistingProfile(true)
        setError(
          'Trình duyệt này đã có hồ sơ demo. Hãy tiếp tục hồ sơ hiện có bằng liên kết bên dưới.'
        )
        return
      }

      localStorage.setItem(
        PROFILE_KEY,
        JSON.stringify({
          fullName,
          university,
          major: '',
          studyYear: '',
          gender: '',
          purpose: '',
          bio: '',
          city: '',
          area: '',
          publicLocation: '',
          maxDistance: '3',
          hidePhone: true,
          hideExactAddress: true,
        })
      )

      sessionStorage.setItem('cocoapp.demoSession.v1', 'active')
navigate('/profile', { replace: true })
    } catch {
      setError(
        'Không lưu được hồ sơ trên trình duyệt. Thông tin đang nhập vẫn được giữ để cậu thử lại.'
      )
    }
  }

  const fields = [
    {
      name: 'fullName',
      label: 'Họ và tên',
      type: 'text',
      placeholder: 'Tên sinh viên mẫu',
      autoComplete: 'name',
      maxLength: 80,
    },
    {
      name: 'email',
      label: 'Email',
      type: 'email',
      placeholder: 'sinhvien@example.com',
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
      label: 'Mật khẩu demo',
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
              Tạo hồ sơ để tìm người đồng hành.
            </p>
          </header>

          <p className="discover-demo-note" id="register-demo-note">
            Đăng ký mô phỏng: chưa tạo tài khoản thật hoặc xác minh email.
            Email và mật khẩu không được lưu hay gửi đi.
            Hãy dùng thông tin mẫu.
          </p>

          {error && (
            <div className="form-error-banner" role="alert">
              {error}
            </div>
          )}

          {existingProfile && (
            <p>
              <Link to="/profile" className="signup-link">
                Tiếp tục hồ sơ hiện có →
              </Link>
            </p>
          )}

          <form
            className="login-form register-form"
            onSubmit={handleSubmit}
            aria-describedby="register-demo-note"
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
                  required
                />
              </div>
            ))}

            <label className="checkbox-label">
              <input
                type="checkbox"
                className="custom-checkbox"
                checked={showPassword}
                onChange={(event) => setShowPassword(event.target.checked)}
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
                required
              />
              <span>
                Tôi hiểu đây là bản demo; tên và trường được lưu
                trên trình duyệt này để điền tiếp hồ sơ.
              </span>
            </label>

            <button type="submit" className="btn-login">
              Tiếp tục tạo hồ sơ →
            </button>
          </form>

          <footer className="card-footer">
            <span>Đã có hồ sơ demo?</span>
            <Link to="/login" className="signup-link">
              Về đăng nhập
            </Link>
          </footer>
        </div>
      </div>
    </Layout>
  )
}