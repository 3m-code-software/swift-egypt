'use client'

import { useState, useEffect, useCallback, useRef } from 'react'
import { useTranslations } from 'next-intl'
import { useAuth } from '@/hooks/useAuth'
import { get } from '@/lib/api'
import { Card, CardContent } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { Map, UserCheck, Package, DollarSign, Phone, RefreshCw, Clock, TrendingUp } from 'lucide-react'

delete (L.Icon.Default.prototype as any)._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
})

interface Stats {
  active_agents: number
  total_agents: number
  today_delivered: number
  today_collected: number
  pending_orders: number
  no_answer_today: number
  updated_at: string
}

interface AgentLocation {
  id: number
  name: string
  latitude: number
  longitude: number
  is_available: boolean
  last_update: string
}

interface Activity {
  id: number
  customer_name: string
  customer_phone: string
  status: string
  collected_amount: number
  delivery_date: string
  assigned_agent_id: number
}

const STATUS_VARIANTS: Record<string, 'success' | 'warning' | 'danger' | 'info' | 'default'> = {
  delivered: 'success',
  confirmed: 'info',
  pending: 'warning',
  cancelled: 'danger',
  returned: 'danger',
  in_transit: 'info',
  out_for_delivery: 'info',
}

function getStatusVariant(status: string) {
  return STATUS_VARIANTS[status.toLowerCase()] || 'default'
}

export default function ControlRoomPage() {
  const t = useTranslations('controlRoom')
  const { user } = useAuth()
  const [stats, setStats] = useState<Stats | null>(null)
  const [agents, setAgents] = useState<AgentLocation[]>([])
  const [activities, setActivities] = useState<Activity[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [secondsAgo, setSecondsAgo] = useState(0)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const fetchData = useCallback(async () => {
    try {
      const [statsData, agentsData, activitiesData] = await Promise.all([
        get<Stats>('/v1/control-room/stats'),
        get<AgentLocation[]>('/v1/control-room/agents/locations'),
        get<Activity[]>('/v1/control-room/recent-activity'),
      ])
      setStats(statsData)
      setAgents(agentsData)
      setActivities(activitiesData)
      setError(null)
      const now = new Date()
      setLastUpdated(now)
      setSecondsAgo(0)
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchData()
    intervalRef.current = setInterval(fetchData, 30000)
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current)
    }
  }, [fetchData])

  useEffect(() => {
    if (!lastUpdated) return
    const tick = setInterval(() => {
      setSecondsAgo(Math.floor((Date.now() - lastUpdated.getTime()) / 1000))
    }, 1000)
    return () => clearInterval(tick)
  }, [lastUpdated])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-gray-500 dark:text-gray-400">{t('loading') || 'Loading...'}</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <p className="text-red-500 text-sm">{error}</p>
        <Button variant="outline" size="sm" onClick={fetchData}>
          <RefreshCw className="w-4 h-4 me-2" />
          {t('retry') || 'Try again'}
        </Button>
      </div>
    )
  }

  const formatCollected = (amount: number) => {
    return `${amount.toLocaleString()} EGP`
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">{t('title') || 'Control Room'}</h1>
          <p className="text-gray-500 dark:text-gray-400 mt-1">
            {user?.full_name ? `Welcome, ${user.full_name}` : ''}
          </p>
        </div>
        <div className="flex items-center gap-3">
          {lastUpdated && (
            <span className="text-xs text-gray-500 dark:text-gray-400 flex items-center gap-1">
              <Clock className="w-3 h-3" />
              {t('lastUpdated', { seconds: secondsAgo }) || `Last updated: ${secondsAgo}s ago`}
            </span>
          )}
          <Button variant="outline" size="sm" onClick={fetchData}>
            <RefreshCw className="w-4 h-4 me-2" />
            {t('refresh') || 'Refresh'}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  {t('activeAgents') || 'Active Agents'}
                </p>
                <p className="text-2xl font-bold mt-1 text-gray-900 dark:text-gray-100">
                  {stats?.active_agents ?? 0}
                  <span className="text-sm font-normal text-gray-400 ms-1">
                    / {stats?.total_agents ?? 0}
                  </span>
                </p>
              </div>
              <div className="p-3 bg-primary-50 dark:bg-primary-900/20 rounded-xl text-primary-600 dark:text-primary-400">
                <UserCheck className="w-6 h-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  {t('deliveredToday') || 'Delivered Today'}
                </p>
                <p className="text-2xl font-bold mt-1 text-gray-900 dark:text-gray-100">
                  {stats?.today_delivered ?? 0}
                </p>
              </div>
              <div className="p-3 bg-green-50 dark:bg-green-900/20 rounded-xl text-green-600 dark:text-green-400">
                <Package className="w-6 h-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  {t('collectedToday') || 'Collected Today'}
                </p>
                <p className="text-2xl font-bold mt-1 text-gray-900 dark:text-gray-100">
                  {stats ? formatCollected(stats.today_collected) : '0 EGP'}
                </p>
              </div>
              <div className="p-3 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl text-emerald-600 dark:text-emerald-400">
                <DollarSign className="w-6 h-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  {t('pendingOrders') || 'Pending Orders'}
                </p>
                <p className="text-2xl font-bold mt-1 text-gray-900 dark:text-gray-100">
                  {stats?.pending_orders ?? 0}
                </p>
              </div>
              <div className="p-3 bg-amber-50 dark:bg-amber-900/20 rounded-xl text-amber-600 dark:text-amber-400">
                <Clock className="w-6 h-6" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="h-[400px] w-full rounded-xl overflow-hidden">
            <MapContainer center={[26.8206, 30.8025]} zoom={6} className="h-full w-full">
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              {agents.map((agent) => (
                <Marker key={agent.id} position={[agent.latitude, agent.longitude]}>
                  <Popup>
                    <div className="text-sm">
                      <p className="font-semibold">{agent.name}</p>
                      <p className={agent.is_available ? 'text-green-600' : 'text-red-600'}>
                        {agent.is_available
                          ? t('available') || 'Available'
                          : t('unavailable') || 'Unavailable'}
                      </p>
                    </div>
                  </Popup>
                </Marker>
              ))}
            </MapContainer>
          </div>
        </CardContent>
      </Card>

      <Card>
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
            {t('recentActivity') || 'Recent Activity'}
          </h2>
        </div>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400 text-xs uppercase tracking-wider">
                    {t('customerName') || 'Customer Name'}
                  </th>
                  <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400 text-xs uppercase tracking-wider">
                    {t('phone') || 'Phone'}
                  </th>
                  <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400 text-xs uppercase tracking-wider">
                    {t('status') || 'Status'}
                  </th>
                  <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400 text-xs uppercase tracking-wider">
                    {t('collectedAmount') || 'Collected Amount'}
                  </th>
                  <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400 text-xs uppercase tracking-wider">
                    {t('time') || 'Time'}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {activities.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-4 py-12 text-center text-gray-500 dark:text-gray-400">
                      {t('noData') || 'No data available'}
                    </td>
                  </tr>
                ) : (
                  activities.map((activity) => (
                    <tr key={activity.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                      <td className="px-4 py-3 whitespace-nowrap font-medium text-gray-900 dark:text-gray-100">
                        {activity.customer_name}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-gray-600 dark:text-gray-400">
                        <span className="flex items-center gap-1">
                          <Phone className="w-3 h-3" />
                          {activity.customer_phone}
                        </span>
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap">
                        <Badge variant={getStatusVariant(activity.status)}>
                          {activity.status}
                        </Badge>
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-gray-900 dark:text-gray-100">
                        {activity.collected_amount > 0
                          ? formatCollected(activity.collected_amount)
                          : '—'}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-gray-500 dark:text-gray-400">
                        {activity.delivery_date
                          ? new Date(activity.delivery_date).toLocaleString()
                          : '—'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
