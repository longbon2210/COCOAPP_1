import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Layout from '../components/Layout'

export default function Register() {
  const navigate = useNavigate()
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [university, setUniversity] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [agreeTerms, setAgreeTerms] = useState(false)
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = (e) => {
    e.preventDefault()
    setErrorMessage('')

    if (password !== confirmPassword) {
      setErrorMessage('Passwords do not match. Please double-check.')
      return
    }

    if (password.length < 6) {
      setErrorMessage('Password must be at least 6 characters long.')
      return
    }

    if (!agreeTerms) {
      setErrorMessage('Please accept the Terms of Service to continue.')
      return
    }

    setIsLoading(true)
    // Simulated registration handler (no Firebase connection yet as per requirements)
    setTimeout(() => {
      setIsLoading(false)
      alert(`Account created successfully for ${fullName} (${email}) at ${university}!`)
      navigate('/login')
    }, 700)
  }

  const handleSSORegister = (provider) => {
    alert(`Initiating ${provider} sign-up for university students...`)
  }

  return (
    <Layout>
      <div className="login-card-container register-card-container">
        <div className="login-card register-card">
          {/* Card Header */}
          <div className="card-header">
            <h1 className="card-heading">Create your account</h1>
            <p className="card-subtitle">Join your university community on Coco</p>
          </div>

          {/* Error notification banner if any */}
          {errorMessage && (
            <div className="form-error-banner" role="alert">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
              </svg>
              <span>{errorMessage}</span>
            </div>
          )}

          {/* Registration Form */}
          <form className="login-form register-form" onSubmit={handleSubmit}>
            {/* Full Name */}
            <div className="form-group">
              <label htmlFor="full-name" className="form-label">
                Full Name
              </label>
              <div className="input-container">
                <span className="input-icon-left" aria-hidden="true">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path>
                    <circle cx="12" cy="7" r="4"></circle>
                  </svg>
                </span>
                <input
                  id="full-name"
                  name="name"
                  type="text"
                  className="form-input"
                  placeholder="Alex Johnson"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  required
                  autoComplete="name"
                />
              </div>
            </div>

            {/* University Email */}
            <div className="form-group">
              <label htmlFor="university-email" className="form-label">
                University Email
              </label>
              <div className="input-container">
                <span className="input-icon-left" aria-hidden="true">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect width="20" height="16" x="2" y="4" rx="2"></rect>
                    <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"></path>
                  </svg>
                </span>
                <input
                  id="university-email"
                  name="email"
                  type="email"
                  className="form-input"
                  placeholder="student@university.edu"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  autoComplete="username"
                />
              </div>
            </div>

            {/* University or School */}
            <div className="form-group">
              <label htmlFor="university-school" className="form-label">
                University or School
              </label>
              <div className="input-container">
                <span className="input-icon-left" aria-hidden="true">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                    <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
                  </svg>
                </span>
                <input
                  id="university-school"
                  name="university"
                  type="text"
                  className="form-input"
                  placeholder="e.g. Stanford University"
                  value={university}
                  onChange={(e) => setUniversity(e.target.value)}
                  required
                  autoComplete="organization"
                />
              </div>
            </div>

            {/* Password */}
            <div className="form-group">
              <label htmlFor="password" className="form-label">
                Password
              </label>
              <div className="input-container">
                <span className="input-icon-left" aria-hidden="true">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect width="18" height="11" x="3" y="11" rx="2" ry="2"></rect>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                  </svg>
                </span>
                <input
                  id="password"
                  name="password"
                  type={showPassword ? 'text' : 'password'}
                  className="form-input"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  minLength={6}
                  autoComplete="new-password"
                />
                <button
                  type="button"
                  className="toggle-password-btn"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"></path>
                      <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"></path>
                      <path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"></path>
                      <line x1="2" x2="22" y1="2" y2="22"></line>
                    </svg>
                  ) : (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"></path>
                      <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                  )}
                </button>
              </div>
            </div>

            {/* Confirm Password */}
            <div className="form-group">
              <label htmlFor="confirm-password" className="form-label">
                Confirm Password
              </label>
              <div className="input-container">
                <span className="input-icon-left" aria-hidden="true">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect width="18" height="11" x="3" y="11" rx="2" ry="2"></rect>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                  </svg>
                </span>
                <input
                  id="confirm-password"
                  name="confirmPassword"
                  type={showConfirmPassword ? 'text' : 'password'}
                  className="form-input"
                  placeholder="••••••••"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                  autoComplete="new-password"
                />
                <button
                  type="button"
                  className="toggle-password-btn"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  aria-label={showConfirmPassword ? 'Hide confirm password' : 'Show confirm password'}
                >
                  {showConfirmPassword ? (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"></path>
                      <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"></path>
                      <path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"></path>
                      <line x1="2" x2="22" y1="2" y2="22"></line>
                    </svg>
                  ) : (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"></path>
                      <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                  )}
                </button>
              </div>
            </div>

            {/* Accept Terms Checkbox */}
            <div className="form-checkbox-group">
              <label htmlFor="accept-terms" className="checkbox-label">
                <input
                  id="accept-terms"
                  type="checkbox"
                  className="custom-checkbox"
                  checked={agreeTerms}
                  onChange={(e) => setAgreeTerms(e.target.checked)}
                  required
                />
                <span className="checkbox-text">
                  I agree to the{' '}
                  <a href="#terms" className="terms-link" onClick={(e) => e.preventDefault()}>
                    Terms of Service
                  </a>{' '}
                  and{' '}
                  <a href="#privacy" className="terms-link" onClick={(e) => e.preventDefault()}>
                    Privacy Policy
                  </a>
                </span>
              </label>
            </div>

            {/* Create Account Button */}
            <button type="submit" className="btn-login" disabled={isLoading}>
              {isLoading ? (
                <span>Creating Account...</span>
              ) : (
                <>
                  <span>Create Account</span>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M5 12h14"></path>
                    <path d="m12 5 7 7-7 7"></path>
                  </svg>
                </>
              )}
            </button>
          </form>

          {/* Divider */}
          <div className="divider">
            <span>or sign up with</span>
          </div>

          {/* Google SSO Button */}
          <div className="sso-group">
            <button
              type="button"
              className="btn-sso"
              onClick={() => handleSSORegister('Google')}
            >
              <svg className="sso-icon" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                />
              </svg>
              <span>Sign up with Google</span>
            </button>
          </div>

          {/* Card Footer */}
          <div className="card-footer">
            <span>Already have an account?</span>
            <Link to="/login" className="signup-link">
              Log in
            </Link>
          </div>
        </div>
      </div>
    </Layout>
  )
}
