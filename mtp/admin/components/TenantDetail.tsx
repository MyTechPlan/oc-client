'use client'
import React, { useState } from 'react'
import Link from 'next/link'
import { Tenant } from '@/lib/tenants'
import { TreeNode, CronJob } from '@/lib/github'
import FileEditor from './FileEditor'

type Tab = 'files' | 'logs' | 'crons'

function FileTreeNode({ node, depth, onSelect }: { node: TreeNode; depth: number; onSelect: (node: TreeNode) => void }) {
  const [expanded, setExpanded] = useState(depth === 0)

  if (node.type === 'dir') {
    return (
      <div>
        <button
          onClick={() => setExpanded(!expanded)}
          className="flex items-center gap-2 w-full text-left px-3 py-1.5 hover:bg-gray-800 rounded text-sm transition-colors"
          style={{ paddingLeft: `${depth * 16 + 12}px` }}
        >
          <span className="text-gray-500 text-xs w-4">{expanded ? '▼' : '▶'}</span>
          <span>📁</span>
          <span className="text-gray-300">{node.name}</span>
        </button>
        {expanded && node.children?.map(child => (
          <FileTreeNode key={child.path} node={child} depth={depth + 1} onSelect={onSelect} />
        ))}
      </div>
    )
  }

  return (
    <button
      onClick={() => onSelect(node)}
      className="flex items-center gap-2 w-full text-left px-3 py-1.5 hover:bg-gray-800 rounded text-sm transition-colors"
      style={{ paddingLeft: `${depth * 16 + 28}px` }}
    >
      <span>📄</span>
      <span className="text-blue-400 hover:text-blue-300">{node.name}</span>
    </button>
  )
}

function formatNextRun(ms?: number): string {
  if (!ms) return '—'
  const d = new Date(ms)
  return d.toLocaleString('es-ES', { timeZone: 'Europe/Madrid', day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function formatTimestamp(ms?: number): string {
  if (!ms) return '—'
  const d = new Date(ms)
  return d.toLocaleString('es-ES', { timeZone: 'Europe/Madrid', day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' })
}

export default function TenantDetail({ tenant, tree, cronJobs }: { tenant: Tenant; tree: TreeNode[]; cronJobs: CronJob[] }) {
  const [tab, setTab] = useState<Tab>('files')
  const [selectedFile, setSelectedFile] = useState<TreeNode | null>(null)
  const [expandedCrons, setExpandedCrons] = useState<Set<string>>(new Set())

  const toggleCron = (id: string) => {
    setExpandedCrons(prev => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

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
        <button
          onClick={() => setTab('crons')}
          className={`px-4 py-2 rounded-t text-sm font-medium ${tab === 'crons' ? 'bg-gray-800 text-white' : 'text-gray-400 hover:text-white'}`}
        >
          ⏰ Crons
        </button>
      </div>

      {tab === 'files' && !selectedFile && (
        <div className="bg-gray-900 border border-gray-800 rounded-lg p-2">
          {tree.length === 0 && <p className="text-gray-500 p-4">No files found</p>}
          {tree.map(node => (
            <FileTreeNode key={node.path} node={node} depth={0} onSelect={setSelectedFile} />
          ))}
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

      {tab === 'crons' && (
        <div className="bg-gray-900 border border-gray-800 rounded-lg overflow-hidden">
          {cronJobs.length === 0 ? (
            <p className="text-gray-500 p-8 text-center">No cron jobs configured</p>
          ) : (
            <table className="w-full text-sm">
              <thead className="bg-gray-800 text-gray-400">
                <tr>
                  <th className="text-left px-4 py-3">Name</th>
                  <th className="text-left px-4 py-3">Schedule</th>
                  <th className="text-left px-4 py-3">Status</th>
                  <th className="text-left px-4 py-3">Next Run</th>
                  <th className="text-left px-4 py-3">Type</th>
                  <th className="text-left px-4 py-3">Message</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800">
                {cronJobs.map(job => (
                  <React.Fragment key={job.id}>
                    <tr onClick={() => toggleCron(job.id)} className="hover:bg-gray-800/50 cursor-pointer">
                      <td className="px-4 py-3 text-white font-medium">
                        <span className="text-gray-500 text-xs mr-2">{expandedCrons.has(job.id) ? '▼' : '▶'}</span>
                        {job.name}
                      </td>
                      <td className="px-4 py-3 text-gray-300">
                        <code className="text-xs bg-gray-800 px-2 py-1 rounded">{job.schedule.expr}</code>
                        <span className="text-gray-500 text-xs ml-2">{job.schedule.tz}</span>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`text-xs px-2 py-1 rounded-full font-medium ${job.enabled ? 'bg-green-900/50 text-green-400' : 'bg-red-900/50 text-red-400'}`}>
                          {job.enabled ? 'Enabled' : 'Disabled'}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-gray-400 text-xs">{formatNextRun(job.state?.nextRunAtMs)}</td>
                      <td className="px-4 py-3">
                        <span className="text-xs bg-blue-900/50 text-blue-400 px-2 py-1 rounded">{job.payload.kind}</span>
                      </td>
                      <td className="px-4 py-3 text-gray-400 text-xs max-w-xs truncate">{job.payload.message?.slice(0, 100)}{(job.payload.message?.length || 0) > 100 ? '…' : ''}</td>
                    </tr>
                    {expandedCrons.has(job.id) && (
                      <tr>
                        <td colSpan={6} className="p-0">
                          <div className="bg-gray-800/70 px-6 py-4 border-t border-gray-700 space-y-3 text-sm">
                            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                              <div>
                                <span className="text-gray-500 text-xs uppercase tracking-wider">ID</span>
                                <p className="text-gray-300 font-mono text-xs mt-1">{job.id}</p>
                              </div>
                              <div>
                                <span className="text-gray-500 text-xs uppercase tracking-wider">Name</span>
                                <p className="text-white mt-1">{job.name}</p>
                              </div>
                              <div>
                                <span className="text-gray-500 text-xs uppercase tracking-wider">Status</span>
                                <p className={`mt-1 font-medium ${job.enabled ? 'text-green-400' : 'text-red-400'}`}>
                                  {job.enabled ? '✅ Enabled' : '❌ Disabled'}
                                </p>
                              </div>
                              <div>
                                <span className="text-gray-500 text-xs uppercase tracking-wider">Schedule</span>
                                <p className="text-gray-300 mt-1">
                                  <code className="bg-gray-900 px-2 py-0.5 rounded text-xs">{job.schedule.kind}: {job.schedule.expr}</code>
                                  <span className="text-gray-500 ml-2 text-xs">({job.schedule.tz})</span>
                                </p>
                              </div>
                              <div>
                                <span className="text-gray-500 text-xs uppercase tracking-wider">Payload Type</span>
                                <p className="text-blue-400 mt-1">{job.payload.kind}</p>
                              </div>
                              <div>
                                <span className="text-gray-500 text-xs uppercase tracking-wider">Session Target</span>
                                <p className="text-gray-300 mt-1">{job.sessionTarget || '—'}</p>
                              </div>
                              {job.payload.timeoutSeconds && (
                                <div>
                                  <span className="text-gray-500 text-xs uppercase tracking-wider">Timeout</span>
                                  <p className="text-gray-300 mt-1">{job.payload.timeoutSeconds}s</p>
                                </div>
                              )}
                              {job.delivery && (
                                <div>
                                  <span className="text-gray-500 text-xs uppercase tracking-wider">Delivery</span>
                                  <p className="text-gray-300 mt-1">{job.delivery.mode}</p>
                                </div>
                              )}
                              <div>
                                <span className="text-gray-500 text-xs uppercase tracking-wider">Next Run</span>
                                <p className="text-gray-300 mt-1">{formatNextRun(job.state?.nextRunAtMs)}</p>
                              </div>
                            </div>
                            <div>
                              <span className="text-gray-500 text-xs uppercase tracking-wider">Message</span>
                              <pre className="mt-1 bg-gray-900 border border-gray-700 rounded-lg p-3 text-gray-300 text-xs whitespace-pre-wrap break-words max-h-64 overflow-y-auto">
                                {job.payload.message || '—'}
                              </pre>
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}
