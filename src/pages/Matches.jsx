import { useState } from 'react'
import { Link } from 'react-router-dom'
import AppLayout from '../components/AppLayout'
import { accountStorage } from '../auth'

const CONNECTIONS_KEY = 'cocoapp.connections.v1'

function readConnections() {
  try {
    const raw = accountStorage.getItem(CONNECTIONS_KEY)

    if (!raw) return { items: [], error: '' }

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
      throw new Error('Invalid connections')
    }

    return { items, error: '' }
  } catch {
    return {
      items: [],
      error: 'Không đọc được danh sách kết nối. Dữ liệu cũ chưa bị ghi đè.',
    }
  }
}

export default function Matches() {
  const [initial] = useState(readConnections)
  const [connections, setConnections] = useState(initial.items)
  const [error, setError] = useState(initial.error)
  const [tab, setTab] = useState('pending')
  const [chatId, setChatId] = useState(null)
  const [draft, setDraft] = useState('')

  const pendingCount = connections.filter(
    (item) => item.status === 'pending'
  ).length

  const acceptedCount = connections.filter(
    (item) => item.status === 'accepted'
  ).length

  const visibleConnections = connections.filter(
    (item) => item.status === tab
  )

  const chat = connections.find(
    (item) => item.id === chatId && item.status === 'accepted'
  )

  function saveConnections(next) {
    if (initial.error) {
      setError('Cần kiểm tra dữ liệu đã lưu trước khi thay đổi kết nối.')
      return false
    }

    try {
      accountStorage.setItem(CONNECTIONS_KEY, JSON.stringify(next))
      setConnections(next)
      setError('')
      return true
    } catch {
      setError('Chưa lưu được thay đổi. Hãy thử lại.')
      return false
    }
  }

  function acceptRequest(id) {
    const next = connections.map((item) =>
      item.id === id && item.status === 'pending'
        ? { ...item, status: 'accepted' }
        : item
    )

    if (saveConnections(next)) {
      setTab('accepted')
    }
  }

  function cancelRequest(id) {
    const next = connections.filter(
      (item) => !(item.id === id && item.status === 'pending')
    )

    saveConnections(next)
  }

  function openChat(id) {
    setChatId(id)
    setDraft('')
  }

  function sendMessage(event) {
    event.preventDefault()

    const text = draft.trim()
    if (!text || !chat) return

    const message = {
      id: crypto.randomUUID(),
      sender: 'me',
      text,
    }

    const next = connections.map((item) =>
      item.id === chat.id
        ? { ...item, messages: [...item.messages, message] }
        : item
    )

    if (saveConnections(next)) {
      setDraft('')
    }
  }

  function simulateReply() {
    if (!chat) return

    const message = {
      id: crypto.randomUUID(),
      sender: 'other',
      text: 'Chào cậu! Mình đã nhận được lời nhắn. Cùng trao đổi thêm nhé.',
    }

    const next = connections.map((item) =>
      item.id === chat.id
        ? { ...item, messages: [...item.messages, message] }
        : item
    )

    saveConnections(next)
  }

  return (
    <AppLayout>
      <section className="discover-page matches-page">
        <header className="discover-header">
          <div>
            <p className="page-eyebrow">KẾT NỐI</p>
            <h1>Biến lời mời thành những cuộc trò chuyện có ích.</h1>
            <p>Quản lý kết nối, phản hồi lời mời và tiếp tục trao đổi tại một nơi.</p>
          </div>

          <Link to="/discover" className="banner-button">
            Tìm thêm bạn
          </Link>
        </header>

        <p className="discover-demo-note">
          Bản demo trên trình duyệt này. Nút mô phỏng dùng để
          trình diễn người kia chấp nhận hoặc trả lời;
          không gửi thông báo đến người thật.
        </p>

        <div className="matches-summary">
          <div className="matches-summary-copy">
            <span className="summary-live-dot" />
            <div><strong>Không gian kết nối của cậu</strong><small>Dữ liệu hiện được lưu riêng theo tài khoản trên trình duyệt này.</small></div>
          </div>
          <div className="matches-summary-stats">
            <span><strong>{pendingCount}</strong> đang chờ</span>
            <span><strong>{acceptedCount}</strong> đã kết nối</span>
          </div>
        </div>

        {error && (
          <div className="form-error-banner" role="alert">
            {error}
          </div>
        )}

        <div className="purpose-tabs" aria-label="Trạng thái kết nối">
          <button
            type="button"
            className={tab === 'pending' ? 'active' : ''}
            aria-pressed={tab === 'pending'}
            onClick={() => {
              setTab('pending')
              setChatId(null)
              setDraft('')
            }}
          >
            Đang chờ ({pendingCount})
          </button>

          <button
            type="button"
            className={tab === 'accepted' ? 'active' : ''}
            aria-pressed={tab === 'accepted'}
            onClick={() => setTab('accepted')}
          >
            Đã kết nối ({acceptedCount})
          </button>
        </div>

        {visibleConnections.length === 0 ? (
          <div className="discover-empty-state">
            <h2>
              {tab === 'pending'
                ? 'Chưa có lời mời đang chờ'
                : 'Chưa có kết nối được chấp nhận'}
            </h2>
            <p>
              {tab === 'pending'
                ? 'Tìm người phù hợp trong trang Khám phá.'
                : 'Kết nối sẽ xuất hiện tại đây sau khi lời mời được chấp nhận.'}
            </p>
            <Link to="/discover">Mở Khám phá →</Link>
          </div>
        ) : (
          <div className="student-card-grid">
            {visibleConnections.map((item) => (
              <article className="discover-student-card connection-card" key={item.id}>
                <div className="discover-avatar">
                  {item.name.trim().split(/\s+/).pop()?.[0] || '?'}
                </div>

                <div className="student-main-info">
                  <h2>{item.name}</h2>
                  <p>{item.major}</p>
                </div>

                <span className="student-purpose">{item.purpose}</span>

                <p className="student-location">
                  {[item.city, item.area, item.location]
                    .filter(Boolean)
                    .join(' · ')}
                </p>

                <p className="student-about">
                  {item.status === 'pending'
                    ? 'Đã gửi lời mời. Chưa thể trò chuyện.'
                    : 'Lời mời đã được chấp nhận trong bản demo.'}
                </p>

                <div className="student-card-actions">
                  {item.status === 'pending' ? (
                    <>
                      <button
                        type="button"
                        className="view-student-button"
                        onClick={() => cancelRequest(item.id)}
                      >
                        Hủy lời mời
                      </button>

                      <button
                        type="button"
                        className="connect-student-button"
                        onClick={() => acceptRequest(item.id)}
                      >
                        Mô phỏng người kia chấp nhận
                      </button>
                    </>
                  ) : (
                    <button
                      type="button"
                      className="connect-student-button"
                      onClick={() => openChat(item.id)}
                    >
                      Mở trò chuyện
                    </button>
                  )}
                </div>
              </article>
            ))}
          </div>
        )}

        {chat && tab === 'accepted' && (
          <section className="discover-detail-panel chat-panel" aria-label="Trò chuyện">
            <button
              type="button"
              onClick={() => {
                setChatId(null)
                setDraft('')
              }}
            >
              Đóng trò chuyện
            </button>

            <h2>Trò chuyện với {chat.name}</h2>

            <div
              className="chat-message-list"
              role="log"
              aria-label="Tin nhắn"
              aria-live="polite"
            >
              {chat.messages.length === 0 && (
                <p>Chưa có tin nhắn. Hãy gửi lời chào đầu tiên.</p>
              )}

              {chat.messages.map((message) => (
                <div
                  key={message.id}
                  className={`chat-message ${message.sender === 'me' ? 'from-me' : 'from-other'}`}
                >
                  <strong>
                    {message.sender === 'me' ? 'Cậu' : `${chat.name} (mô phỏng)`}
                  </strong>
                  <div>{message.text}</div>
                </div>
              ))}
            </div>

            <form onSubmit={sendMessage}>
              <label className="profile-field">
                <span>Tin nhắn</span>
                <textarea
                  value={draft}
                  onChange={(event) => setDraft(event.target.value)}
                  placeholder="Nhập lời chào..."
                  maxLength={1000}
                  required
                />
              </label>

              <div className="student-card-actions" style={{ marginTop: 12 }}>
                <button
                  type="submit"
                  className="connect-student-button"
                  disabled={!draft.trim()}
                >
                  Gửi tin nhắn
                </button>

                <button
                  type="button"
                  className="view-student-button"
                  onClick={simulateReply}
                >
                  Mô phỏng phản hồi
                </button>
              </div>
            </form>
          </section>
        )}
      </section>
    </AppLayout>
  )
}
