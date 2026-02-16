export interface Tenant {
  id: string
  name: string
  repo: string
}

export const TENANTS: Tenant[] = [
  { id: 'enki', name: 'Enki', repo: 'MyTechPlan/taas-enki' },
  { id: 'vesta', name: 'Vesta', repo: 'MyTechPlan/taas-vesta' },
]

export function getTenant(id: string): Tenant | undefined {
  return TENANTS.find(t => t.id === id)
}

export const WORKSPACE_FILES = [
  'workspace/SOUL.md',
  'workspace/MEMORY.md',
  'workspace/TOOLS.md',
  'workspace/USER.md',
  'workspace/AGENTS.md',
  'workspace/HEARTBEAT.md',
]
