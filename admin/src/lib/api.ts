const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api'

function getToken(): string | null {
  if (typeof window !== 'undefined') {
    return localStorage.getItem('auth_token')
  }
  return null
}

function getRefreshToken(): string | null {
  if (typeof window !== 'undefined') {
    return localStorage.getItem('refresh_token')
  }
  return null
}

function storeAuth(access: string, refresh: string) {
  localStorage.setItem('auth_token', access)
  localStorage.setItem('refresh_token', refresh)
}

function clearAuth() {
  localStorage.removeItem('auth_token')
  localStorage.removeItem('refresh_token')
  localStorage.removeItem('auth_user')
}

let refreshing: Promise<boolean> | null = null

async function tryRefresh(): Promise<boolean> {
  const refreshToken = getRefreshToken()
  if (!refreshToken) return false
  try {
    const res = await fetch(`${API_BASE}/v1/auth/refresh-token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh_token: refreshToken }),
    })
    if (!res.ok) return false
    const data = await res.json()
    storeAuth(data.access_token, data.refresh_token)
    return true
  } catch {
    return false
  }
}

async function request<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken()
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const res = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  })

  if (res.status === 401) {
    if (!refreshing) {
      refreshing = tryRefresh()
    }
    const refreshed = await refreshing
    refreshing = null
    if (refreshed) {
      const newToken = getToken()
      if (newToken) {
        headers['Authorization'] = `Bearer ${newToken}`
      }
      const retryRes = await fetch(`${API_BASE}${endpoint}`, {
        ...options,
        headers,
      })
      if (retryRes.ok) {
        return retryRes.json()
      }
    }
    clearAuth()
    if (typeof window !== 'undefined') {
      window.location.href = '/en/login'
    }
    throw new Error('Session expired')
  }

  if (!res.ok) {
    const error = await res.json().catch(() => ({ detail: 'An error occurred' }))
    throw new Error(error.detail || error.message || `HTTP ${res.status}`)
  }

  return res.json()
}

export function get<T>(endpoint: string): Promise<T> {
  return request<T>(endpoint, { method: 'GET' })
}

export function post<T>(endpoint: string, data: unknown): Promise<T> {
  return request<T>(endpoint, { method: 'POST', body: JSON.stringify(data) })
}

export function put<T>(endpoint: string, data: unknown): Promise<T> {
  return request<T>(endpoint, { method: 'PUT', body: JSON.stringify(data) })
}

export function del<T>(endpoint: string): Promise<T> {
  return request<T>(endpoint, { method: 'DELETE' })
}
