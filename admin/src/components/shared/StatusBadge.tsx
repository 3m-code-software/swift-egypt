'use client'

import { useTranslations } from 'next-intl'
import { cn } from '@/lib/utils'

type ShipmentStatus =
  | 'draft' | 'pending' | 'confirmed' | 'in_transit'
  | 'out_for_delivery' | 'picked_up'
  | 'delivered' | 'cancelled' | 'returned' | 'delayed'

const statusStyles: Record<ShipmentStatus, string> = {
  draft: 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300',
  pending: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
  confirmed: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  in_transit: 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400',
  out_for_delivery: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
  picked_up: 'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-400',
  delivered: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
  cancelled: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
  returned: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
  delayed: 'bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400',
}

export function StatusBadge({ status }: { status: ShipmentStatus }) {
  const t = useTranslations('shipmentStatus')
  return (
    <span
      className={cn(
        'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
        statusStyles[status]
      )}
    >
      {t(status)}
    </span>
  )
}
