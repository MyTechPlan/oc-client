'use client'
import { useState } from 'react'
import Link from 'next/link'
import { Tenant } from '@/lib/tenants'
import { GHFile } from '@/lib/github'
import FileEditor from './FileEditor'

type Tab = 'files' | 'logs'

export default function TenantDetail({ tenant, files }: { tenant: Tenant; files: GHFile[] }) {
  const [tab, setTab] = useState<Tab>('files')
  const [selectedFile, setSelectedFile] = useState<GHFile | null>(null)

  return (
    <div className="max-w-6xl mx-auto p-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/" className="text-gray-400 hover:text-white">← Back</Link>
        <h1 className="text-2xl font-bold">{tenant.name}</h1>
        <span className="text-sm text-gray-500">{tenant.repo}</span>
      </div>

      <div className="flex gap-2 mb-6 border-b border-gray-800 pb-2">
        <button
          onClick={() => { setTab('files'); setSelectedFile(null) }}
          className={`px-4 py-2 rounded-t text-sm font-medium ${tab === 'files' ? 'bg-gray-800 text-white' : 'text-gray-400 hover:text-white'}`}
        >
          📁 Files
        </button>
        <button
          onClick={() => setTab('logs')}
          className={`px-4 py-2 rounded-t text-sm font-medium ${tab === 'logs' ? 'bg-gray-800 text-white' : 'text-gray-400 hover:text-white'}`}
        >
          📋 Logs
        </button>
      </div>

      {tab === 'files' && !selectedFile && (
        <div className="grid gap-2">
          {files.map(f => (
            <button
              key={f.path}
              onClick={() => setSelectedFile(f)}
              className="text-left px-4 py-3 bg-gray-900 border border-gray-800 rounded-lg hover:border-blue-500 transition-colors"
            >
              <span className="text-blue-400">{f.path}</span>
            </button>
          ))}
          {files.length === 0 && <p className="text-gray-500">No files found in workspace/</p>}
        </div>
      )}

      {tab === 'files' && selectedFile && (
        <div>
          <button onClick={() => setSelectedFile(null)} className="text-gray-400 hover:text-white text-sm mb-4">
            ← Back to files
          </button>
          <FileEditor tenantId={tenant.id} filePath={selectedFile.path} />
        </div>
      )}

      {tab === 'logs' && (
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-8 text-center">
          <p className="text-gray-400 text-lg">📋 Logs require tunnel connection</p>
          <p className="text-gray-500 text-sm mt-2">Coming soon — Phase 2 via Cloudflare Tunnel</p>
        </div>
      )}
    </div>
  )
}
