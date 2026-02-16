import { NextRequest, NextResponse } from 'next/server'
import { checkPassword, createToken } from '@/lib/auth'

export async function POST(req: NextRequest) {
  // Check if it's a form submission (logout)
  const contentType = req.headers.get('content-type') || ''
  if (contentType.includes('form')) {
    const res = NextResponse.redirect(new URL('/login', req.url))
    res.cookies.delete('auth-token')
    return res
  }

  const { password } = await req.json()
  if (!checkPassword(password)) {
    return NextResponse.json({ error: 'Invalid password' }, { status: 401 })
  }

  const token = await createToken()
  const res = NextResponse.json({ ok: true })
  res.cookies.set('auth-token', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 86400,
    path: '/',
  })
  return res
}
