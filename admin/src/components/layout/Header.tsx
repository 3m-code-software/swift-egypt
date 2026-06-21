'use client'

import { useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { useTheme } from '@/components/shared/ThemeProvider'
import { useAuth } from '@/hooks/useAuth'
import { useNotifications, NotificationItem } from '@/hooks/useNotifications'
import { cn } from '@/lib/utils'
import {
  Search, Moon, Sun, Globe, Menu, Bell,
  User, LogOut, Settings, CheckCheck, Package, CreditCard, AlertTriangle, FileText
} from 'lucide-react'

const typeIcon: Record<string, React.ReactNode> = {
  shipment: <Package className="w-4 h-4" />,
  payment: <CreditCard className="w-4 h-4" />,
  alert: <AlertTriangle className="w-4 h-4" />,
  report: <FileText className="w-4 h-4" />,
}

interface HeaderProps {
  onMenuClick: () => void
}

export function Header({ onMenuClick }: HeaderProps) {
  const t = useTranslations('settings')
  const params = useParams()
  const router = useRouter()
  const { theme, setTheme } = useTheme()
  const { user, logout } = useAuth()
  const { notifications, unreadCount, markAllRead, refresh } = useNotifications()
  const [showUserMenu, setShowUserMenu] = useState(false)
  const [showLangMenu, setShowLangMenu] = useState(false)
  const [showNotifications, setShowNotifications] = useState(false)
  const locale = params.locale as string
  const isRtl = locale === 'ar'

  const toggleLocale = () => {
    const newLocale = locale === 'en' ? 'ar' : 'en'
    const path = window.location.pathname.replace(`/${locale}`, `/${newLocale}`)
    router.push(path)
  }

  const timeAgo = (dateStr: string | null) => {
    if (!dateStr) return ''
    const diff = Date.now() - new Date(dateStr).getTime()
    const mins = Math.floor(diff / 60000)
    if (mins < 1) return 'just now'
    if (mins < 60) return `${mins}m ago`
    const hours = Math.floor(mins / 60)
    if (hours < 24) return `${hours}h ago`
    return `${Math.floor(hours / 24)}d ago`
  }

  return (
    <header className="sticky top-0 z-30 h-16 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800">
      <div className="flex items-center justify-between h-full px-4 lg:px-6">
        <div className="flex items-center gap-3">
          <button
            onClick={onMenuClick}
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 lg:hidden min-w-[44px] min-h-[44px] flex items-center justify-center"
          >
            <Menu className="w-5 h-5" />
          </button>

          <div className="hidden sm:flex items-center gap-2 px-3 py-2 bg-gray-100 dark:bg-gray-800 rounded-lg">
            <Search className="w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder={locale === 'ar' ? 'بحث...' : 'Search...'}
              className="bg-transparent border-none outline-none text-sm w-48 text-gray-700 dark:text-gray-300 placeholder-gray-400"
            />
          </div>
        </div>

        <div className="flex items-center gap-1 sm:gap-2">
          <button
            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-400 transition-colors min-w-[44px] min-h-[44px] flex items-center justify-center"
          >
            {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
          </button>

          <div className="relative">
            <button
              onClick={() => { setShowNotifications(!showNotifications); if (!showNotifications) refresh() }}
              className="relative p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-400 transition-colors min-w-[44px] min-h-[44px] flex items-center justify-center"
            >
              <Bell className="w-5 h-5" />
              {unreadCount > 0 && (
                <span className="absolute top-1.5 right-1.5 min-w-[18px] h-[18px] flex items-center justify-center bg-red-500 text-white text-[10px] font-bold rounded-full px-1">
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              )}
            </button>
            {showNotifications && (
              <>
                <div className="fixed inset-0 z-10" onClick={() => setShowNotifications(false)} />
                <div className={cn(
                  'absolute top-full mt-2 z-20 w-80 sm:w-96 bg-white dark:bg-gray-800 rounded-xl shadow-xl border border-gray-200 dark:border-gray-700',
                  isRtl ? 'left-0' : 'right-0'
                )}>
                  <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 dark:border-gray-700">
                    <h3 className="font-semibold text-sm">Notifications</h3>
                    {unreadCount > 0 && (
                      <button onClick={markAllRead} className="text-xs text-primary-600 dark:text-primary-400 hover:underline flex items-center gap-1">
                        <CheckCheck className="w-3 h-3" /> Mark all read
                      </button>
                    )}
                  </div>
                  <div className="max-h-80 overflow-y-auto">
                    {notifications.length === 0 ? (
                      <p className="text-center py-8 text-sm text-gray-500">No notifications</p>
                    ) : (
                      notifications.map((n) => (
                        <div key={n.id} className={cn('flex items-start gap-3 px-4 py-3 border-b border-gray-100 dark:border-gray-700/50 last:border-0 hover:bg-gray-50 dark:hover:bg-gray-700/30', !n.is_read ? 'bg-primary-50/50 dark:bg-primary-900/10' : '')}>
                          <div className="w-8 h-8 rounded-lg bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-gray-500 dark:text-gray-400 shrink-0">
                            {typeIcon[n.type] || <Bell className="w-4 h-4" />}
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className={cn('text-sm', !n.is_read ? 'font-semibold' : '', 'text-gray-900 dark:text-gray-100')}>{n.title}</p>
                            {n.message && <p className="text-xs text-gray-500 mt-0.5">{n.message}</p>}
                            <p className="text-xs text-gray-400 mt-1">{timeAgo(n.created_at)}</p>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              </>
            )}
          </div>

          <div className="relative">
            <button
              onClick={() => setShowLangMenu(!showLangMenu)}
              className="flex items-center gap-1.5 p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-400 min-w-[44px] min-h-[44px]"
            >
              <Globe className="w-4 h-4" />
              <span className="text-sm font-medium hidden sm:inline">{locale === 'ar' ? 'AR' : 'EN'}</span>
            </button>
            {showLangMenu && (
              <>
                <div className="fixed inset-0 z-10" onClick={() => setShowLangMenu(false)} />
                <div className={cn(
                  'absolute top-full mt-1 z-20 w-32 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 py-1',
                  isRtl ? 'left-0' : 'right-0'
                )}>
                  <button onClick={() => { toggleLocale(); setShowLangMenu(false) }} className="w-full px-4 py-2 text-sm text-left hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2">
                    <span>{locale === 'en' ? '🇸🇦' : '🇬🇧'}</span>
                    <span>{locale === 'en' ? 'العربية' : 'English'}</span>
                  </button>
                </div>
              </>
            )}
          </div>

          <div className="relative">
            <button
              onClick={() => setShowUserMenu(!showUserMenu)}
              className="flex items-center gap-2 p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors min-h-[44px]"
            >
              <div className="w-8 h-8 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center">
                <User className="w-4 h-4 text-primary-600 dark:text-primary-400" />
              </div>
              <span className="hidden sm:block text-sm font-medium text-gray-700 dark:text-gray-300">{user?.full_name?.split(' ')[0] || 'User'}</span>
            </button>
            {showUserMenu && (
              <>
                <div className="fixed inset-0 z-10" onClick={() => setShowUserMenu(false)} />
                <div className={cn(
                  'absolute top-full mt-1 z-20 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 py-1',
                  isRtl ? 'left-0' : 'right-0'
                )}>
                  <div className="px-4 py-2 border-b border-gray-200 dark:border-gray-700">
                    <p className="text-sm font-medium">{user?.full_name || 'User'}</p>
                    <p className="text-xs text-gray-500">{user?.email || ''}</p>
                  </div>
                  <button onClick={() => router.push(`/${locale}/profile`)} className="w-full px-4 py-2 text-sm text-left hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2">
                    <User className="w-4 h-4" /> Profile
                  </button>
                  <button onClick={() => router.push(`/${locale}/settings`)} className="w-full px-4 py-2 text-sm text-left hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2">
                    <Settings className="w-4 h-4" /> Settings
                  </button>
                  <div className="border-t border-gray-200 dark:border-gray-700">
                    <button onClick={logout} className="w-full px-4 py-2 text-sm text-left hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2 text-red-600">
                      <LogOut className="w-4 h-4" /> Logout
                    </button>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </header>
  )
}
