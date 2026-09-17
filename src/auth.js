import { supabase } from './lib/supabaseClient'

let currentUser = null

function getVietnameseAuthError(error) {
  const message = error?.message?.toLowerCase() || ''

  if (message.includes('invalid login credentials')) {
    return new Error('Email hoặc mật khẩu chưa đúng.')
  }

  if (message.includes('user already registered')) {
    return new Error('Email này đã đăng ký. Hãy chuyển sang đăng nhập.')
  }

  if (message.includes('email not confirmed')) {
    return new Error('Email chưa được xác nhận. Hãy kiểm tra hộp thư của cậu.')
  }

  if (message.includes('password should be at least')) {
    return new Error('Mật khẩu cần ít nhất 6 ký tự.')
  }

  return new Error('Đã xảy ra lỗi xác thực. Hãy thử lại sau.')
}

function createLocalProfile(userId, fullName, university) {
  const profileKey = `cocoapp.user.${userId}.cocoapp.profile.v1`
  const profile = {
    fullName: fullName.trim(),
    university: university.trim(),
    major: '',
    studyYear: '',
    gender: '',
    purpose: '',
    bio: '',
    city: '',
    area: '',
    publicLocation: '',
    maxDistance: '3',
    hidePhone: true,
    hideExactAddress: true,
  }

  localStorage.setItem(profileKey, JSON.stringify(profile))
}

export async function registerAccount({
  fullName,
  email,
  university,
  password,
}) {
  const normalizedEmail = email.trim().toLowerCase()

  if (!fullName.trim() || !university.trim()) {
    throw new Error('Hãy nhập họ tên và trường đại học.')
  }

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
    throw new Error('Email chưa đúng định dạng.')
  }

  if (password.length < 6 || !password.trim()) {
    throw new Error('Mật khẩu cần ít nhất 6 ký tự, không chỉ là dấu cách.')
  }

  const { data, error } = await supabase.auth.signUp({
    email: normalizedEmail,
    password,
    options: {
      data: {
        fullName: fullName.trim(),
        university: university.trim(),
      },
    },
  })

  if (error) throw getVietnameseAuthError(error)

  if (data.user) {
    createLocalProfile(data.user.id, fullName, university)
  }

  currentUser = data.session?.user || null

  return {
    requiresEmailConfirmation: Boolean(data.user && !data.session),
  }
}

export async function loginAccount(email, password) {
  const normalizedEmail = email.trim().toLowerCase()

  const { data, error } = await supabase.auth.signInWithPassword({
    email: normalizedEmail,
    password,
  })

  if (error) throw getVietnameseAuthError(error)

  currentUser = data.user
}

export function currentAccount() {
  return currentUser
}

export async function getCurrentAccount() {
  const { data, error } = await supabase.auth.getSession()

  if (error) throw getVietnameseAuthError(error)

  currentUser = data.session?.user || null
  return currentUser
}

export function subscribeToAuthState(callback) {
  const { data } = supabase.auth.onAuthStateChange((_event, session) => {
    currentUser = session?.user || null
    callback(currentUser)
  })

  return () => data.subscription.unsubscribe()
}

export async function logoutAccount() {
  const { error } = await supabase.auth.signOut()

  if (error) throw getVietnameseAuthError(error)

  currentUser = null
}

function getAccountKey(key) {
  const account = currentAccount()

  if (!account) {
    throw new Error('Phiên đăng nhập đã hết. Hãy đăng nhập lại.')
  }

  return `cocoapp.user.${account.id}.${key}`
}

export const accountStorage = {
  getItem(key) {
    return localStorage.getItem(getAccountKey(key))
  },

  setItem(key, value) {
    localStorage.setItem(getAccountKey(key), value)
  },
}