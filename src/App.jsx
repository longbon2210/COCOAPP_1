import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Register from './pages/Register'
import './App.css'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Redirect root / to /login */}
        <Route path="/" element={<Navigate to="/login" replace />} />
        
        {/* Route for Login Page */}
        <Route path="/login" element={<Login />} />
        
        {/* Route for Register Page */}
        <Route path="/register" element={<Register />} />
        
        {/* Fallback wildcard to /login */}
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
