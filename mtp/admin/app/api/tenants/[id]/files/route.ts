import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth'
import { getTenant } from '@/lib/tenants'
import { listFiles } from '@/lib/github'

export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  if (!(await verifyAuth())) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const tenant = getTenant(params.id)
  if (!tenant) return NextResponse.json({ error: 'Not found' }, { status: 404 })

  // Try workspace/ first (Vesta structure), fallback to root (Enki structure)
  let basePath = 'workspace'
  let files = await listFiles(tenant.repo, 'workspace')
  let memoryFiles = await listFiles(tenant.repo, 'workspace/memory')
  
  if (files.length === 0) {
    // Fallback: files in repo root
    basePath = ''
    files = await listFiles(tenant.repo, '.')
    memoryFiles = await listFiles(tenant.repo, 'memory')
  }

  const allFiles = [
    ...files.filter(f => f.type === 'file'),
    ...memoryFiles.filter(f => f.type === 'file'),
  ]

  console.log(`[files] tenant=${params.id} repo=${tenant.repo} basePath=${basePath} found=${allFiles.length}`)

  return NextResponse.json(allFiles)
}
