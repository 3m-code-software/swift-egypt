'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { useParams, useRouter } from 'next/navigation'
import { ArrowLeft, CheckCircle, XCircle, RefreshCw, UserCheck } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { get, post } from '@/lib/api'
import { Button } from '@/components/ui/Button'
import Link from 'next/link'

interface BatchOrder {
  id: string
  customer_name: string
  customer_phone: string
  customer_phone2: string | null
  address: string
  province: string | null
  city: string | null
  product_name: string | null
  quantity: number
  product_price: number
  shipping_cost: number
  commission: number
  total: number
  status: string
  notes: string | null
  delivery_notes: string | null
  returned_reason: string | null
  collected_amount: number
  call_attempts: number
  delivered_quantity: number
  delivery_date: string | null
  assigned_agent_id: string | null
  assigned_at: string | null
}

interface BatchDetail {
  id: string
  batch_number: string
  seller_name: string | null
  status: string
  total_orders: number
  total_amount: number
  commission_percent: number
  commission_amount: number
  notes: string | null
  file_name: string | null
  orders: BatchOrder[]
  created_at: string | null
  end_of_day_done: boolean
}

export default function BatchDetailPage() {
  const t = useTranslations('batches')
  const params = useParams()
  const locale = params.locale as string
  const id = params.id as string
  const router = useRouter()
  const [batch, setBatch] = useState<BatchDetail | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [commissionPercent, setCommissionPercent] = useState(0)
  const [rejectReason, setRejectReason] = useState('')
  const [actionLoading, setActionLoading] = useState(false)
  const [selectedOrders, setSelectedOrders] = useState<Set<string>>(new Set())
  const [agentId, setAgentId] = useState('')
  const [endOfDayLoading, setEndOfDayLoading] = useState(false)
  const [assignLoading, setAssignLoading] = useState(false)

  const fetchBatch = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<BatchDetail>(`/v1/batches/${id}`)
      setBatch(data)
      setCommissionPercent(data.commission_percent || 0)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load batch')
    } finally {
      setIsLoading(false)
    }
  }, [id])

  useEffect(() => { fetchBatch() }, [fetchBatch])

  const handleApprove = async () => {
    setActionLoading(true)
    try {
      await post(`/v1/batches/${id}/approve`, { commission_percent: commissionPercent })
      alert('Batch approved successfully!')
      fetchBatch()
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to approve batch')
    } finally {
      setActionLoading(false)
    }
  }

  const handleReject = async () => {
    if (!rejectReason.trim()) return alert('Please provide a rejection reason')
    setActionLoading(true)
    try {
      await post(`/v1/batches/${id}/reject`, { reason: rejectReason })
      alert('Batch rejected')
      fetchBatch()
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to reject batch')
    } finally {
      setActionLoading(false)
    }
  }

  const handleEndOfDay = async () => {
    if (!confirm(t('endOfDayConfirm'))) return
    setEndOfDayLoading(true)
    try {
      await post(`/v1/agent/batches/${id}/end-day`)
      alert('End of day completed!')
      fetchBatch()
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to complete end of day')
    } finally {
      setEndOfDayLoading(false)
    }
  }

  const handleAssign = async () => {
    if (selectedOrders.size === 0 || !agentId.trim()) return
    setAssignLoading(true)
    try {
      await post('/v1/agent/assign', { order_ids: Array.from(selectedOrders), agent_id: agentId.trim() })
      alert('Orders assigned successfully!')
      setSelectedOrders(new Set())
      setAgentId('')
      fetchBatch()
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to assign orders')
    } finally {
      setAssignLoading(false)
    }
  }

  const toggleSelectAll = () => {
    if (!batch) return
    if (selectedOrders.size === batch.orders.length) {
      setSelectedOrders(new Set())
    } else {
      setSelectedOrders(new Set(batch.orders.map(o => o.id)))
    }
  }

  const toggleOrder = (orderId: string) => {
    const next = new Set(selectedOrders)
    if (next.has(orderId)) {
      next.delete(orderId)
    } else {
      next.add(orderId)
    }
    setSelectedOrders(next)
  }

  const statusColors: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
    under_review: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400',
    approved: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
    rejected: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
  }

  const deliveryStatusColors: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
    delivered: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
    partial: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400',
    returned: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
    no_answer: 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400',
  }

  const isApproved = batch?.status === 'approved'

  if (isLoading) return <div className="p-8 text-center text-gray-500">{t('common.loading')}</div>
  if (error) return (
    <div className="p-8">
      <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
        {error}
        <button onClick={fetchBatch} className="ml-2 underline">Retry</button>
      </div>
    </div>
  )
  if (!batch) return null

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href={`/${locale}/batches`} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <div>
          <h1 className="text-2xl font-bold">{t('details')}: {batch.batch_number}</h1>
          <p className="text-sm text-gray-500">{t('uploadedBy')}: {batch.seller_name || '—'}</p>
        </div>
        <span className={`ml-auto px-3 py-1 rounded-full text-sm font-medium ${statusColors[batch.status] || ''}`}>
          {t(batch.status)}
        </span>
        {isApproved && (
          <span className={`px-3 py-1 rounded-full text-sm font-medium ${batch.end_of_day_done ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'}`}>
            {batch.end_of_day_done ? t('endOfDayDone') : t('pending')}
          </span>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-gray-500">{t('totalOrders')}</p>
            <p className="text-2xl font-bold">{batch.total_orders}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-gray-500">{t('totalAmount')}</p>
            <p className="text-2xl font-bold">{batch.total_amount.toFixed(2)} EGP</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-gray-500">{t('commission')}</p>
            <p className="text-2xl font-bold">{batch.commission_percent}%</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-gray-500">{t('file')}</p>
            <p className="text-lg font-medium truncate">{batch.file_name || '—'}</p>
          </CardContent>
        </Card>
      </div>

      {batch.status === 'pending' && (
        <Card>
          <CardContent className="p-6">
            <h3 className="text-lg font-semibold mb-4">{t('review')}</h3>
            <div className="flex flex-wrap gap-4 items-end">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('setCommission')}</label>
                <input
                  type="number"
                  value={commissionPercent}
                  onChange={(e) => setCommissionPercent(Number(e.target.value))}
                  className="w-32 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm"
                  min="0"
                  max="100"
                  step="0.5"
                />
              </div>
              <div className="flex-1 min-w-[200px]">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('notes')}</label>
                <input
                  type="text"
                  value={batch.notes || ''}
                  onChange={(e) => setBatch({ ...batch, notes: e.target.value })}
                  className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm"
                  placeholder={t('notes')}
                />
              </div>
              <Button onClick={handleApprove} disabled={actionLoading} className="bg-green-600 hover:bg-green-700">
                <CheckCircle className="w-4 h-4 mr-1" />
                {t('approve')}
              </Button>
              <div className="flex gap-2 items-end">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('reason')}</label>
                  <input
                    type="text"
                    value={rejectReason}
                    onChange={(e) => setRejectReason(e.target.value)}
                    className="w-48 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm"
                    placeholder={t('rejectReason')}
                  />
                </div>
                <Button onClick={handleReject} disabled={actionLoading || !rejectReason.trim()} variant="destructive">
                  <XCircle className="w-4 h-4 mr-1" />
                  {t('reject')}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {isApproved && !batch.end_of_day_done && (
        <Card>
          <CardContent className="p-6">
            <h3 className="text-lg font-semibold mb-4">{t('endOfDay')}</h3>
            <p className="text-sm text-gray-500 mb-4">{t('endOfDayConfirm')}</p>
            <Button onClick={handleEndOfDay} disabled={endOfDayLoading} variant="destructive">
              {endOfDayLoading ? t('common.loading') : t('endOfDay')}
            </Button>
          </CardContent>
        </Card>
      )}

      {isApproved && (
        <Card>
          <CardContent className="p-6">
            <h3 className="text-lg font-semibold mb-4">{t('assignAgent')}</h3>
            <div className="flex gap-4 items-end">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('agentId')}</label>
                <input
                  type="text"
                  value={agentId}
                  onChange={(e) => setAgentId(e.target.value)}
                  className="w-48 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm"
                  placeholder={t('agentId')}
                />
              </div>
              <Button onClick={handleAssign} disabled={assignLoading || selectedOrders.size === 0 || !agentId.trim()}>
                <UserCheck className="w-4 h-4 mr-1" />
                {assignLoading ? t('common.loading') : t('assign')}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardContent className="p-0">
          <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <h3 className="font-semibold">{t('totalOrders')} ({batch.orders.length})</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  {isApproved && (
                    <th className="px-4 py-3 w-10">
                      <input
                        type="checkbox"
                        checked={selectedOrders.size === batch.orders.length && batch.orders.length > 0}
                        onChange={toggleSelectAll}
                        className="rounded border-gray-300 dark:border-gray-600"
                        title={t('selectAll')}
                      />
                    </th>
                  )}
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('customerName')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('customerPhone')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('address')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('product')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('quantity')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('price')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('shipping')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('deliveryStatus')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('callAttempts')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('deliveryNotes')}</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('total')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {batch.orders.map((o) => (
                  <tr key={o.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                    {isApproved && (
                      <td className="px-4 py-3">
                        <input
                          type="checkbox"
                          checked={selectedOrders.has(o.id)}
                          onChange={() => toggleOrder(o.id)}
                          className="rounded border-gray-300 dark:border-gray-600"
                        />
                      </td>
                    )}
                    <td className="px-4 py-3 font-medium">{o.customer_name}</td>
                    <td className="px-4 py-3">{o.customer_phone}</td>
                    <td className="px-4 py-3 max-w-[200px] truncate">{o.address}</td>
                    <td className="px-4 py-3">{o.product_name || '—'}</td>
                    <td className="px-4 py-3">{o.quantity}</td>
                    <td className="px-4 py-3">{o.product_price.toFixed(2)}</td>
                    <td className="px-4 py-3">{o.shipping_cost.toFixed(2)}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${deliveryStatusColors[o.status] || 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'}`}>
                        {o.status}
                      </span>
                    </td>
                    <td className="px-4 py-3">{o.call_attempts ?? 0}</td>
                    <td className="px-4 py-3 max-w-[150px] truncate">{o.delivery_notes || '—'}</td>
                    <td className="px-4 py-3 font-medium">{o.total.toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="bg-gray-50 dark:bg-gray-800/50 font-bold">
                  <td colSpan={isApproved ? 11 : 10} className="px-4 py-3 text-right">{t('total')}</td>
                  <td className="px-4 py-3">{batch.total_amount.toFixed(2)}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
