'use client'

import { useState, useRef, useEffect } from 'react'
import { useParams } from 'next/navigation'
import { MessageCircle, X, Send, Bot, Loader2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import { post } from '@/lib/api'

interface Message {
  role: 'user' | 'ai'
  content: string
}

export function AiChat() {
  const [open, setOpen] = useState(false)
  const [messages, setMessages] = useState<Message[]>([
    { role: 'ai', content: 'مرحباً! أنا Swift AI، المساعد الذكي. كيف يمكنني مساعدتك اليوم؟' },
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const params = useParams()
  const locale = (params.locale as string) || 'ar'
  const isRtl = locale === 'ar'

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSend = async () => {
    const msg = input.trim()
    if (!msg || loading) return
    setInput('')
    setError(null)
    setMessages((prev) => [...prev, { role: 'user', content: msg }])
    setLoading(true)
    try {
      const data = await post<{ reply: string }>('/v1/ai/chat', { message: msg })
      setMessages((prev) => [...prev, { role: 'ai', content: data.reply }])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'حدث خطأ أثناء الاتصال بالمساعد')
    } finally {
      setLoading(false)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  return (
    <>
      {/* Floating action button */}
      <button
        onClick={() => setOpen(true)}
        className={cn(
          'fixed bottom-6 z-50 flex h-14 w-14 items-center justify-center rounded-full shadow-lg transition-all hover:scale-110 active:scale-95',
          'bg-primary-600 text-white hover:bg-primary-700 dark:bg-primary-500 dark:hover:bg-primary-600',
          isRtl ? 'left-6' : 'right-6'
        )}
        aria-label="Open AI Chat"
      >
        <MessageCircle className="h-6 w-6" />
      </button>

      {/* Overlay */}
      {open && (
        <div
          className="fixed inset-0 z-40 bg-black/30 backdrop-blur-sm"
          onClick={() => setOpen(false)}
        />
      )}

      {/* Chat drawer */}
      <div
        className={cn(
          'fixed inset-y-0 z-50 flex w-full max-w-md flex-col bg-white shadow-xl transition-transform duration-300 dark:bg-gray-900',
          isRtl ? 'left-0' : 'right-0',
          open
            ? 'translate-x-0'
            : isRtl
              ? '-translate-x-full'
              : 'translate-x-full'
        )}
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b px-4 py-3 dark:border-gray-700">
          <div className="flex items-center gap-2">
            <Bot className="h-6 w-6 text-primary-600 dark:text-primary-400" />
            <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Swift AI
            </span>
          </div>
          <button
            onClick={() => setOpen(false)}
            className="rounded-lg p-1.5 text-gray-500 hover:bg-gray-100 hover:text-gray-700 dark:hover:bg-gray-800 dark:hover:text-gray-300"
            aria-label="Close"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4" dir={isRtl ? 'rtl' : 'ltr'}>
          <div className="flex flex-col gap-4">
            {messages.map((msg, idx) => (
              <div
                key={idx}
                className={cn(
                  'flex',
                  msg.role === 'user' ? 'justify-end' : 'justify-start'
                )}
              >
                <div
                  className={cn(
                    'max-w-[80%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed',
                    msg.role === 'user'
                      ? 'bg-primary-600 text-white rounded-br-md'
                      : 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200 rounded-bl-md'
                  )}
                >
                  {msg.content}
                </div>
              </div>
            ))}
            {loading && (
              <div className="flex justify-start">
                <div className="max-w-[80%] rounded-2xl rounded-bl-md bg-gray-100 px-4 py-3 text-sm text-gray-500 dark:bg-gray-800 dark:text-gray-400">
                  <Loader2 className="h-4 w-4 animate-spin" />
                </div>
              </div>
            )}
            {error && (
              <div className="flex justify-center">
                <div className="rounded-lg bg-red-50 px-4 py-2 text-sm text-red-600 dark:bg-red-900/20 dark:text-red-400">
                  {error}
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>
        </div>

        {/* Input */}
        <div className="border-t p-4 dark:border-gray-700">
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder={isRtl ? 'اكتب رسالتك...' : 'Type your message...'}
              disabled={loading}
              className={cn(
                'flex-1 rounded-xl border border-gray-300 bg-gray-50 px-4 py-2.5 text-sm outline-none transition-colors',
                'focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20',
                'dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100 dark:placeholder-gray-400',
                'disabled:opacity-50 disabled:cursor-not-allowed'
              )}
              dir={isRtl ? 'rtl' : 'ltr'}
            />
            <button
              onClick={handleSend}
              disabled={loading || !input.trim()}
              className={cn(
                'flex h-10 w-10 shrink-0 items-center justify-center rounded-xl transition-colors',
                'bg-primary-600 text-white hover:bg-primary-700',
                'dark:bg-primary-500 dark:hover:bg-primary-600',
                'disabled:opacity-50 disabled:cursor-not-allowed'
              )}
            >
              {loading ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Send className="h-4 w-4" />
              )}
            </button>
          </div>
        </div>
      </div>
    </>
  )
}
