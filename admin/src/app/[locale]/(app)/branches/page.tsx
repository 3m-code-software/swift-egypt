'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { Card, CardContent } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { Building2, Phone, MapPin, RefreshCw } from 'lucide-react'
import { get } from '@/lib/api'
import { SkeletonCard } from '@/components/ui/Skeleton'

interface Branch {
  id: string
  name: string
  name_ar: string | null
  address: string
  phone: string
  latitude: number | null
  longitude: number | null
  is_active: boolean
  created_at: string | null
}

export default function BranchesPage() {
  const t = useTranslations('branches')
  const [branches, setBranches] = useState<Branch[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchBranches = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<Branch[]>('/v1/branches/')
      setBranches(data || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load branches')
      setBranches([])
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchBranches() }, [fetchBranches])

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <Button variant="ghost" size="sm" onClick={fetchBranches}>
          <RefreshCw className="w-4 h-4" />
        </Button>
      </div>

      {error && (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
          {error}
          <button onClick={fetchBranches} className="ml-2 underline">Retry</button>
        </div>
      )}

      {isLoading ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[1,2,3,4].map(i => <SkeletonCard key={i} />)}
        </div>
      ) : branches.length === 0 ? (
        <div className="text-center py-12 text-gray-500">No branches found</div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {branches.map((b) => (
            <Card key={b.id}>
              <CardContent className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-primary-50 dark:bg-primary-900/20 rounded-lg">
                      <Building2 className="w-5 h-5 text-primary-600 dark:text-primary-400" />
                    </div>
                    <div>
                      <h3 className="font-semibold">{b.name}</h3>
                    </div>
                  </div>
                  <Badge variant={b.is_active ? 'success' : 'default'}>
                    {b.is_active ? t('active') : t('inactive')}
                  </Badge>
                </div>

                <div className="space-y-2 text-sm">
                  <div className="flex items-center gap-2 text-gray-500 dark:text-gray-400">
                    <MapPin className="w-3.5 h-3.5" />
                    <span>{b.address}</span>
                  </div>
                  <div className="flex items-center gap-2 text-gray-500 dark:text-gray-400">
                    <Phone className="w-3.5 h-3.5" />
                    <span>{b.phone}</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
