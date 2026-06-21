import { AuthGuard } from '@/components/shared/AuthGuard'
import { DashboardLayout } from '@/components/layout/DashboardLayout'
import { ToastProvider } from '@/components/ui/Toast'
import { ErrorBoundary } from '@/components/shared/ErrorBoundary'

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <ErrorBoundary>
        <ToastProvider>
          <DashboardLayout>{children}</DashboardLayout>
        </ToastProvider>
      </ErrorBoundary>
    </AuthGuard>
  )
}