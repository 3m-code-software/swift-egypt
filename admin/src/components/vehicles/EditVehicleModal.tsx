'use client'

import { useState, useEffect } from 'react'
import { useTranslations } from 'next-intl'
import { Modal } from '@/components/ui/Modal'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Button } from '@/components/ui/Button'
import { get, put } from '@/lib/api'
import { useToast } from '@/components/ui/Toast'

interface Branch {
  id: string
  name: string
}

interface Vehicle {
  id: string
  plate_number: string
  model: string
  type: string
  max_weight: number | null
  max_volume: number | null
  branch_id: string | null
  is_available: boolean
}

interface EditVehicleModalProps {
  open: boolean
  onClose: () => void
  vehicle: Vehicle
  onSaved?: () => void
}

export function EditVehicleModal({ open, onClose, vehicle, onSaved }: EditVehicleModalProps) {
  const t = useTranslations('vehicles')
  const ct = useTranslations('common')
  const { addToast: showToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [branches, setBranches] = useState<Branch[]>([])
  const [plateNumber, setPlateNumber] = useState(vehicle.plate_number)
  const [model, setModel] = useState(vehicle.model)
  const [type, setType] = useState(vehicle.type)
  const [maxWeight, setMaxWeight] = useState(vehicle.max_weight?.toString() || '')
  const [maxVolume, setMaxVolume] = useState(vehicle.max_volume?.toString() || '')
  const [branchId, setBranchId] = useState(vehicle.branch_id || '')
  const [isAvailable, setIsAvailable] = useState(vehicle.is_available)

  useEffect(() => {
    if (open) {
      setPlateNumber(vehicle.plate_number)
      setModel(vehicle.model)
      setType(vehicle.type)
      setMaxWeight(vehicle.max_weight?.toString() || '')
      setMaxVolume(vehicle.max_volume?.toString() || '')
      setBranchId(vehicle.branch_id || '')
      setIsAvailable(vehicle.is_available)
      get<Branch[]>('/v1/branches/').then(setBranches).catch(() => {})
    }
  }, [open, vehicle])

  const handleSave = async () => {
    setLoading(true)
    try {
      await put(`/v1/vehicles/${vehicle.id}`, {
        plate_number: plateNumber,
        model,
        type,
        max_weight: maxWeight ? parseFloat(maxWeight) : null,
        max_volume: maxVolume ? parseFloat(maxVolume) : null,
        branch_id: branchId || null,
        is_available: isAvailable,
      })
      showToast({ message: 'Vehicle updated', type: 'success' })
      onSaved?.()
      onClose()
    } catch (err) {
      showToast({ message: err instanceof Error ? err.message : 'Failed to update vehicle', type: 'error' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title={`${t('title')} — ${vehicle.plate_number}`}>
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <Input label={t('plate')} id="plate_number" value={plateNumber} onChange={(e) => setPlateNumber(e.target.value)} />
          <Input label={t('model')} id="model" value={model} onChange={(e) => setModel(e.target.value)} />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Select
            label={t('type')}
            id="type"
            value={type}
            onChange={(e) => setType(e.target.value)}
            options={[
              { value: 'truck', label: 'Truck' },
              { value: 'van', label: 'Van' },
              { value: 'car', label: 'Car' },
              { value: 'motorcycle', label: 'Motorcycle' },
            ]}
          />
          <Select
            label="Branch"
            id="branch_id"
            value={branchId}
            onChange={(e) => setBranchId(e.target.value)}
            placeholder={ct('noBranch')}
            options={branches.map((b) => ({ value: b.id, label: b.name }))}
          />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Input label="Max Weight (kg)" id="max_weight" type="number" value={maxWeight} onChange={(e) => setMaxWeight(e.target.value)} />
          <Input label="Max Volume (m³)" id="max_volume" type="number" value={maxVolume} onChange={(e) => setMaxVolume(e.target.value)} />
        </div>
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={isAvailable}
            onChange={(e) => setIsAvailable(e.target.checked)}
            className="rounded border-gray-300 dark:border-gray-600"
          />
          Available
        </label>
        <div className="flex justify-end gap-3 pt-4">
          <Button variant="outline" onClick={onClose} disabled={loading}>{ct('cancel')}</Button>
          <Button onClick={handleSave} disabled={loading}>{loading ? ct('saving') : ct('save')}</Button>
        </div>
      </div>
    </Modal>
  )
}
