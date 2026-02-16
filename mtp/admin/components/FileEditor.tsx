'use client'
import { useState, useEffect } from 'react'

export default function FileEditor({ tenantId, filePath }: { tenantId: string; filePath: string }) {
  const [content, setContent] = useState('')
  const [sha, setSha] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [status, setStatus] = useState<'idle' | 'saved' | 'error'>('idle')

  useEffect(() => {
    setLoading(true)
    fetch(`/api/tenants/${tenantId}/files/${filePath}`)
      .then(r => r.json())
      .then(data => {
        setContent(data.content || '')
        setSha(data.sha || '')
        setLoading(false)
      })
      .catch(() => setLoading(false))
  }, [tenantId, filePath])

  async function save() {
    setSaving(true)
    setStatus('idle')
    try {
      const res = await fetch(`/api/tenants/${tenantId}/files/${filePath}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content, sha }),
      })
      if (res.ok) {
        setStatus('saved')
        // Refresh sha
        const updated = await fetch(`/api/tenants/${tenantId}/files/${filePath}`).then(r => r.json())
        setSha(updated.sha)
      } else {
        setStatus('error')
      }
    } catch {
      setStatus('error')
    }
    setSaving(false)
  }

  if (loading) return <div className="text-gray-400">Loading...</div>

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-mono text-blue-400">{filePath}</h2>
        <div className="flex items-center gap-3">
          {status === 'saved' && <span className="text-green-400 text-sm">✓ Saved</span>}
          {status === 'error' && <span className="text-red-400 text-sm">✗ Error saving</span>}
          <button
            onClick={save}
            disabled={saving}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 rounded text-sm font-medium"
          >
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
      <textarea
        value={content}
        onChange={e => { setContent(e.target.value); setStatus('idle') }}
        className="w-full h-[70vh] bg-gray-900 border border-gray-800 rounded-lg p-4 font-mono text-sm resize-none focus:border-blue-500 outline-none"
        spellCheck={false}
      />
    </div>
  )
}
