import { useEffect, useRef, useState } from 'react'
import AppLayout, { Icon } from '../components/AppLayout'
import { getCurrentAccount, accountStorage } from '../auth'
import { supabase } from '../lib/supabaseClient'

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

const requiredFields = [
  'fullName',
  'university',
  'major',
  'studyYear',
  'gender',
  'purpose',
  'city',
  'area',
  'maxDistance',
]

const fieldLabels = {
  fullName: 'Họ và tên',
  university: 'Trường đại học',
  major: 'Ngành học',
  studyYear: 'Năm học',
  gender: 'Giới tính',
  purpose: 'Mục tiêu kết nối',
  city: 'Tỉnh / Thành phố',
  area: 'Khu vực trong tỉnh / thành phố',
  maxDistance: 'Khoảng cách mong muốn',
}

function readProfile() {
  try {
    const raw = accountStorage.getItem(STORAGE_KEY)

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

function profileFromSupabase(profile) {
  if (!profile) return { ...defaultProfile }

  return {
    fullName: profile.full_name || '',
    university: profile.university || '',
    major: profile.major || '',
    studyYear: profile.study_year || '',
    gender: profile.gender || '',
    purpose: profile.purpose || '',
    bio: (profile.bio || '').slice(0, 180),
    city: profile.city || '',
    area: profile.area || '',
    publicLocation: profile.public_location || '',
    maxDistance: String(profile.max_distance_km || 3),
  }
}

function isNearlyEmptyProfile(profile) {
  return [
    'university',
    'major',
    'studyYear',
    'gender',
    'purpose',
    'bio',
    'city',
    'area',
    'publicLocation',
  ].every((field) => !profile[field])
}

function getProfileErrorMessage(error, action) {
  const message = error?.message?.toLowerCase() || ''

  if (message.includes('row-level security')) {
    return `Không thể ${action} hồ sơ do quyền truy cập. Hãy đăng nhập lại và thử lại.`
  }

  return `Không thể ${action} hồ sơ. Hãy thử lại sau.`
}

export default function Profile() {
  const [initial] = useState(readProfile)
  const [formData, setFormData] = useState(initial.data)
  const [savedProfile, setSavedProfile] = useState(initial.data)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState(initial.warning)
  const [fieldErrors, setFieldErrors] = useState({})
  const [privateProfile, setPrivateProfile] = useState({
    phone: null,
    exact_address: null,
    hide_phone: true,
    hide_exact_address: true,
  })
  const [phone, setPhone] = useState('')
  const [savedPhone, setSavedPhone] = useState('')
  const [isLoadingProfile, setIsLoadingProfile] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const statusRef = useRef(null)

  const isDirty = JSON.stringify(formData) !== JSON.stringify(savedProfile) ||
    phone !== savedPhone

  const completedFields = Object.values(formData).filter(
    (value) => value.trim() !== ''
  ).length

  const completion = Math.round(
    (completedFields / Object.keys(defaultProfile).length) * 100
  )

  const lastName = formData.fullName.trim().split(/\s+/).pop()
  const avatarLetter = lastName ? lastName[0].toUpperCase() : '?'

  useEffect(() => {
    let isMounted = true

    async function loadProfile() {
      try {
        const user = await getCurrentAccount()

        if (!user) {
          throw new Error('Phiên đăng nhập đã hết.')
        }

        const [{ data: publicProfile, error: publicError }, { data: privateData, error: privateError }] = await Promise.all([
          supabase
            .from('profiles')
            .select('id, full_name, university, major, study_year, gender, purpose, bio, city, area, public_location, max_distance_km')
            .eq('id', user.id)
            .maybeSingle(),
          supabase
            .from('profile_private')
            .select('phone, exact_address, hide_phone, hide_exact_address')
            .eq('profile_id', user.id)
            .maybeSingle(),
        ])

        if (publicError) throw publicError
        if (privateError) throw privateError

        const supabaseProfile = profileFromSupabase(publicProfile)
        const legacyProfile = initial.data
        const shouldUseLegacy = isNearlyEmptyProfile(supabaseProfile) &&
          JSON.stringify(legacyProfile) !== JSON.stringify(defaultProfile)
        const loadedProfile = shouldUseLegacy ? legacyProfile : supabaseProfile

        if (isMounted) {
          setFormData(loadedProfile)
          setSavedProfile(shouldUseLegacy ? supabaseProfile : loadedProfile)
          setPrivateProfile(privateData || {
            phone: null,
            exact_address: null,
            hide_phone: true,
            hide_exact_address: true,
          })
          setPhone(privateData?.phone || '')
          setSavedPhone(privateData?.phone || '')
          setSaved(false)
          setError('')
        }
      } catch (loadError) {
        if (isMounted) {
          setError(getProfileErrorMessage(loadError, 'tải'))
        }
      } finally {
        if (isMounted) setIsLoadingProfile(false)
      }
    }

    loadProfile()

    return () => {
      isMounted = false
    }
  }, [initial.data])

  useEffect(() => {
    function handleBeforeUnload(event) {
      if (!isDirty) return

      event.preventDefault()
      event.returnValue = ''
    }

    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [isDirty])

  useEffect(() => {
    if (error) {
      statusRef.current?.focus({ preventScroll: true })
    }
  }, [error])

  function validateForm(data) {
    const nextErrors = {}

    for (const field of requiredFields) {
      if (!data[field]) {
        nextErrors[field] = `${fieldLabels[field]} là thông tin bắt buộc.`
      }
    }

    return nextErrors
  }

  function handleChange(event) {
    const { name, value } = event.target

    if (name === 'phone') {
      setPhone(value)
    } else {
      setFormData((current) => ({
        ...current,
        [name]: value,
      }))
    }

    setSaved(false)
    setError('')
    setFieldErrors((current) => {
      if (!current[name]) return current

      const next = { ...current }
      delete next[name]
      return next
    })
  }

  function handleBlur(event) {
    const { name, value } = event.target

    if (name === 'phone') {
      const normalizedPhone = value.replace(/[ .-]/g, '')
      const isValidPhone = !value.trim() ||
        /^0\d{9}$/.test(normalizedPhone) ||
        /^\+84\d{9}$/.test(normalizedPhone)

      setFieldErrors((current) => {
        const next = { ...current }

        if (isValidPhone) {
          delete next.phone
        } else {
          next.phone = 'Số điện thoại cần có dạng 0xxxxxxxxx hoặc +84xxxxxxxxx.'
        }

        return next
      })
      return
    }

    if (requiredFields.includes(name) && !value.trim()) {
      setFieldErrors((current) => ({
        ...current,
        [name]: `${fieldLabels[name]} là thông tin bắt buộc.`,
      }))
    }
  }

  async function handleSubmit(event) {
    event.preventDefault()
    if (isSaving || isLoadingProfile) return
    setSaved(false)

    const cleaned = Object.fromEntries(
      Object.entries(formData).map(([key, value]) => [
        key,
        value.trim(),
      ])
    )

    const cleanedPhone = phone.trim()
    const nextErrors = validateForm(cleaned)
    const normalizedPhone = cleanedPhone.replace(/[ .-]/g, '')
    const isValidPhone = !phone.trim() ||
      /^0\d{9}$/.test(normalizedPhone) ||
      /^\+84\d{9}$/.test(normalizedPhone)

    if (!isValidPhone) {
      nextErrors.phone = 'Số điện thoại cần có dạng 0xxxxxxxxx hoặc +84xxxxxxxxx.'
    }

    if (Object.keys(nextErrors).length > 0) {
      setFieldErrors(nextErrors)
      setError(
        Object.keys(nextErrors).every((field) => field === 'phone')
          ? ''
          : 'Hãy bổ sung các thông tin bắt buộc được đánh dấu bên dưới.'
      )
      return
    }

    setIsSaving(true)

    try {
      const user = await getCurrentAccount()

      if (!user) {
        throw new Error('Phiên đăng nhập đã hết.')
      }

      const { data: savedPublicProfile, error: publicError } = await supabase
        .from('profiles')
        .upsert({
          id: user.id,
          full_name: cleaned.fullName,
          university: cleaned.university,
          major: cleaned.major,
          study_year: cleaned.studyYear,
          gender: cleaned.gender,
          purpose: cleaned.purpose,
          bio: cleaned.bio,
          city: cleaned.city,
          area: cleaned.area,
          public_location: cleaned.publicLocation,
          max_distance_km: Number(cleaned.maxDistance),
        })
        .select('id, full_name, university, major, study_year, gender, purpose, bio, city, area, public_location, max_distance_km')
        .single()

      if (publicError) throw publicError

      const { data: savedPrivateProfile, error: privateError } = await supabase
        .from('profile_private')
        .upsert({
          profile_id: user.id,
          phone: cleanedPhone || null,
          exact_address: privateProfile.exact_address,
          hide_phone: privateProfile.hide_phone,
          hide_exact_address: privateProfile.hide_exact_address,
        })
        .select('phone, exact_address, hide_phone, hide_exact_address')
        .single()

      if (privateError) throw privateError

      const savedData = profileFromSupabase(savedPublicProfile)
      setFormData(savedData)
      setSavedProfile(savedData)
      setPrivateProfile(savedPrivateProfile || privateProfile)
      setPhone(savedPrivateProfile?.phone || cleanedPhone)
      setSavedPhone(savedPrivateProfile?.phone || cleanedPhone)
      setFieldErrors({})
      setError('')
      setSaved(true)
    } catch (saveError) {
      setError(getProfileErrorMessage(saveError, 'lưu'))
    } finally {
      setIsSaving(false)
    }
  }

  function renderSelect(name, label) {
    const errorId = `${name}-error`

    return (
      <label className="profile-field">
        <span>{label} <em>Bắt buộc</em></span>
        <select
          id={`profile-${name}`}
          name={name}
          value={formData[name]}
          onChange={handleChange}
          onBlur={handleBlur}
          aria-invalid={Boolean(fieldErrors[name])}
          aria-describedby={fieldErrors[name] ? errorId : undefined}
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
        {fieldErrors[name] && <small id={errorId} className="profile-field-error">{fieldErrors[name]}</small>}
      </label>
    )
  }

  function fieldLabel(name, label, optional = false) {
    return <span>{label} <em>{optional ? 'Không bắt buộc' : 'Bắt buộc'}</em></span>
  }

  return (
    <AppLayout>
      <section className="profile-page">
        <header className="profile-page-header profile-hero">
          <div className="profile-hero-copy">
            <span className="profile-hero-label">COCO PROFILE</span>
            <h1>Xây dựng hồ sơ khiến người phù hợp muốn kết nối.</h1>
            <p>
              Thể hiện mục tiêu, kỹ năng và khu vực của cậu. Thông tin
              riêng tư vẫn luôn được bảo vệ.
            </p>
          </div>

          <div className="profile-hero-actions">
            <span className="profile-visibility"><i /> Chỉ hiển thị thông tin công khai</span>
            <button
              type="submit"
              form="profile-form"
              className="profile-save-button"
              disabled={isLoadingProfile || isSaving}
            >
              {isSaving ? 'Đang lưu hồ sơ…' : saved ? 'Đã lưu thay đổi' : 'Lưu hồ sơ'}
              <Icon name="arrow" />
            </button>
          </div>

          <div className="profile-hero-art" aria-hidden="true">
            <span>{avatarLetter}</span>
            <i className="profile-art-one" />
            <i className="profile-art-two" />
          </div>
        </header>

        <div className="profile-insight-row profile-mobile-summary" aria-label="Tóm tắt hồ sơ">
          <div><span>Mức hoàn thiện</span><strong>{completion}%</strong></div>
          <div><span>Mục tiêu</span><strong>{formData.purpose || 'Chưa chọn'}</strong></div>
          <div><span>Khu vực</span><strong>{formData.area || formData.city || 'Chưa điền'}</strong></div>
          <div><span>Quyền riêng tư</span><strong>Đang bảo vệ</strong></div>
        </div>

        {isLoadingProfile && (
          <div className="profile-loading-message" role="status" aria-live="polite">
            Đang tải hồ sơ…
          </div>
        )}

        {error && (
          <div ref={statusRef} className="form-error-banner" role="alert" aria-live="assertive" tabIndex="-1">
            {error}
          </div>
        )}

        {saved && (
          <div className="profile-success-message" role="status" aria-live="polite">
            Đã lưu hồ sơ vào Supabase. Cậu có thể tải lại trang để kiểm tra.
          </div>
        )}

        {isDirty && (
          <div className="profile-unsaved-notice" role="status" aria-live="polite">
            <span><Icon name="profile" /> Cậu có thay đổi chưa được lưu.</span>
            <button type="submit" form="profile-form">Lưu thay đổi</button>
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
              <Icon name="profile" /> Xác minh tài khoản: Chưa xác minh
            </span>

            <div className="profile-completion">
              <div className="completion-heading">
                <span>Mức độ hoàn thiện hồ sơ</span>
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
            aria-busy={isLoadingProfile || isSaving}
            noValidate
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
                  {fieldLabel('fullName', 'Họ và tên')}
                  <input
                    id="profile-fullName"
                    name="fullName"
                    value={formData.fullName}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    aria-invalid={Boolean(fieldErrors.fullName)}
                    aria-describedby={fieldErrors.fullName ? 'fullName-error' : undefined}
                    placeholder="Tên sinh viên mẫu"
                    maxLength={80}
                  />
                  {fieldErrors.fullName && <small id="fullName-error" className="profile-field-error">{fieldErrors.fullName}</small>}
                </label>

                <label className="profile-field">
                  {fieldLabel('university', 'Trường đại học')}
                  <input
                    id="profile-university"
                    name="university"
                    value={formData.university}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    aria-invalid={Boolean(fieldErrors.university)}
                    aria-describedby={fieldErrors.university ? 'university-error' : undefined}
                    placeholder="Nhập tên trường"
                    maxLength={120}
                  />
                  {fieldErrors.university && <small id="university-error" className="profile-field-error">{fieldErrors.university}</small>}
                </label>

                <label className="profile-field">
                  {fieldLabel('major', 'Ngành học')}
                  <input
                    id="profile-major"
                    name="major"
                    value={formData.major}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    aria-invalid={Boolean(fieldErrors.major)}
                    aria-describedby={fieldErrors.major ? 'major-error' : undefined}
                    placeholder="Nhập ngành học"
                    maxLength={100}
                  />
                  {fieldErrors.major && <small id="major-error" className="profile-field-error">{fieldErrors.major}</small>}
                </label>

                {renderSelect('studyYear', 'Năm học')}
              </div>

              <label className="profile-field profile-field-full">
                {fieldLabel('bio', 'Giới thiệu ngắn', true)}
                <textarea
                  id="profile-bio"
                  name="bio"
                  value={formData.bio}
                  onChange={handleChange}
                  onBlur={handleBlur}
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
                  <p>Chọn mục tiêu để nhận gợi ý phù hợp hơn.</p>
                </div>
              </div>

              <div className="profile-form-grid">
                {renderSelect('gender', 'Giới tính')}
                {renderSelect('purpose', 'Mục tiêu hiện tại')}
              </div>

              <div className="gender-safety-note">
                <p>
                  <Icon name="room" />
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
                  <p>Số điện thoại và địa chỉ chính xác được bảo vệ riêng tư.</p>
                </div>
              </div>

                           <div className="profile-form-grid">
                <label className="profile-field">
                  {fieldLabel('city', 'Tỉnh / Thành phố')}
                  <input
                    id="profile-city"
                    name="city"
                    value={formData.city}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    aria-invalid={Boolean(fieldErrors.city)}
                    aria-describedby={fieldErrors.city ? 'city-error' : undefined}
                    placeholder="Ví dụ: Hà Nội"
                    maxLength={80}
                  />
                  {fieldErrors.city && <small id="city-error" className="profile-field-error">{fieldErrors.city}</small>}
                </label>

                <label className="profile-field">
                  {fieldLabel('area', 'Khu vực trong tỉnh / thành phố')}
                  <input
                    id="profile-area"
                    name="area"
                    value={formData.area}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    aria-invalid={Boolean(fieldErrors.area)}
                    aria-describedby={fieldErrors.area ? 'area-error' : undefined}
                    placeholder="Ví dụ: Cầu Giấy, Thanh Xuân"
                    maxLength={100}
                  />
                  {fieldErrors.area && <small id="area-error" className="profile-field-error">{fieldErrors.area}</small>}
                </label>

                <label className="profile-field">
                  {fieldLabel('publicLocation', 'Tên đường hoặc địa danh gần đó', true)}
                  <input
                    id="profile-publicLocation"
                    name="publicLocation"
                    value={formData.publicLocation}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    placeholder="Ví dụ: gần trường, tên đường"
                    maxLength={160}
                  />
                </label>

                <label className="profile-field">
                  {fieldLabel('phone', 'Số điện thoại', true)}
                  <input
                    id="profile-phone"
                    name="phone"
                    type="tel"
                    inputMode="tel"
                    autoComplete="tel"
                    value={phone}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    aria-invalid={Boolean(fieldErrors.phone)}
                    aria-describedby={fieldErrors.phone ? 'phone-error' : undefined}
                    placeholder="Ví dụ: 0912 345 678"
                    maxLength={20}
                  />
                  {fieldErrors.phone && <small id="phone-error" className="profile-field-error">{fieldErrors.phone}</small>}
                </label>

                {renderSelect('maxDistance', 'Khoảng cách mong muốn')}
              </div>

              <div className="privacy-options">
                <div className="privacy-option">
                  <div>
                      <strong><Icon name="profile" /> Không công khai số điện thoại</strong>
                    <span>
                        Số điện thoại được lưu riêng tư và chỉ cậu có thể xem hoặc chỉnh sửa.
                    </span>
                  </div>
                  <span>Luôn bật</span>
                </div>

                <div className="privacy-option">
                  <div>
                      <strong><Icon name="room" /> Không công khai địa chỉ chính xác</strong>
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
