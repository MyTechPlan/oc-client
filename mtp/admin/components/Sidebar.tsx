import Link from 'next/link'
import { TENANTS } from '@/lib/tenants'

export default function Sidebar() {
  return (
    <aside className="w-56 bg-gray-900 border-r border-gray-800 p-4 min-h-screen">
      <h2 className="text-lg font-bold mb-4">🛠 TaaS</h2>
      <nav className="space-y-1">
        {TENANTS.map(t => (
          <Link key={t.id} href={`/tenant/${t.id}`}
            className="block px-3 py-2 rounded hover:bg-gray-800 text-gray-300 hover:text-white text-sm">
            {t.name}
          </Link>
        ))}
      </nav>
    </aside>
  )
}
