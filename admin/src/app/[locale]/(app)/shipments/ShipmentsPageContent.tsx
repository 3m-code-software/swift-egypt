'use client'

import { useState } from 'react'
import { useTranslations } from 'next-intl'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { ShipmentTable } from '@/components/shipments/ShipmentTable'
import { useShipments } from '@/hooks/useShipments'
import { Search, RefreshCw } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { SkeletonTable } from '@/components/ui/Skeleton'
import { useToast } from '@/components/ui/Toast'

const statusOptions = [
  { value: '', label: 'All Statuses' },
  { value: 'draft', label: 'Draft' },
  { value: 'pending', label: 'Pending' },
  { value: 'confirmed', label: 'Confirmed' },
  { value: 'in_transit', label: 'In Transit' },
  { value: 'delivered', label: 'Delivered' },
  { value: 'cancelled', label: 'Cancelled' },
]

const serviceOptions = [
  { value: '', label: 'All Services' },
  { value: 'express', label: 'Express' },
  { value: 'standard', label: 'Standard' },
  { value: 'same_day', label: 'Same Day' },
  { value: 'freight', label: 'Freight' },
]

export default function ShipmentsPageContent() {
  const t = useTranslations('shipments')
  const { shipments, isLoading, error, refetch } = useShipments()
  const { addToast: showToast } = useToast()
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [service, setService] = useState('')

  const filtered = shipments.filter((s) => {
    const matchSearch =
      !search ||
      s.trackingId.toLowerCase().includes(search.toLowerCase()) ||
      s.customer.toLowerCase().includes(search.toLowerCase())
    const matchStatus = !status || s.status === status
    const matchService = !service || s.serviceType === service
    return matchSearch && matchStatus && matchService
  })

  const handleRefresh = () => {
    refetch()
    showToast({ message: 'Shipments refreshed', type: 'success' })
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder={t('search')}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
        </div>
        <div className="flex gap-2 w-full sm:w-auto">
          <Select
            options={statusOptions}
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            className="w-full sm:w-40"
          />
          <Select
            options={serviceOptions}
            value={service}
            onChange={(e) => setService(e.target.value)}
            className="w-full sm:w-40"
          />
          <Button variant="ghost" size="sm" onClick={handleRefresh}>
            <RefreshCw className="w-4 h-4" />
          </Button>
        </div>
      </div>

      {error && (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
          {error}
          <button onClick={refetch} className="ml-2 underline">Retry</button>
        </div>
      )}

      {isLoading ? (
        <SkeletonTable rows={8} cols={7} />
      ) : (
        <ShipmentTable shipments={filtered} onRefresh={refetch} />
      )}
    </div>
  )
}
