'use client'

import { useState, useEffect, useCallback } from 'react'
import { useParams } from 'next/navigation'
import { get } from '@/lib/api'
import { ShipmentDetails } from '@/components/shipments/ShipmentDetails'
import { SkeletonCard } from '@/components/ui/Skeleton'
import { Button } from '@/components/ui/Button'
import { RefreshCw } from 'lucide-react'

interface ShipmentItem {
  id: string
  description: string
  quantity: number
  weight: number | null
}

interface TrackingEvent {
  id: string
  event_type: string
  new_status: string | null
  location: string | null
  description: string | null
  created_at: string
}

export interface ApiShipmentDetail {
  id: string
  tracking_number: string
  service_type: string
  status: string
  sender_name: string
  sender_phone: string
  recipient_name: string
  recipient_phone: string
  pickup_address: string | null
  delivery_address: string | null
  weight: number | null
  volume_weight: number | null
  estimated_price: number | null
  final_price: number | null
  notes: string | null
  customer_id: string
  driver_id: string | null
  vehicle_id: string | null
  branch_id: string | null
  items: ShipmentItem[]
  tracking_events: TrackingEvent[] | null
  created_at: string
  updated_at: string
}

export default function ShipmentDetailContent() {
  const params = useParams()
  const [shipment, setShipment] = useState<ApiShipmentDetail | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchShipment = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<ApiShipmentDetail>('/v1/shipments/' + params.id)
      setShipment(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load shipment')
    } finally {
      setIsLoading(false)
    }
  }, [params.id])

  useEffect(() => { if (params.id) fetchShipment() }, [params.id, fetchShipment])

  if (isLoading) {
    return (
      <div className="space-y-6">
        <SkeletonCard />
        <SkeletonCard />
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <p className="text-red-500 mb-4">{error}</p>
        <Button variant="outline" onClick={fetchShipment}>
          <RefreshCw className="w-4 h-4 mr-2" />Retry
        </Button>
      </div>
    )
  }

  if (!shipment) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <p className="text-gray-500 dark:text-gray-400 text-lg">Shipment not found</p>
      </div>
    )
  }

  return <ShipmentDetails shipment={shipment} />
}