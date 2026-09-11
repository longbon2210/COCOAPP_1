import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Register from './pages/Register'
import Dashboard from './pages/Dashboard'
import Profile from './pages/Profile'
import Discover from './pages/Discover'
import Matches from './pages/Matches'
import './App.css'

function RequireDemoSession({ children }) {
  let loggedIn = false

  try {
    loggedIn =
      sessionStorage.getItem('cocoapp.demoSession.v1') === 'active'
  } catch {
    loggedIn = false
  }

  return loggedIn
    ? children
    : <Navigate to="/login" replace />
}

function protectedPage(page) {
  return <RequireDemoSession>{page}</RequireDemoSession>
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/dashboard" replace />} />

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
          element={protectedPage(<Discover key="discover" />)}
        />
        <Route
          path="/study"
          element={protectedPage(
            <Discover key="study" initialPurpose="Học nhóm" />
          )}
        />
        <Route
          path="/team"
          element={protectedPage(
            <Discover key="team" initialPurpose="Team Project" />
          )}
        />
        <Route
          path="/roommates"
          element={protectedPage(
            <Discover key="roommates" initialPurpose="Ghép trọ" />
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