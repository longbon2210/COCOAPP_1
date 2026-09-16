import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import AppLayout, { Icon } from '../components/AppLayout'
import { accountStorage } from '../auth'
import { VIETNAM_LOCATIONS } from '../data/vietnamLocations'

const PROFILE_KEY = 'cocoapp.profile.v1'
const CONNECTIONS_KEY = 'cocoapp.connections.v1'

function readConnections() {
  const raw = accountStorage.getItem(CONNECTIONS_KEY)
  if (!raw) return []

  const items = JSON.parse(raw)

  if (
    !Array.isArray(items) ||
    !items.every(
      (item) =>
        item &&
        typeof item.id === 'number' &&
        typeof item.name === 'string' &&
        ['pending', 'accepted'].includes(item.status) &&
        Array.isArray(item.messages) &&
        item.messages.every(
          (message) =>
            message &&
            typeof message.id === 'string' &&
            typeof message.text === 'string' &&
            ['me', 'other'].includes(message.sender)
        )
    )
  ) {
    throw new Error('Dữ liệu kết nối không hợp lệ')
  }

  return items
}

const students = [
  {
    id: 1,
    name: 'Nguyễn Minh Anh',
    gender: 'Nữ',
    major: 'Công nghệ thông tin',
    purpose: 'Học nhóm',
    city: 'Hà Nội',
    area: 'Hà Đông',
    location: 'Gần Đại học Phenikaa',
    distance: 1.2,
    skills: ['Java', 'Cấu trúc dữ liệu'],
    about: 'Tìm bạn ôn bài vào tối thứ Ba và thứ Năm.',
  },
  {
    id: 2,
    name: 'Trần Quang Huy',
    gender: 'Nam',
    major: 'Kỹ thuật phần mềm',
    purpose: 'Team Project',
    city: 'Hà Nội',
    area: 'Cầu Giấy',
    location: 'Khu vực đường Xuân Thủy',
    distance: 2.4,
    skills: ['React', 'UI/UX'],
    about: 'Tìm thành viên cùng làm website cho đồ án môn học.',
  },
  {
    id: 3,
    name: 'Lê Đức Long',
    gender: 'Nam',
    major: 'Khoa học máy tính',
    purpose: 'Ghép trọ',
    city: 'Hà Nội',
    area: 'Hà Đông',
    location: 'Đường Nguyễn Trác, gần Đại học Phenikaa',
    distance: 1.6,
    skills: ['Gọn gàng', 'Không hút thuốc'],
    about: 'Tìm bạn nam ở ghép, cùng chia tiền phòng và điện nước.',
  },
  {
    id: 4,
    name: 'Phạm Thu Trang',
    gender: 'Nữ',
    major: 'Trí tuệ nhân tạo',
    purpose: 'Ghép trọ',
    city: 'Hà Nội',
    area: 'Hà Đông',
    location: 'Khu vực Yên Nghĩa',
    distance: 3.1,
    skills: ['Yên tĩnh', 'Không nuôi thú cưng'],
    about: 'Tìm bạn nữ ở cùng, tôn trọng không gian riêng.',
  },
  {
    id: 5,
    name: 'Đỗ Ngọc Mai',
    gender: 'Nữ',
    major: 'Ngôn ngữ Anh',
    purpose: 'Ghép trọ',
    city: 'Hà Nội',
    area: 'Cầu Giấy',
    location: 'Gần đường Trần Thái Tông',
    distance: 2,
    skills: ['Gọn gàng', 'Yên tĩnh'],
    about: 'Tìm bạn nữ cùng chia phòng, thống nhất giờ nghỉ ngơi.',
  },
  {
    id: 6,
    name: 'Vũ Minh Khang',
    gender: 'Nam',
    major: 'Công nghệ thông tin',
    purpose: 'Ghép trọ',
    city: 'Hà Nội',
    area: 'Cầu Giấy',
    location: 'Khu vực đường Duy Tân',
    distance: 2.5,
    skills: ['Không hút thuốc', 'Tôn trọng riêng tư'],
    about: 'Tìm bạn nam ở cùng, chia sẻ công việc dọn phòng.',
  },
  {
    id: 7,
    name: 'Bùi Hải Yến',
    gender: 'Nữ',
    major: 'Kinh tế',
    purpose: 'Học nhóm',
    city: 'Hà Nội',
    area: 'Thanh Xuân',
    location: 'Khu vực đường Nguyễn Trãi',
    distance: 1.8,
    skills: ['Tiếng Anh', 'Thuyết trình'],
    about: 'Tìm bạn luyện tiếng Anh và thuyết trình cuối tuần.',
  },
  {
    id: 8,
    name: 'Nguyễn Gia Bảo',
    gender: 'Nam',
    major: 'Kỹ thuật phần mềm',
    purpose: 'Team Project',
    city: 'Đà Nẵng',
    area: 'Hải Châu',
    location: 'Khu vực đường Nguyễn Văn Linh',
    distance: 2.8,
    skills: ['React', 'Git'],
    about: 'Tìm bạn cùng xây dựng giao diện cho dự án sinh viên.',
  },
]

const purposes = ['Tất cả', 'Học nhóm', 'Team Project', 'Ghép trọ']

function normalize(value) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ')
}

function readProfile() {
  try {
    const raw = accountStorage.getItem(PROFILE_KEY)

    if (!raw) {
      return {
        data: {},
        notice: 'Chưa có hồ sơ đã lưu. Hãy hoàn thiện Hồ sơ để tìm bạn ghép trọ.',
      }
    }

    const stored = JSON.parse(raw)

    if (!stored || typeof stored !== 'object' || Array.isArray(stored)) {
      throw new Error('Invalid profile')
    }

    const data = {}

    for (const key of ['gender', 'city', 'area', 'maxDistance']) {
      data[key] =
        typeof stored[key] === 'string' ? stored[key].trim() : ''
    }

    return { data, notice: '' }
  } catch {
    return {
      data: {},
      notice: 'Không đọc được hồ sơ. Hãy mở Hồ sơ và lưu lại thông tin.',
    }
  }
}

function uniqueLocations(values) {
  const result = new Map()

  for (const value of values) {
    if (normalize(value)) {
      result.set(normalize(value), value)
    }
  }

  return [...result.values()]
}

function locationText(student) {
  return `${student.city} · ${student.area} · ${student.location}`
}

export default function Discover({ initialPurpose = 'Tất cả' }) {
  const [profileResult] = useState(readProfile)
  const profile = profileResult.data

  const initialDistance = ['1', '3', '5', '10'].includes(profile.maxDistance)
    ? profile.maxDistance
    : '5'

  const [search, setSearch] = useState('')
  const [purpose, setPurpose] = useState(initialPurpose)
  const [city, setCity] = useState(profile.city || '')
  const [area, setArea] = useState(profile.area || '')
  const [maxDistance, setMaxDistance] = useState(initialDistance)
  const [selectedId, setSelectedId] = useState(null)
  const [isFiltersOpen, setIsFiltersOpen] = useState(false)
  const [undoStudent, setUndoStudent] = useState(null)
  const [requestError, setRequestError] = useState('')
  const [sentIds, setSentIds] = useState(() => {
  try {
    return readConnections().map((item) => item.id)
  } catch {
    return []
  }
})
  const [hiddenIds, setHiddenIds] = useState([])
  const dialogRef = useRef(null)
  const lastProfileTriggerRef = useRef(null)

  const canFilterRoommates = ['Nam', 'Nữ', 'Khác'].includes(profile.gender)

  const cities = uniqueLocations([
    ...VIETNAM_LOCATIONS,
    profile.city,
  ])

  const areas = uniqueLocations([
    ...students
      .filter((student) => !city || normalize(student.city) === normalize(city))
      .map((student) => student.area),
    ...(!city || normalize(city) === normalize(profile.city)
      ? [profile.area]
      : []),
  ])

  const filteredStudents = students.filter((student) => {
    const searchableText = normalize([
      student.name,
      student.major,
      student.city,
      student.area,
      student.location,
      ...student.skills,
    ].join(' '))

    // Quy tắc này áp dụng cả khi đang ở tab Tất cả.
    const genderMatches =
      student.purpose !== 'Ghép trọ' ||
      (canFilterRoommates && student.gender === profile.gender)

    return (
      searchableText.includes(normalize(search)) &&
      (purpose === 'Tất cả' || student.purpose === purpose) &&
      (!city || normalize(student.city) === normalize(city)) &&
      (!area || normalize(student.area) === normalize(area)) &&
      student.distance <= Number(maxDistance) &&
      genderMatches &&
      !hiddenIds.includes(student.id)
    )
  })

  const selectedStudent = filteredStudents.find(
    (student) => student.id === selectedId
  )

  useEffect(() => {
    if (!selectedStudent) return undefined

    dialogRef.current?.focus({ preventScroll: true })

    function handleEscape(event) {
      if (event.key === 'Escape') {
        closeProfile()
      }
    }

    document.addEventListener('keydown', handleEscape)
    return () => document.removeEventListener('keydown', handleEscape)
  }, [selectedStudent])

  function openProfile(studentId) {
    lastProfileTriggerRef.current = document.activeElement
    setSelectedId(studentId)
  }

  function closeProfile(restoreFocus = true) {
    setSelectedId(null)
    if (restoreFocus) {
      lastProfileTriggerRef.current?.focus({ preventScroll: true })
    }
  }

  function skipProfile() {
    if (!selectedStudent) return

    setHiddenIds((current) => [...current, selectedStudent.id])
    setUndoStudent(selectedStudent)
    closeProfile(false)
  }

  function sendRequest(id) {
  const student = filteredStudents.find((item) => item.id === id)
  if (!student) return

  try {
    // Đọc dữ liệu mới nhất để giữ các kết nối và tin nhắn đã có.
    const connections = readConnections()

    if (connections.some((item) => item.id === id)) {
      setSentIds(connections.map((item) => item.id))
      return
    }

    const newConnection = {
      id: student.id,
      name: student.name,
      major: student.major,
      purpose: student.purpose,
      city: student.city,
      area: student.area,
      location: student.location,
      status: 'pending',
      messages: [],
    }

    const updated = [...connections, newConnection]

    accountStorage.setItem(
      CONNECTIONS_KEY,
      JSON.stringify(updated)
    )

    setSentIds(updated.map((item) => item.id))
    setRequestError('')
  } catch {
    setRequestError('Chưa gửi được lời mời vì không đọc hoặc lưu được dữ liệu. Dữ liệu cũ chưa bị ghi đè.')
  }
}

  function resetFilters() {
    setSearch('')
    setPurpose('Tất cả')
    setCity('')
    setArea('')
    setMaxDistance('10')
    setHiddenIds([])
    setUndoStudent(null)
    closeProfile(false)
  }

  return (
    <AppLayout>
      <section className="discover-page">
        <header className="discover-header">
          <div>
            <p className="page-eyebrow">KHÁM PHÁ</p>
            <h1>Những kết nối phù hợp đang ở ngay quanh cậu.</h1>
            <p>Tìm theo mục tiêu, kỹ năng và khu vực — không phải lướt ngẫu nhiên.</p>
          </div>
          <div className="discover-head-actions">
            <span aria-live="polite"><strong>{filteredStudents.length}</strong> kết quả phù hợp</span>
            <Link to="/profile" className="secondary-action">Cập nhật tiêu chí</Link>
          </div>
        </header>

        <p className="discover-demo-note">
          Hồ sơ sinh viên và khoảng cách là dữ liệu mẫu.
          Khoảng cách không được tính từ vị trí của cậu.
          Lời mời chỉ mô phỏng trong trang hiện tại.
        </p>

        <div className="discover-trust-bar">
          <div><span><Icon name="profile" /></span><strong>Ẩn số điện thoại</strong><small>Chỉ chia sẻ khi cậu muốn</small></div>
          <div><span><Icon name="room" /></span><strong>Vị trí gần đúng</strong><small>Không hiển thị số nhà</small></div>
          <div><span><Icon name="discover" /></span><strong>Lọc theo mục tiêu</strong><small>Học tập, dự án hoặc ghép trọ</small></div>
        </div>

        {profileResult.notice && (
          <div className="form-error-banner" role="status">
            {profileResult.notice}{' '}
            <Link to="/profile">Mở Hồ sơ</Link>
          </div>
        )}

        {requestError && (
          <div className="form-error-banner" role="alert" aria-live="assertive">
            {requestError}
          </div>
        )}

        <div className="discover-layout">
          <button
            type="button"
            className="discover-filter-toggle"
            aria-expanded={isFiltersOpen}
            aria-controls="discover-filters"
            onClick={() => setIsFiltersOpen((current) => !current)}
          >
            <span><Icon name="discover" /> Bộ lọc</span>
            <strong>{isFiltersOpen ? 'Thu gọn' : 'Mở bộ lọc'}</strong>
          </button>

          <aside
            id="discover-filters"
            className={`discover-filter-panel ${isFiltersOpen ? 'is-open' : ''}`}
          >
            <div className="filter-title">
              <h2>Bộ lọc</h2>
              <button type="button" onClick={resetFilters}>
                Đặt lại
              </button>
            </div>

            <label className="discover-filter-field">
              <span>Tên, ngành, kỹ năng hoặc địa điểm</span>
              <input
                type="search"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Ví dụ: React, Cầu Giấy"
              />
            </label>

            <label className="discover-filter-field">
              <span>Tỉnh / Thành phố</span>
              <select
                value={city}
                onChange={(event) => {
                  setCity(event.target.value)
                  setArea('')
                  setSelectedId(null)
                }}
              >
                <option value="">Tất cả tỉnh / thành phố</option>
                {cities.map((item) => (
                  <option key={normalize(item)} value={item}>
                    {item}
                  </option>
                ))}
              </select>
            </label>

            <label className="discover-filter-field">
              <span>Khu vực</span>
              <select
                value={area}
                onChange={(event) => {
                  setArea(event.target.value)
                  setSelectedId(null)
                }}
              >
                <option value="">Tất cả khu vực</option>
                {areas.map((item) => (
                  <option key={normalize(item)} value={item}>
                    {item}
                  </option>
                ))}
              </select>
            </label>

            <label className="discover-filter-field">
              <span>Khoảng cách tối đa — số liệu mẫu</span>
              <select
                value={maxDistance}
                onChange={(event) => setMaxDistance(event.target.value)}
              >
                <option value="1">1 km</option>
                <option value="3">3 km</option>
                <option value="5">5 km</option>
                <option value="10">10 km</option>
              </select>
            </label>

            <div className="privacy-filter-note">
              <strong>Giới tính từ Hồ sơ</strong>
              <p>{profile.gender || 'Chưa có thông tin'}</p>
              <Link to="/profile">Chỉnh sửa Hồ sơ</Link>

              <p>
                Hồ sơ ghép trọ chỉ xuất hiện khi cùng giới tính đã lưu.
                Học nhóm và Team Project không bị giới hạn giới tính.
              </p>

              {!canFilterRoommates && (
                <p>
                  Chưa hiển thị hồ sơ ghép trọ vì thiếu thông tin
                  dùng để lọc. Cậu vẫn có thể tìm bạn học và team.
                </p>
              )}

              <p>
                Không công khai số điện thoại hoặc số nhà.
                Lọc giới tính không thay thế việc xác minh danh tính.
              </p>
            </div>
          </aside>

          <div className="discover-results">
            <div className="discover-results-toolbar">
              <div>
                <strong>{filteredStudents.length} kết quả phù hợp</strong>
                <span>Ưu tiên theo mục tiêu và khu vực cậu chọn</span>
              </div>
              <button type="button" onClick={resetFilters}>Đặt lại bộ lọc</button>
            </div>

            <div className="purpose-tabs" aria-label="Mục tiêu kết nối">
              {purposes.map((item) => (
                <button
                  key={item}
                  type="button"
                  className={purpose === item ? 'active' : ''}
                  aria-pressed={purpose === item}
                  onClick={() => {
                    setPurpose(item)
                    closeProfile(false)
                  }}
                >
                  {item}
                </button>
              ))}
            </div>

            <div className="student-card-grid">
              {filteredStudents.map((student) => {
                const sent = sentIds.includes(student.id)
                const purposeClass = student.purpose === 'Học nhóm'
                  ? 'purpose-study-card'
                  : student.purpose === 'Team Project'
                    ? 'purpose-team-card'
                    : 'purpose-room-card'

                return (
                  <article
                    className={`discover-student-card ${purposeClass}`}
                    key={student.id}
                  >
                    <div className="discover-avatar">
                      {student.name.split(' ').slice(-1)[0][0]}
                    </div>

                    <span className="student-purpose">
                      {student.purpose}
                    </span>

                    <div className="student-main-info">
                      <h2>{student.name}</h2>
                      <p>{student.major}</p>
                    </div>

                    <div className="student-skill-list">
                      {student.skills.map((skill) => (
                        <span key={skill}>{skill}</span>
                      ))}
                    </div>

                    <p className="student-location">
                      {locationText(student)}
                      <br />
                      Khoảng cách mẫu:{' '}
                      {student.distance.toLocaleString('vi-VN')} km
                    </p>

                    <p className="student-about">{student.about}</p>

                    <div className="student-card-actions">
                      <button
                        type="button"
                        className="view-student-button"
                        onClick={() => openProfile(student.id)}
                      >
                        Xem hồ sơ
                      </button>

                      <button
                        type="button"
                        className="connect-student-button"
                        disabled={sent}
                        onClick={() => sendRequest(student.id)}
                      >
                        {sent ? 'Đã gửi lời mời' : 'Kết nối'}
                      </button>
                    </div>
                  </article>
                )
              })}
            </div>

            {filteredStudents.length === 0 && (
              <div className="discover-empty-state">
                <div className="discover-empty-icon" aria-hidden="true"><Icon name="discover" /></div>
                <h2>Chưa có kết quả phù hợp</h2>
                <p>
                  Bộ dữ liệu mẫu chưa bao phủ mọi khu vực.
                  Thử đổi địa điểm, tăng khoảng cách hoặc đặt lại bộ lọc.
                </p>
                <button type="button" onClick={resetFilters}>
                  Đặt lại bộ lọc
                </button>
              </div>
            )}

            {undoStudent && (
              <div className="discover-undo-notice" role="status">
                <span>Đã ẩn hồ sơ {undoStudent.name} khỏi kết quả hiện tại.</span>
                <button
                  type="button"
                  onClick={() => {
                    setHiddenIds((current) => current.filter((id) => id !== undoStudent.id))
                    setUndoStudent(null)
                  }}
                >
                  Hoàn tác
                </button>
              </div>
            )}
          </div>
        </div>

        {selectedStudent && (
          <div className="discover-dialog-backdrop" role="presentation" onMouseDown={(event) => {
            if (event.target === event.currentTarget) closeProfile()
          }}>
            <section
              ref={dialogRef}
              className="discover-profile-dialog"
              role="dialog"
              aria-modal="true"
              aria-labelledby="discover-dialog-title"
              tabIndex="-1"
            >
              <header className="discover-dialog-header">
                <div className="discover-avatar">
                  {selectedStudent.name.split(' ').slice(-1)[0][0]}
                </div>
                <div>
                  <p className="discover-dialog-kicker">HỒ SƠ SINH VIÊN</p>
                  <h2 id="discover-dialog-title">{selectedStudent.name}</h2>
                  <p>{selectedStudent.purpose} · {selectedStudent.major}</p>
                </div>
                <button type="button" className="discover-dialog-close" onClick={closeProfile}>
                  Đóng
                </button>
              </header>

              <div className="discover-dialog-body">
                <div className="discover-dialog-section">
                  <span>Giới thiệu</span>
                  <p>{selectedStudent.about}</p>
                </div>
                <div className="discover-dialog-section">
                  <span>Khu vực gần đúng</span>
                  <p>{locationText(selectedStudent)}</p>
                  <small>Không hiển thị số nhà hoặc thông tin liên hệ cá nhân.</small>
                </div>
                <div className="discover-dialog-section">
                  <span>Kỹ năng và điểm chung</span>
                  <div className="student-skill-list">
                    {selectedStudent.skills.map((skill) => <span key={skill}>{skill}</span>)}
                  </div>
                </div>
              </div>

              <footer className="discover-dialog-actions">
                <button type="button" className="view-student-button" onClick={skipProfile}>
                  Bỏ qua hồ sơ
                </button>
                <button
                  type="button"
                  className="connect-student-button"
                  disabled={sentIds.includes(selectedStudent.id)}
                  onClick={() => sendRequest(selectedStudent.id)}
                >
                  {sentIds.includes(selectedStudent.id) ? 'Đã gửi lời mời' : 'Gửi lời mời'}
                </button>
              </footer>
            </section>
          </div>
        )}
      </section>
    </AppLayout>
  )
}
