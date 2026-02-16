import Link from 'next/link'
import { Tenant } from '@/lib/tenants'

export default function TenantCard({ tenant }: { tenant: Tenant }) {
  return (
    <Link href={`/tenant/${tenant.id}`}
      className="block bg-gray-900 border border-gray-800 rounded-xl p-6 hover:border-blue-500 transition-colors">
      <div className="flex items-center gap-3 mb-3">
        <div className="w-3 h-3 rounded-full bg-green-500" />
        <h2 className="text-xl font-semibold">{tenant.name}</h2>
      </div>
      <p className="text-sm text-gray-400">{tenant.repo}</p>
      <p className="text-xs text-gray-500 mt-2">Click to manage files →</p>
    </Link>
  )
}
