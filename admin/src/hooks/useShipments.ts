'use client'

import { useState, useEffect, useCallback } from 'react'
import { get } from '@/lib/api'

export interface Shipment {
  id: string
  trackingId: string
  customer: string
  origin: string
  destination: string
  status: ShipmentStatus
  serviceType: ServiceType
  weight: string
  estimatedDelivery: string
  createdAt: string
  assignedDriver?: string
  assignedVehicle?: string
}

export type ShipmentStatus =
  | 'draft'
  | 'pending'
  | 'confirmed'
  | 'in_transit'
  | 'out_for_delivery'
  | 'delivered'
  | 'cancelled'
  | 'returned'
  | 'delayed'
  | 'picked_up'

export type ServiceType = 'express' | 'standard' | 'same_day' | 'international' | 'freight'

interface ApiShipment {
  id: string
  tracking_number: string
  service_type: string
  status: string
  sender_name: string
  recipient_name: string
  pickup_address: string | null
  delivery_address: string | null
  weight: number | null
  estimated_price: number | null
  created_at: string
  items: unknown[]
  tracking_events?: unknown[]
}

interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  page_size: number
  total_pages: number
}

function mapShipment(s: ApiShipment): Shipment {
  const customer = [s.sender_name, s.recipient_name].filter(Boolean).join(' → ') || s.sender_name || '—'
  return {
    id: s.id,
    trackingId: s.tracking_number,
    customer,
    origin: s.pickup_address || '—',
    destination: s.delivery_address || '—',
    status: s.status as ShipmentStatus,
    serviceType: s.service_type as ServiceType,
    weight: s.weight ? `${s.weight} kg` : '—',
    estimatedDelivery: '—',
    createdAt: s.created_at,
  }
}

export function useShipments() {
  const [shipments, setShipments] = useState<Shipment[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [total, setTotal] = useState(0)

  const fetchShipments = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<PaginatedResponse<ApiShipment>>('/v1/shipments/')
      setShipments((data.items || []).map(mapShipment))
      setTotal(data.total || 0)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load shipments')
      setShipments([])
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchShipments() }, [fetchShipments])

  const getShipment = useCallback(
    (id: string) => shipments.find((s) => s.id === id) || null,
    [shipments]
  )

  return { shipments, isLoading, error, total, getShipment, refetch: fetchShipments }
}
