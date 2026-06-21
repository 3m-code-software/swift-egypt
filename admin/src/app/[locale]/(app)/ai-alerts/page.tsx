'use client'

import { useState, useEffect } from 'react'
import { useTranslations } from 'next-intl'
import { get, put } from '@/lib/api'
import { useToast } from '@/components/ui/Toast'
import { Card, CardContent } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { SkeletonTable } from '@/components/ui/Skeleton'
import { AlertTriangle, AlertCircle, Info, Eye, EyeOff, RefreshCw } from 'lucide-react'

interface AiAlert {
  id: string
  shipment_id: string | null
  alert_type: string
  severity: string
  title: string
  description: string | null
  is_read: boolean
  created_at: string | null
}

const severityIcon: Record<string, React.ReactNode> = {
  critical: <AlertCircle className="w-3 h-3" />,
  high: <AlertTriangle className="w-3 h-3" />,
  medium: <AlertTriangle className="w-3 h-3" />,
  low: <Info className="w-3 h-3" />,
}

const severityBadge: Record<string, 'danger' | 'warning' | 'info'> = {
  critical: 'danger',
  high: 'warning',
  medium: 'warning',
  low: 'info',
}

export default function AiAlertsPage() {
  const t = useTranslations('aiAlerts')
  const { addToast } = useToast()
  const [alerts, setAlerts] = useState<AiAlert[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadAlerts()
  }, [])

  const loadAlerts = async () => {
    setLoading(true)
    try {
      const data = await get<AiAlert[]>('/v1/ai/alerts')
      setAlerts(data)
    } catch (err: any) {
      addToast({ type: 'error', message: err.message })
    } finally {
      setLoading(false)
    }
  }

  const markRead = async (id: string) => {
    try {
      await put(`/v1/ai/alerts/${id}/read`, {})
      setAlerts((prev) => prev.map((a) => (a.id === id ? { ...a, is_read: true } : a)))
      addToast({ type: 'success', message: 'Alert marked as read' })
    } catch (err: any) {
      addToast({ type: 'error', message: err.message })
    }
  }

  const timeAgo = (dateStr: string | null) => {
    if (!dateStr) return ''
    const diff = Date.now() - new Date(dateStr).getTime()
    const mins = Math.floor(diff / 60000)
    if (mins < 60) return `${mins} min ago`
    const hours = Math.floor(mins / 60)
    if (hours < 24) return `${hours}h ago`
    return `${Math.floor(hours / 24)}d ago`
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{t('title')}</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">AI-powered insights and alerts for your logistics operations</p>
        </div>
        <Button variant="outline" size="sm" onClick={loadAlerts} disabled={loading}>
          <RefreshCw className={`w-4 h-4 me-2 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>

      <Card>
        <CardContent className="p-0">
          {loading ? (
            <SkeletonTable rows={5} cols={4} />
          ) : alerts.length === 0 ? (
            <p className="text-center py-12 text-sm text-gray-500">No alerts</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-gray-700">
                    <th className="px-4 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('severity')}</th>
                    <th className="px-4 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('message')}</th>
                    <th className="hidden sm:table-cell px-4 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('timestamp')}</th>
                    <th className="px-4 sm:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('action')}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {alerts.map((alert) => (
                    <tr key={alert.id} className={`hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors ${!alert.is_read ? 'bg-primary-50/50 dark:bg-primary-900/10' : ''}`}>
                      <td className="px-4 sm:px-6 py-4">
                        <Badge variant={severityBadge[alert.severity] || 'default'}>
                          <span className="flex items-center gap-1">
                            {severityIcon[alert.severity]}
                            {t(alert.severity)}
                          </span>
                        </Badge>
                      </td>
                      <td className="px-4 sm:px-6 py-4 max-w-md">
                        <p className={`text-sm ${!alert.is_read ? 'font-semibold' : ''} text-gray-900 dark:text-gray-100`}>{alert.title}</p>
                        {alert.description && <p className="text-xs text-gray-500 mt-0.5">{alert.description}</p>}
                        <p className="text-xs text-gray-400 mt-1 sm:hidden">{timeAgo(alert.created_at)}</p>
                      </td>
                      <td className="hidden sm:table-cell px-4 sm:px-6 py-4 text-sm text-gray-500 whitespace-nowrap">{timeAgo(alert.created_at)}</td>
                      <td className="px-4 sm:px-6 py-4">
                        {!alert.is_read ? (
                          <Button variant="ghost" size="sm" onClick={() => markRead(alert.id)}>
                            <EyeOff className="w-3 h-3 me-1" />
                            Dismiss
                          </Button>
                        ) : (
                          <span className="text-xs text-gray-400 flex items-center gap-1">
                            <Eye className="w-3 h-3" /> Read
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
