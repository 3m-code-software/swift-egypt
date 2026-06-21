'use client'

import { useTranslations } from 'next-intl'
import { Card, CardContent, CardHeader } from '@/components/ui/Card'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Button } from '@/components/ui/Button'
import { useTheme } from '@/components/shared/ThemeProvider'
import { useParams, useRouter } from 'next/navigation'
import { useState } from 'react'

export default function SettingsPage() {
  const t = useTranslations('settings')
  const ct = useTranslations('common')
  const { theme, setTheme } = useTheme()
  const params = useParams()
  const router = useRouter()
  const locale = params.locale as string
  const [companyName, setCompanyName] = useState('Swift Egypt for Shipping & Logistics')

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{t('title')}</h1>

      <div className="max-w-2xl space-y-6">
        <Card>
          <CardHeader>
            <h3 className="font-semibold">{t('general')}</h3>
          </CardHeader>
          <CardContent className="space-y-4">
            <Input
              label={t('companyName')}
              id="companyName"
              value={companyName}
              onChange={(e) => setCompanyName(e.target.value)}
            />
            <Select
              label={t('language')}
              id="language"
              value={locale}
              options={[
                { value: 'en', label: 'English' },
                { value: 'ar', label: 'العربية' },
              ]}
            />
            <Select
              label={t('theme')}
              id="theme"
              value={theme || 'system'}
              onChange={(e) => setTheme(e.target.value as 'light' | 'dark' | 'system')}
              options={[
                { value: 'light', label: t('light') },
                { value: 'dark', label: t('dark') },
                { value: 'system', label: t('system') },
              ]}
            />
            <div className="pt-2">
              <Button>{t('save')}</Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <h3 className="font-semibold">{t('notifications')}</h3>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-gray-500 dark:text-gray-400">Notification settings coming soon...</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
