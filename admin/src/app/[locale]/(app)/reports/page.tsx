'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { useToast } from '@/components/ui/Toast'
import { get } from '@/lib/api'
import { Card, CardContent, CardHeader } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Skeleton, SkeletonCard } from '@/components/ui/Skeleton'
import { BarChart3, TrendingUp, Users, Truck, Download, RefreshCw, Building2 } from 'lucide-react'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend
} from 'recharts'

interface MonthlyItem {
  month: string
  shipments: number
  revenue: number
}

interface StatusItem {
  name: string
  value: number
  color: string
}

interface DriverItem {
  name: string
  rating: number
  trips: number
}

interface CustomerItem {
  customer_name: string
  company_name: string | null
  total_shipments: number
  total_revenue: number
  avg_shipment_value: number
}

interface ReportData {
  monthly: MonthlyItem[]
  status_distribution: StatusItem[]
  driver_performance: DriverItem[]
  customers: CustomerItem[]
}

export default function ReportsPage() {
  const t = useTranslations('reports')
  const { addToast } = useToast()
  const [data, setData] = useState<ReportData | null>(null)
  const [loading, setLoading] = useState(true)
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [appliedStart, setAppliedStart] = useState('')
  const [appliedEnd, setAppliedEnd] = useState('')

  const loadReport = useCallback(async (sd: string, ed: string) => {
    setLoading(true)
    try {
      let url = '/v1/reports/summary'
      const params = new URLSearchParams()
      if (sd) params.set('start_date', sd)
      if (ed) params.set('end_date', ed)
      const qs = params.toString()
      if (qs) url += '?' + qs
      const res = await get<ReportData>(url)
      setData(res)
    } catch (err: any) {
      addToast({ type: 'error', message: err.message })
    } finally {
      setLoading(false)
    }
  }, [addToast])

  useEffect(() => {
    loadReport('', '')
  }, [loadReport])

  const handleGenerate = () => {
    setAppliedStart(startDate)
    setAppliedEnd(endDate)
    loadReport(startDate, endDate)
  }

  const handleExport = async () => {
    try {
      const token = localStorage.getItem('auth_token')
      let url = `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api'}/v1/reports/export/excel`
      const params = new URLSearchParams()
      if (appliedStart) params.set('start_date', appliedStart)
      if (appliedEnd) params.set('end_date', appliedEnd)
      const qs = params.toString()
      if (qs) url += '?' + qs

      const res = await fetch(url, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      })
      if (!res.ok) throw new Error('Export failed')
      const blob = await res.blob()
      const dlUrl = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = dlUrl
      a.download = `shipments_report_${new Date().toISOString().slice(0, 10)}.xlsx`
      a.click()
      URL.revokeObjectURL(dlUrl)
      addToast({ type: 'success', message: 'Report exported successfully' })
    } catch (err: any) {
      addToast({ type: 'error', message: err.message })
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <Skeleton className="h-8 w-32" />
          <Skeleton className="h-10 w-32" />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {Array.from({ length: 6 }).map((_, i) => <SkeletonCard key={i} className="h-80" />)}
        </div>
      </div>
    )
  }

  const formatRevenue = (value: number) => `EGP ${value.toLocaleString()}`

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1">
            <Input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} className="w-36" />
            <span className="text-gray-400">—</span>
            <Input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} className="w-36" />
          </div>
          <Button size="sm" onClick={handleGenerate}>{t('generate')}</Button>
          <Button variant="outline" size="sm" onClick={() => { setStartDate(''); setEndDate(''); setAppliedStart(''); setAppliedEnd(''); loadReport('', '') }}>
            <RefreshCw className="w-4 h-4" />
          </Button>
          <Button variant="outline" size="sm" onClick={handleExport}>
            <Download className="w-4 h-4 me-2" />
            {t('export')}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <h3 className="font-semibold flex items-center gap-2"><TrendingUp className="w-4 h-4" />{t('shipmentReport')}</h3>
          </CardHeader>
          <CardContent>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={data?.monthly || []}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="month" stroke="#9ca3af" fontSize={12} />
                  <YAxis stroke="#9ca3af" fontSize={12} />
                  <Tooltip />
                  <Bar dataKey="shipments" fill="#3b82f6" radius={[4, 4, 0, 0]} name="Shipments" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <h3 className="font-semibold flex items-center gap-2"><BarChart3 className="w-4 h-4" />{t('revenueReport')}</h3>
          </CardHeader>
          <CardContent>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={data?.monthly || []}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="month" stroke="#9ca3af" fontSize={12} />
                  <YAxis stroke="#9ca3af" fontSize={12} />
                  <Tooltip formatter={(value: number) => formatRevenue(value)} />
                  <Bar dataKey="revenue" fill="#22c55e" radius={[4, 4, 0, 0]} name="Revenue" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <h3 className="font-semibold flex items-center gap-2"><Truck className="w-4 h-4" />Shipment Status Distribution</h3>
          </CardHeader>
          <CardContent>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={data?.status_distribution || []} cx="50%" cy="50%" innerRadius={60} outerRadius={100} paddingAngle={4} dataKey="value" label>
                    {(data?.status_distribution || []).map((entry: StatusItem, idx: number) => (
                      <Cell key={idx} fill={entry.color} />
                    ))}
                  </Pie>
                  <Legend />
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <h3 className="font-semibold flex items-center gap-2"><Users className="w-4 h-4" />{t('driverPerformance')}</h3>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {(data?.driver_performance || []).length === 0 ? (
                <p className="text-sm text-gray-500 text-center py-8">No driver data available</p>
              ) : (
                (data?.driver_performance || []).map((driver) => (
                  <div key={driver.name} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                    <div>
                      <p className="text-sm font-medium">{driver.name}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{driver.trips} trips</p>
                    </div>
                    <div className="flex items-center gap-1">
                      <span className="text-yellow-500">★</span>
                      <span className="text-sm font-medium">{driver.rating}</span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <h3 className="font-semibold flex items-center gap-2"><Building2 className="w-4 h-4" />{t('customerReport')}</h3>
          </CardHeader>
          <CardContent>
            {(data?.customers || []).length === 0 ? (
              <p className="text-sm text-gray-500 text-center py-8">No customer data available</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-gray-200 dark:border-gray-700">
                      <th className="text-start py-2 px-3 font-medium text-gray-500">Customer</th>
                      <th className="text-start py-2 px-3 font-medium text-gray-500">Company</th>
                      <th className="text-end py-2 px-3 font-medium text-gray-500">Shipments</th>
                      <th className="text-end py-2 px-3 font-medium text-gray-500">Total Revenue</th>
                      <th className="text-end py-2 px-3 font-medium text-gray-500">Avg / Shipment</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(data?.customers || []).map((c) => (
                      <tr key={c.customer_name} className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-800/50">
                        <td className="py-2 px-3">{c.customer_name}</td>
                        <td className="py-2 px-3 text-gray-500">{c.company_name || '—'}</td>
                        <td className="py-2 px-3 text-end font-medium">{c.total_shipments}</td>
                        <td className="py-2 px-3 text-end">{formatRevenue(c.total_revenue)}</td>
                        <td className="py-2 px-3 text-end">{formatRevenue(c.avg_shipment_value)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
