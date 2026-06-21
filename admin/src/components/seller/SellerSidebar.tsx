'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard, ClipboardList, Upload, Wallet, BarChart3,
  ChevronLeft, ChevronRight, X, LogOut
} from 'lucide-react'
import { useState } from 'react'
import { useAuth } from '@/hooks/useAuth'

interface SellerSidebarProps {
  locale: string
  mobileOpen: boolean
  onMobileClose: () => void
}

const navItems = [
  { labelKey: 'dashboard', href: '/seller/dashboard', icon: <LayoutDashboard className="w-5 h-5" /> },
  { labelKey: 'myOrders', href: '/seller/batches', icon: <ClipboardList className="w-5 h-5" /> },
  { labelKey: 'uploadSheet', href: '/seller/upload', icon: <Upload className="w-5 h-5" /> },
  { labelKey: 'wallet', href: '/seller/wallet', icon: <Wallet className="w-5 h-5" /> },
]

export function SellerSidebar({ locale, mobileOpen, onMobileClose }: SellerSidebarProps) {
  const pathname = usePathname()
  const t = useTranslations('sellerNav')
  const { user, logout } = useAuth()
  const [collapsed, setCollapsed] = useState(false)
  const isRtl = locale === 'ar'

  return (
    <>
      {mobileOpen && (
        <div className="fixed inset-0 z-40 bg-black/50 lg:hidden" onClick={onMobileClose} />
      )}
      <aside
        className={cn(
          'fixed top-0 z-50 h-full bg-white dark:bg-gray-900 border-gray-200 dark:border-gray-800 transition-all duration-300 flex flex-col',
          isRtl ? 'right-0 border-l' : 'left-0 border-r',
          collapsed ? 'w-16' : 'w-64',
          mobileOpen
            ? 'translate-x-0'
            : isRtl ? 'translate-x-full lg:translate-x-0' : '-translate-x-full lg:translate-x-0'
        )}
      >
        <div className={cn(
          'flex items-center justify-between h-16 px-4 border-b border-gray-200 dark:border-gray-800',
          isRtl ? 'flex-row-reverse' : ''
        )}>
          <Link href={`/${locale}/seller/dashboard`} className="flex items-center gap-3">
            <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center text-white font-bold text-sm">
              S
            </div>
            {!collapsed && <span className="font-bold text-lg text-primary-600 dark:text-primary-400">Seller Hub</span>}
          </Link>
          <button onClick={onMobileClose} className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 lg:hidden">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="px-4 py-3 border-b border-gray-200 dark:border-gray-800">
          <p className="text-sm font-medium truncate">{user?.full_name || 'Seller'}</p>
          <p className="text-xs text-gray-500">{user?.email || ''}</p>
        </div>

        <nav className="flex-1 overflow-y-auto py-4 px-2 space-y-1">
          {navItems.map((item) => {
            const isActive = pathname.includes(item.href)
            return (
              <Link
                key={item.href}
                href={`/${locale}${item.href}`}
                onClick={onMobileClose}
                className={cn(
                  'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-primary-50 text-primary-700 dark:bg-primary-900/20 dark:text-primary-400'
                    : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800'
                )}
              >
                {item.icon}
                {!collapsed && <span>{t(item.labelKey)}</span>}
              </Link>
            )
          })}
        </nav>

        <div className="px-2 py-3 border-t border-gray-200 dark:border-gray-800">
          <button
            onClick={logout}
            className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 w-full"
          >
            <LogOut className="w-5 h-5" />
            {!collapsed && <span>Logout</span>}
          </button>
        </div>

        <button
          onClick={() => setCollapsed(!collapsed)}
          className="hidden lg:flex items-center justify-center h-12 border-t border-gray-200 dark:border-gray-800 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
        >
          {collapsed
            ? isRtl ? <ChevronLeft className="w-5 h-5" /> : <ChevronRight className="w-5 h-5" />
            : isRtl ? <ChevronRight className="w-5 h-5" /> : <ChevronLeft className="w-5 h-5" />
          }
        </button>
      </aside>
    </>
  )
}
