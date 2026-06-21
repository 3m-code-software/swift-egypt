import { Suspense } from 'react'
import { PageLoading } from '@/components/shared/LoadingSpinner'
import ShipmentsPageContent from './ShipmentsPageContent'

export default function ShipmentsPage() {
  return (
    <Suspense fallback={<PageLoading />}>
      <ShipmentsPageContent />
    </Suspense>
  )
}
