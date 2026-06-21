'use client'

import { useState, useEffect, useCallback } from 'react'
import { useTranslations } from 'next-intl'
import { Wallet, TrendingUp, DollarSign, RefreshCw } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { get } from '@/lib/api'
import { Button } from '@/components/ui/Button'

interface WalletData {
  wallet_balance: number
  total_earned: number
  total_commission: number
}

export default function SellerWalletPage() {
  const t = useTranslations()
  const [wallet, setWallet] = useState<WalletData | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const fetchWallet = useCallback(async () => {
    setIsLoading(true)
    try {
      const data = await get<WalletData>('/v1/sellers/me/wallet')
      setWallet(data)
    } catch {
      setWallet(null)
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => { fetchWallet() }, [fetchWallet])

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('sellerNav.wallet')}</h1>
        <Button variant="ghost" size="sm" onClick={fetchWallet}>
          <RefreshCw className="w-4 h-4" />
        </Button>
      </div>

      {isLoading ? (
        <div className="text-center py-12 text-gray-500">{t('common.loading')}</div>
      ) : wallet ? (
        <>
          <Card className="bg-gradient-to-br from-primary-500 to-primary-700 text-white">
            <CardContent className="p-6">
              <div className="flex items-center gap-3 mb-4">
                <Wallet className="w-6 h-6" />
                <p className="text-sm font-medium opacity-80">{t('sellers.walletBalance')}</p>
              </div>
              <p className="text-4xl font-bold mb-1">{wallet.wallet_balance.toFixed(2)} EGP</p>
              <p className="text-sm opacity-70">Available balance</p>
            </CardContent>
          </Card>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-3 bg-green-100 dark:bg-green-900/30 rounded-lg">
                    <TrendingUp className="w-5 h-5 text-green-600 dark:text-green-400" />
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">{t('batches.totalAmount')}</p>
                    <p className="text-xl font-bold">{wallet.total_earned.toFixed(2)} EGP</p>
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-3 bg-red-100 dark:bg-red-900/30 rounded-lg">
                    <DollarSign className="w-5 h-5 text-red-600 dark:text-red-400" />
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">{t('batches.commission')}</p>
                    <p className="text-xl font-bold">{wallet.total_commission.toFixed(2)} EGP</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </>
      ) : (
        <div className="text-center py-12 text-gray-500">
          <Wallet className="w-12 h-12 mx-auto mb-3 text-gray-400" />
          <p>{t('common.noData')}</p>
        </div>
      )}
    </div>
  )
}
