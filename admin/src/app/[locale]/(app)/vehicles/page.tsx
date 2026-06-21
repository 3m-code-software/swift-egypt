'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { Card, CardContent } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { Car, Weight, RefreshCw, Pencil } from 'lucide-react'
import { get } from '@/lib/api'
import { SkeletonCard } from '@/components/ui/Skeleton'
import { EditVehicleModal } from '@/components/vehicles/EditVehicleModal'

interface Vehicle {
  id: string
  plate_number: string
  model: string
  type: string
  max_weight: number | null
  max_volume: number | null
  branch_id: string | null
  is_available: boolean
  created_at: string | null
}

const statusVariant: Record<string, 'success' | 'info' | 'warning'> = {
  available: 'success',
  in_use: 'info',
  maintenance: 'warning',
}

export default function VehiclesPage() {
  const t = useTranslations('vehicles')
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [editVehicle, setEditVehicle] = useState<Vehicle | null>(null)

  const fetchVehicles = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<Vehicle[]>('/v1/vehicles/')
      setVehicles(data || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load vehicles')
      setVehicles([])
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchVehicles() }, [fetchVehicles])

  const statusLabel = (v: Vehicle) =>
    v.is_available ? 'available' : 'in_use'

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <Button variant="ghost" size="sm" onClick={fetchVehicles}>
          <RefreshCw className="w-4 h-4" />
        </Button>
      </div>

      {error && (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
          {error}
          <button onClick={fetchVehicles} className="ml-2 underline">Retry</button>
        </div>
      )}

      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {[1,2,3,4,5,6].map(i => <SkeletonCard key={i} />)}
        </div>
      ) : vehicles.length === 0 ? (
        <div className="text-center py-12 text-gray-500">No vehicles found</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {vehicles.map((v) => (
            <Card key={v.id}>
              <CardContent className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-indigo-50 dark:bg-indigo-900/20 rounded-lg">
                      <Car className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                    </div>
                    <div>
                      <p className="font-semibold">{v.plate_number}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{v.model}</p>
                    </div>
                  </div>
                  <Badge variant={statusVariant[statusLabel(v)] || 'default'}>{t(statusLabel(v))}</Badge>
                </div>
                  <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400">
                    <span className="flex items-center gap-1"><Weight className="w-3.5 h-3.5" />{v.max_weight ? `${v.max_weight} kg` : '—'}</span>
                    <span>{v.type}</span>
                  </div>
                  <div className="mt-3 flex justify-end">
                    <button
                      onClick={() => setEditVehicle(v)}
                      className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
                    >
                      <Pencil className="w-4 h-4" />
                    </button>
                  </div>
                </CardContent>
              </Card>
          ))}
        </div>
      )}
      {editVehicle && (
        <EditVehicleModal
          open={!!editVehicle}
          onClose={() => setEditVehicle(null)}
          vehicle={editVehicle}
          onSaved={fetchVehicles}
        />
      )}
    </div>
  )
}
