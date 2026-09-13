import { Fragment } from 'react'
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
import { currentAccount } from './auth'
import './App.css'

function RequireLogin({ children }) {
  const account = currentAccount()

  if (!account) {
    return <Navigate to="/login" replace />
  }

  return (
    <Fragment key={account.id}>
      {children}
    </Fragment>
  )
}

function protectedPage(page) {
  return <RequireLogin>{page}</RequireLogin>
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route
          path="/"
          element={<Navigate to="/dashboard" replace />}
        />

        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />

        <Route
          path="/dashboard"
          element={protectedPage(<Dashboard />)}
        />

        <Route
          path="/profile"
          element={protectedPage(<Profile />)}
        />

        <Route
          path="/discover"
          element={protectedPage(
            <Discover key="discover" />
          )}
        />

        <Route
          path="/study"
          element={protectedPage(
            <Discover
              key="study"
              initialPurpose="Học nhóm"
            />
          )}
        />

        <Route
          path="/team"
          element={protectedPage(
            <Discover
              key="team"
              initialPurpose="Team Project"
            />
          )}
        />

        <Route
          path="/roommates"
          element={protectedPage(
            <Discover
              key="roommates"
              initialPurpose="Ghép trọ"
            />
          )}
        />

        <Route
          path="/matches"
          element={protectedPage(<Matches />)}
        />

        <Route
          path="*"
          element={<Navigate to="/dashboard" replace />}
        />
      </Routes>
    </BrowserRouter>
  )
}