import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import { verifyAuth } from '@/lib/auth'
import { TENANTS } from '@/lib/tenants'
import TenantCard from '@/components/TenantCard'

export default async function Dashboard() {
  const authed = await verifyAuth()
  if (!authed) redirect('/login')

  return (
    <div className="max-w-5xl mx-auto p-8">
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">🛠 TaaS Admin</h1>
        <form action="/api/auth" method="POST">
          <input type="hidden" name="action" value="logout" />
          <button className="text-sm text-gray-400 hover:text-white">Logout</button>
        </form>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {TENANTS.map(t => (
          <TenantCard key={t.id} tenant={t} />
        ))}
      </div>
    </div>
  )
}
