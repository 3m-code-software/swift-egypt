'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useParams } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { get } from '@/lib/api'
import { Card, CardHeader, CardContent } from '@/components/ui/Card'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Table } from '@/components/ui/Table'
import { SkeletonTable } from '@/components/ui/Skeleton'

interface RecentShipment {
  id: string
  tracking_number: string
  sender_name: string
  recipient_name: string
  status: string
  service_type: string
  created_at: string
}

export function RecentShipments() {
  const t = useTranslations('dashboard')
  const st = useTranslations('shipments')
  const router = useRouter()
  const params = useParams()
  const locale = params.locale as string
  const [shipments, setShipments] = useState<RecentShipment[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    get<RecentShipment[]>('/v1/dashboard/recent-shipments')
      .then(setShipments)
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const columns = [
    {
      key: 'tracking_number',
      header: st('trackingId') || 'Tracking ID',
      render: (item: RecentShipment) => (
        <span className="font-medium text-primary-600 dark:text-primary-400">{item.tracking_number}</span>
      ),
    },
    { key: 'sender_name', header: st('sender') || 'Sender' },
    { key: 'recipient_name', header: st('recipient') || 'Recipient' },
    {
      key: 'status',
      header: st('status') || 'Status',
      render: (item: RecentShipment) => <StatusBadge status={item.status as any} />,
    },
  ]

  return (
    <Card>
      <CardHeader className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">{t('recentShipments')}</h3>
        <button
          onClick={() => router.push(`/${locale}/shipments`)}
          className="text-sm text-primary-600 dark:text-primary-400 hover:underline"
        >
          {t('viewAll')}
        </button>
      </CardHeader>
      <CardContent className="p-0">
        {loading ? (
          <SkeletonTable rows={4} cols={4} />
        ) : (
          <Table
            columns={columns}
            data={shipments}
            onRowClick={(item) => router.push(`/${locale}/shipments/${item.id}`)}
          />
        )}
      </CardContent>
    </Card>
  )
}
