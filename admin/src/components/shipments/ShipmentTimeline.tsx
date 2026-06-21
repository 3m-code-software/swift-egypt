'use client'

import { useTranslations } from 'next-intl'
import { cn } from '@/lib/utils'
import { Check, Circle } from 'lucide-react'

type ShipmentStatus =
  | 'draft' | 'pending' | 'confirmed' | 'in_transit'
  | 'out_for_delivery' | 'delivered' | 'cancelled' | 'returned' | 'delayed' | 'picked_up'

interface TrackingEvent {
  id: string
  event_type: string
  new_status: string | null
  location: string | null
  description: string | null
  created_at: string
}

interface ShipmentTimelineProps {
  events: TrackingEvent[]
  status: ShipmentStatus
}

const allSteps: { status: ShipmentStatus; label: string }[] = [
  { status: 'draft', label: 'Draft' },
  { status: 'pending', label: 'Pending' },
  { status: 'confirmed', label: 'Confirmed' },
  { status: 'picked_up', label: 'Picked Up' },
  { status: 'in_transit', label: 'In Transit' },
  { status: 'out_for_delivery', label: 'Out for Delivery' },
  { status: 'delivered', label: 'Delivered' },
]

function getStepIndex(status: ShipmentStatus): number {
  const idx = allSteps.findIndex((s) => s.status === status)
  if (['cancelled', 'returned', 'delayed'].includes(status)) {
    const baseIdx = allSteps.findIndex((s) => s.status === 'in_transit')
    return baseIdx >= 0 ? baseIdx : idx
  }
  return idx
}

export function ShipmentTimeline({ events, status }: ShipmentTimelineProps) {
  const t = useTranslations('shipmentStatus')
  const currentIdx = getStepIndex(status)
  const isTerminal = ['cancelled', 'returned', 'delivered'].includes(status)

  if (events.length > 0) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
        <h3 className="font-semibold mb-6">{t('timeline') || 'Timeline'}</h3>
        <div className="relative">
          {events.map((event, idx) => {
            const isLast = idx === events.length - 1
            return (
              <div key={event.id} className="flex items-start gap-4 pb-6 last:pb-0">
                <div className="flex flex-col items-center">
                  <div className={cn(
                    'w-8 h-8 rounded-full flex items-center justify-center border-2 transition-colors',
                    isLast
                      ? 'bg-primary-600 border-primary-600 text-white'
                      : 'bg-primary-600/20 border-primary-600 text-primary-600'
                  )}>
                    {isLast ? <Check className="w-4 h-4" /> : <Circle className="w-3 h-3" />}
                  </div>
                  {!isLast && <div className="w-0.5 h-8 bg-primary-600/30" />}
                </div>
                <div className="pt-1.5">
                  <p className="text-sm font-medium text-gray-700 dark:text-gray-300">
                    {event.new_status ? event.new_status.replace(/_/g, ' ') : event.event_type.replace(/_/g, ' ')}
                  </p>
                  {event.description && (
                    <p className="text-xs text-gray-500 mt-0.5">{event.description}</p>
                  )}
                  {event.location && (
                    <p className="text-xs text-gray-400 mt-0.5">{event.location}</p>
                  )}
                  <p className="text-xs text-gray-400 mt-0.5">{new Date(event.created_at).toLocaleString()}</p>
                </div>
              </div>
            )
          })}
        </div>
      </div>
    )
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
      <h3 className="font-semibold mb-6">{t('timeline') || 'Timeline'}</h3>
      <div className="relative">
        {allSteps.map((step, idx) => {
          const isCompleted = idx <= currentIdx && !isTerminal
          const isCurrent = idx === currentIdx && !isTerminal
          return (
            <div key={step.status} className="flex items-start gap-4 pb-6 last:pb-0">
              <div className="flex flex-col items-center">
                <div
                  className={cn(
                    'w-8 h-8 rounded-full flex items-center justify-center border-2 transition-colors',
                    isCompleted
                      ? 'bg-primary-600 border-primary-600 text-white'
                      : isCurrent
                        ? 'border-primary-600 text-primary-600'
                        : 'border-gray-300 dark:border-gray-600 text-gray-400'
                  )}
                >
                  {isCompleted ? <Check className="w-4 h-4" /> : <Circle className="w-3 h-3" />}
                </div>
                {idx < allSteps.length - 1 && (
                  <div
                    className={cn(
                      'w-0.5 h-8',
                      idx < currentIdx ? 'bg-primary-600' : 'bg-gray-200 dark:bg-gray-700'
                    )}
                  />
                )}
              </div>
              <div className="pt-1.5">
                <p
                  className={cn(
                    'text-sm font-medium',
                    isCurrent ? 'text-primary-600 dark:text-primary-400' : 'text-gray-700 dark:text-gray-300'
                  )}
                >
                  {t(step.status)}
                </p>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
