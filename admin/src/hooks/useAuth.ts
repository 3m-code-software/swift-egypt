'use client'

import { useState, useCallback, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { User, getStoredAuth, storeAuth, clearAuth } from '@/store/auth'
import { post } from '@/lib/api'

interface LoginResponse {
  user: User
  token: {
    access_token: string
    refresh_token: string
    token_type: string
  }
}

interface UseAuthReturn {
  user: User | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  setUser: (user: User | null) => void
}

export function useAuth(): UseAuthReturn {
  const [user, setUserState] = useState<User | null>(null)
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()

  useEffect(() => {
    const auth = getStoredAuth()
    if (auth.isAuthenticated) {
      setUserState(auth.user)
      setIsAuthenticated(true)
    }
    setIsLoading(false)
  }, [])

  const setUser = useCallback((user: User | null) => {
    setUserState(user)
    if (user) {
      const token = localStorage.getItem('auth_token')
      const refreshToken = localStorage.getItem('refresh_token') || undefined
      if (token) storeAuth(token, user, refreshToken)
    }
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    setIsLoading(true)
    try {
      const res = await post<LoginResponse>('/v1/auth/login', { email, password })
      storeAuth(res.token.access_token, res.user, res.token.refresh_token)
      setUserState(res.user)
      setIsAuthenticated(true)
    } finally {
      setIsLoading(false)
    }
  }, [])

  const logout = useCallback(() => {
    clearAuth()
    setUserState(null)
    setIsAuthenticated(false)
    router.push('/en/login')
  }, [router])

  return { user, isAuthenticated, isLoading, login, logout, setUser }
}