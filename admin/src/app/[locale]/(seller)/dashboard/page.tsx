'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { useParams } from 'next/navigation'
import { Package, TrendingUp, TrendingDown, DollarSign, RefreshCw } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { get } from '@/lib/api'
import { Button } from '@/components/ui/Button'
import Link from 'next/link'

interface Stats {
  total_orders: number
  total_delivered: number
  total_returned: number
  pending_orders: number
  delivery_rate: number
  return_rate: number
  total_revenue: number
}

interface Batch {
  id: string
  batch_number: string
  status: string
  total_orders: number
  total_amount: number
  created_at: string | null
}

export default function SellerDashboardPage() {
  const t = useTranslations()
  const params = useParams()
  const locale = params.locale as string
  const [stats, setStats] = useState<Stats | null>(null)
  const [recentBatches, setRecentBatches] = useState<Batch[]>([])
  const [isLoading, setIsLoading] = useState(true)

  const fetchData = useCallback(async () => {
    setIsLoading(true)
    try {
      const [statsData, batchesData] = await Promise.all([
        get<Stats>('/v1/sellers/me/stats').catch(() => null),
        get<Batch[]>('/v1/batches/my/list').catch(() => []),
      ])
      setStats(statsData)
      setRecentBatches((batchesData || []).slice(0, 5))
    } catch {
      // ignore
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchData() }, [fetchData])

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('sellerNav.dashboard')}</h1>
        <Button variant="ghost" size="sm" onClick={fetchData}>
          <RefreshCw className="w-4 h-4" />
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{t('batches.totalOrders')}</p>
                <p className="text-2xl font-bold">{isLoading ? '...' : stats?.total_orders || 0}</p>
              </div>
              <Package className="w-8 h-8 text-primary-400" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{t('common.role_seller', '')}</p>
                <p className="text-2xl font-bold text-green-600">{isLoading ? '...' : stats?.total_delivered || 0}</p>
              </div>
              <TrendingUp className="w-8 h-8 text-green-400" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{t('shipmentStatus.returned')}</p>
                <p className="text-2xl font-bold text-red-600">{isLoading ? '...' : stats?.total_returned || 0}</p>
              </div>
              <TrendingDown className="w-8 h-8 text-red-400" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{t('invoices.amount')}</p>
                <p className="text-2xl font-bold">{isLoading ? '...' : `${(stats?.total_revenue || 0).toFixed(2)} EGP`}</p>
              </div>
              <DollarSign className="w-8 h-8 text-yellow-400" />
            </div>
          </CardContent>
        </Card>
      </div>

      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card>
            <CardContent className="p-4">
              <p className="text-sm text-gray-500 mb-1">{t('sellers.deliveryRate')}</p>
              <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3">
                <div
                  className="bg-green-500 h-3 rounded-full transition-all"
                  style={{ width: `${Math.min(stats.delivery_rate, 100)}%` }}
                />
              </div>
              <p className="text-sm mt-1">{stats.delivery_rate.toFixed(1)}%</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-sm text-gray-500 mb-1">{t('customers.totalShipments')}</p>
              <div className="flex gap-2 flex-wrap">
                <span className="px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 rounded-full text-sm">
                  {t('batches.pending')}: {stats.pending_orders}
                </span>
                <span className="px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 rounded-full text-sm">
                  {t('batches.approved')}: {stats.total_delivered}
                </span>
                <span className="px-3 py-1 bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 rounded-full text-sm">
                  {t('batches.rejected')}: {stats.total_returned}
                </span>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      <Card>
        <CardContent className="p-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold">{t('batches.title')}</h3>
            <Link
              href={`/${locale}/seller/batches`}
              className="text-sm text-primary-600 hover:text-primary-800"
            >
              {t('dashboard.viewAll')}
            </Link>
          </div>
          {recentBatches.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <p>{t('common.noData')}</p>
              <Link
                href={`/${locale}/seller/upload`}
                className="inline-block mt-2 text-primary-600 hover:text-primary-800 text-sm font-medium"
              >
                {t('sellerNav.uploadSheet')}
              </Link>
            </div>
          ) : (
            <div className="space-y-2">
              {recentBatches.map((b) => (
                <Link
                  key={b.id}
                  href={`/${locale}/seller/batches/${b.id}`}
                  className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800/50 border border-gray-200 dark:border-gray-700"
                >
                  <div>
                    <p className="font-medium text-sm">{b.batch_number}</p>
                    <p className="text-xs text-gray-500">{b.total_orders} orders</p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium text-sm">{b.total_amount.toFixed(2)} EGP</p>
                    <p className="text-xs text-gray-500">{b.created_at ? new Date(b.created_at).toLocaleDateString() : ''}</p>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
