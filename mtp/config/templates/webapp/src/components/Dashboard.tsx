import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { User } from '@supabase/supabase-js'

interface DashboardProps {
  user: User
}

export function Dashboard({ user }: DashboardProps) {
  const [loading, setLoading] = useState(false)

  const signOut = async () => {
    setLoading(true)
    await supabase.auth.signOut()
  }

  return (
    <div style={{ padding: '2rem', fontFamily: 'system-ui, sans-serif', maxWidth: '800px', margin: '0 auto' }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h1>{{DISPLAY_NAME}}</h1>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <span style={{ color: '#666' }}>{user.email}</span>
          <button onClick={signOut} disabled={loading}
            style={{ padding: '8px 16px', cursor: 'pointer', border: '1px solid #ddd', borderRadius: '6px', background: 'white' }}>
            Cerrar sesión
          </button>
        </div>
      </header>
      
      <main>
        <div style={{ padding: '2rem', border: '1px solid #eee', borderRadius: '12px', textAlign: 'center', color: '#999' }}>
          <p>🚧 Dashboard en construcción</p>
          <p>Tu bot está trabajando en esto. Pedile lo que necesites.</p>
        </div>
      </main>
    </div>
  )
}
