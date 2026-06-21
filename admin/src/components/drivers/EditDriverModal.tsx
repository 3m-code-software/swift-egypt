'use client'

import { useState, useEffect } from 'react'
import { useTranslations } from 'next-intl'
import { Modal } from '@/components/ui/Modal'
import { Select } from '@/components/ui/Select'
import { Button } from '@/components/ui/Button'
import { get, put } from '@/lib/api'
import { useToast } from '@/components/ui/Toast'

interface Vehicle {
  id: string
  plate_number: string
  model: string
}

interface Branch {
  id: string
  name: string
}

interface Driver {
  id: string
  user_id: string
  branch_id: string | null
  vehicle_id: string | null
  is_available: boolean
  user: { id: string; full_name: string; email: string; phone: string } | null
}

interface EditDriverModalProps {
  open: boolean
  onClose: () => void
  driver: Driver
  onSaved?: () => void
}

export function EditDriverModal({ open, onClose, driver, onSaved }: EditDriverModalProps) {
  const t = useTranslations('drivers')
  const ct = useTranslations('common')
  const { addToast: showToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [branches, setBranches] = useState<Branch[]>([])
  const [vehicleId, setVehicleId] = useState(driver.vehicle_id || '')
  const [branchId, setBranchId] = useState(driver.branch_id || '')
  const [isAvailable, setIsAvailable] = useState(driver.is_available)

  useEffect(() => {
    if (open) {
      setVehicleId(driver.vehicle_id || '')
      setBranchId(driver.branch_id || '')
      setIsAvailable(driver.is_available)
      get<Vehicle[]>('/v1/vehicles/available').then(setVehicles).catch(() => {})
      get<Branch[]>('/v1/branches/').then(setBranches).catch(() => {})
    }
  }, [open, driver])

  const handleSave = async () => {
    setLoading(true)
    try {
      await put(`/v1/drivers/${driver.id}`, {
        branch_id: branchId || null,
        vehicle_id: vehicleId || null,
        is_available: isAvailable,
      })
      showToast({ message: 'Driver updated', type: 'success' })
      onSaved?.()
      onClose()
    } catch (err) {
      showToast({ message: err instanceof Error ? err.message : 'Failed to update driver', type: 'error' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title={`${t('title')} — ${driver.user?.full_name || ''}`}>
      <div className="space-y-4">
        <Select
          label="Assign Vehicle"
          id="vehicle_id"
          value={vehicleId}
          onChange={(e) => setVehicleId(e.target.value)}
          placeholder="No vehicle"
          options={vehicles.map((v) => ({ value: v.id, label: `${v.plate_number} — ${v.model}` }))}
        />
        <Select
          label="Branch"
          id="branch_id"
          value={branchId}
          onChange={(e) => setBranchId(e.target.value)}
          placeholder={ct('noBranch')}
          options={branches.map((b) => ({ value: b.id, label: b.name }))}
        />
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={isAvailable}
            onChange={(e) => setIsAvailable(e.target.checked)}
            className="rounded border-gray-300 dark:border-gray-600"
          />
          Available for trips
        </label>
        <div className="flex justify-end gap-3 pt-4">
          <Button variant="outline" onClick={onClose} disabled={loading}>{ct('cancel')}</Button>
          <Button onClick={handleSave} disabled={loading}>{loading ? ct('saving') : ct('save')}</Button>
        </div>
      </div>
    </Modal>
  )
}
