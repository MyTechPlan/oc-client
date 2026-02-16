import { NextRequest, NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth'
import { getTenant } from '@/lib/tenants'
import { getFile, updateFile } from '@/lib/github'

export async function GET(_req: NextRequest, { params }: { params: { id: string; path: string[] } }) {
  if (!(await verifyAuth())) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const tenant = getTenant(params.id)
  if (!tenant) return NextResponse.json({ error: 'Not found' }, { status: 404 })

  const filePath = params.path.join('/')
  const file = await getFile(tenant.repo, filePath)
  if (!file) return NextResponse.json({ error: 'File not found' }, { status: 404 })
  return NextResponse.json(file)
}

export async function PUT(req: NextRequest, { params }: { params: { id: string; path: string[] } }) {
  if (!(await verifyAuth())) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const tenant = getTenant(params.id)
  if (!tenant) return NextResponse.json({ error: 'Not found' }, { status: 404 })

  const { content, sha } = await req.json()
  const filePath = params.path.join('/')
  const ok = await updateFile(tenant.repo, filePath, content, sha)
  if (!ok) return NextResponse.json({ error: 'Failed to update' }, { status: 500 })
  return NextResponse.json({ ok: true })
}
