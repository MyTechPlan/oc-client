import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth'
import { getTenant } from '@/lib/tenants'
import { listTree } from '@/lib/github'

export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  if (!(await verifyAuth())) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const tenant = getTenant(params.id)
  if (!tenant) return NextResponse.json({ error: 'Not found' }, { status: 404 })

  const { tree, basePath } = await listTree(tenant.repo)

  console.log(`[files] tenant=${params.id} repo=${tenant.repo} basePath=${basePath} treeNodes=${tree.length}`)

  return NextResponse.json({ tree, basePath })
}
