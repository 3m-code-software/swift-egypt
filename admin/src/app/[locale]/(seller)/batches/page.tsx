'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { useParams } from 'next/navigation'
import { RefreshCw, Eye } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { get } from '@/lib/api'
import { SkeletonTable } from '@/components/ui/Skeleton'
import { Button } from '@/components/ui/Button'
import Link from 'next/link'

interface Batch {
  id: string
  batch_number: string
  status: string
  total_orders: number
  total_amount: number
  created_at: string | null
}

export default function SellerBatchesPage() {
  const t = useTranslations('batches')
  const params = useParams()
  const locale = params.locale as string
  const [batches, setBatches] = useState<Batch[]>([])
  const [isLoading, setIsLoading] = useState(true)

  const fetchBatches = useCallback(async () => {
    setIsLoading(true)
    try {
      const data = await get<Batch[]>('/v1/batches/my/list')
      setBatches(data || [])
    } catch {
      setBatches([])
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchBatches() }, [fetchBatches])

  const statusColors: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
    under_review: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400',
    approved: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
    rejected: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <div className="flex items-center gap-2">
          <Link
            href={`/${locale}/seller/upload`}
            className="px-4 py-2 bg-primary-600 text-white rounded-lg text-sm font-medium hover:bg-primary-700"
          >
            {t('common.import')}
          </Link>
          <Button variant="ghost" size="sm" onClick={fetchBatches}>
            <RefreshCw className="w-4 h-4" />
          </Button>
        </div>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('batchNumber')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('status')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('totalOrders')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('totalAmount')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('createdAt')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('common.actions', {})}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {isLoading ? (
                  <tr><td colSpan={6} className="px-6 py-12"><SkeletonTable rows={5} cols={6} /></td></tr>
                ) : batches.length === 0 ? (
                  <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-500">{t('common.noData')}</td></tr>
                ) : (
                  batches.map((b) => (
                    <tr key={b.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="px-6 py-4 font-mono text-sm font-medium">{b.batch_number}</td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${statusColors[b.status] || ''}`}>
                          {t(b.status)}
                        </span>
                      </td>
                      <td className="px-6 py-4">{b.total_orders}</td>
                      <td className="px-6 py-4">{b.total_amount.toFixed(2)} EGP</td>
                      <td className="px-6 py-4">{b.created_at ? new Date(b.created_at).toLocaleDateString() : '—'}</td>
                      <td className="px-6 py-4">
                        <Link href={`/${locale}/batches/${b.id}`} className="inline-flex items-center gap-1 text-primary-600 hover:text-primary-800 text-sm font-medium">
                          <Eye className="w-4 h-4" /> View
                        </Link>
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
