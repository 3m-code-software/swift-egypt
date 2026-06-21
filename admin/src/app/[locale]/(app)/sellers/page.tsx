'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { Search, Store, RefreshCw, Wallet, BarChart3 } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { get } from '@/lib/api'
import { SkeletonTable } from '@/components/ui/Skeleton'
import { Button } from '@/components/ui/Button'
import Link from 'next/link'
import { useParams } from 'next/navigation'

interface Seller {
  id: string
  full_name: string | null
  email: string | null
  phone: string | null
  company_name: string | null
  total_orders: number
  wallet_balance: number
  delivery_rate: number
  created_at: string | null
}

export default function SellersPage() {
  const t = useTranslations('sellers')
  const params = useParams()
  const locale = params.locale as string
  const [sellers, setSellers] = useState<Seller[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')

  const fetchSellers = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<Seller[]>('/v1/sellers/')
      setSellers(data || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load sellers')
      setSellers([])
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchSellers() }, [fetchSellers])

  const filtered = sellers.filter((s) =>
    (s.full_name || '').toLowerCase().includes(search.toLowerCase()) ||
    (s.company_name || '').toLowerCase().includes(search.toLowerCase()) ||
    (s.email || '').toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="sm" onClick={fetchSellers}>
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
          <button onClick={fetchSellers} className="ml-2 underline">Retry</button>
        </div>
      )}

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('name')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('company')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('email')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('phone')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('totalOrders')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('walletBalance')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('joinDate')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('common.actions', {})}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {isLoading ? (
                  <tr><td colSpan={8} className="px-6 py-12"><SkeletonTable rows={5} cols={8} /></td></tr>
                ) : filtered.length === 0 ? (
                  <tr><td colSpan={8} className="px-6 py-12 text-center text-gray-500">No sellers found</td></tr>
                ) : (
                  filtered.map((s) => (
                    <tr key={s.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="px-6 py-4 font-medium">{s.full_name || '—'}</td>
                      <td className="px-6 py-4">{s.company_name || '—'}</td>
                      <td className="px-6 py-4">{s.email || '—'}</td>
                      <td className="px-6 py-4">{s.phone || '—'}</td>
                      <td className="px-6 py-4">{s.total_orders}</td>
                      <td className="px-6 py-4">{s.wallet_balance?.toFixed(2) || '0.00'} EGP</td>
                      <td className="px-6 py-4">{s.created_at ? new Date(s.created_at).toLocaleDateString() : '—'}</td>
                      <td className="px-6 py-4">
                        <Link
                          href={`/${locale}/sellers/${s.id}`}
                          className="text-primary-600 hover:text-primary-800 text-sm font-medium"
                        >
                          View
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
