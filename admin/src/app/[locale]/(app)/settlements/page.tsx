'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { RefreshCw, Plus, DollarSign } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { get, post } from '@/lib/api'
import { useAuth } from '@/hooks/useAuth'
import { SkeletonTable } from '@/components/ui/Skeleton'

interface SellerSettlement {
  id: string
  seller_name: string
  period_start: string
  period_end: string
  total_orders: number
  delivered: number
  returned: number
  net_amount: number
  status: string
  created_at: string
}

interface DriverSettlement {
  id: string
  driver_name: string
  period_start: string
  period_end: string
  assigned: number
  delivered: number
  returned: number
  no_answer: number
  collected: number
  fees: number
  net_amount: number
  status: string
  created_at: string
}

export default function SettlementsPage() {
  const t = useTranslations('settlements')
  const { user } = useAuth()
  const isAdmin = user?.role === 'admin'

  const [activeTab, setActiveTab] = useState<'seller' | 'driver'>('seller')

  const [sellerSettlements, setSellerSettlements] = useState<SellerSettlement[]>([])
  const [sellerLoading, setSellerLoading] = useState(true)
  const [sellerError, setSellerError] = useState<string | null>(null)

  const [driverSettlements, setDriverSettlements] = useState<DriverSettlement[]>([])
  const [driverLoading, setDriverLoading] = useState(true)
  const [driverError, setDriverError] = useState<string | null>(null)

  const [showSellerForm, setShowSellerForm] = useState(false)
  const [sellerStart, setSellerStart] = useState('')
  const [sellerEnd, setSellerEnd] = useState('')
  const [sellerId, setSellerId] = useState('')
  const [generateLoading, setGenerateLoading] = useState(false)

  const [showDriverForm, setShowDriverForm] = useState(false)
  const [driverStart, setDriverStart] = useState('')
  const [driverEnd, setDriverEnd] = useState('')
  const [deliveryFee, setDeliveryFee] = useState('10')
  const [driverGenerateLoading, setDriverGenerateLoading] = useState(false)

  const [payLoading, setPayLoading] = useState<string | null>(null)

  const fetchSellerSettlements = useCallback(async () => {
    setSellerLoading(true)
    setSellerError(null)
    try {
      const data = await get<{ settlements: SellerSettlement[]; total: number; page: number; per_page: number }>('/v1/settlements/seller/list')
      setSellerSettlements(data.settlements || [])
    } catch (err) {
      setSellerError(err instanceof Error ? err.message : 'Failed to load seller settlements')
      setSellerSettlements([])
    } finally {
      setSellerLoading(false)
    }
  }, [])

  const fetchDriverSettlements = useCallback(async () => {
    setDriverLoading(true)
    setDriverError(null)
    try {
      const data = await get<{ settlements: DriverSettlement[]; total: number; page: number; per_page: number }>('/v1/settlements/driver/list')
      setDriverSettlements(data.settlements || [])
    } catch (err) {
      setDriverError(err instanceof Error ? err.message : 'Failed to load driver settlements')
      setDriverSettlements([])
    } finally {
      setDriverLoading(false)
    }
  }, [])

  useEffect(() => { fetchSellerSettlements() }, [fetchSellerSettlements])
  useEffect(() => { fetchDriverSettlements() }, [fetchDriverSettlements])

  const handleGenerateSeller = async () => {
    if (!sellerStart || !sellerEnd) return alert('Please select start and end dates')
    setGenerateLoading(true)
    try {
      let url = `/v1/settlements/seller/generate?period_start=${sellerStart}&period_end=${sellerEnd}`
      if (sellerId.trim()) url += `&seller_id=${sellerId.trim()}`
      await post(url, {})
      alert(t('generated'))
      setShowSellerForm(false)
      setSellerStart('')
      setSellerEnd('')
      setSellerId('')
      fetchSellerSettlements()
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to generate settlement')
    } finally {
      setGenerateLoading(false)
    }
  }

  const handleGenerateDriver = async () => {
    if (!driverStart || !driverEnd) return alert('Please select start and end dates')
    setDriverGenerateLoading(true)
    try {
      const url = `/v1/settlements/driver/generate?period_start=${driverStart}&period_end=${driverEnd}&delivery_fee_per_order=${deliveryFee || 10}`
      await post(url, {})
      alert(t('generated'))
      setShowDriverForm(false)
      setDriverStart('')
      setDriverEnd('')
      setDeliveryFee('10')
      fetchDriverSettlements()
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to generate settlement')
    } finally {
      setDriverGenerateLoading(false)
    }
  }

  const handlePaySeller = async (id: string) => {
    setPayLoading(id)
    try {
      await post(`/v1/settlements/seller/${id}/pay`, { notes: '' })
      alert(t('paid'))
      fetchSellerSettlements()
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to mark as paid')
    } finally {
      setPayLoading(null)
    }
  }

  const handlePayDriver = async (id: string) => {
    setPayLoading(id)
    try {
      await post(`/v1/settlements/driver/${id}/pay`, {})
      alert(t('paid'))
      fetchDriverSettlements()
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to mark as paid')
    } finally {
      setPayLoading(null)
    }
  }

  const formatDate = (d: string) => {
    if (!d) return '—'
    return new Date(d).toLocaleDateString()
  }

  const renderSellerTable = () => {
    if (sellerLoading) {
      return (
        <Card>
          <CardContent className="p-0">
            <SkeletonTable rows={5} cols={8} />
          </CardContent>
        </Card>
      )
    }
    if (sellerError) {
      return (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
          {sellerError}
          <button onClick={fetchSellerSettlements} className="ml-2 underline">Retry</button>
        </div>
      )
    }
    return (
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('seller')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('period')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('orders')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('delivered')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('returned')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('netAmount')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('status')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {sellerSettlements.length === 0 ? (
                  <tr><td colSpan={8} className="px-6 py-12 text-center text-gray-500">{t('noData')}</td></tr>
                ) : (
                  sellerSettlements.map((s) => (
                    <tr key={s.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="px-6 py-4 font-medium">{s.seller_name}</td>
                      <td className="px-6 py-4">{formatDate(s.period_start)} → {formatDate(s.period_end)}</td>
                      <td className="px-6 py-4">{s.total_orders}</td>
                      <td className="px-6 py-4">{s.delivered}</td>
                      <td className="px-6 py-4">{s.returned}</td>
                      <td className="px-6 py-4 font-medium">{s.net_amount.toFixed(2)} EGP</td>
                      <td className="px-6 py-4">
                        <Badge variant={s.status === 'paid' ? 'success' : 'warning'}>{s.status}</Badge>
                      </td>
                      <td className="px-6 py-4">
                        {isAdmin && s.status === 'pending' && (
                          <Button size="sm" variant="outline" onClick={() => handlePaySeller(s.id)} disabled={payLoading === s.id}>
                            <DollarSign className="w-3.5 h-3.5 mr-1" />
                            {payLoading === s.id ? '...' : t('pay')}
                          </Button>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    )
  }

  const renderDriverTable = () => {
    if (driverLoading) {
      return (
        <Card>
          <CardContent className="p-0">
            <SkeletonTable rows={5} cols={8} />
          </CardContent>
        </Card>
      )
    }
    if (driverError) {
      return (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
          {driverError}
          <button onClick={fetchDriverSettlements} className="ml-2 underline">Retry</button>
        </div>
      )
    }
    return (
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('driver')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('period')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('assigned')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('delivered')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('fees')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('netAmount')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('status')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {driverSettlements.length === 0 ? (
                  <tr><td colSpan={8} className="px-6 py-12 text-center text-gray-500">{t('noData')}</td></tr>
                ) : (
                  driverSettlements.map((s) => (
                    <tr key={s.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="px-6 py-4 font-medium">{s.driver_name}</td>
                      <td className="px-6 py-4">{formatDate(s.period_start)} → {formatDate(s.period_end)}</td>
                      <td className="px-6 py-4">{s.assigned}</td>
                      <td className="px-6 py-4">{s.delivered}</td>
                      <td className="px-6 py-4">{s.fees.toFixed(2)} EGP</td>
                      <td className="px-6 py-4 font-medium">{s.net_amount.toFixed(2)} EGP</td>
                      <td className="px-6 py-4">
                        <Badge variant={s.status === 'paid' ? 'success' : 'warning'}>{s.status}</Badge>
                      </td>
                      <td className="px-6 py-4">
                        {isAdmin && s.status === 'pending' && (
                          <Button size="sm" variant="outline" onClick={() => handlePayDriver(s.id)} disabled={payLoading === s.id}>
                            <DollarSign className="w-3.5 h-3.5 mr-1" />
                            {payLoading === s.id ? '...' : t('pay')}
                          </Button>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{t('title')}</h1>

      <div className="flex border-b border-gray-200 dark:border-gray-700">
        <button
          onClick={() => setActiveTab('seller')}
          className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'seller'
              ? 'border-primary-600 text-primary-600'
              : 'border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'
          }`}
        >
          {t('sellerSettlements')}
        </button>
        <button
          onClick={() => setActiveTab('driver')}
          className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'driver'
              ? 'border-primary-600 text-primary-600'
              : 'border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'
          }`}
        >
          {t('driverSettlements')}
        </button>
      </div>

      <div className="flex items-center justify-between">
        <div />
        <div className="flex items-center gap-2">
          {isAdmin && (
            <Button size="sm" onClick={() => {
              if (activeTab === 'seller') setShowSellerForm(!showSellerForm)
              else setShowDriverForm(!showDriverForm)
            }}>
              <Plus className="w-4 h-4 mr-1" />
              {t('generate')}
            </Button>
          )}
          <Button variant="ghost" size="sm" onClick={() => {
            if (activeTab === 'seller') fetchSellerSettlements()
            else fetchDriverSettlements()
          }}>
            <RefreshCw className="w-4 h-4" />
          </Button>
        </div>
      </div>

      {activeTab === 'seller' && showSellerForm && (
        <Card>
          <CardContent className="p-4">
            <div className="flex flex-wrap gap-3 items-end">
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">{t('period')} Start</label>
                <input type="date" value={sellerStart} onChange={(e) => setSellerStart(e.target.value)} className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">{t('period')} End</label>
                <input type="date" value={sellerEnd} onChange={(e) => setSellerEnd(e.target.value)} className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">{t('seller')} ID (optional)</label>
                <input type="text" value={sellerId} onChange={(e) => setSellerId(e.target.value)} placeholder="Seller ID" className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm" />
              </div>
              <Button size="sm" onClick={handleGenerateSeller} disabled={generateLoading}>
                {generateLoading ? '...' : t('generate')}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {activeTab === 'driver' && showDriverForm && (
        <Card>
          <CardContent className="p-4">
            <div className="flex flex-wrap gap-3 items-end">
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">{t('period')} Start</label>
                <input type="date" value={driverStart} onChange={(e) => setDriverStart(e.target.value)} className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">{t('period')} End</label>
                <input type="date" value={driverEnd} onChange={(e) => setDriverEnd(e.target.value)} className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">{t('fees')} Per Order</label>
                <input type="number" value={deliveryFee} onChange={(e) => setDeliveryFee(e.target.value)} className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm w-24" placeholder="10" />
              </div>
              <Button size="sm" onClick={handleGenerateDriver} disabled={driverGenerateLoading}>
                {driverGenerateLoading ? '...' : t('generate')}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {activeTab === 'seller' ? renderSellerTable() : renderDriverTable()}
    </div>
  )
}
