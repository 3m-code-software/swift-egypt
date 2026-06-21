'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { Card, CardContent } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { RefreshCw } from 'lucide-react'
import { get } from '@/lib/api'
import { SkeletonTable } from '@/components/ui/Skeleton'

interface Invoice {
  id: string
  invoice_number: string
  customer_name: string | null
  total: number
  payment_status: string
  subtotal: number
  tax: number
  insurance: number
  additional_fees: number
  created_at: string | null
  paid_at: string | null
}

const statusVariant: Record<string, 'success' | 'warning' | 'danger' | 'info' | 'default'> = {
  paid: 'success',
  pending: 'warning',
  overdue: 'danger',
  partial: 'info',
  refunded: 'default',
}

export default function InvoicesPage() {
  const t = useTranslations('invoices')
  const [invoices, setInvoices] = useState<Invoice[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchInvoices = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<{ items: Invoice[]; total: number }>('/v1/invoices/')
      setInvoices(data.items || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load invoices')
      setInvoices([])
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchInvoices() }, [fetchInvoices])

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <Button variant="ghost" size="sm" onClick={fetchInvoices}>
          <RefreshCw className="w-4 h-4" />
        </Button>
      </div>

      {error && (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
          {error}
          <button onClick={fetchInvoices} className="ml-2 underline">Retry</button>
        </div>
      )}

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('invoiceNumber')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('customer')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('amount')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('status')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('issueDate')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {isLoading ? (
                  <tr><td colSpan={5} className="px-6 py-12"><SkeletonTable rows={5} cols={5} /></td></tr>
                ) : invoices.length === 0 ? (
                  <tr><td colSpan={5} className="px-6 py-12 text-center text-gray-500">No invoices found</td></tr>
                ) : (
                  invoices.map((inv) => (
                    <tr key={inv.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="px-6 py-4 font-mono text-sm font-medium">{inv.invoice_number}</td>
                      <td className="px-6 py-4">{inv.customer_name || '—'}</td>
                      <td className="px-6 py-4 font-medium">EGP {inv.total.toLocaleString()}</td>
                      <td className="px-6 py-4"><Badge variant={statusVariant[inv.payment_status] || 'default'}>{t(inv.payment_status)}</Badge></td>
                      <td className="px-6 py-4">{inv.created_at ? new Date(inv.created_at).toLocaleDateString() : '—'}</td>
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
