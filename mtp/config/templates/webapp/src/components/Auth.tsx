import { supabase } from '../lib/supabase'

export function Auth() {
  const signInWithGoogle = async () => {
    await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: window.location.origin,
      },
    })
  }

  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      justifyContent: 'center', minHeight: '100vh', gap: '1rem',
      fontFamily: 'system-ui, sans-serif',
    }}>
      <h1>{{DISPLAY_NAME}}</h1>
      <p style={{ color: '#666' }}>Inicia sesión para continuar</p>
      <button
        onClick={signInWithGoogle}
        style={{
          padding: '12px 24px', fontSize: '16px', cursor: 'pointer',
          border: '1px solid #ddd', borderRadius: '8px', background: 'white',
          display: 'flex', alignItems: 'center', gap: '8px',
        }}
      >
        <svg width="18" height="18" viewBox="0 0 18 18"><path d="M16.51 8H8.98v3h4.3c-.18 1-.74 1.48-1.6 2.04v2.01h2.6a7.8 7.8 0 0 0 2.38-5.88c0-.57-.05-.66-.15-1.18Z" fill="#4285F4"/><path d="M8.98 17c2.16 0 3.97-.72 5.3-1.94l-2.6-2a4.8 4.8 0 0 1-7.18-2.54H1.83v2.07A8 8 0 0 0 8.98 17Z" fill="#34A853"/><path d="M4.5 10.52a4.8 4.8 0 0 1 0-3.04V5.41H1.83a8 8 0 0 0 0 7.18l2.67-2.07Z" fill="#FBBC05"/><path d="M8.98 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.59A8 8 0 0 0 1.83 5.4L4.5 7.49A4.77 4.77 0 0 1 8.98 3.58Z" fill="#EA4335"/></svg>
        Continuar con Google
      </button>
    </div>
  )
}
