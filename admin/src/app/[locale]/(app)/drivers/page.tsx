'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { Search, Star, RefreshCw, Pencil } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { get } from '@/lib/api'
import { SkeletonTable } from '@/components/ui/Skeleton'
import { EditDriverModal } from '@/components/drivers/EditDriverModal'

interface Driver {
  id: string
  user_id: string
  branch_id: string | null
  vehicle_id: string | null
  is_available: boolean
  total_deliveries: number
  rating: number | null
  created_at: string
  user: { id: string; full_name: string; email: string; phone: string } | null
}

const statusVariant: Record<string, 'success' | 'info' | 'default'> = {
  online: 'success',
  on_trip: 'info',
  offline: 'default',
}

export default function DriversPage() {
  const t = useTranslations('drivers')
  const [drivers, setDrivers] = useState<Driver[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [editDriver, setEditDriver] = useState<Driver | null>(null)

  const fetchDrivers = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<{ items: Driver[]; total: number }>('/v1/drivers/')
      setDrivers(data.items || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load drivers')
      setDrivers([])
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchDrivers() }, [fetchDrivers])

  const filtered = drivers.filter((d) =>
    (d.user?.full_name || '').toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="sm" onClick={fetchDrivers}>
            <RefreshCw className="w-4 h-4" />
          </Button>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder={t('search')}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-64 pl-10 pr-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>
        </div>
      </div>

      {error && (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
          {error}
          <button onClick={fetchDrivers} className="ml-2 underline">Retry</button>
        </div>
      )}

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('name')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('phone')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('status')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('rating')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('completedTrips')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('joinedDate')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {isLoading ? (
                  <tr><td colSpan={7} className="px-6 py-12"><SkeletonTable rows={5} cols={7} /></td></tr>
                ) : filtered.length === 0 ? (
                  <tr><td colSpan={7} className="px-6 py-12 text-center text-gray-500">No drivers found</td></tr>
                ) : (
                  filtered.map((d) => (
                    <tr key={d.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="px-6 py-4 font-medium">{d.user?.full_name || '—'}</td>
                      <td className="px-6 py-4 text-gray-500">{d.user?.phone || '—'}</td>
                      <td className="px-6 py-4">
                        <Badge variant={d.is_available ? 'success' : 'default'}>
                          {d.is_available ? t('online') : t('offline')}
                        </Badge>
                      </td>
                      <td className="px-6 py-4">
                        <span className="flex items-center gap-1"><Star className="w-3.5 h-3.5 text-yellow-500 fill-yellow-500" />{d.rating?.toFixed(1) || '—'}</span>
                      </td>
                      <td className="px-6 py-4">{d.total_deliveries.toLocaleString()}</td>
                      <td className="px-6 py-4">{d.created_at ? new Date(d.created_at).toLocaleDateString() : '—'}</td>
                      <td className="px-6 py-4">
                        <button
                          onClick={() => setEditDriver(d)}
                          className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
      {editDriver && (
        <EditDriverModal
          open={!!editDriver}
          onClose={() => setEditDriver(null)}
          driver={editDriver}
          onSaved={fetchDrivers}
        />
      )}
    </div>
  )
}
