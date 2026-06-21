'use client'

import { useState } from 'react'
import { useParams } from 'next/navigation'
import { cn } from '@/lib/utils'
import { AuthGuard } from '@/components/shared/AuthGuard'
import { SellerSidebar } from '@/components/seller/SellerSidebar'
import { Menu } from 'lucide-react'

function SellerLayoutContent({ children }: { children: React.ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const params = useParams()
  const locale = params.locale as string
  const isRtl = locale === 'ar'

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <SellerSidebar
        locale={locale}
        mobileOpen={mobileOpen}
        onMobileClose={() => setMobileOpen(false)}
      />
      <div className={cn('flex flex-col min-h-screen', isRtl ? 'lg:pr-64' : 'lg:pl-64')}>
        <header className="sticky top-0 z-30 h-16 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800 flex items-center px-4 gap-4">
          <button
            onClick={() => setMobileOpen(true)}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg lg:hidden"
          >
            <Menu className="w-5 h-5" />
          </button>
          <div className="text-sm text-gray-500">Seller Portal</div>
        </header>
        <main className="flex-1 px-3 py-4 sm:px-4 sm:py-6 lg:p-6">{children}</main>
      </div>
    </div>
  )
}

export default function SellerLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <SellerLayoutContent>{children}</SellerLayoutContent>
    </AuthGuard>
  )
}
