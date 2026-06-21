'use client'

import { useTranslations } from 'next-intl'
import { Card, CardContent, CardHeader } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { MapPin, Calendar, Weight, User, Truck, Phone, Package } from 'lucide-react'
import type { ShipmentStatus } from '@/hooks/useShipments'
import { ShipmentTimeline } from './ShipmentTimeline'
import type { ApiShipmentDetail } from '@/app/[locale]/(app)/shipments/[id]/ShipmentDetailContent'

interface ShipmentDetailsProps {
  shipment: ApiShipmentDetail
}

export function ShipmentDetails({ shipment }: ShipmentDetailsProps) {
  const t = useTranslations('shipments')

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{t('details')}</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1 font-mono">
            {shipment.tracking_number}
          </p>
        </div>
        <StatusBadge status={shipment.status as ShipmentStatus} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <h3 className="font-semibold">{t('details')}</h3>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div className="flex items-start gap-3">
                    <User className="w-4 h-4 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{t('sender')}</p>
                      <p className="text-sm font-medium">{shipment.sender_name}</p>
                      <p className="text-xs text-gray-400">{shipment.sender_phone}</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <User className="w-4 h-4 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{t('recipient')}</p>
                      <p className="text-sm font-medium">{shipment.recipient_name}</p>
                      <p className="text-xs text-gray-400">{shipment.recipient_phone}</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <MapPin className="w-4 h-4 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{t('origin')}</p>
                      <p className="text-sm font-medium">{shipment.pickup_address || '—'}</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <MapPin className="w-4 h-4 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{t('destination')}</p>
                      <p className="text-sm font-medium">{shipment.delivery_address || '—'}</p>
                    </div>
                  </div>
                </div>
                <div className="space-y-4">
                  <div className="flex items-start gap-3">
                    <Weight className="w-4 h-4 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{t('weight')}</p>
                      <p className="text-sm font-medium">{shipment.weight ? `${shipment.weight} kg` : '—'}</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <Package className="w-4 h-4 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{t('serviceType')}</p>
                      <p className="text-sm font-medium capitalize">{shipment.service_type.replace('_', ' ')}</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <Calendar className="w-4 h-4 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{t('createdAt')}</p>
                      <p className="text-sm font-medium">{new Date(shipment.created_at).toLocaleDateString()}</p>
                    </div>
                  </div>
                  {shipment.estimated_price != null && (
                    <div className="flex items-start gap-3">
                      <div className="w-4 h-4 text-gray-400 mt-0.5 flex items-center justify-center font-bold text-xs">$</div>
                      <div>
                        <p className="text-xs text-gray-500 dark:text-gray-400">{t('estimatedPrice')}</p>
                        <p className="text-sm font-medium">EGP {shipment.estimated_price.toLocaleString()}</p>
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {shipment.items.length > 0 && (
                <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 className="text-sm font-semibold mb-3">{t('items')}</h4>
                  <div className="space-y-2">
                    {shipment.items.map((item) => (
                      <div key={item.id} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg text-sm">
                        <span className="font-medium">{item.description}</span>
                        <span className="text-gray-500">x{item.quantity}{item.weight ? ` (${item.weight} kg)` : ''}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {shipment.notes && (
                <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 className="text-sm font-semibold mb-2">{t('notes')}</h4>
                  <p className="text-sm text-gray-600 dark:text-gray-400">{shipment.notes}</p>
                </div>
              )}
            </CardContent>
          </Card>

          <ShipmentTimeline events={shipment.tracking_events || []} status={shipment.status as ShipmentStatus} />
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <h3 className="font-semibold">Assignment</h3>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                <User className="w-4 h-4 text-gray-400" />
                <div>
                  <p className="text-xs text-gray-500 dark:text-gray-400">{t('assignedDriver')}</p>
                  <p className="text-sm font-medium">{shipment.driver_id ? 'Driver assigned' : 'Unassigned'}</p>
                </div>
              </div>
              <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                <Truck className="w-4 h-4 text-gray-400" />
                <div>
                  <p className="text-xs text-gray-500 dark:text-gray-400">{t('assignedVehicle')}</p>
                  <p className="text-sm font-medium">{shipment.vehicle_id ? 'Vehicle assigned' : 'Unassigned'}</p>
                </div>
              </div>
              <Button variant="outline" className="w-full">{t('assignDriver')}</Button>
              <Button variant="outline" className="w-full">{t('assignVehicle')}</Button>
            </CardContent>
          </Card>

          {shipment.final_price != null && (
            <Card>
              <CardHeader>
                <h3 className="font-semibold">{t('pricing')}</h3>
              </CardHeader>
              <CardContent>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500">{t('finalPrice')}</span>
                  <span className="text-lg font-bold text-primary-600">EGP {shipment.final_price.toLocaleString()}</span>
                </div>
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <h3 className="font-semibold">{t('documents')}</h3>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-gray-500 dark:text-gray-400">No documents attached</p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
