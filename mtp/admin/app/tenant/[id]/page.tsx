import { redirect } from 'next/navigation'
import { verifyAuth } from '@/lib/auth'
import { getTenant } from '@/lib/tenants'
import { listTree, getCronJobs } from '@/lib/github'
import TenantDetail from '@/components/TenantDetail'

export default async function TenantPage({ params }: { params: { id: string } }) {
  const authed = await verifyAuth()
  if (!authed) redirect('/login')

  const tenant = getTenant(params.id)
  if (!tenant) redirect('/')

  const [{ tree }, cronJobs] = await Promise.all([
    listTree(tenant.repo),
    getCronJobs(tenant.repo),
  ])

  return <TenantDetail tenant={tenant} tree={tree} cronJobs={cronJobs} />
}
