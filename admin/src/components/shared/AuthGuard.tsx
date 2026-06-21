'use client'

import { useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import { getStoredAuth } from '@/store/auth'

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const params = useParams()
  const locale = params.locale as string

  useEffect(() => {
    const auth = getStoredAuth()
    if (!auth.isAuthenticated) {
      router.replace(`/${locale}/login`)
    }
  }, [router, locale])

  return <>{children}</>
}