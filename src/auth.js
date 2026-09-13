const ACCOUNTS_KEY = 'cocoapp.accounts.v2'
const SESSION_KEY = 'cocoapp.session.v2'

function readAccounts() {
  const accounts = JSON.parse(
    localStorage.getItem(ACCOUNTS_KEY) || '[]'
  )

  const valid =
    Array.isArray(accounts) &&
    accounts.every(
      (account) =>
        account &&
        ['id', 'email', 'salt', 'passwordHash'].every(
          (key) => typeof account[key] === 'string'
        )
    )

  if (!valid) {
    throw new Error('Dữ liệu tài khoản bị lỗi. Chưa thay đổi dữ liệu cũ.')
  }

  return accounts
}

async function hashPassword(password, salt) {
  if (!globalThis.crypto?.subtle) {
    throw new Error('Hãy mở web bằng địa chỉ localhost hoặc HTTPS.')
  }

  const encoder = new TextEncoder()

  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(password),
    'PBKDF2',
    false,
    ['deriveBits']
  )

  const result = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt: encoder.encode(salt),
      iterations: 210000,
      hash: 'SHA-256',
    },
    key,
    256
  )

  return Array.from(new Uint8Array(result), (byte) =>
    byte.toString(16).padStart(2, '0')
  ).join('')
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

  if (readAccounts().some((account) => account.email === normalizedEmail)) {
    throw new Error('Email này đã đăng ký. Hãy chuyển sang đăng nhập.')
  }

  if (!globalThis.crypto?.subtle) {
    throw new Error('Hãy mở web bằng địa chỉ localhost hoặc HTTPS.')
  }

  const id = crypto.randomUUID()
  const salt = crypto.randomUUID()
  const passwordHash = await hashPassword(password, salt)

  const accounts = readAccounts()

  if (accounts.some((account) => account.email === normalizedEmail)) {
    throw new Error('Email này đã đăng ký.')
  }

  const profileKey = `cocoapp.user.${id}.cocoapp.profile.v1`

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

  localStorage.setItem(
    ACCOUNTS_KEY,
    JSON.stringify([
      ...accounts,
      {
        id,
        email: normalizedEmail,
        salt,
        passwordHash,
      },
    ])
  )
}

export async function loginAccount(email, password) {
  const normalizedEmail = email.trim().toLowerCase()

  const account = readAccounts().find(
    (item) => item.email === normalizedEmail
  )

  if (!account) {
    throw new Error('Email hoặc mật khẩu chưa đúng.')
  }

  const passwordHash = await hashPassword(password, account.salt)

  if (passwordHash !== account.passwordHash) {
    throw new Error('Email hoặc mật khẩu chưa đúng.')
  }

  sessionStorage.setItem(SESSION_KEY, account.id)
}

export function currentAccount() {
  try {
    const accountId = sessionStorage.getItem(SESSION_KEY)

    return (
      readAccounts().find((account) => account.id === accountId) || null
    )
  } catch {
    return null
  }
}

export function logoutAccount() {
  sessionStorage.removeItem(SESSION_KEY)
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