'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { cn } from '@/lib/utils'
import { useAuth } from '@/hooks/useAuth'
import {
  LayoutDashboard, Package, Users, Truck, Building2, Car,
  FileText, BarChart3, Headphones, Bell, Settings, Shield, User,
  ChevronLeft, ChevronRight, X, FolderOpen, Store, ClipboardList,
  Map, DollarSign
} from 'lucide-react'
import { useState } from 'react'

interface NavItem {
  labelKey: string
  href: string
  icon: React.ReactNode
  roles?: string[]
}

interface NavSection {
  sectionKey: string
  items: NavItem[]
  roles?: string[]
}

const navSections: NavSection[] = [
  {
    sectionKey: 'main',
    items: [{ labelKey: 'dashboard', href: '/dashboard', icon: <LayoutDashboard className="w-5 h-5" /> }],
  },
  {
    sectionKey: 'operations',
    items: [
      { labelKey: 'shipments', href: '/shipments', icon: <Package className="w-5 h-5" /> },
      { labelKey: 'batches', href: '/batches', icon: <ClipboardList className="w-5 h-5" /> },
      { labelKey: 'sellers', href: '/sellers', icon: <Store className="w-5 h-5" /> },
      { labelKey: 'customers', href: '/customers', icon: <Users className="w-5 h-5" /> },
      { labelKey: 'drivers', href: '/drivers', icon: <Truck className="w-5 h-5" /> },
      { labelKey: 'branches', href: '/branches', icon: <Building2 className="w-5 h-5" /> },
      { labelKey: 'documents', href: '/documents', icon: <FolderOpen className="w-5 h-5" /> },
      { labelKey: 'vehicles', href: '/vehicles', icon: <Car className="w-5 h-5" /> },
      { labelKey: 'controlRoom', href: '/control-room', icon: <Map className="w-5 h-5" /> },
    ],
    roles: ['admin', 'operations', 'branch_manager'],
  },
  {
    sectionKey: 'finance',
    items: [
      { labelKey: 'invoices', href: '/invoices', icon: <FileText className="w-5 h-5" /> },
      { labelKey: 'settlements', href: '/settlements', icon: <DollarSign className="w-5 h-5" /> },
      { labelKey: 'reports', href: '/reports', icon: <BarChart3 className="w-5 h-5" /> },
    ],
    roles: ['admin', 'operations', 'finance'],
  },
  {
    sectionKey: 'admin',
    items: [
      { labelKey: 'usersManagement', href: '/users', icon: <Shield className="w-5 h-5" /> },
      { labelKey: 'profile', href: '/profile', icon: <User className="w-5 h-5" /> },
      { labelKey: 'support', href: '/support', icon: <Headphones className="w-5 h-5" /> },
      { labelKey: 'aiAlerts', href: '/ai-alerts', icon: <Bell className="w-5 h-5" /> },
      { labelKey: 'settings', href: '/settings', icon: <Settings className="w-5 h-5" /> },
    ],
    roles: ['admin', 'operations', 'branch_manager', 'finance'],
  },
]

interface SidebarProps {
  locale: string
  mobileOpen: boolean
  onMobileClose: () => void
}

export function Sidebar({ locale, mobileOpen, onMobileClose }: SidebarProps) {
  const pathname = usePathname()
  const t = useTranslations('nav')
  const { user } = useAuth()
  const [collapsed, setCollapsed] = useState(false)
  const isRtl = locale === 'ar'
  const userRole = user?.role || ''

  const visibleSections = navSections
    .map((section) => ({
      ...section,
      items: section.items.filter((item) => !item.roles || item.roles.includes(userRole)),
    }))
    .filter((section) => !section.roles || section.roles.includes(userRole))

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
          <Link href={`/${locale}/dashboard`} className="flex items-center gap-3">
            <img src="/logo.svg" alt="Swift Egypt" className="w-8 h-8" />
            {!collapsed && <span className="font-bold text-lg text-primary-600 dark:text-primary-400">Swift Egypt</span>}
          </Link>
          <button
            onClick={onMobileClose}
            className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 lg:hidden"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto py-4 px-2 space-y-6">
          {visibleSections.length === 0 && (
            <p className="text-xs text-gray-400 text-center px-3">No menu items available</p>
          )}
          {visibleSections.map((section) => (
            <div key={section.sectionKey}>
              {!collapsed && (
                <p className="px-3 text-xs font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500 mb-2">
                  {t(section.sectionKey)}
                </p>
              )}
              <ul className="space-y-1">
                {section.items.map((item) => {
                  const isActive = pathname.includes(item.href)
                  return (
                    <li key={item.href}>
                      <Link
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
                    </li>
                  )
                })}
              </ul>
            </div>
          ))}
        </nav>

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
