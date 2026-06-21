'use client'

import { useState, useRef } from 'react'
import { useTranslations } from 'next-intl'
import { Upload, FileSpreadsheet, CheckCircle, AlertCircle } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api'

export default function UploadSheetPage() {
  const t = useTranslations()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [file, setFile] = useState<File | null>(null)
  const [uploading, setUploading] = useState(false)
  const [result, setResult] = useState<{ success: boolean; message: string; batch_number?: string } | null>(null)

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selected = e.target.files?.[0]
    if (selected && selected.name.endsWith('.xlsx')) {
      setFile(selected)
      setResult(null)
    }
  }

  const handleUpload = async () => {
    if (!file) return
    setUploading(true)
    setResult(null)

    const token = localStorage.getItem('auth_token')
    const formData = new FormData()
    formData.append('file', file)

    try {
      const res = await fetch(`${API_BASE}/v1/batches/upload`, {
        method: 'POST',
        headers: token ? { Authorization: `Bearer ${token}` } : {},
        body: formData,
      })
      const data = await res.json()
      if (res.ok) {
        setResult({ success: true, message: 'Batch uploaded successfully!', batch_number: data.batch_number })
        setFile(null)
        if (fileInputRef.current) fileInputRef.current.value = ''
      } else {
        setResult({ success: false, message: data.detail || 'Upload failed' })
      }
    } catch (err) {
      setResult({ success: false, message: err instanceof Error ? err.message : 'Upload failed' })
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold">{t('sellerNav.uploadSheet')}</h1>

      <Card>
        <CardContent className="p-6">
          <div className="text-center mb-6">
            <FileSpreadsheet className="w-16 h-16 mx-auto text-green-500 mb-4" />
            <h2 className="text-lg font-semibold mb-2">{t('common.import')} Excel Sheet</h2>
            <p className="text-sm text-gray-500">
              Upload your orders Excel file. Required columns: Customer Name, Phone, Address, Product Name, Quantity, Price, Shipping Cost
            </p>
          </div>

          <div
            className="border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-xl p-8 text-center cursor-pointer hover:border-primary-500 transition-colors"
            onClick={() => fileInputRef.current?.click()}
          >
            <input
              ref={fileInputRef}
              type="file"
              accept=".xlsx"
              className="hidden"
              onChange={handleFileChange}
            />
            <Upload className="w-10 h-10 mx-auto text-gray-400 mb-3" />
            <p className="text-sm font-medium">{file ? file.name : 'Click to select .xlsx file'}</p>
            <p className="text-xs text-gray-500 mt-1">Maximum 10MB</p>
          </div>

          {file && (
            <div className="mt-4 flex items-center justify-between p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <div className="flex items-center gap-2">
                <FileSpreadsheet className="w-5 h-5 text-blue-500" />
                <span className="text-sm font-medium">{file.name}</span>
                <span className="text-xs text-gray-500">({(file.size / 1024).toFixed(1)} KB)</span>
              </div>
              <Button onClick={handleUpload} disabled={uploading}>
                {uploading ? t('common.saving') : t('common.import')}
              </Button>
            </div>
          )}

          {result && (
            <div className={`mt-4 p-4 rounded-lg flex items-start gap-3 ${result.success ? 'bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400' : 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400'}`}>
              {result.success ? <CheckCircle className="w-5 h-5 mt-0.5 shrink-0" /> : <AlertCircle className="w-5 h-5 mt-0.5 shrink-0" />}
              <div>
                <p className="font-medium">{result.success ? 'Success!' : 'Error'}</p>
                <p className="text-sm">{result.message}</p>
                {result.batch_number && <p className="text-sm font-mono mt-1">Batch: {result.batch_number}</p>}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-6">
          <h3 className="font-semibold mb-3">Excel File Format</h3>
          <p className="text-sm text-gray-500 mb-3">Your Excel file should have these columns (in order):</p>
          <div className="overflow-x-auto">
            <table className="w-full text-sm border border-gray-200 dark:border-gray-700 rounded-lg">
              <thead>
                <tr className="bg-gray-50 dark:bg-gray-800">
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">A</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">B</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">C</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">D</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">E</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">F</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">G</th>
                </tr>
              </thead>
              <tbody>
                <tr className="border-t border-gray-200 dark:border-gray-700">
                  <td className="px-3 py-2 font-medium">Customer Name</td>
                  <td className="px-3 py-2">Phone</td>
                  <td className="px-3 py-2">Address</td>
                  <td className="px-3 py-2">Product</td>
                  <td className="px-3 py-2">Qty</td>
                  <td className="px-3 py-2">Price</td>
                  <td className="px-3 py-2">Shipping</td>
                </tr>
              </tbody>
            </table>
          </div>
          <p className="text-xs text-gray-500 mt-3">Additional columns: Phone 2 (H), Province (I), City (J), Notes (K) — optional</p>
        </CardContent>
      </Card>
    </div>
  )
}
