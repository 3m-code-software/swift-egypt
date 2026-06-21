'use client'

import { useState, useEffect } from 'react'
import { useTranslations } from 'next-intl'
import { get } from '@/lib/api'
import { Card, CardHeader, CardContent } from '@/components/ui/Card'
import { AlertTriangle, AlertCircle, Info } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Skeleton } from '@/components/ui/Skeleton'

interface Alert {
  id: string
  severity: 'critical' | 'high' | 'medium' | 'low'
  title: string
  description: string
  created_at: string
}

const severityConfig = {
  critical: { icon: AlertCircle, color: 'text-red-600 dark:text-red-400', bg: 'bg-red-50 dark:bg-red-900/20' },
  high: { icon: AlertTriangle, color: 'text-orange-600 dark:text-orange-400', bg: 'bg-orange-50 dark:bg-orange-900/20' },
  medium: { icon: AlertTriangle, color: 'text-yellow-600 dark:text-yellow-400', bg: 'bg-yellow-50 dark:bg-yellow-900/20' },
  low: { icon: Info, color: 'text-blue-600 dark:text-blue-400', bg: 'bg-blue-50 dark:bg-blue-900/20' },
}

export function AlertsWidget() {
  const t = useTranslations('dashboard')
  const [alerts, setAlerts] = useState<Alert[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    get<Alert[]>('/v1/dashboard/alerts')
      .then(setAlerts)
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const timeAgo = (dateStr: string) => {
    const diff = Date.now() - new Date(dateStr).getTime()
    const mins = Math.floor(diff / 60000)
    if (mins < 60) return `${mins} min ago`
    const hours = Math.floor(mins / 60)
    if (hours < 24) return `${hours}h ago`
    return `${Math.floor(hours / 24)}d ago`
  }

  return (
    <Card>
      <CardHeader>
        <h3 className="text-lg font-semibold">{t('alerts')}</h3>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="flex items-start gap-3 p-3">
                <Skeleton className="w-5 h-5 rounded-full shrink-0 mt-0.5" />
                <div className="flex-1 space-y-2">
                  <Skeleton className="h-4 w-3/4" />
                  <Skeleton className="h-3 w-full" />
                </div>
              </div>
            ))}
          </div>
        ) : alerts.length === 0 ? (
          <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-8">No alerts</p>
        ) : (
          <div className="space-y-3">
            {alerts.map((alert) => {
              const config = severityConfig[alert.severity] || severityConfig.low
              const Icon = config.icon
              return (
                <div key={alert.id} className={cn('flex items-start gap-3 p-3 rounded-lg', config.bg)}>
                  <Icon className={cn('w-5 h-5 mt-0.5 flex-shrink-0', config.color)} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 dark:text-gray-100">{alert.title}</p>
                    {alert.description && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{alert.description}</p>
                    )}
                    <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">{timeAgo(alert.created_at)}</p>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
