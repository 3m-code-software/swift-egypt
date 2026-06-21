'use client'

import { useState, useEffect } from 'react'
import { useTranslations } from 'next-intl'
import { useParams } from 'next/navigation'
import { useAuth } from '@/hooks/useAuth'
import { useToast } from '@/components/ui/Toast'
import { get, put } from '@/lib/api'
import { Card, CardContent, CardHeader } from '@/components/ui/Card'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Skeleton, SkeletonCard } from '@/components/ui/Skeleton'
import { User, Mail, Phone, Save, Loader2, Key, CheckCircle2, Copy, Calendar, Shield, Building2, CheckCircle, XCircle, Package, Truck, Clock, Activity } from 'lucide-react'

function Avatar({ name, size = 'lg' }: { name: string; size?: 'sm' | 'lg' }) {
  const initials = name
    ? name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
    : '?'
  const sizeClasses = size === 'lg' ? 'w-20 h-20 text-2xl' : 'w-10 h-10 text-sm'

  return (
    <div className={`${sizeClasses} rounded-full bg-primary-100 dark:bg-primary-900/40 flex items-center justify-center font-bold text-primary-600 dark:text-primary-400 border-4 border-white dark:border-gray-800 shadow-md`}>
      {initials}
    </div>
  )
}

function InfoRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: React.ReactNode }) {
  return (
    <div className="flex items-center gap-3 py-3 border-b border-gray-100 dark:border-gray-700/50 last:border-0">
      <div className="w-9 h-9 rounded-lg bg-gray-100 dark:bg-gray-800 flex items-center justify-center text-gray-500 dark:text-gray-400 shrink-0">
        {icon}
      </div>
      <div className="min-w-0">
        <p className="text-xs text-gray-500 dark:text-gray-400">{label}</p>
        <div className="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
          {value}
        </div>
      </div>
    </div>
  )
}

function StatCard({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="bg-gray-50 dark:bg-gray-800/50 rounded-xl p-4 flex items-center gap-3 border border-gray-100 dark:border-gray-700/50">
      <div className="w-10 h-10 rounded-lg bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center text-primary-600 dark:text-primary-400">
        {icon}
      </div>
      <div>
        <p className="text-xs text-gray-500 dark:text-gray-400">{label}</p>
        <p className="text-lg font-bold text-gray-900 dark:text-gray-100">{value}</p>
      </div>
    </div>
  )
}

export default function ProfilePage() {
  const t = useTranslations('profile')
  const ct = useTranslations('common')
  const { user, setUser } = useAuth()
  const params = useParams()
  const locale = params.locale as string

  const { addToast } = useToast()
  const [fullName, setFullName] = useState('')
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')
  const [profileData, setProfileData] = useState<any>(null)
  const [saving, setSaving] = useState(false)
  const [loadingProfile, setLoadingProfile] = useState(true)

  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [changingPassword, setChangingPassword] = useState(false)

  const [copied, setCopied] = useState(false)

  useEffect(() => {
    loadProfile()
  }, [])

  const loadProfile = async () => {
    setLoadingProfile(true)
    try {
      const data = await get<any>('/v1/users/me')
      setProfileData(data)
      setFullName(data.full_name || '')
      setPhone(data.phone || '')
      setEmail(data.email || '')
      if (user) {
        setUser({ ...user, ...data })
      }
    } catch {
    } finally {
      setLoadingProfile(false)
    }
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    try {
      const res = await put<any>('/v1/users/me', { full_name: fullName, phone })
      setProfileData(res)
      if (res && user) {
        setUser({ ...user, full_name: fullName, phone })
      }
      addToast({ type: 'success', message: ct('saved') })
    } catch (err: any) {
      addToast({ type: 'error', message: err.message || 'Failed to save' })
    } finally {
      setSaving(false)
    }
  }

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    if (newPassword !== confirmPassword) {
      addToast({ type: 'error', message: ct('passwordsDoNotMatch') })
      return
    }
    if (newPassword.length < 8) {
      addToast({ type: 'error', message: ct('passwordTooShort') })
      return
    }
    setChangingPassword(true)
    try {
      await put('/v1/users/me/password', {
        current_password: currentPassword,
        new_password: newPassword,
      })
      addToast({ type: 'success', message: ct('passwordChanged') })
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
    } catch (err: any) {
      addToast({ type: 'error', message: err.message || 'Failed to change password' })
    } finally {
      setChangingPassword(false)
    }
  }

  const copyId = (id: string) => {
    navigator.clipboard.writeText(id)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const formatDate = (dateStr: string | undefined) => {
    if (!dateStr) return '—'
    try {
      const d = new Date(dateStr)
      return d.toLocaleDateString(locale === 'ar' ? 'ar-EG' : 'en-US', {
        year: 'numeric', month: 'long', day: 'numeric',
      })
    } catch {
      return dateStr
    }
  }

  const roleColors: Record<string, 'danger' | 'warning' | 'info' | 'default'> = {
    admin: 'danger',
    operations: 'warning',
    branch_manager: 'info',
    driver: 'default',
    customer: 'default',
    finance: 'info',
  }

  if (loadingProfile) {
    return (
      <div className="space-y-6 max-w-3xl">
        <Skeleton className="h-32 rounded-xl" />
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
          <div className="lg:col-span-3 space-y-6">
            <Skeleton className="h-64 rounded-xl" />
            <Skeleton className="h-72 rounded-xl" />
          </div>
          <div className="lg:col-span-2">
            <Skeleton className="h-80 rounded-xl" />
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Hero */}
      <Card className="overflow-hidden">
        <div className="h-32 bg-gradient-to-r from-primary-600 to-primary-800 dark:from-primary-800 dark:to-primary-950" />
        <CardContent className="relative px-6 pb-6">
          <div className="flex flex-col sm:flex-row sm:items-end gap-4 -mt-16">
            <Avatar name={profileData?.full_name || user?.full_name || ''} />
            <div className="sm:pb-1">
              <h1 className="text-xl font-bold text-gray-900 dark:text-gray-100">
                {profileData?.full_name || user?.full_name}
              </h1>
              <div className="flex items-center gap-2 mt-1">
                <Mail className="w-4 h-4 text-gray-400" />
                <span className="text-sm text-gray-500 dark:text-gray-400">{profileData?.email || user?.email}</span>
              </div>
            </div>
            <div className="sm:ml-auto flex items-center gap-2 mt-2 sm:mt-0">
              <Badge variant={roleColors[profileData?.role || user?.role || ''] || 'default'}>
                {ct(`role_${profileData?.role || user?.role}` as any)}
              </Badge>
              {profileData?.is_active !== false && (
                <Badge variant="success">
                  {ct('active')}
                </Badge>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <StatCard icon={<Package className="w-5 h-5" />} label={ct('total')} value="—" />
        <StatCard icon={<Truck className="w-5 h-5" />} label="Active" value="—" />
        <StatCard icon={<Clock className="w-5 h-5" />} label={t('memberSince')} value={formatDate(profileData?.created_at)} />
        <StatCard icon={<Activity className="w-5 h-5" />} label={t('lastUpdated')} value={formatDate(profileData?.updated_at)} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        {/* Personal Info */}
        <div className="lg:col-span-3 space-y-6">
          <Card>
            <CardHeader>
              <h3 className="font-semibold flex items-center gap-2">
                <User className="w-5 h-5 text-primary-500" />
                {t('personalInfo')}
              </h3>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSave} className="space-y-4">
                <Input
                  label={t('fullName')}
                  id="fullName"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                />
                <Input
                  label={t('email')}
                  id="email"
                  value={email}
                  disabled
                />
                <Input
                  label={t('phone')}
                  id="phone"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  dir="ltr"
                />

                <div className="pt-2">
                  <Button type="submit" disabled={saving}>
                    {saving ? <Loader2 className="w-4 h-4 me-2 animate-spin" /> : <Save className="w-4 h-4 me-2" />}
                    {saving ? ct('saving') : ct('save')}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>

          {/* Security */}
          <Card>
            <CardHeader>
              <h3 className="font-semibold flex items-center gap-2">
                <Key className="w-5 h-5 text-primary-500" />
                {t('changePassword')}
              </h3>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleChangePassword} className="space-y-4">
                <p className="text-sm text-gray-500 dark:text-gray-400">{t('passwordHint')}</p>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <Input type="password" label={t('currentPassword')} value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} placeholder="••••••••" required />
                  <Input type="password" label={t('newPassword')} value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="••••••••" required />
                  <Input type="password" label={t('confirmPassword')} value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} placeholder="••••••••" required />
                </div>
                <div className="pt-2">
                  <Button type="submit" disabled={changingPassword}>
                    {changingPassword ? <Loader2 className="w-4 h-4 animate-spin" /> : <Key className="w-4 h-4" />}
                    {changingPassword ? ct('saving') : ct('changePassword')}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>

        {/* Account Details Sidebar */}
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <h3 className="font-semibold flex items-center gap-2">
                <Shield className="w-5 h-5 text-primary-500" />
                {t('accountDetails')}
              </h3>
            </CardHeader>
            <CardContent className="divide-y divide-gray-100 dark:divide-gray-700/50">
              <InfoRow
                icon={<Mail className="w-4 h-4" />}
                label={t('email')}
                value={profileData?.email}
              />
              <InfoRow
                icon={<Building2 className="w-4 h-4" />}
                label={t('branch')}
                value={profileData?.branch_name || ct('noBranch')}
              />
              <InfoRow
                icon={<Shield className="w-4 h-4" />}
                label={t('roleLabel')}
                value={
                  <Badge variant={roleColors[profileData?.role || ''] || 'default'} size="sm">
                    {ct(`role_${profileData?.role}` as any)}
                  </Badge>
                }
              />
              <InfoRow
                icon={profileData?.is_verified ? <CheckCircle className="w-4 h-4 text-green-500" /> : <XCircle className="w-4 h-4 text-gray-400" />}
                label={t('emailVerified')}
                value={
                  profileData?.is_verified
                    ? <span className="text-green-600 dark:text-green-400">{ct('yes')}</span>
                    : <span className="text-gray-400">{ct('no')}</span>
                }
              />
              <InfoRow
                icon={<Calendar className="w-4 h-4" />}
                label={t('memberSince')}
                value={formatDate(profileData?.created_at)}
              />
              <InfoRow
                icon={<Clock className="w-4 h-4" />}
                label={t('lastUpdated')}
                value={formatDate(profileData?.updated_at)}
              />
              <InfoRow
                icon={<Copy className="w-4 h-4" />}
                label="User ID"
                value={
                  <button onClick={() => copyId(profileData?.id)} className="flex items-center gap-1.5 text-primary-600 dark:text-primary-400 hover:underline text-xs font-mono">
                    {profileData?.id?.slice(0, 8)}...
                    {copied ? <CheckCircle2 className="w-3 h-3" /> : <Copy className="w-3 h-3" />}
                  </button>
                }
              />
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
