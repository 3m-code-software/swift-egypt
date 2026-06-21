'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import { get, put } from '@/lib/api'

export interface NotificationItem {
  id: string
  title: string
  message: string | null
  type: string
  is_read: boolean
  created_at: string | null
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api'

function wsUrl(): string | null {
  if (typeof window === 'undefined') return null
  const token = localStorage.getItem('auth_token')
  if (!token) return null
  const base = API_BASE.replace(/^http/, 'ws')
  return `${base}/v1/ws?token=${encodeURIComponent(token)}`
}

export function useNotifications() {
  const [notifications, setNotifications] = useState<NotificationItem[]>([])
  const [unreadCount, setUnreadCount] = useState(0)
  const wsRef = useRef<WebSocket | null>(null)
  const pollingRef = useRef<NodeJS.Timeout | null>(null)
  const reconnectRef = useRef<number>(0)

  const fetchRest = useCallback(async () => {
    try {
      const [notifs, countData] = await Promise.all([
        get<NotificationItem[]>('/v1/notifications/?limit=5'),
        get<{ count: number }>('/v1/notifications/unread-count'),
      ])
      setNotifications(notifs)
      setUnreadCount(countData.count)
    } catch {}
  }, [])

  const connectWs = useCallback(() => {
    const url = wsUrl()
    if (!url) return
    try {
      const ws = new WebSocket(url)
      ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data)
          if (msg.type === 'new_notification') {
            setNotifications((prev) => [msg.data, ...prev].slice(0, 5))
            setUnreadCount((prev) => prev + 1)
          } else if (msg.type === 'all_read') {
            setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })))
            setUnreadCount(0)
          }
        } catch {}
      }
      ws.onclose = () => {
        if (reconnectRef.current < 3) {
          reconnectRef.current++
          setTimeout(connectWs, 3000 * reconnectRef.current)
        }
      }
      ws.onopen = () => {
        reconnectRef.current = 0
      }
      wsRef.current = ws
    } catch {}
  }, [])

  const markAllRead = useCallback(async () => {
    try {
      await put('/v1/notifications/read-all', {})
    } catch {}
  }, [])

  useEffect(() => {
    fetchRest()
    connectWs()
    pollingRef.current = setInterval(fetchRest, 30000)
    return () => {
      if (wsRef.current) wsRef.current.close()
      if (pollingRef.current) clearInterval(pollingRef.current)
    }
  }, [fetchRest, connectWs])

  return { notifications, unreadCount, markAllRead, refresh: fetchRest }
}
