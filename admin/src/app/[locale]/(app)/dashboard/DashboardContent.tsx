'use client'

import { useState, useEffect } from 'react'
import { useTranslations } from 'next-intl'
import { useAuth } from '@/hooks/useAuth'
import { useToast } from '@/components/ui/Toast'
import { get } from '@/lib/api'
import { StatsCard } from '@/components/dashboard/StatsCard'
import { ShipmentsChart } from '@/components/dashboard/ShipmentsChart'
import { RecentShipments } from '@/components/dashboard/RecentShipments'
import { AlertsWidget } from '@/components/dashboard/AlertsWidget'
import { SkeletonStatsGrid, Skeleton } from '@/components/ui/Skeleton'
import { Package, Truck, Clock, CheckCircle, DollarSign, RefreshCw } from 'lucide-react'
import { Button } from '@/components/ui/Button'

interface DashboardStats {
  total_shipments: number
  active_shipments: number
  delayed_shipments: number
  delivered_today: number
  total_revenue: number
}

export default function DashboardContent() {
  const t = useTranslations('dashboard')
  const { user } = useAuth()
  const { addToast } = useToast()
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    loadDashboard()
  }, [])

  const loadDashboard = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await get<DashboardStats>('/v1/dashboard/stats')
      setStats(data)
    } catch (err: any) {
      setError(err.message)
      addToast({ type: 'error', message: err.message })
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <div>
          <Skeleton className="h-8 w-48" />
          <Skeleton className="h-5 w-64 mt-2" />
        </div>
        <SkeletonStatsGrid count={5} />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2">
            <Skeleton className="h-80 rounded-xl" />
          </div>
          <Skeleton className="h-80 rounded-xl" />
        </div>
        <Skeleton className="h-64 rounded-xl" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <p className="text-red-500 text-sm">{error}</p>
        <Button variant="outline" size="sm" onClick={loadDashboard}>
          <RefreshCw className="w-4 h-4 me-2" />
          Try again
        </Button>
      </div>
    )
  }

  const formatRevenue = (amount: number) => {
    return `EGP ${(amount / 1000).toFixed(1)}K`
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <p className="text-gray-500 dark:text-gray-400 mt-1">
          {t('welcomeBack', { name: user?.full_name?.split(' ')[0] || 'User' })}
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4">
        <StatsCard title={t('totalShipments')} value={stats?.total_shipments ?? 0} icon={<Package className="w-6 h-6" />} />
        <StatsCard title={t('activeShipments')} value={stats?.active_shipments ?? 0} icon={<Truck className="w-6 h-6" />} />
        <StatsCard title={t('delayedShipments')} value={stats?.delayed_shipments ?? 0} icon={<Clock className="w-6 h-6" />} />
        <StatsCard title={t('deliveredToday')} value={stats?.delivered_today ?? 0} icon={<CheckCircle className="w-6 h-6" />} />
        <StatsCard title={t('revenue')} value={formatRevenue(stats?.total_revenue ?? 0)} icon={<DollarSign className="w-6 h-6" />} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <ShipmentsChart />
        </div>
        <AlertsWidget />
      </div>

      <RecentShipments />
    </div>
  )
}
