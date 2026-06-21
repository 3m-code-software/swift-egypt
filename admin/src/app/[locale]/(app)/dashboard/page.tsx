import { Suspense } from 'react'
import { PageLoading } from '@/components/shared/LoadingSpinner'
import DashboardContent from './DashboardContent'

export default function DashboardPage() {
  return (
    <Suspense fallback={<PageLoading />}>
      <DashboardContent />
    </Suspense>
  )
}
