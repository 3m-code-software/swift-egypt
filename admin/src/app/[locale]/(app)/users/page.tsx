'use client'

import { useState, useEffect } from 'react'
import { useTranslations } from 'next-intl'
import { get, put } from '@/lib/api'
import { useToast } from '@/components/ui/Toast'
import { Card, CardContent, CardHeader } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Input } from '@/components/ui/Input'
import { Table } from '@/components/ui/Table'
import { SkeletonTable } from '@/components/ui/Skeleton'
import { useAuth } from '@/hooks/useAuth'
import { Shield, Search, RefreshCw } from 'lucide-react'

interface UserRow {
  id: string
  full_name: string
  email: string
  phone: string
  role: string
  is_active: boolean
  branch_id?: string | null
}

const roleColors: Record<string, 'danger' | 'warning' | 'info' | 'default'> = {
  admin: 'danger',
  operations: 'warning',
  branch_manager: 'info',
  customer: 'default',
  driver: 'default',
}

export default function UsersPage() {
  const t = useTranslations('users')
  const ct = useTranslations('common')
  const { addToast } = useToast()
  const { user: currentUser } = useAuth()
  const [users, setUsers] = useState<UserRow[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [error, setError] = useState('')

  useEffect(() => {
    loadUsers()
  }, [])

  const loadUsers = async () => {
    setLoading(true)
    setError('')
    try {
      const res = await get<{ items: UserRow[]; total: number }>('/v1/users/')
      setUsers(res.items || [])
    } catch (err: any) {
      setError(err.message || 'Failed to load users')
      addToast({ type: 'error', message: err.message || 'Failed to load users' })
    } finally {
      setLoading(false)
    }
  }

  const handleRoleChange = async (userId: string, newRole: string) => {
    try {
      await put(`/v1/users/${userId}/role`, { role: newRole })
      addToast({ type: 'success', message: 'Role updated' })
      loadUsers()
    } catch (err: any) {
      addToast({ type: 'error', message: err.message || 'Failed to update role' })
    }
  }

  const filtered = users.filter((u) =>
    u.full_name?.toLowerCase().includes(search.toLowerCase()) ||
    u.email?.toLowerCase().includes(search.toLowerCase())
  )

  const columns: { key: string; header: string; render?: (item: UserRow) => React.ReactNode }[] = [
    {
      key: 'full_name',
      header: t('name'),
      render: (item: UserRow) => (
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center">
            <span className="text-sm font-medium text-primary-600 dark:text-primary-400">
              {item.full_name?.charAt(0) || '?'}
            </span>
          </div>
          <div>
            <p className="font-medium text-sm">{item.full_name}</p>
            <p className="text-xs text-gray-500">{item.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'phone',
      header: ct('phone'),
    },
    {
      key: 'role',
      header: ct('role'),
      render: (item: UserRow) => (
        <Badge variant={roleColors[item.role] || 'default'}>
          {item.role}
        </Badge>
      ),
    },
    {
      key: 'is_active',
      header: ct('status'),
      render: (item: UserRow) => (
        <Badge variant={item.is_active ? 'success' : 'danger'}>
          {item.is_active ? ct('active') : ct('inactive')}
        </Badge>
      ),
    },
    {
      key: 'actions',
      header: ct('actions'),
      render: (item: UserRow) =>
        currentUser?.role === 'admin' && item.id !== currentUser.id ? (
          <select
            value={item.role}
            onChange={(e) => handleRoleChange(item.id, e.target.value)}
            className="text-xs px-2 py-1 rounded border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800"
          >
            <option value="admin">admin</option>
            <option value="operations">operations</option>
            <option value="branch_manager">branch_manager</option>
            <option value="customer">customer</option>
            <option value="driver">driver</option>
          </select>
        ) : (
          <span className="text-xs text-gray-400">—</span>
        ),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="relative flex-1 max-w-sm">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <Input
                placeholder={t('search')}
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-9"
              />
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <SkeletonTable rows={6} cols={5} />
          ) : error ? (
            <div className="flex flex-col items-center py-12 gap-3">
              <p className="text-red-500 text-sm">{error}</p>
              <Button variant="outline" size="sm" onClick={loadUsers}>
                <RefreshCw className="w-4 h-4 me-2" />
                Try again
              </Button>
            </div>
          ) : (
            <Table
              columns={columns as any}
              data={filtered as any}
            />
          )}
        </CardContent>
      </Card>
    </div>
  )
}