import { NextResponse } from 'next/server'
import { verifyAuth } from '@/lib/auth'
import { TENANTS } from '@/lib/tenants'

export async function GET() {
  if (!(await verifyAuth())) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  return NextResponse.json(TENANTS)
}
