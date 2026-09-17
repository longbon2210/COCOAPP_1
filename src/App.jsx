import { Fragment, useEffect, useState } from 'react'
import {
  BrowserRouter,
  Routes,
  Route,
  Navigate,
} from 'react-router-dom'

import Login from './pages/Login'
import Register from './pages/Register'
import Dashboard from './pages/Dashboard'
import Profile from './pages/Profile'
import Discover from './pages/Discover'
import Matches from './pages/Matches'
import {
  getCurrentAccount,
  subscribeToAuthState,
} from './auth'
import './App.css'
import './ProductV2.css'

function RequireLogin({ children, account, isCheckingSession }) {
  if (isCheckingSession) return null

  if (!account) {
    return <Navigate to="/login" replace />
  }

  return (
    <Fragment key={account.id}>
      {children}
    </Fragment>
  )
}

function protectedPage(page, account, isCheckingSession) {
  return (
    <RequireLogin
      account={account}
      isCheckingSession={isCheckingSession}
    >
      {page}
    </RequireLogin>
  )
}

export default function App() {
  const [account, setAccount] = useState(null)
  const [isCheckingSession, setIsCheckingSession] = useState(true)

  useEffect(() => {
    let isMounted = true

    getCurrentAccount()
      .then((user) => {
        if (isMounted) setAccount(user)
      })
      .catch(() => {
        if (isMounted) setAccount(null)
      })
      .finally(() => {
        if (isMounted) setIsCheckingSession(false)
      })

    const unsubscribe = subscribeToAuthState((user) => {
      if (isMounted) {
        setAccount(user)
        setIsCheckingSession(false)
      }
    })

    return () => {
      isMounted = false
      unsubscribe()
    }
  }, [])

  return (
    <BrowserRouter>
      {isCheckingSession && (
        <div className="auth-session-loading" role="status" aria-live="polite">
          Đang kiểm tra phiên đăng nhập…
        </div>
      )}

      <Routes>
        <Route
          path="/"
          element={<Navigate to="/dashboard" replace />}
        />

        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />

        <Route
          path="/dashboard"
          element={protectedPage(<Dashboard />, account, isCheckingSession)}
        />

        <Route
          path="/profile"
          element={protectedPage(<Profile />, account, isCheckingSession)}
        />

        <Route
          path="/discover"
          element={protectedPage(<Discover key="discover" />, account, isCheckingSession)}
        />

        <Route
          path="/study"
          element={protectedPage(<Discover key="study" initialPurpose="Học nhóm" />, account, isCheckingSession)}
        />

        <Route
          path="/team"
          element={protectedPage(<Discover key="team" initialPurpose="Team Project" />, account, isCheckingSession)}
        />

        <Route
          path="/roommates"
          element={protectedPage(<Discover key="roommates" initialPurpose="Ghép trọ" />, account, isCheckingSession)}
        />

        <Route
          path="/matches"
          element={protectedPage(<Matches />, account, isCheckingSession)}
        />

        <Route
          path="*"
          element={<Navigate to="/dashboard" replace />}
        />
      </Routes>
    </BrowserRouter>
  )
}
