'use client'

import { Card, CardContent, CardHeader } from '@/components/ui/Card'
import { useTranslations } from 'next-intl'
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Legend
} from 'recharts'

const data = [
  { month: 'Jan', shipments: 400, delivered: 380 },
  { month: 'Feb', shipments: 300, delivered: 280 },
  { month: 'Mar', shipments: 600, delivered: 550 },
  { month: 'Apr', shipments: 800, delivered: 720 },
  { month: 'May', shipments: 500, delivered: 480 },
  { month: 'Jun', shipments: 700, delivered: 650 },
  { month: 'Jul', shipments: 900, delivered: 820 },
]

export function ShipmentsChart() {
  const t = useTranslations('dashboard')

  return (
    <Card>
      <CardHeader>
        <h3 className="text-lg font-semibold">{t('shipmentsOverTime')}</h3>
      </CardHeader>
      <CardContent>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis dataKey="month" stroke="#9ca3af" fontSize={12} />
              <YAxis stroke="#9ca3af" fontSize={12} />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'var(--tooltip-bg, #fff)',
                  border: '1px solid #e5e7eb',
                  borderRadius: '8px',
                }}
              />
              <Legend />
              <Line
                type="monotone"
                dataKey="shipments"
                stroke="#3b82f6"
                strokeWidth={2}
                dot={{ fill: '#3b82f6', r: 4 }}
                name="Shipments"
              />
              <Line
                type="monotone"
                dataKey="delivered"
                stroke="#22c55e"
                strokeWidth={2}
                dot={{ fill: '#22c55e', r: 4 }}
                name="Delivered"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  )
}
