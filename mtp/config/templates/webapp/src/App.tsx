import { useEffect, useState } from 'react'
import { supabase } from './lib/supabase'
import { Auth } from './components/Auth'
import { Dashboard } from './components/Dashboard'
import type { User } from '@supabase/supabase-js'

export default function App() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null)
      setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
    })

    return () => subscription.unsubscribe()
  }, [])

  if (loading) return <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>Cargando...</div>
  
  return user ? <Dashboard user={user} /> : <Auth />
}
