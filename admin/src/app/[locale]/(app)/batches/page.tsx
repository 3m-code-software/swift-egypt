'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { Search, RefreshCw, Eye, CheckCircle, XCircle } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { get } from '@/lib/api'
import { SkeletonTable } from '@/components/ui/Skeleton'
import { Button } from '@/components/ui/Button'
import { StatusBadge } from '@/components/ui/StatusBadge'
import Link from 'next/link'
import { useParams } from 'next/navigation'

interface Batch {
  id: string
  batch_number: string
  seller_name: string | null
  status: string
  total_orders: number
  total_amount: number
  commission_percent: number
  file_name: string | null
  created_at: string | null
}

export default function BatchesPage() {
  const t = useTranslations('batches')
  const params = useParams()
  const locale = params.locale as string
  const [batches, setBatches] = useState<Batch[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')

  const fetchBatches = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<Batch[]>(`/v1/batches/${statusFilter ? `?status=${statusFilter}` : ''}`)
      setBatches(data || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load batches')
      setBatches([])
    } finally {
      setIsLoading(false)
    }
  }, [statusFilter])

  useEffect(() => { fetchBatches() }, [fetchBatches])

  const filtered = batches.filter((b) =>
    b.batch_number.toLowerCase().includes(search.toLowerCase()) ||
    (b.seller_name || '').toLowerCase().includes(search.toLowerCase())
  )

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
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm"
          >
            <option value="">{t('common.filter', {})}...</option>
            <option value="pending">{t('pending')}</option>
            <option value="under_review">{t('underReview')}</option>
            <option value="approved">{t('approved')}</option>
            <option value="rejected">{t('rejected')}</option>
          </select>
          <Button variant="ghost" size="sm" onClick={fetchBatches}>
            <RefreshCw className="w-4 h-4" />
          </Button>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder={`${t('batchNumber')}...`}
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
          <button onClick={fetchBatches} className="ml-2 underline">Retry</button>
        </div>
      )}

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('batchNumber')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('seller')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('status')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('totalOrders')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('totalAmount')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('commission')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('createdAt')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('common.actions', {})}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {isLoading ? (
                  <tr><td colSpan={8} className="px-6 py-12"><SkeletonTable rows={5} cols={8} /></td></tr>
                ) : filtered.length === 0 ? (
                  <tr><td colSpan={8} className="px-6 py-12 text-center text-gray-500">No batches found</td></tr>
                ) : (
                  filtered.map((b) => (
                    <tr key={b.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="px-6 py-4 font-mono text-sm font-medium">{b.batch_number}</td>
                      <td className="px-6 py-4">{b.seller_name || '—'}</td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${statusColors[b.status] || ''}`}>
                          {t(b.status)}
                        </span>
                      </td>
                      <td className="px-6 py-4">{b.total_orders}</td>
                      <td className="px-6 py-4">{b.total_amount.toFixed(2)} EGP</td>
                      <td className="px-6 py-4">{b.commission_percent}%</td>
                      <td className="px-6 py-4">{b.created_at ? new Date(b.created_at).toLocaleDateString() : '—'}</td>
                      <td className="px-6 py-4">
                        <Link
                          href={`/${locale}/batches/${b.id}`}
                          className="inline-flex items-center gap-1 text-primary-600 hover:text-primary-800 text-sm font-medium"
                        >
                          <Eye className="w-4 h-4" />
                          {t('review')}
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
