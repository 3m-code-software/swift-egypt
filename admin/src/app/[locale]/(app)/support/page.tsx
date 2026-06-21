'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { Card, CardContent } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Plus, MessageSquare, RefreshCw } from 'lucide-react'
import { get } from '@/lib/api'
import { SkeletonTable } from '@/components/ui/Skeleton'

interface Ticket {
  id: string
  customer_id: string | null
  shipment_id: string | null
  subject: string
  message: string
  status: string
  priority?: string
  assigned_to: string | null
  created_at: string
  resolved_at: string | null
}

const statusVariant: Record<string, 'info' | 'warning' | 'success' | 'default'> = {
  open: 'info',
  in_progress: 'warning',
  resolved: 'success',
  closed: 'default',
}

const priorityVariant: Record<string, 'danger' | 'warning' | 'info'> = {
  high: 'danger',
  medium: 'warning',
  low: 'info',
}

export default function SupportPage() {
  const t = useTranslations('support')
  const [tickets, setTickets] = useState<Ticket[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchTickets = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await get<{ items: Ticket[]; total: number }>('/v1/support/tickets')
      setTickets(data.items || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load tickets')
      setTickets([])
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchTickets() }, [fetchTickets])

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="sm" onClick={fetchTickets}>
            <RefreshCw className="w-4 h-4" />
          </Button>
          <Button><Plus className="w-4 h-4 mr-2" />{t('newTicket')}</Button>
        </div>
      </div>

      {error && (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-600 dark:text-red-400 text-sm">
          {error}
          <button onClick={fetchTickets} className="ml-2 underline">Retry</button>
        </div>
      )}

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('subject')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('status')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('createdAt')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {isLoading ? (
                  <tr><td colSpan={5} className="px-6 py-12"><SkeletonTable rows={5} cols={5} /></td></tr>
                ) : tickets.length === 0 ? (
                  <tr><td colSpan={5} className="px-6 py-12 text-center text-gray-500">No tickets found</td></tr>
                ) : (
                  tickets.map((ticket) => (
                    <tr key={ticket.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                      <td className="px-6 py-4 font-mono text-sm">{ticket.id.slice(0, 8)}</td>
                      <td className="px-6 py-4">
                        <span className="flex items-center gap-2">
                          <MessageSquare className="w-3.5 h-3.5 text-gray-400" />
                          {ticket.subject}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <Badge variant={statusVariant[ticket.status] || 'default'}>{t(ticket.status)}</Badge>
                      </td>
                      <td className="px-6 py-4">{ticket.created_at ? new Date(ticket.created_at).toLocaleDateString() : '—'}</td>
                      <td className="px-6 py-4">
                        <Button variant="ghost" size="sm">View</Button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
