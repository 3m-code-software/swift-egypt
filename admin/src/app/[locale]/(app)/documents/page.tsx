'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { FileText, Trash2, ExternalLink, RefreshCw, Upload } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Modal } from '@/components/ui/Modal'
import { get, del } from '@/lib/api'
import { SkeletonTable } from '@/components/ui/Skeleton'
import { useToast } from '@/components/ui/Toast'

interface Document {
  id: string
  shipment_id: string
  document_type: string
  file_name: string
  file_url: string
  file_size: number | null
  uploaded_by: string | null
  created_at: string
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api'

const typeColors: Record<string, 'info' | 'warning' | 'success' | 'default'> = {
  invoice: 'info',
  waybill: 'warning',
  proof_of_delivery: 'success',
  id_card: 'default',
  other: 'default',
}

export default function DocumentsPage() {
  const t = useTranslations('documents')
  const { addToast } = useToast()
  const [documents, setDocuments] = useState<Document[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedShipment, setSelectedShipment] = useState('')
  const [uploadOpen, setUploadOpen] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [uploadForm, setUploadForm] = useState({ shipment_id: '', document_type: 'other' })
  const [uploadFile, setUploadFile] = useState<File | null>(null)

  const fetchDocuments = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const shipmentId = selectedShipment.trim()
      const endpoint = shipmentId
        ? `/v1/documents/shipment/${shipmentId}`
        : '/v1/documents/'
      const data = await get<Document[]>(endpoint)
      setDocuments(data || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load documents')
      setDocuments([])
    } finally {
      setIsLoading(false)
    }
  }, [selectedShipment])

  useEffect(() => { fetchDocuments() }, [fetchDocuments])

  const handleDelete = async (id: string) => {
    try {
      await del(`/v1/documents/${id}`)
      addToast({ message: 'Document deleted', type: 'success' })
      fetchDocuments()
    } catch (err) {
      addToast({ message: err instanceof Error ? err.message : 'Failed to delete document', type: 'error' })
    }
  }

  const handleUpload = async () => {
    if (!uploadForm.shipment_id || !uploadFile) {
      addToast({ message: 'Shipment ID and file are required', type: 'error' })
      return
    }
    setUploading(true)
    try {
      const token = localStorage.getItem('auth_token')
      const formData = new FormData()
      formData.append('shipment_id', uploadForm.shipment_id)
      formData.append('document_type', uploadForm.document_type)
      formData.append('file', uploadFile)

      const res = await fetch(`${API_BASE}/v1/documents/upload`, {
        method: 'POST',
        headers: token ? { Authorization: `Bearer ${token}` } : {},
        body: formData,
      })
      if (!res.ok) throw new Error((await res.json()).detail || 'Upload failed')
      addToast({ message: 'Document uploaded', type: 'success' })
      setUploadOpen(false)
      setUploadForm({ shipment_id: '', document_type: 'other' })
      setUploadFile(null)
      fetchDocuments()
    } catch (err) {
      addToast({ message: err instanceof Error ? err.message : 'Upload failed', type: 'error' })
    } finally {
      setUploading(false)
    }
  }

  const formatSize = (bytes: number | null) => {
    if (!bytes) return '—'
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <div className="flex items-center gap-2">
          <input
            type="text"
            placeholder="Filter by Shipment ID"
            value={selectedShipment}
            onChange={(e) => setSelectedShipment(e.target.value)}
            className="w-64 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
          <Button variant="ghost" size="sm" onClick={fetchDocuments}>
            <RefreshCw className="w-4 h-4" />
          </Button>
          <Button size="sm" onClick={() => setUploadOpen(true)}>
            <Upload className="w-4 h-4 me-1" /> Upload
          </Button>
        </div>
      </div>

      {error && (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
          {error}
          <button onClick={fetchDocuments} className="ml-2 underline">Retry</button>
        </div>
      )}

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">File Name</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Shipment</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Size</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Uploaded</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {isLoading ? (
                  <tr><td colSpan={6} className="px-6 py-12"><SkeletonTable rows={5} cols={6} /></td></tr>
                ) : documents.length === 0 ? (
                  <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-500">No documents found</td></tr>
                ) : (
                  documents.map((doc) => (
                    <tr key={doc.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="px-6 py-4">
                        <span className="flex items-center gap-2">
                          <FileText className="w-4 h-4 text-gray-400" />
                          {doc.file_name}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <Badge variant={typeColors[doc.document_type] || 'default'}>{doc.document_type}</Badge>
                      </td>
                      <td className="px-6 py-4 font-mono text-xs">{doc.shipment_id.slice(0, 8)}...</td>
                      <td className="px-6 py-4 text-gray-500">{formatSize(doc.file_size)}</td>
                      <td className="px-6 py-4 text-gray-500">{new Date(doc.created_at).toLocaleDateString()}</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          <a
                            href={doc.file_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
                          >
                            <ExternalLink className="w-4 h-4" />
                          </a>
                          <button
                            onClick={() => handleDelete(doc.id)}
                            className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-500 hover:text-red-600"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <Modal open={uploadOpen} onClose={() => setUploadOpen(false)} title="Upload Document">
        <div className="space-y-4">
          <Input
            label="Shipment ID"
            id="shipment_id"
            placeholder="Enter shipment UUID"
            value={uploadForm.shipment_id}
            onChange={(e) => setUploadForm((f) => ({ ...f, shipment_id: e.target.value }))}
          />
          <Select
            label="Document Type"
            id="document_type"
            value={uploadForm.document_type}
            onChange={(e) => setUploadForm((f) => ({ ...f, document_type: e.target.value }))}
            options={[
              { value: 'invoice', label: 'Invoice' },
              { value: 'waybill', label: 'Waybill' },
              { value: 'proof_of_delivery', label: 'Proof of Delivery' },
              { value: 'id_card', label: 'ID Card' },
              { value: 'other', label: 'Other' },
            ]}
          />
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">File</label>
            <input
              type="file"
              onChange={(e) => setUploadFile(e.target.files?.[0] || null)}
              className="w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-medium file:bg-primary-50 file:text-primary-700 dark:file:bg-primary-900/20 dark:file:text-primary-400 hover:file:bg-primary-100"
            />
          </div>
          <div className="flex justify-end gap-3 pt-4">
            <Button variant="outline" onClick={() => setUploadOpen(false)} disabled={uploading}>Cancel</Button>
            <Button onClick={handleUpload} disabled={uploading || !uploadFile}>
              {uploading ? 'Uploading...' : 'Upload'}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
