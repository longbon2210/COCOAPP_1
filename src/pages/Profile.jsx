import { useState } from 'react'
import AppLayout from '../components/AppLayout'

const STORAGE_KEY = 'cocoapp.profile.v1'

const defaultProfile = {
  fullName: '',
  university: '',
  major: '',
  studyYear: '',
  gender: '',
  purpose: '',
  bio: '',
   city: '',
  area: '',
  publicLocation: '',   
  maxDistance: '3',
}

const selectOptions = {
  studyYear: ['Năm 1', 'Năm 2', 'Năm 3', 'Năm 4', 'Khác'],
  gender: ['Nam', 'Nữ', 'Khác', 'Không muốn công khai'],
  purpose: ['Học nhóm', 'Team Project', 'Ghép trọ'],
  maxDistance: ['1', '3', '5', '10'],
}

function readProfile() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)

    if (!raw) {
      return { data: { ...defaultProfile }, warning: '' }
    }

    const stored = JSON.parse(raw)

    if (!stored || typeof stored !== 'object' || Array.isArray(stored)) {
      throw new Error('Invalid profile')
    }

    const data = { ...defaultProfile }

    for (const key of Object.keys(defaultProfile)) {
      if (typeof stored[key] === 'string') {
        data[key] = stored[key]
      }
    }

    for (const [key, options] of Object.entries(selectOptions)) {
      if (!options.includes(data[key])) {
        data[key] = defaultProfile[key]
      }
    }

    data.bio = data.bio.slice(0, 180)

    return { data, warning: '' }
  } catch {
    return {
      data: { ...defaultProfile },
      warning:
        'Không đọc được hồ sơ đã lưu. Cậu có thể nhập lại; dữ liệu cũ chưa bị ghi đè.',
    }
  }
}

export default function Profile() {
  const [initial] = useState(readProfile)
  const [formData, setFormData] = useState(initial.data)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState(initial.warning)

  const completedFields = Object.values(formData).filter(
    (value) => value.trim() !== ''
  ).length

  const completion = Math.round(
    (completedFields / Object.keys(defaultProfile).length) * 100
  )

  const lastName = formData.fullName.trim().split(/\s+/).pop()
  const avatarLetter = lastName ? lastName[0].toUpperCase() : '?'

  function handleChange(event) {
    const { name, value } = event.target

    setFormData((current) => ({
      ...current,
      [name]: value,
    }))

    setSaved(false)
  }

  function handleSubmit(event) {
    event.preventDefault()
    setSaved(false)

    const cleaned = Object.fromEntries(
      Object.entries(formData).map(([key, value]) => [
        key,
        value.trim(),
      ])
    )

    if (!cleaned.fullName || !cleaned.university || !cleaned.major) {
      setError('Hãy điền họ tên, trường và ngành học, không chỉ nhập dấu cách.')
      return
    }

    try {
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          ...cleaned,
          hidePhone: true,
          hideExactAddress: true,
        })
      )

      setFormData(cleaned)
      setError('')
      setSaved(true)
    } catch {
      setError(
        'Chưa lưu được. Trình duyệt có thể đang chặn lưu trữ hoặc đã đầy. Thông tin đang nhập vẫn được giữ trên màn hình.'
      )
    }
  }

  function renderSelect(name, label) {
    return (
      <label className="profile-field">
        <span>{label}</span>
        <select
          name={name}
          value={formData[name]}
          onChange={handleChange}
          required
        >
          <option value="">Chọn thông tin</option>

          {selectOptions[name].map((option) => (
            <option key={option} value={option}>
              {name === 'maxDistance'
                ? `Trong vòng ${option} km`
                : option}
            </option>
          ))}
        </select>
      </label>
    )
  }

  return (
    <AppLayout>
      <section className="profile-page">
        <header className="profile-page-header">
          <div>
            <p className="page-eyebrow">HỒ SƠ CÁ NHÂN</p>
            <h1>Thông tin của cậu</h1>
            <p>
              Bản demo: chỉ nhập thông tin mẫu. Hồ sơ được lưu
              trên trình duyệt này, không gửi lên máy chủ.
            </p>
          </div>

          <button
            type="submit"
            form="profile-form"
            className="profile-save-button"
          >
            {saved ? '✓ Đã lưu' : 'Lưu thay đổi'}
          </button>
        </header>

        {error && (
          <div className="form-error-banner" role="alert">
            {error}
          </div>
        )}

        {saved && (
          <div className="profile-success-message" role="status">
            Đã lưu trên trình duyệt này. Cậu có thể tải lại trang
            để kiểm tra.
          </div>
        )}

        <div className="profile-layout">
          <aside className="profile-summary-card">
            <div className="profile-avatar-large">
              {avatarLetter}
            </div>

            <h2>{formData.fullName || 'Hồ sơ của cậu'}</h2>
            <p>{formData.major || 'Chưa điền ngành học'}</p>

            <span className="verified-student">
              Hồ sơ demo · Chưa xác minh
            </span>

            <div className="profile-completion">
              <div className="completion-heading">
                <span>Thông tin đã điền</span>
                <strong>{completion}%</strong>
              </div>

              <div
                className="completion-track"
                role="progressbar"
                aria-label="Mức độ hoàn thiện hồ sơ"
                aria-valuemin={0}
                aria-valuemax={100}
                aria-valuenow={completion}
              >
                <span style={{ width: `${completion}%` }} />
              </div>
            </div>

            <div className="profile-summary-information">
              <div>
                <span>Trường</span>
                <strong>{formData.university || 'Chưa điền'}</strong>
              </div>
              <div>
                <span>Năm học</span>
                <strong>{formData.studyYear || 'Chưa chọn'}</strong>
              </div>
              <div>
                <span>Giới tính</span>
                <strong>{formData.gender || 'Chưa chọn'}</strong>
              </div>
              <div>
                <span>Mục tiêu</span>
                <strong>{formData.purpose || 'Chưa chọn'}</strong>
              </div>
            </div>
          </aside>

          <form
            id="profile-form"
            className="profile-form-card"
            onSubmit={handleSubmit}
          >
            <div className="profile-form-section">
              <div className="profile-section-heading">
                <span>01</span>
                <div>
                  <h2>Thông tin cơ bản</h2>
                  <p>
                    Phần tóm tắt bên trái thay đổi theo nội dung đang nhập.
                    Bấm Lưu để giữ thay đổi.
                  </p>
                </div>
              </div>

              <div className="profile-form-grid">
                <label className="profile-field">
                  <span>Họ và tên</span>
                  <input
                    name="fullName"
                    value={formData.fullName}
                    onChange={handleChange}
                    placeholder="Tên sinh viên mẫu"
                    maxLength={80}
                    required
                  />
                </label>

                <label className="profile-field">
                  <span>Trường đại học</span>
                  <input
                    name="university"
                    value={formData.university}
                    onChange={handleChange}
                    placeholder="Nhập tên trường"
                    maxLength={120}
                    required
                  />
                </label>

                <label className="profile-field">
                  <span>Ngành học</span>
                  <input
                    name="major"
                    value={formData.major}
                    onChange={handleChange}
                    placeholder="Nhập ngành học"
                    maxLength={100}
                    required
                  />
                </label>

                {renderSelect('studyYear', 'Năm học')}
              </div>

              <label className="profile-field profile-field-full">
                <span>Giới thiệu ngắn</span>
                <textarea
                  name="bio"
                  value={formData.bio}
                  onChange={handleChange}
                  placeholder="Ví dụ: Mình tìm bạn cùng ôn Cấu trúc dữ liệu."
                  maxLength={180}
                />
                <small>{formData.bio.length}/180 ký tự</small>
              </label>
            </div>

            <div className="profile-form-section">
              <div className="profile-section-heading">
                <span>02</span>
                <div>
                  <h2>Giới tính và mục tiêu</h2>
                  <p>Thông tin dùng cho bộ lọc kết nối.</p>
                </div>
              </div>

              <div className="profile-form-grid">
                {renderSelect('gender', 'Giới tính')}
                {renderSelect('purpose', 'Mục tiêu hiện tại')}
              </div>

              <div className="gender-safety-note">
                <p>
                  Lọc cùng giới tính là quy tắc ghép trọ của bản
                  demo, không phải xác minh danh tính hay bảo đảm
                  an toàn. Không áp dụng giới hạn này cho học nhóm
                  và team project.
                </p>
              </div>
            </div>

            <div className="profile-form-section">
              <div className="profile-section-heading">
                <span>03</span>
                <div>
                  <h2>Khu vực và quyền riêng tư</h2>
                  <p>Không nhập số điện thoại hoặc địa chỉ nhà cụ thể.</p>
                </div>
              </div>

                           <div className="profile-form-grid">
                <label className="profile-field">
                  <span>Tỉnh / Thành phố</span>
                  <input
                    name="city"
                    value={formData.city}
                    onChange={handleChange}
                    placeholder="Ví dụ: Hà Nội"
                    maxLength={80}
                    required
                  />
                </label>

                <label className="profile-field">
                  <span>Khu vực trong tỉnh / thành phố</span>
                  <input
                    name="area"
                    value={formData.area}
                    onChange={handleChange}
                    placeholder="Ví dụ: Cầu Giấy, Thanh Xuân"
                    maxLength={100}
                    required
                  />
                </label>

                <label className="profile-field">
                  <span>Tên đường hoặc địa danh gần đó</span>
                  <input
                    name="publicLocation"
                    value={formData.publicLocation}
                    onChange={handleChange}
                    placeholder="Ví dụ: gần trường, tên đường"
                    maxLength={160}
                  />
                </label>

                {renderSelect('maxDistance', 'Khoảng cách mong muốn')}
              </div>

              <div className="privacy-options">
                <div className="privacy-option">
                  <div>
                    <strong>Không công khai số điện thoại</strong>
                    <span>
                      Bản demo không thu thập hay lưu số điện thoại.
                    </span>
                  </div>
                  <span>Luôn bật</span>
                </div>

                <div className="privacy-option">
                  <div>
                    <strong>Không công khai địa chỉ chính xác</strong>
                    <span>
                      Chỉ nhập địa danh gần đó hoặc tên đường.
                    </span>
                  </div>
                  <span>Luôn bật</span>
                </div>
              </div>
            </div>
          </form>
        </div>
      </section>
    </AppLayout>
  )
}