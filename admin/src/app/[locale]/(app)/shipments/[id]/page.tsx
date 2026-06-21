import { Suspense } from 'react'
import { PageLoading } from '@/components/shared/LoadingSpinner'
import ShipmentDetailContent from './ShipmentDetailContent'

export default function ShipmentDetailPage() {
  return (
    <Suspense fallback={<PageLoading />}>
      <ShipmentDetailContent />
    </Suspense>
  )
}
