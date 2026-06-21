export interface User {
  id: string
  full_name: string
  email: string
  phone?: string
  role: string
  branch_id?: string | null
  is_active?: boolean
  is_verified?: boolean
}

export interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
}

export function getStoredAuth(): AuthState {
  if (typeof window === 'undefined') {
    return { user: null, token: null, isAuthenticated: false }
  }
  const token = localStorage.getItem('auth_token')
  const userStr = localStorage.getItem('auth_user')
  if (token && userStr) {
    try {
      const user = JSON.parse(userStr) as User
      return { user, token, isAuthenticated: true }
    } catch {
      return { user: null, token: null, isAuthenticated: false }
    }
  }
  return { user: null, token: null, isAuthenticated: false }
}

export function storeAuth(token: string, user: User, refreshToken?: string) {
  localStorage.setItem('auth_token', token)
  localStorage.setItem('auth_user', JSON.stringify(user))
  if (refreshToken) {
    localStorage.setItem('refresh_token', refreshToken)
  }
}

export function clearAuth() {
  localStorage.removeItem('auth_token')
  localStorage.removeItem('auth_user')
  localStorage.removeItem('refresh_token')
}