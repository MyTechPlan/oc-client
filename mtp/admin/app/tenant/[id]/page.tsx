import { redirect } from 'next/navigation'
import { verifyAuth } from '@/lib/auth'
import { getTenant } from '@/lib/tenants'
import { listFiles } from '@/lib/github'
import TenantDetail from '@/components/TenantDetail'

export default async function TenantPage({ params }: { params: { id: string } }) {
  const authed = await verifyAuth()
  if (!authed) redirect('/login')

  const tenant = getTenant(params.id)
  if (!tenant) redirect('/')

  // Try workspace/ first (Vesta), fallback to root (Enki)
  let files = await listFiles(tenant.repo, 'workspace')
  let memoryFiles = await listFiles(tenant.repo, 'workspace/memory')

  if (files.length === 0) {
    files = await listFiles(tenant.repo, '.')
    memoryFiles = await listFiles(tenant.repo, 'memory')
  }

  const allFiles = [
    ...files.filter(f => f.type === 'file'),
    ...memoryFiles.filter(f => f.type === 'file').map(f => ({ ...f, path: f.path })),
  ]

  return <TenantDetail tenant={tenant} files={allFiles} />
}
