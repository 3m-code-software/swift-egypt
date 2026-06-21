'use client'

import { useState } from 'react'
import { useTranslations } from 'next-intl'
import { Modal } from '@/components/ui/Modal'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Button } from '@/components/ui/Button'
import { post } from '@/lib/api'
import { useToast } from '@/components/ui/Toast'

interface CreateShipmentModalProps {
  open: boolean
  onClose: () => void
  onCreated?: () => void
}

export function CreateShipmentModal({ open, onClose, onCreated }: CreateShipmentModalProps) {
  const t = useTranslations('shipments')
  const ct = useTranslations('common')
  const { addToast: showToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [form, setForm] = useState({
    sender_name: '',
    sender_phone: '',
    recipient_name: '',
    recipient_phone: '',
    pickup_address: '',
    delivery_address: '',
    service_type: 'standard',
    weight: '',
    notes: '',
  })

  const handleChange = (field: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setForm((prev) => ({ ...prev, [field]: e.target.value }))
  }

  const handleSubmit = async () => {
    if (!form.sender_name || !form.recipient_name) {
      showToast({ message: 'Sender and recipient names are required', type: 'error' })
      return
    }
    setLoading(true)
    try {
      await post('/v1/shipments/', {
        ...form,
        weight: form.weight ? parseFloat(form.weight) : null,
      })
      showToast({ message: 'Shipment created successfully', type: 'success' })
      setForm({ sender_name: '', sender_phone: '', recipient_name: '', recipient_phone: '', pickup_address: '', delivery_address: '', service_type: 'standard', weight: '', notes: '' })
      onCreated?.()
      onClose()
    } catch (err) {
      showToast({ message: err instanceof Error ? err.message : 'Failed to create shipment', type: 'error' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title={t('create')}>
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <Input label={t('senderName') || 'Sender Name'} id="sender_name" placeholder="Sender name" value={form.sender_name} onChange={handleChange('sender_name')} />
          <Input label={t('senderPhone') || 'Sender Phone'} id="sender_phone" placeholder="Sender phone" value={form.sender_phone} onChange={handleChange('sender_phone')} />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Input label={t('recipientName') || 'Recipient Name'} id="recipient_name" placeholder="Recipient name" value={form.recipient_name} onChange={handleChange('recipient_name')} />
          <Input label={t('recipientPhone') || 'Recipient Phone'} id="recipient_phone" placeholder="Recipient phone" value={form.recipient_phone} onChange={handleChange('recipient_phone')} />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Input label={t('origin')} id="pickup_address" placeholder="Pickup address" value={form.pickup_address} onChange={handleChange('pickup_address')} />
          <Input label={t('destination')} id="delivery_address" placeholder="Delivery address" value={form.delivery_address} onChange={handleChange('delivery_address')} />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Select
            label={t('serviceType')}
            id="service_type"
            value={form.service_type}
            onChange={(e) => setForm((prev) => ({ ...prev, service_type: e.target.value }))}
            options={[
              { value: 'standard', label: 'Standard' },
              { value: 'express', label: 'Express' },
              { value: 'same_day', label: 'Same Day' },
              { value: 'freight', label: 'Freight' },
            ]}
          />
          <Input label={t('weight')} id="weight" placeholder="Weight (kg)" type="number" value={form.weight} onChange={handleChange('weight')} />
        </div>
        <Input label={t('notes') || 'Notes'} id="notes" placeholder="Optional notes" value={form.notes} onChange={handleChange('notes')} />
        <div className="flex justify-end gap-3 pt-4">
          <Button variant="outline" onClick={onClose} disabled={loading}>{ct('cancel')}</Button>
          <Button onClick={handleSubmit} disabled={loading}>{loading ? 'Creating...' : ct('create')}</Button>
        </div>
      </div>
    </Modal>
  )
}
