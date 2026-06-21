'use client'

import { useRouter, useParams } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { Table } from '@/components/ui/Table'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/Button'
import { Plus } from 'lucide-react'
import { useState } from 'react'
import { CreateShipmentModal } from './CreateShipmentModal'
import type { Shipment, ShipmentStatus } from '@/hooks/useShipments'

interface ShipmentTableProps {
  shipments: Shipment[]
  onRefresh?: () => void
}

const serviceTypeColors: Record<string, string> = {
  express: 'text-purple-600 dark:text-purple-400',
  standard: 'text-gray-600 dark:text-gray-400',
  same_day: 'text-blue-600 dark:text-blue-400',
  international: 'text-green-600 dark:text-green-400',
  freight: 'text-orange-600 dark:text-orange-400',
}

export function ShipmentTable({ shipments, onRefresh }: ShipmentTableProps) {
  const t = useTranslations('shipments')
  const router = useRouter()
  const params = useParams()
  const locale = params.locale as string
  const [showCreate, setShowCreate] = useState(false)

  const columns = [
    {
      key: 'trackingId',
      header: t('trackingId'),
      render: (item: Shipment) => (
        <span className="font-mono text-sm font-medium text-primary-600 dark:text-primary-400">
          {item.trackingId}
        </span>
      ),
    },
    { key: 'customer', header: t('customer') },
    { key: 'origin', header: t('origin') },
    { key: 'destination', header: t('destination') },
    {
      key: 'status',
      header: t('status'),
      render: (item: Shipment) => <StatusBadge status={item.status as ShipmentStatus} />,
    },
    {
      key: 'serviceType',
      header: t('serviceType'),
      render: (item: Shipment) => (
        <span className={`text-sm capitalize ${serviceTypeColors[item.serviceType] || ''}`}>
          {item.serviceType.replace('_', ' ')}
        </span>
      ),
    },
    { key: 'estimatedDelivery', header: t('estimatedDelivery') },
  ]

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <Button onClick={() => setShowCreate(true)}>
          <Plus className="w-4 h-4 mr-2" />
          {t('create')}
        </Button>
      </div>
      <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">
        <Table
          columns={columns}
          data={shipments as any}
          onRowClick={(item: any) => router.push(`/${locale}/shipments/${item.id}`)}
        />
      </div>
      <CreateShipmentModal open={showCreate} onClose={() => setShowCreate(false)} onCreated={onRefresh} />
    </div>
  )
}
