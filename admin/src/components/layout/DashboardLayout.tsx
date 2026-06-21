'use client'

import { useState } from 'react'
import { useParams } from 'next/navigation'
import { cn } from '@/lib/utils'
import { Sidebar } from './Sidebar'
import { Header } from './Header'

export function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const params = useParams()
  const locale = params.locale as string
  const isRtl = locale === 'ar'

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <Sidebar
        locale={locale}
        mobileOpen={mobileOpen}
        onMobileClose={() => setMobileOpen(false)}
      />
      <div className={cn('flex flex-col min-h-screen', isRtl ? 'lg:pr-64' : 'lg:pl-64')}>
        <Header onMenuClick={() => setMobileOpen(true)} />
        <main className="flex-1 px-3 py-4 sm:px-4 sm:py-6 lg:p-6">{children}</main>
      </div>
    </div>
  )
}
