import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import AppLayout, { Icon } from '../components/AppLayout'
import { accountStorage, getCurrentAccount } from '../auth'
import { supabase } from '../lib/supabaseClient'

const MESSAGES_KEY_PREFIX = 'cocoapp.connection-messages.'
const purposeLabels = {
  study_group: 'Học nhóm',
  team_project: 'Team Project',
  roommates: 'Ghép trọ',
}

function readMessages(id) {
  try {
    const raw = accountStorage.getItem(`${MESSAGES_KEY_PREFIX}${id}`)
    const messages = raw ? JSON.parse(raw) : []

    if (!Array.isArray(messages)) throw new Error('Invalid messages')
    return messages
  } catch {
    return []
  }
}

function writeMessages(id, messages) {
  accountStorage.setItem(
    `${MESSAGES_KEY_PREFIX}${id}`,
    JSON.stringify(messages)
  )
}

function mapRequest(request, userId) {
  const isIncoming = request.recipient_id === userId
  const otherProfile = isIncoming ? request.requester : request.recipient

  return {
    id: request.id,
    name: otherProfile?.full_name?.trim() || 'Sinh viên CocoApp',
    major: otherProfile?.major?.trim() || 'Chưa cập nhật ngành học',
    purpose: purposeLabels[request.purpose] || 'Kết nối',
    city: otherProfile?.city?.trim() || '',
    area: otherProfile?.area?.trim() || '',
    location: otherProfile?.public_location?.trim() || '',
    about: otherProfile?.bio?.trim() || 'Chưa có giới thiệu.',
    status: request.status,
    isIncoming,
    requesterId: request.requester_id,
    recipientId: request.recipient_id,
    messages: readMessages(request.id),
  }
}

const profileFields = 'id, full_name, major, purpose, city, area, public_location, bio'
const requestSelect = `id, requester_id, recipient_id, purpose, status, created_at, responded_at, requester:profiles!connection_requests_requester_id_fkey (${profileFields}), recipient:profiles!connection_requests_recipient_id_fkey (${profileFields})`

function getMatchesErrorMessage(error) {
  if (error?.message?.toLowerCase().includes('row-level security')) {
    return 'Không thể tải hoặc cập nhật lời mời do quyền truy cập. Hãy đăng nhập lại.'
  }

  return 'Không thể tải danh sách kết nối. Hãy thử lại sau.'
}

async function fetchConnections() {
  const user = await getCurrentAccount()
  if (!user) throw new Error('Phiên đăng nhập đã hết.')

  const { data, error } = await supabase
    .from('connection_requests')
    .select(requestSelect)
    .or(`requester_id.eq.${user.id},recipient_id.eq.${user.id}`)
    .order('created_at', { ascending: false })

  if (error) throw error

  return (data || []).map((request) => mapRequest(request, user.id))
}

export default function Matches() {
  const [connections, setConnections] = useState([])
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [actionId, setActionId] = useState(null)
  const [tab, setTab] = useState('pending')
  const [chatId, setChatId] = useState(null)
  const [draft, setDraft] = useState('')
  const [statusMessage, setStatusMessage] = useState('')
  const [confirmation, setConfirmation] = useState(null)
  const chatHeadingRef = useRef(null)
  const messageListRef = useRef(null)
  const lastChatTriggerRef = useRef(null)
  const shouldFocusChatRef = useRef(false)
  const confirmationTriggerRef = useRef(null)

  useEffect(() => {
    let isMounted = true

    fetchConnections()
      .then((nextConnections) => {
        if (isMounted) setConnections(nextConnections)
      })
      .catch((loadError) => {
        if (isMounted) setError(getMatchesErrorMessage(loadError))
      })
      .finally(() => {
        if (isMounted) setIsLoading(false)
      })

    return () => {
      isMounted = false
    }
  }, [])

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
  const chatMessageCount = chat?.messages.length ?? 0

  const acceptedConnections = connections.filter(
    (item) => item.status === 'accepted'
  )

  useEffect(() => {
    if (chat && shouldFocusChatRef.current) {
      chatHeadingRef.current?.focus({ preventScroll: true })
      shouldFocusChatRef.current = false
    }
  }, [chat, chatId])

  useEffect(() => {
    if (chatId !== null) {
      const messageList = messageListRef.current
      if (messageList) messageList.scrollTop = messageList.scrollHeight
    }
  }, [chatId, chatMessageCount])

  async function updateRequest(id, status) {
    const request = connections.find((item) => item.id === id)
    if (!request || !['pending', 'accepted'].includes(request.status) || actionId) return

    setActionId(id)
    setError('')

    try {
      const { error: updateError } = await supabase
        .from('connection_requests')
        .update({ status })
        .eq('id', id)

      if (updateError) throw updateError

      const nextConnections = await fetchConnections()
      setConnections(nextConnections)
      setStatusMessage(
        status === 'accepted'
          ? 'Đã chấp nhận lời mời kết nối.'
          : status === 'declined'
            ? 'Đã từ chối lời mời kết nối.'
            : 'Đã hủy lời mời kết nối.'
      )
      if (status === 'cancelled' && chatId === id) closeChat()
      if (status === 'accepted') setTab('accepted')
    } catch (updateError) {
      setError(getMatchesErrorMessage(updateError))
    } finally {
      setActionId(null)
    }
  }

  function cancelRequest(id) {
    const connection = connections.find((item) => item.id === id)
    if (!connection) return

    confirmationTriggerRef.current = document.activeElement
    setConfirmation({
      id,
      title: 'Hủy lời mời kết nối?',
      message: `Lời mời gửi cho ${connection.name} sẽ được hủy.`,
      actionLabel: 'Hủy lời mời',
    })
  }

  function disconnectConnection(id) {
    const connection = connections.find((item) => item.id === id)
    if (!connection) return

    confirmationTriggerRef.current = document.activeElement
    setConfirmation({
      id,
      title: 'Ngắt kết nối?',
      message: `Cậu và ${connection.name} sẽ không còn ở trạng thái kết nối. Lịch sử tin nhắn vẫn được giữ lại.`,
      actionLabel: 'Ngắt kết nối',
    })
  }

  function closeConfirmation() {
    setConfirmation(null)
    confirmationTriggerRef.current?.focus({ preventScroll: true })
  }

  async function confirmConnectionAction() {
    if (!confirmation) return

    const { id } = confirmation
    setConfirmation(null)
    await updateRequest(id, 'cancelled')
    confirmationTriggerRef.current?.focus({ preventScroll: true })
  }

  function openChat(id) {
    lastChatTriggerRef.current = document.activeElement
    if (document.activeElement instanceof HTMLElement) {
      document.activeElement.blur()
    }
    shouldFocusChatRef.current = window.matchMedia('(max-width: 760px)').matches
    setChatId(id)
    setDraft('')
  }

  function closeChat() {
    setChatId(null)
    setDraft('')
    lastChatTriggerRef.current?.focus({ preventScroll: true })
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

    try {
      const messages = [...chat.messages, message]
      writeMessages(chat.id, messages)
      setConnections((current) => current.map((item) =>
        item.id === chat.id ? { ...item, messages } : item
      ))
      setDraft('')
    } catch {
      setError('Chưa lưu được tin nhắn. Hãy thử lại.')
    }
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
          Lời mời được lưu trên Supabase. Tin nhắn vẫn được lưu
          riêng trên trình duyệt trong giai đoạn này.
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

        {statusMessage && (
          <div className="matches-status-message" role="status" aria-live="polite">
            <Icon name="connection" /> {statusMessage}
          </div>
        )}

        {isLoading && (
          <div className="form-error-banner" role="status" aria-live="polite">
            Đang tải lời mời kết nối…
          </div>
        )}

        {confirmation && (
          <div className="discover-dialog-backdrop" role="presentation">
            <section
              className="discover-profile-dialog connection-confirmation-dialog"
              role="alertdialog"
              aria-modal="true"
              aria-labelledby="connection-confirmation-title"
              aria-describedby="connection-confirmation-message"
            >
              <div className="discover-dialog-body">
                <div className="discover-dialog-section">
                  <h2 id="connection-confirmation-title">{confirmation.title}</h2>
                  <p id="connection-confirmation-message">{confirmation.message}</p>
                </div>
              </div>
              <footer className="discover-dialog-actions">
                <button
                  type="button"
                  className="view-student-button"
                  onClick={closeConfirmation}
                >
                  Quay lại
                </button>
                <button
                  type="button"
                  className="connect-student-button"
                  autoFocus
                  disabled={actionId === confirmation.id}
                  onClick={confirmConnectionAction}
                >
                  {actionId === confirmation.id ? 'Đang cập nhật…' : confirmation.actionLabel}
                </button>
              </footer>
            </section>
          </div>
        )}

        <div className="purpose-tabs matches-tabs" role="tablist" aria-label="Trạng thái kết nối">
          <button
            type="button"
            className={tab === 'pending' ? 'active' : ''}
            id="pending-tab"
            role="tab"
            aria-selected={tab === 'pending'}
            aria-controls="matches-panel"
            onClick={() => {
              setTab('pending')
              closeChat()
            }}
          >
            Đang chờ ({pendingCount})
          </button>

          <button
            type="button"
            className={tab === 'accepted' ? 'active' : ''}
            id="accepted-tab"
            role="tab"
            aria-selected={tab === 'accepted'}
            aria-controls="matches-panel"
            onClick={() => {
              setTab('accepted')
              closeChat()
            }}
          >
            Đã kết nối ({acceptedCount})
          </button>
        </div>

        {!isLoading && visibleConnections.length === 0 ? (
          <div id="matches-panel" role="tabpanel" aria-labelledby={`${tab}-tab`} className="discover-empty-state">
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
        ) : tab === 'accepted' ? (
          <div id="matches-panel" role="tabpanel" aria-labelledby="accepted-tab" className={`messenger-workspace ${chat ? 'has-active-chat' : ''}`}>
            <aside className="conversation-list" aria-label="Danh sách cuộc trò chuyện">
              <div className="conversation-list-header">
                <div>
                  <h2>Cuộc trò chuyện</h2>
                  <p>{acceptedConnections.length} kết nối đã chấp nhận</p>
                </div>
              </div>

              <div className="conversation-list-items">
                {acceptedConnections.map((item) => {
                  const lastMessage = item.messages[item.messages.length - 1]

                  return (
                    <button
                      key={item.id}
                      type="button"
                      className={`conversation-item ${chatId === item.id ? 'active' : ''}`}
                      aria-pressed={chatId === item.id}
                      onMouseDown={(event) => event.preventDefault()}
                      onClick={() => openChat(item.id)}
                    >
                      <span className="conversation-avatar">
                        {item.name.trim().split(/\s+/).pop()?.[0] || '?'}
                      </span>
                      <span className="conversation-item-copy">
                        <strong>{item.name}</strong>
                        <small>{lastMessage?.text || item.purpose || 'Sẵn sàng trò chuyện'}</small>
                      </span>
                    </button>
                  )
                })}
              </div>
            </aside>

            {chat ? (
              <section className="chat-panel" aria-label={`Trò chuyện với ${chat.name}`}>
                <header className="chat-header">
                  <button
                    type="button"
                    className="chat-back-button"
                    onClick={closeChat}
                  >
                    <Icon name="arrow" /> Quay lại
                  </button>
                  <div className="chat-header-person">
                    <span className="conversation-avatar">
                      {chat.name.trim().split(/\s+/).pop()?.[0] || '?'}
                    </span>
                    <div>
                      <h2 ref={chatHeadingRef} tabIndex="-1">{chat.name}</h2>
                      <p><span className="chat-status-dot" /> Đã kết nối · {chat.purpose || 'Cộng đồng sinh viên'}</p>
                    </div>
                  </div>
                  <button
                    type="button"
                    className="chat-close-button"
                    onClick={closeChat}
                  >
                    Đóng trò chuyện
                  </button>
                  <button
                    type="button"
                    className="view-student-button"
                    onClick={() => disconnectConnection(chat.id)}
                  >
                    Ngắt kết nối
                  </button>
                </header>

                <div
                  ref={messageListRef}
                  className="chat-message-list"
                  role="log"
                  aria-label={`Tin nhắn với ${chat.name}`}
                  aria-live="polite"
                >
                  {chat.messages.length === 0 && (
                    <p className="chat-empty-message">Chưa có tin nhắn. Hãy gửi lời chào đầu tiên.</p>
                  )}

                  {chat.messages.map((message) => (
                    <div
                      key={message.id}
                      className={`chat-message ${message.sender === 'me' ? 'from-me' : 'from-other'}`}
                    >
                      <strong>
                        {message.sender === 'me' ? 'Cậu' : chat.name}
                      </strong>
                      <div>{message.text}</div>
                    </div>
                  ))}
                </div>

                <form className="chat-composer" onSubmit={sendMessage}>
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

                  <div className="chat-composer-actions">
                    <button
                      type="submit"
                      className="connect-student-button"
                      disabled={!draft.trim()}
                    >
                      Gửi tin nhắn
                    </button>

                  </div>
                </form>
              </section>
            ) : (
              <div className="chat-placeholder" role="status">
                <div className="chat-placeholder-icon" aria-hidden="true">C</div>
                <h2>Chọn một cuộc trò chuyện</h2>
                <p>Chọn một kết nối bên trái để tiếp tục trao đổi.</p>
              </div>
            )}
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
                    ? item.isIncoming
                      ? 'Lời mời đang chờ cậu phản hồi.'
                      : 'Đã gửi lời mời. Chưa thể trò chuyện.'
                    : 'Đã kết nối. Có thể bắt đầu trò chuyện.'}
                </p>

                <div className="student-card-actions">
                  {item.status === 'pending' ? (
                    <>
                      {item.isIncoming ? (
                        <>
                          <button
                            type="button"
                            className="view-student-button"
                            disabled={actionId === item.id}
                            onClick={() => updateRequest(item.id, 'declined')}
                          >
                            Từ chối
                          </button>
                          <button
                            type="button"
                            className="connect-student-button"
                            disabled={actionId === item.id}
                            onClick={() => updateRequest(item.id, 'accepted')}
                          >
                            {actionId === item.id ? 'Đang cập nhật…' : 'Chấp nhận'}
                          </button>
                        </>
                      ) : (
                        <button
                          type="button"
                          className="view-student-button"
                          disabled={actionId === item.id}
                          onClick={() => cancelRequest(item.id)}
                        >
                          {actionId === item.id ? 'Đang hủy…' : 'Hủy lời mời'}
                        </button>
                      )}
                    </>
                  ) : (
                    <>
                      <button
                        type="button"
                        className="connect-student-button"
                        onClick={() => openChat(item.id)}
                      >
                        Mở trò chuyện
                      </button>
                      <button
                        type="button"
                        className="view-student-button"
                        onClick={() => disconnectConnection(item.id)}
                      >
                        Ngắt kết nối
                      </button>
                    </>
                  )}
                </div>
              </article>
            ))}
          </div>
        )}

      </section>
    </AppLayout>
  )
}
